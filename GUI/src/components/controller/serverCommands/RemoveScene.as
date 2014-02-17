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
	import components.controller.userDataCommands.SetSceneKeybinding;
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scene;
	
	import flexunit.framework.Assert;

	public class RemoveScene extends ServerCommand
	{
		public function RemoveScene( sceneID:int )
		{
			super();
			
			_sceneID = sceneID;
		}


		public function get sceneID():int { return _sceneID; }


		public override function initialize( model:IntegraModel ):Boolean
		{
			return ( model.getScene( _sceneID ) != null );
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );
			pushInverseCommand( new AddScene( scene.start, scene.length, scene.id, scene.name, scene.mode, scene.info.markdown ) )
		}		


		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//remove midi control inputs

			while( true )
			{
				var midiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( _sceneID, "activate" );
				if( !midiControlInput ) 
				{
					break;
				}
				
				controller.processCommand( new RemoveMidiControlInput( midiControlInput.id ) );
			}
			
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );
			if( scene.keybinding.length > 0 )
			{
				controller.processCommand( new SetSceneKeybinding( scene.id, "" ) );
			}

			if( model.project.player.selectedSceneID == _sceneID )
			{
				controller.processCommand( new SelectScene( -1 ) );
			}
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _sceneID );
		}

		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _sceneID ) );
			connection.callQueued( "command.delete" );
		}
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new UpdateProjectLength() );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.delete" );
		}
		
		
		private var _sceneID:int;
	}
}