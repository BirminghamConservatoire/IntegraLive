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
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.Script;
	
	import flexunit.framework.Assert;
	

	public class AddScript extends ServerCommand
	{
		public function AddScript( parentID:int, scriptID:int = -1, scriptName:String = null )
		{
			super();

			_parentID = parentID;
			_scriptID = scriptID;			
			_scriptName = scriptName;
		}
		
		public function get parentID():int { return _parentID; }
		public function get scriptID():int { return _scriptID; }
		public function get scriptName():String { return _scriptName; }
		
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			var parent:IntegraContainer = model.getDataObjectByID( _parentID ) as IntegraContainer;
			if( !parent ) 
			{
				return false;
			}

			if( _scriptID < 0 )
			{
				_scriptID = model.generateNewID();
			} 

			var definition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Script._serverInterfaceName );
			if( !definition )
			{
				return false;
			}
			
			if( !_scriptName )
			{
				_scriptName = parent.getNewChildName( Script._serverInterfaceName, definition.guid ); 				
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveScript( _scriptID ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var script:Script = new Script();
			
			script.id = _scriptID;
			script.name = _scriptName;

			var definition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Script._serverInterfaceName );
			Assert.assertNotNull( definition );
			script.text = definition.getEndpointDefinition( "text" ).controlInfo.stateInfo.defaultValue.toString(); 
			script.info.markdown = definition.getEndpointDefinition( "info" ).controlInfo.stateInfo.defaultValue.toString();
			
			model.addDataObject( _parentID, script ); 						
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var parentPath:Array = model.getPathArrayFromID( _parentID );
			
			connection.addParam( model.getCoreInterfaceGuid( Script._serverInterfaceName ), XMLRPCDataTypes.STRING );
			connection.addParam( _scriptName, XMLRPCDataTypes.STRING );
			connection.addArrayParam( parentPath );
			
			connection.callQueued( "command.new" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.new" );
		}
		
		
		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new SetPrimarySelectedChild( _parentID, _scriptID ) );
		}		


		private var _parentID:int;
		private var _scriptID:int;
		private var _scriptName:String;
	}
}