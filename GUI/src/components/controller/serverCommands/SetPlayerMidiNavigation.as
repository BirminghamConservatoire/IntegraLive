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

	public class SetPlayerMidiNavigation extends ServerCommand
	{
		public function SetPlayerMidiNavigation( nextMidiNote:int, nextCCNumber:int, prevMidiNote:int, prevCCNumber:int )
		{
			super();

			_nextMidiNote = nextMidiNote;
			_nextCCNumber = nextCCNumber;
			_prevMidiNote = prevMidiNote;
			_prevCCNumber = prevCCNumber;
		}

		
		public function get nextMidiNote():int { return _nextMidiNote; }
		public function get nextCCNumber():int { return _nextCCNumber; }
		public function get prevMidiNote():int { return _prevMidiNote; }
		public function get prevCCNumber():int { return _prevCCNumber; }
		
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var player:Player = model.project.player;
			
			var oldPrevCCNumber:int = model.project.getConnectedCCNumber( player.id, "prev" );
			var oldNextCCNumber:int = model.project.getConnectedCCNumber( player.id, "next" );
			var oldPrevMidiNote:int = model.project.getConnectedMidiNote( player.id, "prev" );
			var oldNextMidiNote:int = model.project.getConnectedMidiNote( player.id, "next" );
			
			//unassign any midi notes or cc numbers already used in the player
			if( _prevMidiNote != oldPrevMidiNote && _prevMidiNote >= 0 && _prevMidiNote == oldNextMidiNote )
			{
				_nextMidiNote = -1;
			}

			if( _prevCCNumber != oldPrevCCNumber && _prevCCNumber >= 0 && _prevCCNumber == oldNextCCNumber )
			{
				_nextCCNumber = -1;
			}
			
			if( _nextMidiNote != oldNextMidiNote && _nextMidiNote >= 0 && _nextMidiNote == oldPrevMidiNote )
			{
				_prevMidiNote = -1;
			}
			
			if( _nextCCNumber != oldNextCCNumber && _nextCCNumber >= 0 && _nextCCNumber == oldPrevCCNumber )
			{
				_prevCCNumber = -1;
			}
			
			return( _nextMidiNote != oldNextMidiNote ||
					_nextCCNumber != oldNextCCNumber ||
					_prevMidiNote != oldPrevMidiNote ||
					_prevCCNumber != oldPrevCCNumber );
		} 

		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//unassign any midi notes or cc numbers that are already assigned to scenes
			
			var player:Player = model.project.player;
			
			for each( var scene:Scene in player.scenes )
			{
				var sceneCCNumber:int = model.project.getConnectedCCNumber( scene.id, "activate" );
				var sceneMidiNote:int = model.project.getConnectedMidiNote( scene.id, "activate" );

				var unassignMidiNote:Boolean = ( sceneMidiNote >= 0 && ( sceneMidiNote == _nextMidiNote || sceneMidiNote == _prevMidiNote ) );
				var unassignCCNumber:Boolean = ( sceneCCNumber >= 0 && ( sceneCCNumber == _nextCCNumber || sceneCCNumber == _prevCCNumber ) );

				if( unassignMidiNote || unassignCCNumber )
				{
					var midiNote:int = unassignMidiNote ? -1 : sceneMidiNote;
					var ccNumber:int = unassignCCNumber ? -1 : sceneCCNumber;

					controller.processCommand( new SetSceneMidiNavigation( scene.id, midiNote, ccNumber ) );
				}
			}

			updateProjectMidiConnection( model, controller, Midi.ccAttributePrefix, player.id, "prev", _prevCCNumber );
			updateProjectMidiConnection( model, controller, Midi.noteAttributePrefix, player.id, "prev", _prevMidiNote );
			updateProjectMidiConnection( model, controller, Midi.ccAttributePrefix, player.id, "next", _nextCCNumber );
			updateProjectMidiConnection( model, controller, Midi.noteAttributePrefix, player.id, "next", _nextMidiNote );
		}
		

		private var _nextMidiNote:int;
		private var _nextCCNumber:int;
		private var _prevMidiNote:int;
		private var _prevCCNumber:int;
	}
}
