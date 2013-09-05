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

package components.views.ArrangeView
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import mx.controls.HScrollBar;
	import mx.core.ScrollPolicy;
	import mx.events.ScrollEvent;
	
	import __AS3__.vec.Vector;
	
	import components.controller.events.ScrollbarShowHideEvent;
	import components.controller.serverCommands.AddBlock;
	import components.controller.serverCommands.AddTrack;
	import components.controller.serverCommands.ImportBlock;
	import components.controller.serverCommands.ImportTrack;
	import components.controller.serverCommands.RemoveBlock;
	import components.controller.serverCommands.RemoveTrack;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.RepositionBlock;
	import components.controller.serverCommands.SelectScene;
	import components.controller.serverCommands.SetBlockTrack;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetPlayPosition;
	import components.controller.serverCommands.SetTrackOrder;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTimeDomainSnaplines;
	import components.controller.userDataCommands.SetTimelineState;
	import components.controller.userDataCommands.SetTrackExpanded;
	import components.controller.userDataCommands.SetTrackHeight;
	import components.controller.userDataCommands.SetViewMode;
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.Block;
	import components.model.Info;
	import components.model.Scene;
	import components.model.Track;
	import components.model.userData.TimelineState;
	import components.model.userData.ViewMode;
	import components.utils.CursorSetter;
	import components.utils.FontSize;
	import components.utils.Snapper;
	import components.utils.TimeDomainSnapLines;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	import components.views.Timeline.PlayPositionMarker;
	import components.views.viewContainers.ViewTree;
	
	import flexunit.framework.Assert;
	

	public class ArrangeView extends IntegraView
	{
		public function ArrangeView()
		{
			super();
			
			doubleClickEnabled = true;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;

			_tracks.setStyle( "left", 0 );
			_tracks.setStyle( "right", 0 );
			_tracks.setStyle( "top", 0 );
			_tracks.setStyle( "bottom", 0 );
			
			_tracks.canReorder = true;
			_tracks.addEventListener( ViewTree.TREE_REORDERED, onTreeReordered );
			_tracks.addEventListener( ScrollbarShowHideEvent.EVENT_NAME, onVerticalScrollbarShowHide ); 
			_tracks.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			_tracks.addEventListener( MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown );
			_tracks.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
			addChild( _tracks );
			
			_horizontalScrollBar.setStyle( "left", 0 );
			_horizontalScrollBar.setStyle( "right", 0 );
			_horizontalScrollBar.setStyle( "bottom", 0 );
			_horizontalScrollBar.addEventListener( ScrollEvent.SCROLL, onHorizontalScroll );
			addChild( _horizontalScrollBar );

			_playPositionMarker.setStyle( "top", 0 );
			_playPositionMarker.setStyle( "bottom", 0 );
			addChild( _playPositionMarker );

			addChild( _snapLines );
			
			addUpdateMethod( AddTrack, onTrackAdded );
			addUpdateMethod( RemoveTrack, onTrackRemoved );
			addUpdateMethod( SetTrackOrder, onTracksReordered );
			addUpdateMethod( SetTimelineState, onTimelineStateChanged );
			addUpdateMethod( SetPlayPosition, onPlayPositionChanged );
			addUpdateMethod( SetTrackExpanded, onTrackExpanded );
			addUpdateMethod( SetTrackHeight, onTrackHeightChanged );
			addUpdateMethod( SetTimeDomainSnaplines, onSetTimeDomainSnaplines );
			addUpdateMethod( UpdateProjectLength, onProjectLengthChanged );
			
			addTitleInvalidatingCommand( RenameObject );
			addActiveChangingCommand( SetContainerActive );
			
			addEventListener( Event.RESIZE, onResize );
			
			_scrollTimer.addEventListener( TimerEvent.TIMER, onScrollTimer );

			contextMenuDataProvider = contextMenuData;
		}
		
		
		public function getPrimaryBlockRectangle():Rectangle
		{
			if( !model ) return null;
			var primarySelectedBlock:Block = model.primarySelectedBlock;
			if( !primarySelectedBlock ) return null;
			
			for( var trackIndex:int = 0; trackIndex < _tracks.getItemCount(); trackIndex++ )
			{
				var trackView:ArrangeViewTrack = _tracks.getItem( trackIndex ) as ArrangeViewTrack;
				Assert.assertNotNull( trackView );
				
				if( trackView.trackID != model.getPrimarySelectedChildID( model.project.id ) ) continue;
				
				var rectangle:Rectangle = _tracks.getItemRect( trackIndex );
				rectangle.x = model.project.projectUserData.timelineState.ticksToPixels( primarySelectedBlock.start );
				rectangle.width = model.project.projectUserData.timelineState.ticksToPixels( primarySelectedBlock.end ) - rectangle.x;
				return rectangle;
			}
			
			return null;
		}
		
		
		override public function get title():String 
		{ 
			return model && model.project ? model.project.name : super.title; 
		}


		override public function get vuMeterContainerID():int
		{
			return model ? model.project.id : super.vuMeterContainerID;
		}	

		
		override public function getInfoToDisplay( event:Event ):Info 
		{ 
			return model.project.info;
		}
		
		
		override public function get active():Boolean
		{
			return model.project.active;
		}
		
		
		override public function set active( active:Boolean ):void 
		{
			controller.processCommand( new SetContainerActive( model.project.id, active ) );
		}
				
		
		public function get lastBlockDirectory():String { return _lastBlockDirectory; }
		public function set lastBlockDirectory( lastBlockDirectory:String ):void { _lastBlockDirectory = lastBlockDirectory; }

		public function get lastTrackDirectory():String { return _lastTrackDirectory; }
		public function set lastTrackDirectory( lastTrackDirectory:String ):void { _lastTrackDirectory = lastTrackDirectory; }

		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );

			var minTrackHeight:Number = FontSize.getTextRowHeight( this );

			if( !style || style == FontSize.STYLENAME )
			{
				for( var i:int = 0; i < _tracks.getItemCount(); i++ )
				{
					if( _tracks.getItem( i ).height < minTrackHeight )
					{
						_tracks.setItemHeight( i, minTrackHeight );
					} 
				}
			}
		} 


		override protected function onAllDataChanged():void
		{
			_tracks.removeAllItems();
			_blockDragInfo = null;
			_draggedBlocks = null;
			_draggedTrackChanges = null;
			
			var tracksInOrder:Vector.<Track> = model.project.orderedTracks;		
			for each( var track:Track in tracksInOrder )
			{
				addTrack( track, _tracks.getItemCount() );
			}
			
			updatePlayPositionMarker();
			
			updateScrollbar();
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
				var trackView:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
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
				
				
		private function onTimelineStateChanged( command:SetTimelineState ):void
		{
			updatePlayPositionMarker();
			
			if( !_processingHorizontalScrollBarEvent )
			{
				updateScrollbar();
			}
		}
		
		
		private function onPlayPositionChanged( command:SetPlayPosition ):void
		{
			updatePlayPositionMarker();
		}
		
		
		private function onTrackExpanded( command:SetTrackExpanded ):void
		{
			if( command.context != SetTrackExpanded.ARRANGE_VIEW ) return;
			
			for( var i:int = 0; i <_tracks.getItemCount(); i++ )
			{
				var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
				Assert.assertNotNull( track );
				
				if( track.trackID != command.trackID )
				{
					continue;
				}
				
				track.collapsed = command.collapsed;
				break;
			} 
		}


		private function onTrackHeightChanged( command:SetTrackHeight ):void
		{
			for( var i:int = 0; i <_tracks.getItemCount(); i++ )
			{
				var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
				Assert.assertNotNull( track );
				
				if( track.trackID != command.trackID )
				{
					continue;
				}
				
				_tracks.setItemHeight( i, command.height );
				break;
			}
		}
		
		
		private function onSetTimeDomainSnaplines( command:SetTimeDomainSnaplines ):void
		{
			_snapLines.update( command, model.project.projectUserData.timelineState );
		}
		
		
		private function onProjectLengthChanged( command:UpdateProjectLength ):void
		{
			updateScrollbar();
		}
		
		
		private function addTrack( track:Track, index:int ):void
		{
			if( index < 0 || index > _tracks.getItemCount() )
			{
				Assert.assertTrue( false );	//invalid insertion index
				return;
			}
			
			var trackView:ArrangeViewTrack = new ArrangeViewTrack( track.id );
			
			trackView.collapsed = track.trackUserData.arrangeViewCollapsed;
			trackView.height = track.trackUserData.arrangeViewHeight;
			
			_tracks.addItemAt( trackView, index, true );
		}
		
		
		private function updatePlayPositionMarker():void
		{
			var timelineState:TimelineState = model.project.projectUserData.timelineState;
			var playPosition:int = model.project.player.playPosition;

			_playPositionMarker.x = timelineState.ticksToPixels( playPosition );
		}
		
		
		private function updateScrollbar():void
		{
			_horizontalScrollBar.minScrollPosition = 0;

			var scrollBarWidth:Number = width;
			if( _tracks.verticalScrollBar )
			{
				_horizontalScrollBar.setStyle( "right", _tracks.verticalScrollBar.width );
				scrollBarWidth -= _tracks.verticalScrollBar.width;
			}
			else
			{
				_horizontalScrollBar.setStyle( "right", 0 );
			}
			
			var timelineState:TimelineState = model.project.projectUserData.timelineState;
			_horizontalScrollBar.pageSize = scrollBarWidth / timelineState.zoom;
			_horizontalScrollBar.pageScrollSize = _horizontalScrollBar.pageSize; 
			
			_horizontalScrollBar.maxScrollPosition = Math.max( 0, model.projectLength - _horizontalScrollBar.pageSize );
			
			_horizontalScrollBar.scrollPosition = timelineState.scroll;
		
			if( _horizontalScrollBar.maxScrollPosition > 0 )
			{
				if( !_horizontalScrollBar.visible )
				{
					_horizontalScrollBar.visible = true;
					_tracks.setStyle( "bottom", _horizontalScrollBar.minHeight );
					
					_playPositionMarker.setStyle( "bottom", _horizontalScrollBar.minHeight );
				}
			}
			else
			{
				if( _horizontalScrollBar.visible )
				{
					_horizontalScrollBar.visible = false;
					_tracks.setStyle( "bottom", 0 );
	
					_playPositionMarker.setStyle( "bottom", 0 );
				}
			}
		}
		
		
		private function onVerticalScrollbarShowHide( event:ScrollbarShowHideEvent ):void
		{
			updateScrollbar();	
		}
		
		
		private function onHorizontalScroll( event:ScrollEvent ):void
		{
			var timelineState:TimelineState = new TimelineState;
			timelineState.copyFrom( model.project.projectUserData.timelineState ); 
			
			timelineState.scroll = event.position;
			
			_processingHorizontalScrollBarEvent = true;
			
			controller.processCommand( new SetTimelineState( timelineState ) );
			
			_processingHorizontalScrollBarEvent = false;
		}


		private function deleteBlocks():void
		{
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					if( model.isObjectSelected( block.id ) )
					{
						controller.processCommand( new RemoveBlock( block.id ) );			
					}
				}
			}
		}


		private function openBlock():void
		{
 			var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
 			viewMode.blockPropertiesOpen = true;
 			controller.processCommand( new SetViewMode( viewMode ) );			
		}
		

		private function onMouseDown( event:MouseEvent ):void
		{
			var track:ArrangeViewTrack = getTrackUnderMouse();
			if( !track ) 
			{
				if( mouseY >= _tracks.getBottomOfItems( this ) )
				{
					selectProject();
				}
				return;
			}
			
			_blockDragInfo = track.getBlockDragInfo();
			if( !_blockDragInfo )
			{ 
				deselectAllBlocks();
				return;
			}

			var blockView:BlockView = _blockDragInfo.blockView;
			_blockDragXTicks = model.project.projectUserData.timelineState.pixelsToTicks( Math.max( 0, mouseX ) );
			_blockDragXOffset = 0;

			if( MouseCapture.instance.hasCapture )
			{
				//special case when mouse already captured
				if( blockView )
				{
					_blockDragInfo.dragType = BlockDragType.SELECT;	
				}
				else
				{
					return;
				}
			} 
			
			var cursorType:String;

			switch( _blockDragInfo.dragType )
			{
				case BlockDragType.SELECT:
					selectBlock( blockView.blockID, Utilities.hasMultiselectionModifier( event ), false, false );
					_blockDragInfo = null;
					return;
					
				case BlockDragType.MOVE:
					selectBlock( blockView.blockID, Utilities.hasMultiselectionModifier( event ), true, false );
					cursorType = CursorSetter.MOVE_EW;
					break;
				
				case BlockDragType.CHANGE_START:
					selectBlock( blockView.blockID, Utilities.hasMultiselectionModifier( event ), true, true );
					_blockDragXOffset = mouseX - blockView.x;
					cursorType = CursorSetter.RESIZE_EW;
					break;
					
				case BlockDragType.CHANGE_END:
					selectBlock( blockView.blockID, Utilities.hasMultiselectionModifier( event ), true, true );
					_blockDragXOffset = mouseX - ( blockView.x + blockView.width );
					cursorType = CursorSetter.RESIZE_EW;
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}
			
			MouseCapture.instance.setCapture( this, onDragBlock, onReleaseBlock, cursorType );
			
			_scrollTimer.start();
		}
		
		
		private function onRightMouseDown( event:MouseEvent ):void
		{
			var track:ArrangeViewTrack = getTrackUnderMouse();
			if( track )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.project.id, track.trackID ) );
			}
		}
		
		
		private function onDoubleClick( event:MouseEvent ):void
		{
			var arrangeViewTrack:ArrangeViewTrack = getTrackUnderMouse();
			if( arrangeViewTrack )
			{
				var blockDragInfo:BlockDragInfo = arrangeViewTrack.getBlockDragInfo();
				if( blockDragInfo )
				{
					blockDragInfo.blockView.handleDoubleClick();
				}
				else
				{
					createBlockOnDoubleClick( arrangeViewTrack.trackID );
				}
			}
			else
			{
				if( mouseY > _tracks.getBottomOfItems( this ) )
				{
					createTrack();
				}
			}
		}
		
		
		private function onResize( event:Event ):void 
		{
			updateScrollbar();
		}
		
		
		private function onDragBlock( event:MouseEvent ):void
		{
			Assert.assertNotNull( _blockDragInfo );
			
			var timelineState:TimelineState = model.project.projectUserData.timelineState;
			var blockID:int = ( _blockDragInfo.blockView ) ? _blockDragInfo.blockView.blockID : -1;
			var block:Block = ( blockID > 0 ) ? model.getBlock( blockID ) : null;

			_draggedBlocks = new Object;
			_draggedTrackChanges = new Object;
			var draggedBlock:Block = null;
			var isMovingRight:Boolean;
			
			var snapTicks:Vector.<int> = new Vector.<int>;
			
			switch( _blockDragInfo.dragType )
			{
				case BlockDragType.MOVE:
					isMovingRight = doBlockMove( snapTicks );
					break;
					
				case BlockDragType.CHANGE_START:
					draggedBlock = new Block;
					draggedBlock.copyBlockProperties( block );
					var snapper:Snapper = getSnap( timelineState.pixelsToTicks( mouseX - _blockDragXOffset ) );
					draggedBlock.start = Math.max( 0, Math.min( snapper.value, draggedBlock.end - Block.minimumBlockLength ) );
					draggedBlock.end = block.end;
					_draggedBlocks[ blockID ] = draggedBlock;
					isMovingRight = ( draggedBlock.start > block.start );
					
					if( snapper.snapped && draggedBlock.start == snapper.value )
					{
						snapTicks.push( snapper.value );
					}
					break;
					
				case BlockDragType.CHANGE_END:
					draggedBlock = new Block;
					draggedBlock.copyBlockProperties( block );
					snapper = getSnap( timelineState.pixelsToTicks( mouseX - _blockDragXOffset ) );
					draggedBlock.end = Math.max( snapper.value, draggedBlock.start + Block.minimumBlockLength );
					_draggedBlocks[ blockID ] = draggedBlock;
					isMovingRight = ( draggedBlock.end > block.end );

					if( snapper.snapped && draggedBlock.end == snapper.value )
					{
						snapTicks.push( snapper.value );
					}
					break;
					
				case BlockDragType.SELECT:
				default:
					Assert.assertTrue( false );
					break;
			}
			
			doBlockRescheduling( isMovingRight );
			
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
				Assert.assertNotNull( track );
				track.applyDraggedBlocks( _draggedBlocks, _draggedTrackChanges );
			}
			
			controller.processCommand( new SetTimeDomainSnaplines( snapTicks ) );
		}
		
		
		private function doBlockMove( snapTicks:Vector.<int> ):Boolean
		{
			var timelineState:TimelineState = model.project.projectUserData.timelineState;
			
			var primaryBlock:Block = model.primarySelectedBlock;
			Assert.assertNotNull( primaryBlock );
			
			var timeDisplacement:int = Math.max( -primaryBlock.start, timelineState.pixelsToTicks( Math.max( 0, Math.min( width, mouseX ) ) ) - _blockDragXTicks );

			var startSnapper:Snapper = getSnap( primaryBlock.start + timeDisplacement );
			var endSnapper:Snapper = getSnap( primaryBlock.end + timeDisplacement );
			
			var blockStartTicks:int;
			if( startSnapper.snapped )
			{
				if( endSnapper.snapped )
				{
					if( endSnapper.snappedDistance < startSnapper.snappedDistance )
					{
						blockStartTicks = Math.max( 0, endSnapper.value - primaryBlock.length );
						snapTicks.push( endSnapper.value );
					}
					else
					{
						blockStartTicks = startSnapper.value;
						snapTicks.push( startSnapper.value );
						
						if( endSnapper.snappedDistance == startSnapper.snappedDistance )
						{
							snapTicks.push( endSnapper.value );
						}
					}
				}
				else
				{
					blockStartTicks = startSnapper.value;
					snapTicks.push( startSnapper.value );
				}
			}
			else
			{
				if( endSnapper.snapped )
				{
					blockStartTicks = Math.max( 0, endSnapper.value - primaryBlock.length );
					snapTicks.push( endSnapper.value );
				}
				else
				{
					blockStartTicks = startSnapper.value;
				}
			}
			
			blockStartTicks = Math.max( 0, blockStartTicks );
			
			timeDisplacement = blockStartTicks - primaryBlock.start;
			
			var draggedTrackIndex:int = model.getTrackIndex( _blockDragInfo.trackID );
			Assert.assertTrue( draggedTrackIndex >= 0 );
			
			var trackDisplacement:int = _tracks.getExpandedIndex( getTrackIndexNearestMouse() ) - _tracks.getExpandedIndex( draggedTrackIndex );
			
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					if( model.isObjectSelected( block.id ) )
					{
						var blockID:int = block.id;
						
						var copiedBlock:Block = new Block;
						copiedBlock.copyBlockProperties( block );
						
						var myTimeDisplacement:Number = Math.max( timeDisplacement, -copiedBlock.start );
						
						copiedBlock.start = copiedBlock.start + myTimeDisplacement;
						_draggedBlocks[ blockID ] = copiedBlock;
		
						var myExpandedTrackIndex:int = Math.max( 0, Math.min( _tracks.getExpandedItemCount() - 1, _tracks.getExpandedIndex( model.getTrackIndex( model.getTrackFromBlock( blockID ).id ) ) + trackDisplacement ) );
						_draggedTrackChanges[ blockID ] = ( _tracks.getItemFromExpandedIndex( myExpandedTrackIndex ) as ArrangeViewTrack ).trackID; 
					}
				}
			}
			
			return ( timeDisplacement >= 0 );
		}

		
		private function onReleaseBlock():void
		{
			_scrollTimer.stop();
			
			//handle repositioning			
			if( _draggedBlocks ) 
			{
				for( var i:int = 0; i < _tracks.getItemCount(); i++ )
				{
					var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
					Assert.assertNotNull( track );
					track.revertDraggedBlocks();
				}
	
				for each( var block:Block in _draggedBlocks )
				{
					var blockID:int = block.id;
					
					if( _draggedTrackChanges.hasOwnProperty( blockID ) )
					{
						controller.processCommand( new SetBlockTrack( blockID, _draggedTrackChanges[ blockID ] ) );
					}

					controller.processCommand( new RepositionBlock( blockID, block.start, block.end ) );
				}
			}
			
			//handle post-click selection
			handlePostClickSelection();		
			
			//clear snaplines
			controller.processCommand( new SetTimeDomainSnaplines() );
			
			//reset internal state			
			_draggedBlocks = null;
			_draggedTrackChanges = null;
			_blockDragInfo = null;
		}
		
		
		private function doBlockRescheduling( isMovingRight:Boolean ):void
		{
			Assert.assertNotNull( _draggedBlocks );
			Assert.assertNotNull( _draggedTrackChanges );
			
			for each( var track:Track in model.project.tracks )
			{
				//find dragged blocks on this track
				var draggedBlocks:Vector.<Block> = new Vector.<Block>;
				for each( var block:Block in _draggedBlocks )
				{
					var blockID:int = block.id;
					if( _draggedTrackChanges.hasOwnProperty( blockID ) )
					{
						if( _draggedTrackChanges[ blockID ] == track.id )
						{
							draggedBlocks.push( block );
						}
					}
					else
					{
						if( model.getTrackFromBlock( blockID ).id == track.id )
						{
							draggedBlocks.push( block );
						}
					}
				}
				
				if( draggedBlocks.length == 0 )
				{
					continue;	//no dragged blocks on this track
				}
				
				//sort dragged blocks
				draggedBlocks.sort( compareBlocksByStart );
				
				//fix overlaps in dragged blocks
				fixOverlaps( draggedBlocks );

				//find undragged blocks on this track
				var undraggedBlocks:Vector.<Block> = new Vector.<Block>;
				for each( block in track.blocks )
				{
					if( !_draggedBlocks.hasOwnProperty( block.id ) )
					{
						undraggedBlocks.push( block );
					}
				}
				
				//sort undragged blocks
				undraggedBlocks.sort( compareBlocksByCentrePoint );
						
				var previousDraggedBlock:Block = null;
				var insertionIndexOfPreviousDraggedBlock:int = 0;	
					
				//iterate through dragged blocks on this track
				for each( var draggedBlock:Block in draggedBlocks )
				{
					//find 'insertion index' for dragged block in undragged blocks
					var insertionIndex:int = getInsertionIndex( draggedBlock, undraggedBlocks, isMovingRight );
					
					//find total available duration (from start, or end of previous dragged block)
					var availableDurationToLeft:Number = draggedBlock.start;
					if( previousDraggedBlock )
					{
						availableDurationToLeft -= previousDraggedBlock.end; 
					}
					
					//find sum duration of previous undragged blocks (after previous dragged block) 
					var sumDurationOfPreviousUndraggedBlocks:Number = 0;
					for( var i:int = insertionIndexOfPreviousDraggedBlock; i < insertionIndex; i++ )
					{
						sumDurationOfPreviousUndraggedBlocks += undraggedBlocks[ i ].length;
					}
					
					//decrement insertion index to bump blocks to the right until there's enough room to the left 
					while( sumDurationOfPreviousUndraggedBlocks > availableDurationToLeft )
					{
						Assert.assertTrue( insertionIndex > 0 ); 
						insertionIndex--;
						
						sumDurationOfPreviousUndraggedBlocks -= undraggedBlocks[ insertionIndex ].length;
					}

					//walk to left through previous undragged blocks moving left until don't need to
					var maximumEnd:Number = draggedBlock.start;
					for( i = insertionIndex - 1; i >= 0; i-- )
					{
						var moveCandidate:Block = undraggedBlocks[ i ];
						if( _draggedBlocks.hasOwnProperty( moveCandidate.id ) )
						{
							moveCandidate = _draggedBlocks[ moveCandidate.id ];
						} 
						
						if( moveCandidate.end <= maximumEnd )
						{
							break;
						}

						var moved:Block = new Block;
						moved.copyBlockProperties( moveCandidate );
						moved.start = maximumEnd - moved.length;
						moved.end = maximumEnd;
						maximumEnd = moved.start;
						_draggedBlocks[ moved.id ] = moved;
					}
					
					//walk to right through subsequent dragged blocks moving right until don't need to
					var minimumStart:Number = draggedBlock.end;
					for( i = insertionIndex; i < undraggedBlocks.length; i++ )
					{
						moveCandidate = undraggedBlocks[ i ];
						if( _draggedBlocks.hasOwnProperty( moveCandidate.id ) )
						{
							moveCandidate = _draggedBlocks[ moveCandidate.id ];
						} 

						if( moveCandidate.start >= minimumStart )
						{
							break;
						}

						moved = new Block;
						moved.copyBlockProperties( moveCandidate );
						moved.start = minimumStart;
						minimumStart = moved.end;
						_draggedBlocks[ moved.id ] = moved;
					}
					
					previousDraggedBlock = draggedBlock;
					insertionIndexOfPreviousDraggedBlock = insertionIndex;
				}			
			}
		}
		
		
		private function fixOverlaps( draggedBlocks:Vector.<Block> ):void
		{
			var previousBlock:Block = null;
			
			for each( var block:Block in draggedBlocks )
			{
				if( previousBlock )
				{
					var overlap:Number = previousBlock.end - block.start;
					if( overlap > 0 )
					{
						block.start += overlap;
					} 	
				}
				
				previousBlock = block;
			}
		}
		
		
		private function compareBlocksByStart( block1:Block, block2:Block ):Number
		{
			if( block1.start < block2.start ) return -1;
			if( block1.start > block2.start ) return 1;
			return 0;
		}
		
		
		private function compareBlocksByCentrePoint( block1:Block, block2:Block ):Number
		{
			if( block1.centre < block2.centre ) return -1;
			if( block1.centre > block2.centre ) return 1;
			return 0;
		}
		
		
		private function getInsertionIndex( block:Block, blockArray:Vector.<Block>, isMovingRight:Boolean ):int
		{
			if( isMovingRight )
			{
				for( var i:int = 0; i < blockArray.length; i++ )
				{
					if( blockArray[ i ].end > block.start )
					{
						return i;
					}
				}  
			}
			else
			{
				for( i = 0; i < blockArray.length; i++ )
				{
					if( blockArray[ i ].start >= block.end )
					{
						return i;
					}
				}  
			}
			
			return blockArray.length;
		}
		
		
		private function getSnap( ticks:int ):Snapper
		{
			var timelineState:TimelineState = model.project.projectUserData.timelineState;
			
			var tickMargin:Number = _snapPixelMargin / timelineState.zoom;

			ticks = Math.max( 0, ticks );
			
			var result:Snapper = new Snapper( ticks, tickMargin );
			
			//snap to non-selected blocks
			for each( var track:Track in model.project.tracks )
			{
				if( track == model.selectedTrack ) continue;
				
				if( track.trackUserData.arrangeViewCollapsed ) continue;		
				
				for each( var block:Block in track.blocks )
				{
					if( model.isObjectSelected( block.id ) ) continue;
					
					if( _draggedBlocks.hasOwnProperty( block.id ) ) continue;
					
					result.doSnap( block.start );
					result.doSnap( block.end );
				}
			}
			
			//snap to scenes
			for each( var scene:Scene in model.project.player.scenes )
			{
				result.doSnap( scene.start );
				result.doSnap( scene.end );
			}

			return result;			
		}
		
		
		private function getTrackUnderMouse():ArrangeViewTrack
		{
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				if( _tracks.isItemCollapsed( i ) )
				{
					continue;
				}
				
				var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
				Assert.assertNotNull( track );
				
				if( Utilities.pointIsInRectangle( track.getRect( this ), mouseX, mouseY ) )
				{
					return track;
				}
			} 
			
			return null;
		}
		
		
		private function getTrackIndexNearestMouse():int
		{
			var nearestTrackIndex:int = -1;
			var distanceToNearestTrack:Number;
			
			var mousePoint:Point = new Point( mouseX, mouseY );
				
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				if( _tracks.isItemCollapsed( i ) )
				{
					continue;
				}
				
				var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
				Assert.assertNotNull( track );
				
				var trackRect:Rectangle = track.getRect( this );
				
				var distanceToTrack:Number = distanceFromRectangleToPoint( trackRect, mousePoint );
				if( distanceToTrack < 0 )
				{
					return i;
				}
				
				if( nearestTrackIndex < 0 || distanceToTrack < distanceToNearestTrack )
				{
					nearestTrackIndex = i;
					distanceToNearestTrack = distanceToTrack;
				}
			} 
			
			return nearestTrackIndex;			
		}
		
		
		private function distanceFromRectangleToPoint( rect:Rectangle, point:Point ):Number
		{
			if( Utilities.pointIsInRectangle( rect, point.x, point.y ) ) 
			{
				return -1;
			}
			
			var xDifference:Number = point.x < rect.left ? rect.left - point.x : point.x - rect.right;
			var yDifference:Number = point.y < rect.top ? rect.top - point.y : point.y - rect.bottom;   
			
			Assert.assertTrue( xDifference >= 0 || yDifference >= 0 );
			
			if( xDifference < 0 ) return yDifference;
			if( yDifference < 0 ) return xDifference;
			
			return Math.max( xDifference, yDifference );
		}
		
		
		private function onScrollTimer( event:TimerEvent ):void
		{
			const scrollMargin:int = 5;
			const scrollPixels:int = 25;
			
			var timelineState:TimelineState = model.project.projectUserData.timelineState;
			
			var scrollAmount:Number = 0; 
			
			if( mouseX < scrollMargin )
			{
				if( _blockDragInfo.dragType != BlockDragType.CHANGE_END || timelineState.pixelsToTicks( mouseX ) > _blockDragXTicks )
				{
					scrollAmount = -scrollPixels / timelineState.zoom;
				}
			}
			else
			{
				if( mouseX > width - scrollMargin )
				{
					if( _blockDragInfo.dragType != BlockDragType.CHANGE_START || timelineState.pixelsToTicks( mouseX ) < _blockDragXTicks )
					{
						scrollAmount = scrollPixels / timelineState.zoom;
					}
				}
			}
			
			if( scrollAmount != 0 )
			{
				var scrolledState:TimelineState = new TimelineState;
				scrolledState.copyFrom( timelineState );
				scrolledState.scroll += scrollAmount;
				
				controller.processCommand( new SetTimelineState( scrolledState ) );
				onDragBlock( null );
			}
		}
		
		
		private function getTrackIndexFromTree( trackID:int ):int
		{
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				if( ( _tracks.getItem( i ) as ArrangeViewTrack ).trackID == trackID )
				{
					return i;
				}
			}
			
			Assert.assertTrue( false );	//trackID not found
			return -1;	
		}
		
		
		private function onTreeReordered( event:Event ):void
		{
			var newTrackOrder:Vector.<int> = new Vector.<int>;
			
			for( var i:int = 0; i < _tracks.getItemCount(); i++ )
			{
				var track:ArrangeViewTrack = _tracks.getItem( i ) as ArrangeViewTrack;
				Assert.assertNotNull( track );
				newTrackOrder.push( track.trackID );				
			}

			controller.processCommand( new SetTrackOrder( newTrackOrder ) );			
		}
	
	
		private function selectBlock( blockID:int, hasMultiselectionModifier:Boolean, isRepositionArea:Boolean, isResizeArea:Boolean ):void
		{
			var track:Track = model.getTrackFromBlock( blockID );
			Assert.assertNotNull( track );
			
			_selectedBlockWasPreviouslySelected = model.isObjectSelected( blockID );
			_selectedBlockWasMultiSelectionClicked = hasMultiselectionModifier && !isResizeArea;
			
			controller.processCommand( new SetPrimarySelectedChild( track.id, blockID ) );
			
			if( !_selectedBlockWasPreviouslySelected )
			{
				controller.processCommand( new SetObjectSelection( blockID, true ) );

				if( !hasMultiselectionModifier )
				{
					deselectOtherBlocks( blockID );	
				}
			}
			
			if( !isRepositionArea )
			{
				handlePostClickSelection();
			}
		}
		
		
		private function handlePostClickSelection():void
		{
			if( _blockDragInfo.blockView )
			{
				if( _selectedBlockWasMultiSelectionClicked )
				{
					if( _selectedBlockWasPreviouslySelected )
					{
						controller.processCommand( new SetObjectSelection( _blockDragInfo.blockView.blockID, false ) );
					}
				}
				else
				{
					if( _selectedBlockWasPreviouslySelected )
					{
						deselectOtherBlocks( _blockDragInfo.blockView.blockID );
					}
				}
			}
		}
		
		
		private function deselectOtherBlocks( blockID:int ):void
		{
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					if( block.id != blockID )
					{
						controller.processCommand( new SetObjectSelection( block.id, false ) );
					}
				}
			}
		}

		
		private function deselectAllBlocks():void
		{
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					controller.processCommand( new SetObjectSelection( block.id, false ) );
				}
			}
			
			if( model.primarySelectedBlock != null )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.selectedTrack.id, -1 ) );
			}
		}
		
		
		private function selectProject():void
		{
			if( model.selectedTrack != null )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.project.id, -1 ) );
			}
			
			if( model.selectedScene != null )
			{
				controller.processCommand( new SelectScene( -1 ) );
			}
		}
		
		
 		private function createTrack():void
 		{
 			controller.processCommand( new AddTrack() );
 		}
 		
 		
 		private function createBlockFromMenu():void
 		{
			var track:Track = model.selectedTrack;
			Assert.assertNotNull( track );
			
			var start:int = 0;
			for each( var existingBlock:Block in track.blocks )
			{
				start = Math.max( start, existingBlock.end );
			} 			
			
			createBlock( track.id, start );
 		}
 		
 		
		private function createBlockOnDoubleClick( trackID:int ):void
		{
			var centre:int = model.project.projectUserData.timelineState.pixelsToTicks( mouseX );
			var start:int = Math.max( 0, centre - Block.newBlockSeconds * model.project.player.rate / 2 );

			createBlock( trackID, start );
		}


		private function createBlock( trackID:int, start:int ):void
		{
			var track:Track = model.getTrack( trackID );
			Assert.assertNotNull( track );
			
			for each( var existingBlock:Block in track.blocks )
			{
				if( existingBlock.start <= start && existingBlock.end > start )
				{
					start = existingBlock.end;
				}
			}
			
			var end:int = start + Block.newBlockSeconds * model.project.player.rate;
		
			var addBlockCommand:AddBlock = new AddBlock( trackID, start, end ); 
			controller.processCommand( addBlockCommand );

			//move downstream blocks
			var newBlock:Block = new Block;
			newBlock.copyBlockProperties( model.getBlock( addBlockCommand.blockID ) );
			_draggedBlocks = new Object;
			_draggedBlocks[ newBlock.id ] = newBlock;
			
			_draggedTrackChanges = new Object;
			_draggedTrackChanges[ newBlock.id ] = trackID;
			
			doBlockRescheduling( true );	
			
			for each( var block:Block in _draggedBlocks )
			{
				var blockID:int = block.id;
				
				if( blockID == newBlock.id ) 
				{
					continue;
				}
				
				controller.processCommand( new RepositionBlock( blockID, block.start, block.end ) );
			}
			
			_draggedBlocks = null;
			_draggedTrackChanges = null;
		}


 		private function deleteTrack():void
 		{
 			Assert.assertNotNull( model.selectedTrack );

   			controller.processCommand( new RemoveTrack( model.selectedTrack.id ) );
 		}
 		
 		
 		private function changeTrackColor():void
 		{
			Assert.assertNotNull( model.selectedTrack );
			
			new TrackColorPicker( model, controller, this );
 		}
 		
 		
 		private function get blockDirectory():String
 		{
 			if( _lastBlockDirectory )
 			{
 				var directory:File = new File( _lastBlockDirectory );
 				if( directory.exists )
 				{
	 				return _lastBlockDirectory;
 				}
 			}

			return File.documentsDirectory.nativePath;
 		}


 		private function get trackDirectory():String
 		{
			if( _lastTrackDirectory )
 			{
 				var directory:File = new File( _lastTrackDirectory );
 				if( directory.exists )
 				{
	 				return _lastTrackDirectory;
 				}
 			}

			return File.documentsDirectory.nativePath;
 		}
 		
 		
 		private function importBlock():void
 		{
			var filter:FileFilter = new FileFilter( "Integra Blocks", "*." + Utilities.integraFileExtension + ";*.bixd" );
 			var file:File = new File( blockDirectory );
 			file.browseForOpen( "Import Block", [filter] );
 			
 			file.addEventListener( Event.SELECT, onSelectBlockToImport );      			
 		}


 		private function exportBlock():void
 		{
			var filter:FileFilter = new FileFilter( "Integra Blocks", "*." + Utilities.integraFileExtension );
 			var file:File = new File( blockDirectory + "/" + model.primarySelectedBlock.name + "." + Utilities.integraFileExtension );
 			file.browseForSave( "Export Block" );
 			
 			file.addEventListener( Event.SELECT, onSelectBlockToExport );      			
 		}
 		
 		
 		private function addBlockToBlockLibrary():void
 		{
 			var directory:File = new File( Utilities.getUserBlockLibraryDirectory() );
			Assert.assertTrue( directory.exists && directory.isDirectory );
			
 			var block:Block = model.primarySelectedBlock;
 			Assert.assertNotNull( block );
 			
			var filename:String = block.name;
			
			while( directory.resolvePath( filename + "." + Utilities.integraFileExtension ).exists )
			{
				filename += "_";
			}
				
 			var file:File = directory.resolvePath( filename + "." + Utilities.integraFileExtension );
			Assert.assertFalse( file.exists );
			controller.exportBlock( file.nativePath );
 		}
 		

 		private function importTrack():void
 		{
			var filter:FileFilter = new FileFilter( "Integra Tracks", "*." + Utilities.integraFileExtension + ";*.tixd" );
 			var file:File = new File( trackDirectory );
 			file.browseForOpen( "Import Track", [filter] );
 			
 			file.addEventListener( Event.SELECT, onSelectTrackToImport );      			
 		}


 		private function exportTrack():void
 		{
			var filter:FileFilter = new FileFilter( "Integra Tracks", "*." + Utilities.integraFileExtension );
 			var file:File = new File( trackDirectory + "/" + model.selectedTrack.name + "." + Utilities.integraFileExtension );
 			file.browseForSave( "Export Track" );
 			
 			file.addEventListener( Event.SELECT, onSelectTrackToExport );      			
 		}
 		
 		
 		private function onSelectBlockToImport( event:Event ):void
 		{
 			var file:File = event.target as File;
 			Assert.assertNotNull( file );
 			
 			_lastBlockDirectory = file.parent.nativePath;

			controller.processCommand( new ImportBlock( file.nativePath, model.selectedTrack.id, model.project.player.playPosition ) );
 		}


 		private function onSelectBlockToExport( event:Event ):void
 		{
 			var file:File = event.target as File;
 			Assert.assertNotNull( file );
 			
 			_lastBlockDirectory = file.parent.nativePath;

			controller.exportBlock( file.nativePath ); 			
 		}


 		private function onSelectTrackToImport( event:Event ):void
 		{
 			var file:File = event.target as File;
 			Assert.assertNotNull( file );
 			
 			_lastTrackDirectory = file.parent.nativePath;

			controller.processCommand( new ImportTrack( file.nativePath ) ); 			
 		}


 		private function onSelectTrackToExport( event:Event ):void
 		{
 			var file:File = event.target as File;
 			Assert.assertNotNull( file );
 			
 			_lastTrackDirectory = file.parent.nativePath;

			controller.exportTrack( file.nativePath ); 			
 		}

 		
		private function onUpdateDeleteBlocksMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = false;
			menuItem.label = "Delete Block";
			
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					if( model.isObjectSelected( block.id ) )
					{
						if( menuItem.enabled )
						{
							menuItem.label = "Delete Blocks";
							return;
						}
						else
						{	
							menuItem.enabled = true;
						}
					}
				}
			}

		}
		
		
		private function onUpdateCreateBlockMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.selectedTrack != null );
		}
		

		private function onUpdateOpenBlockMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.primarySelectedBlock != null );
		}

		
		private function onUpdateDeleteTrackMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.selectedTrack != null );
		}
		
		
		private function onUpdateChangeTrackColorMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.selectedTrack != null && model.selectedTrack.active && model.project.active );
		}


		private function onUpdateImportBlockMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.selectedTrack != null );
		}


		private function onUpdateExportBlockMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.primarySelectedBlock != null );
		}


		private function onUpdateExportTrackMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.selectedTrack != null );
		}
		
		
		private var _tracks:ViewTree = new ViewTree;
		
		private var _blockDragInfo:BlockDragInfo = null;
		private var _blockDragXTicks:Number = 0;
		private var _blockDragXOffset:Number = 0;
		private var _selectedBlockWasPreviouslySelected:Boolean = false;
		private var _selectedBlockWasMultiSelectionClicked:Boolean = false;
		private var _lastBlockDirectory:String = null;
		private var _lastTrackDirectory:String = null;

		private var _draggedBlocks:Object = null;		//map of blocknames to locally modified blocks
		private var _draggedTrackChanges:Object = null;	//map of blocknames to target tracks

		private var _scrollTimer:Timer = new Timer( 100 );

		private var _playPositionMarker:PlayPositionMarker = new PlayPositionMarker( false, false );
		private var _snapLines:TimeDomainSnapLines = new TimeDomainSnapLines;

		private var _horizontalScrollBar:HScrollBar = new HScrollBar;		
		private var _processingHorizontalScrollBarEvent:Boolean = false;
		
		
        private var contextMenuData:Array = 
        [
            { label: "Create Block", keyEquivalent: "b", ctrlKey: true, keyCode: Keyboard.B, handler: createBlockFromMenu, updater:onUpdateCreateBlockMenuItem },
            { label: "Delete Block(s)", keyEquivalent: "backspace", keyCode: Keyboard.BACKSPACE, handler: deleteBlocks, updater: onUpdateDeleteBlocksMenuItem },
            { label: "Open Block", keyEquivalent: "b", ctrlKey: true, shiftKey: true, keyCode: Keyboard.B, handler: openBlock, updater: onUpdateOpenBlockMenuItem },
            { type: "separator" },             
            { label: "Create Track", keyEquivalent: "t", ctrlKey: true, keyCode: Keyboard.T, handler: createTrack },
            { label: "Delete Track", keyEquivalent: "t", ctrlKey: true, shiftKey: true, keyCode: Keyboard.T, handler: deleteTrack, updater: onUpdateDeleteTrackMenuItem },
            { label: "Change Track Color...", handler: changeTrackColor, updater: onUpdateChangeTrackColorMenuItem },
            { type: "separator" }, 
			{ label: "Import", children: 
			[
	            { label: "Track...", handler: importTrack },
	            { label: "Block...", handler: importBlock, updater: onUpdateImportBlockMenuItem }
			] }, 
			{ label: "Export", children: 
			[
    	        { label: "Track...", handler: exportTrack, updater: onUpdateExportTrackMenuItem },
	            { label: "Block...", handler: exportBlock, updater: onUpdateExportBlockMenuItem },
	            { type: "separator" }, 
	            { label: "Add Block to Block Library", handler: addBlockToBlockLibrary, updater: onUpdateExportBlockMenuItem }
			] }
        ];
		
		private const _snapPixelMargin:Number = 10;
	}
}
