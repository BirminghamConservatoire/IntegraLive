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

package components.views.LiveView
{
	import flash.events.MouseEvent;
	
	import mx.core.ScrollPolicy;
	
	import __AS3__.vec.Vector;
	
	import components.controller.serverCommands.AddTrack;
	import components.controller.serverCommands.RemoveTrack;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetTrackOrder;
	import components.controller.userDataCommands.SetTrackExpanded;
	import components.model.Info;
	import components.model.Track;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.viewContainers.ViewTree;
	
	import flexunit.framework.Assert;
	
	

	public class LiveView extends IntegraView
	{
		public function LiveView()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    

			_tracks.percentWidth = 100;
			_tracks.percentHeight = 100;
			
			addElement( _tracks );
			
			addUpdateMethod( AddTrack, onTrackAdded );
			addUpdateMethod( RemoveTrack, onTrackRemoved );
			addUpdateMethod( SetTrackOrder, onTracksReordered );
			addUpdateMethod( SetTrackExpanded, onTrackExpanded );			
			
			addTitleInvalidatingCommand( RenameObject );
			addActiveChangingCommand( SetContainerActive );
		}


		override public function get title():String 
		{ 
			return model ? model.project.name : super.title; 
		}
		
		override public function get vuMeterContainerID():int
		{
			return model ? model.project.id : super.vuMeterContainerID;
		}	
		
		
		override public function get active():Boolean
		{
			return model.project.active;
		}
		
		
		override public function set active( active:Boolean ):void 
		{
			controller.processCommand( new SetContainerActive( model.project.id, active ) );
		}
		

		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
		} 

		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "LiveView" );
		}
		

		override protected function onAllDataChanged():void
		{
			_tracks.removeAllItems();
			
			var tracksInOrder:Vector.<Track> = model.project.orderedTracks;		
			for each( var track:Track in tracksInOrder )
			{
				addTrack( track, _tracks.getItemCount() );
			}
		}
		
		
		private function onTrackAdded( command:AddTrack ):void
		{
			var trackID:int = command.trackID;
			addTrack( model.getTrack( trackID ), model.getTrackIndex( trackID ) );
		}


		private function onTrackRemoved( command:RemoveTrack ):void
		{
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				var trackView:LiveViewTrack = _tracks.getItem( i ) as LiveViewTrack;
				Assert.assertNotNull( trackView );
				if( trackView.trackID == command.trackID )
				{
					_tracks.removeItem( i );
					return;
				}
			}
			
			Assert.assertTrue( false );	//failed to find removed track
		}


		private function onTracksReordered( command:SetTrackOrder ):void
		{
			for( var i:int = 0; i < command.newOrder.length; i++ )
			{
				var trackID:int = command.newOrder[ i ];
				
				_tracks.setItemIndex( getTrackIndexFromTree( trackID ), i ); 
			}	
		}


		private function onTrackExpanded( command:SetTrackExpanded ):void
		{
			if( command.context != SetTrackExpanded.LIVE_VIEW ) return;
			
			for( var i:int = 0; i <_tracks.getItemCount(); i++ )
			{
				var track:LiveViewTrack = _tracks.getItem( i ) as LiveViewTrack;
				Assert.assertNotNull( track );
				
				if( track.trackID != command.trackID )
				{
					continue;
				}
				
				track.collapsed = command.collapsed;
				break;
			} 
		}
		
		
		private function addTrack( track:Track, index:int ):void
		{
			if( index < 0 || index > _tracks.getItemCount() )
			{
				Assert.assertTrue( false );	//invalid insertion index
				return;
			}
			
			var trackView:LiveViewTrack = new LiveViewTrack( track.id );
			trackView.collapsed = track.trackUserData.liveViewCollapsed;
			
			_tracks.addItemAt( trackView, index );
		}
		
		
		private function getTrackIndexFromTree( trackID:int ):int
		{
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				if( ( _tracks.getItem( i ) as LiveViewTrack ).trackID == trackID )
				{
					return i;
				}
			}
			
			Assert.assertTrue( false );	//trackID not found
			return -1;	
		} 
		
		
		private var _tracks:ViewTree = new ViewTree;
	}
}