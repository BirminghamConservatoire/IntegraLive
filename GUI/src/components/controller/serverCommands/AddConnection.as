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
	import components.controller.userDataCommands.SetObjectSelection;
	import components.model.Connection;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;
	

	public class AddConnection extends ServerCommand
	{
		public function AddConnection( containerID:int, connectionID:int = -1, connectionName:String = null )
		{
			super();

			_containerID = containerID;			
			_connectionID = connectionID;
			_connectionName = connectionName;
		}
		
		public function get containerID():int { return _containerID; }
		public function get connectionID():int { return _connectionID; }
		public function get connectionName():String { return _connectionName; }
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _connectionID < 0 )
			{
				_connectionID = model.generateNewID();
			} 
			
			if( !_connectionName )
			{
				var container:IntegraContainer = model.getContainer( _containerID );
				Assert.assertNotNull( container );
				
				var connectionDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Connection._serverInterfaceName );
				_connectionName = container.getNewChildName( Connection._serverInterfaceName, connectionDefinition.moduleGuid ); 				
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveConnection( _connectionID ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var connection:Connection = new Connection();
			
			connection.id = _connectionID;
			connection.name = _connectionName;

			model.addDataObject( _containerID, connection ); 						
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var containerPath:Array = model.getPathArrayFromID( _containerID );
			
			connection.addParam( model.getCoreInterfaceGuid( Connection._serverInterfaceName ), XMLRPCDataTypes.STRING );
			connection.addParam( _connectionName, XMLRPCDataTypes.STRING );
			connection.addArrayParam( containerPath );
			
			connection.callQueued( "command.new" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.new" );
		}
		

		private var _containerID:int;
		private var _connectionID:int;
		private var _connectionName:String;
	}
}