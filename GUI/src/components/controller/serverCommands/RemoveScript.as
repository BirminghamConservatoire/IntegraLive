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
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.Script;
	
	import flexunit.framework.Assert;

	public class RemoveScript extends ServerCommand
	{
		public function RemoveScript( scriptID:int )
		{
			super();

			_scriptID = scriptID; 
		}

		public function get scriptID():int { return _scriptID; }
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			removeConnectionsReferringTo( _scriptID, model, controller );
			deselectScript( model, controller );
			controller.processCommand( new SetScript( _scriptID, null ) );
		}
		

		public override function generateInverse( model:IntegraModel ):void
		{
			var script:Script = model.getScript( _scriptID );
			var parent:IntegraContainer = model.getContainerFromScript( _scriptID );
			Assert.assertNotNull( script );
			Assert.assertNotNull( parent );
			
			pushInverseCommand( new AddScript( parent.id, _scriptID, script.name ) );	
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _scriptID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _scriptID ) );
			connection.callQueued( "command.delete" );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.delete" );
		}


		private function deselectScript( model:IntegraModel, controller:IntegraController ):void
		{
			var parent:IntegraContainer = model.getContainerFromScript( _scriptID );
			Assert.assertNotNull( parent );
			
			if( parent.primarySelectedChildID == _scriptID )
			{
				controller.processCommand( new SetPrimarySelectedChild( parent.id, -1 ) );
			}
		}

		private var _scriptID:int;
	}
}