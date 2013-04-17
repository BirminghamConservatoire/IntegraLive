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

	public class SetTrackHeight extends UserDataCommand
	{
		public function SetTrackHeight( trackID:int, height:uint )
		{
			super();
			
			_trackID = trackID;
			_height = height;
		}
		
		
		public function get trackID():int { return _trackID; }
		public function get height():uint { return _height; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var track:Track = model.getTrack( _trackID );
			if( !track )
			{
				Assert.assertTrue( false );
				return false;
			}
			
			return( _height != track.trackUserData.arrangeViewHeight );	
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetTrackHeight( _trackID, model.getTrack( _trackID ).trackUserData.arrangeViewHeight ) );
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var track:Track = model.getTrack( _trackID );
			track.trackUserData.arrangeViewHeight = _height;			
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetTrackHeight = previousCommand as SetTrackHeight;
			Assert.assertNotNull( previous );
			
			return ( _trackID == previous._trackID ); 
		}		
		
		
		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _trackID );	
		}		

		
		private var _trackID:int;
		private var _height:uint;
		
	}
}