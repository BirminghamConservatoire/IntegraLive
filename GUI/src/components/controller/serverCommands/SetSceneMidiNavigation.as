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
	import com.mattism.http.xmlrpc.Connection;
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.Midi;
	import components.model.Player;
	import components.model.Project;
	import components.model.Scene;
	
	import flexunit.framework.Assert;

	public class SetSceneMidiNavigation extends ServerCommand
	{
		public function SetSceneMidiNavigation( sceneID:int, midiNote:int, ccNumber:int )
		{
			super();

			_sceneID = sceneID;
			_midiNote = midiNote;
			_ccNumber = ccNumber;
		}

		
		public function get sceneID():int { return _sceneID; }
		public function get midiNote():int { return _midiNote; }
		public function get ccNumber():int { return _ccNumber; }
		
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var scene:Scene = model.getScene( _sceneID );
			if( !scene ) return false;
			
			return true;
		} 

		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var project:Project = model.project;
			
			//remove clashing assignments from other scenes
			for each( var otherScene:Scene in project.player.scenes )
			{
				if( otherScene.id == _sceneID )
				{
					continue;
				}
				
				var otherMidiNote:int = project.getConnectedMidiNote( otherScene.id, "activate" );
				var otherCCNumber:int = project.getConnectedCCNumber( otherScene.id, "activate" );
				
				var unassignMidiNote:Boolean = ( _midiNote >= 0 && otherMidiNote == _midiNote ); 
				var unassignCCNumber:Boolean = ( _ccNumber >= 0 && otherCCNumber == _ccNumber ); 
				
				if( unassignMidiNote || unassignCCNumber )
				{
					if( unassignMidiNote ) otherMidiNote = -1;
					if( unassignCCNumber ) otherCCNumber = -1;
					
					controller.processCommand( new SetSceneMidiNavigation( otherScene.id, otherMidiNote, otherCCNumber ) );
				}
			}

			//remove clashing assignments from player

			var playerPrevCCNumber:int = project.getConnectedCCNumber( project.player.id, "prev" );
			var playerNextCCNumber:int = project.getConnectedCCNumber( project.player.id, "next" );
			var playerPrevMidiNote:int = project.getConnectedMidiNote( project.player.id, "prev" );
			var playerNextMidiNote:int = project.getConnectedMidiNote( project.player.id, "next" );
			
			var updatePlayer:Boolean = false;
			
			if( playerPrevCCNumber >= 0 && playerPrevCCNumber == _ccNumber )
			{
				updatePlayer = true;
				playerPrevCCNumber = -1;
			}
				
			if( playerNextCCNumber >= 0 && playerNextCCNumber == _ccNumber )
			{
				updatePlayer = true;
				playerNextCCNumber = -1;
			}
			
			if( playerPrevMidiNote >= 0 && playerPrevMidiNote == _midiNote )
			{
				updatePlayer = true;
				playerPrevMidiNote = -1;
			}
			
			if( playerNextMidiNote >= 0 && playerNextMidiNote == _midiNote )
			{
				updatePlayer = true;
				playerNextMidiNote = -1;
			}
			
			if( updatePlayer )
			{
				controller.processCommand( new SetPlayerMidiNavigation( playerNextMidiNote, playerNextCCNumber, playerPrevMidiNote, playerPrevCCNumber ) );
			}
			
			//now update the connections for this scene
			updateProjectMidiConnection( model, controller, Midi.ccAttributePrefix, _sceneID, "activate", _ccNumber );
			updateProjectMidiConnection( model, controller, Midi.noteAttributePrefix, _sceneID, "activate", _midiNote );
		}
		
		
		private var _sceneID:int;
		private var _midiNote:int;
		private var _ccNumber:int;
	}
}
