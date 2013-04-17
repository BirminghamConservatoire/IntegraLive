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
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Connection;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	public class RemoveConnection extends ServerCommand
	{
		public function RemoveConnection( connectionID:int )
		{
			super();

			_connectionID = connectionID; 
		}

		public function get connectionID():int { return _connectionID; }
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			deselectConnection( model, controller );
			controller.processCommand( new SetConnectionRouting( _connectionID, -1, null, -1, null ) );
		}
		

		public override function generateInverse( model:IntegraModel ):void
		{
			var connection:Connection = model.getConnection( _connectionID );
			var container:IntegraContainer = model.getContainerFromConnection( _connectionID );
			Assert.assertNotNull( connection );
			Assert.assertNotNull( container );
			
			pushInverseCommand( new AddConnection( container.id, _connectionID, connection.name ) );	
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _connectionID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _connectionID ) );
			connection.callQueued( "command.delete" );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.delete" );
		}


		private function deselectConnection( model:IntegraModel, controller:IntegraController ):void
		{
			var container:IntegraContainer = model.getContainerFromConnection( _connectionID );
			Assert.assertNotNull( container );
			
			if( model.isObjectSelected( _connectionID ) )
			{
				controller.processCommand( new SetObjectSelection( _connectionID, false ) );
			}

			if( container.userData.primarySelectedChildID == _connectionID )
			{
				controller.processCommand( new SetPrimarySelectedChild( container.id, -1 ) );
			}
		}

		private var _connectionID:int;
	}
}