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


package components.model
{
	import __AS3__.vec.Vector;
	
	import components.model.userData.ProjectUserData;
	
	import flexunit.framework.Assert;
	
	
	public class Project extends IntegraContainer
	{
		public function Project()
		{
			super();
			
			internalUserData = new ProjectUserData; 
		}

		public function get tracks():Object { return _tracks; }
		public function get player():Player { return _player; }
		public function get midiMonitor():MidiRawInput { return _midiMonitor; }
		
		public function get projectUserData():ProjectUserData { return userData as ProjectUserData; }
		
		public function get orderedTracks():Vector.<Track>
		{
			var orderedTracks:Vector.<Track> = new Vector.<Track>;
			for each( var track:Track in _tracks )
			{
				orderedTracks.push( track );
			}
			
			function compareTrackOrder( track1:Track, track2:Track ):int
			{
				if( track1.zIndex < track2.zIndex ) return -1;
				if( track1.zIndex > track2.zIndex ) return 1;
				return 0;
			}
			
			orderedTracks.sort( compareTrackOrder );

			return orderedTracks;			
		}
		
		
		override public function childrenChanged():void 
		{
			super.childrenChanged();
			
			_tracks = new Object;
			_player = null;
			_midiMonitor = null;
			
			for each( var child:IntegraDataObject in children )
			{
				if( child is Track )
				{
					_tracks[ child.id ] = child;
				}
				
				if( child is Player )
				{
					if( _player )
					{
						Assert.assertTrue( false );		//didn't expect two players as children of project		
					}
					else
					{
						_player = child as Player;
					}
				}

				if( child is MidiRawInput )
				{
					if( _midiMonitor )
					{
						Assert.assertTrue( false );		//didn't expect two raw midi inputs as children of project		
					}
					else
					{
						_midiMonitor = child as MidiRawInput;
					}
				}
			} 
		}
		

		public static const defaultProjectName:String = "Untitled";

		private var _tracks:Object = new Object;
		private var _player:Player = null;
		private var _midiMonitor:MidiRawInput = null;
		
	}
}