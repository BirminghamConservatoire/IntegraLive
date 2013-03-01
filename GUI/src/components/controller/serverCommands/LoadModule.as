/* Integra Live graphical user interface
 *
 * Copyright (C) 2009 Birmingham City University
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA   02110-1301,
 * USA.
 */


package components.controller.serverCommands
{
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.SetModulePosition;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import flexunit.framework.Assert;

	public class LoadModule extends ServerCommand
	{
		public function LoadModule( interfaceGuid:String, blockID:int, position:Rectangle, moduleID:int = -1, moduleName:String = null )
		{
			super();
	
			_moduleID = moduleID;
			_moduleName = moduleName;		
			_interfaceGuid = interfaceGuid;
			_blockID = blockID;
			_position = position;
		}
		
		public function get moduleID():int { return _moduleID; }
		public function get moduleName():String { return _moduleName; }
		public function get interfaceGuid():String { return _interfaceGuid; }
		public function get blockID():int { return _blockID; }
		public function get position():Rectangle { return _position; }
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByGuid( _interfaceGuid );
			if( !interfaceDefinition )
			{
				return false;
			}

			if( _moduleID < 0 )
			{
				_moduleID = model.generateNewID();
			}
			
			if( !_moduleName )
			{
				_moduleName = model.getBlock( blockID ).getNewChildName( interfaceDefinition.interfaceInfo.name, _interfaceGuid ); 
			}	
			
			return true;				
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new UnloadModule( _moduleID ) );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			var module:ModuleInstance = new ModuleInstance;
			module.id = _moduleID;
			module.name = _moduleName;
			module.interfaceDefinition = model.getInterfaceDefinitionByGuid( _interfaceGuid );
			Assert.assertNotNull( module.interfaceDefinition );
			
			module.attributes = new Object;
			for each( var endpoint:EndpointDefinition in module.interfaceDefinition.endpoints )
			{
				if( !endpoint.isStateful )
				{
					continue;
				}

				module.attributes[ endpoint.name ] = endpoint.controlInfo.stateInfo.defaultValue;
			}
			
			model.addDataObject( _blockID, module );
		}
		
		
		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			//set the initial position
			controller.processCommand( new SetModulePosition( moduleID, _position ) );
			
			//set the initial selection
			controller.processCommand( new SetPrimarySelectedChild(  _blockID, _moduleID ) );
			controller.processCommand( new SetObjectSelection( _moduleID, true ) );
		}
		
		
		override public function executeServerCommand( model:IntegraModel ):void
		{
			connection.addParam( _interfaceGuid, XMLRPCDataTypes.STRING );
			connection.addParam( _moduleName, XMLRPCDataTypes.STRING );
			connection.addArrayParam( model.getPathArrayFromID( _blockID ) );
			connection.callQueued( "command.new" );	
		}


		override protected function testServerResponse( response:Object ):Boolean
		{
			if( response.interfaceid != _interfaceGuid ) return false;
			if( response.instancename != _moduleName ) return false;
			if( response.response != "command.new" ) return false;
			
			return true;
		}
		
		
		private var _moduleID:int;
		private var _moduleName:String;		
		private var _blockID:int;		
		private var _interfaceGuid:String;
		private var _position:Rectangle; 
	}
}