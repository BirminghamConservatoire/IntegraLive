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


package components.controller.userDataCommands
{
	import components.controller.Command;
	import components.controller.UserDataCommand;
	import components.model.IntegraModel;
	import components.model.Track;
	
	import flexunit.framework.Assert;

	public class SetTrackColor extends UserDataCommand
	{
		public function SetTrackColor( trackID:int, color:uint )
		{
			super();
			
			_trackID = trackID;
			_color = color;
		}
		
		
		public function get trackID():int { return _trackID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var track:Track = model.getTrack( _trackID );
			if( !track )
			{
				Assert.assertTrue( false );
				return false;
			}
			
			return( _color != track.trackUserData.color );	
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetTrackColor( _trackID, model.getTrack( _trackID ).trackUserData.color ) );
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var track:Track = model.getTrack( _trackID );
			track.trackUserData.color = _color;			
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetTrackColor = previousCommand as SetTrackColor;
			Assert.assertNotNull( previous );
			
			return ( _trackID == previous._trackID ); 
		}		
		
		
		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _trackID );	
		}		

		
		private var _trackID:int;
		private var _color:uint;
		
	}
}