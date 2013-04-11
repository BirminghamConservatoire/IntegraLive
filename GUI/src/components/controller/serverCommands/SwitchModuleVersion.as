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
	import components.controller.ServerCommand;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	public class SwitchModuleVersion extends ServerCommand
	{
		public function SwitchModuleVersion( moduleID:int, toGuid:String, newAttributeValues:Object = null )
		{
			super();
	
			_moduleID = moduleID;
			_toGuid = toGuid;		
			
			_newAttributeValues = newAttributeValues;
		}
		
		public function get moduleID():int { return _moduleID; }
		public function get toGuid():String { return _toGuid; }
		public function get newAttributeValues():Object { return _newAttributeValues; }
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			if( !module ) return false;
			
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );
			if( !newInterface ) return false;
			
			if( module.interfaceDefinition.originGuid != newInterface.originGuid ) return false;
			
			if( module.interfaceDefinition.moduleGuid == newInterface.moduleGuid ) return false;
			
			if( !_newAttributeValues )
			{
				_newAttributeValues = generateNewAttributeValues( module.attributes, newInterface );
			}
			
			return true;				
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			Assert.assertNotNull( module );
			
			pushInverseCommand( new SwitchModuleVersion( _moduleID, module.interfaceDefinition.moduleGuid, copyAttributeValues( module.attributes ) ) );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			Assert.assertNotNull( module );

			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );
			Assert.assertNotNull( newInterface );

			module.interfaceDefinition = newInterface;
			
			module.attributes = _newAttributeValues;
		}
		
		
		override public function executeServerCommand( model:IntegraModel ):void
		{
			var modulePath:Array = model.getPathArrayFromID( _moduleID );
			Assert.assertTrue( modulePath.length > 0 );
			
			var moduleName:String = modulePath[ modulePath.length - 1 ];
			var parentPath:Array = modulePath.slice( 0, modulePath.length - 1 );
			
			var methodCalls:Array = new Array;
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.delete";
			methodCalls[ 0 ].params = [ modulePath ];
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.new";
			methodCalls[ 1 ].params = [ _toGuid, moduleName, parentPath ];

			for( var attributeName:String in _newAttributeValues )
			{
				var setCall:Object = new Object;
				setCall.methodName = "command.set";
				setCall.params = [ modulePath.concat( attributeName ), _newAttributeValues[ attributeName ] ];
				
				methodCalls.push( setCall );
			}
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );		
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 2 + Utilities.getNumberOfProperties( _newAttributeValues ) ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 1 ][ 0 ].response != "command.new" ) return false;
			
			for( var i:int = 2; i < response.length; i++ )
			{
				if( response[ i ][ 0 ].response != "command.set" ) return false;
			}
			
			return true;
		}				
			
		
		private function copyAttributeValues( attributeValues:Object ):Object
		{
			var copy:Object = new Object;
			
			for( var key:String in attributeValues )
			{
				copy[ key ] = attributeValues[ key ];
			}
			
			return copy;
		}

		
		private function generateNewAttributeValues( attributeValues:Object, newInterface:InterfaceDefinition ):Object
		{
			//todo
			
			return copyAttributeValues( attributeValues );
		}
		
		
		private var _moduleID:int;
		private var _toGuid:String;		
		
		private var _newAttributeValues:Object;
	}
}