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

	public class SetTrackExpanded extends UserDataCommand
	{
		public function SetTrackExpanded( trackID:int, expanded:Boolean, context:String = ARRANGE_VIEW )
		{
			super();
			
			_trackID = trackID;
			_expanded = expanded;
			_context = context;
		}
		
		
		public function get trackID():int { return _trackID; }
		public function get context():String { return _context; }
		public function get expanded():Boolean { return _expanded; }
		public function get collapsed():Boolean { return !_expanded; }
		
		public static const ARRANGE_VIEW:String = "arrange";
		public static const LIVE_VIEW:String = "arrange"; 
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var track:Track = model.getTrack( _trackID );
			if( !track )
			{
				Assert.assertTrue( false );
				return false;
			}
			
			switch( _context )
			{
				case ARRANGE_VIEW: 	
					return ( _expanded != track.trackUserData.arrangeViewExpanded );
					
				case LIVE_VIEW: 	
					return ( _expanded != track.trackUserData.liveViewExpanded );
					
				default:			
					return false;
			}
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );

			switch( _context )
			{
				case ARRANGE_VIEW: 	
					pushInverseCommand( new SetTrackExpanded( _trackID, track.trackUserData.arrangeViewExpanded, _context ) );
					break;
					
				case LIVE_VIEW: 	
					pushInverseCommand( new SetTrackExpanded( _trackID, track.trackUserData.liveViewExpanded, _context ) );
					break;
					
				default:
					Assert.assertTrue( false );
					break;			
			}
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );

			switch( _context )
			{
				case ARRANGE_VIEW: 	
					track.trackUserData.arrangeViewExpanded = _expanded;
					break;
					
				case LIVE_VIEW: 	
					track.trackUserData.liveViewExpanded = _expanded;
					break;
					
				default:
					Assert.assertTrue( false );
					break;			
			}
		}
		
		
		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetTrackExpanded = previousCommand as SetTrackExpanded;
			Assert.assertNotNull( previous );
			
			return ( _trackID == previous._trackID && _context == previous._context ); 
		}		
		
		
		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _trackID );	
		}		

		
		private var _trackID:int;
		private var _expanded:Boolean;
		private var _context:String;
	}
}