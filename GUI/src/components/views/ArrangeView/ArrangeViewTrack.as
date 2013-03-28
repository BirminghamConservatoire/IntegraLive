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
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import components.controller.serverCommands.AddBlock;
	import components.controller.serverCommands.ImportBlock;
	import components.controller.serverCommands.RemoveBlock;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.RepositionBlock;
	import components.controller.serverCommands.SetBlockTrack;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTimelineState;
	import components.controller.userDataCommands.SetTrackColor;
	import components.controller.userDataCommands.SetTrackExpanded;
	import components.controller.userDataCommands.SetTrackHeight;
	import components.model.Block;
	import components.model.Info;
	import components.model.Project;
	import components.model.Track;
	import components.model.userData.TimelineState;
	import components.utils.DragImage;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;
	

	public class ArrangeViewTrack extends IntegraView
	{
		public function ArrangeViewTrack( trackID:int )
		{
			super();
			
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			addEventListener( DragEvent.DRAG_ENTER, onDragEnter );
			addEventListener( DragEvent.DRAG_OVER, onDragOver );
			addEventListener( DragEvent.DRAG_EXIT, onDragExit );
			addEventListener( DragEvent.DRAG_DROP, onDragDrop );
	
			addUpdateMethod( AddBlock, onBlockAdded );
			addUpdateMethod( RemoveBlock, onBlockRemoved );
			addUpdateMethod( RepositionBlock, onBlockRepositioned );
			addUpdateMethod( SetBlockTrack, onBlockChangedTrack );
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( SetTimelineState, onTimlineStateChanged );
			
			addTitleInvalidatingCommand( RenameObject );
			addColorChangingCommand( SetTrackColor );
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    
			
			setStyle( "backgroundColor", 0x808080 );

			_trackID = trackID;
			_track = model.getTrack( _trackID );
			Assert.assertNotNull( _track );
		}
		
		public function get trackID():int { return _trackID; }
		
		
		
		override public function get vuMeterContainerID():int
		{
			return _trackID;
		}	
	
		
		override public function get title():String
		{
			if( _track ) 
			{
				return _track.name;
			}
			
			return "";
		}
		
		
		override public function get isTitleEditable():Boolean 
		{ 
			return true;
		}
		
		
		override public function set title( title:String ):void 
		{
			super.title = title;
			
			controller.processCommand( new RenameObject( _trackID, title ) );
		}
		
		
		override public function set collapsed( collapsed:Boolean ):void 
		{
			super.collapsed = collapsed; 

			controller.processCommand( new SetTrackExpanded( _trackID, !collapsed, SetTrackExpanded.ARRANGE_VIEW ) );
		}
		

		override public function get color():uint
		{
			return _track.userData.color;
		}
		
		
		override public function resizeFinished():void
		{
			controller.processCommand( new SetTrackHeight( _trackID, height ) );
		}

		
		override public function titleClicked():void
		{
			controller.processCommand( new SetPrimarySelectedChild( model.project.id, _trackID ) );
		}
		
		
		override public function getInfoToDisplay( event:MouseEvent ):Info 
		{ 
			return _track.info; 
		}
		
		
		override public function free():void
		{
			_trackID = -1;

			super.free();
			
			clear();
		}
		
				
		public function getBlockDragInfo():BlockDragInfo
		{
			for each( var blockView:BlockView in _blockViews )
			{
				var dragInfo:BlockDragInfo = blockView.getDragInfo();
				if( dragInfo )
				{
					return dragInfo;
				}
			}
			
			return null;
		}		
		
		
		public function applyDraggedBlocks( draggedBlocks:Object, draggedTrackChanges:Object ):void
		{
			if( _lastDraggedBlocks )
			{
				for each( var previouslyDraggedBlock:Block in _lastDraggedBlocks )
				{
					var previouslyDraggedBlockID:int = previouslyDraggedBlock.id;
					if( !draggedBlocks.hasOwnProperty( previouslyDraggedBlockID ) )
					{
						revertBlock( previouslyDraggedBlockID );
					}
				}
			}
			
			for each( var block:Block in draggedBlocks )
			{
				var blockID:int = block.id;
				
				if( draggedTrackChanges.hasOwnProperty( blockID ) )
				{
					repositionBlock( block, draggedTrackChanges[ blockID ] );
				}
				else
				{
					repositionBlock( block );
				}
			}
			
			_lastDraggedBlocks = draggedBlocks;
		}
		
		
		public function revertDraggedBlocks():void
		{
			if( !_lastDraggedBlocks ) return;

			for each( var previouslyDraggedBlock:Block in _lastDraggedBlocks )
			{
				revertBlock( previouslyDraggedBlock.id );
			}
			
			_lastDraggedBlocks = null;
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == FontSize.STYLENAME )
			{
				minHeight = FontSize.getTextRowHeight( this );
			}
		} 
		
		
		override protected function onAllDataChanged():void
		{
			clear();
			
			updateSelection();
			
			for each( var block:Block in _track.blocks )
			{
				addBlock( block );
			}
		}
		
		
		private function onBlockAdded( command:AddBlock ):void
		{
			if( command.trackID == _trackID )
			{
				addBlock( model.getBlock( command.blockID ) );
			}
		}


		private function onBlockRemoved( command:RemoveBlock ):void
		{
			var blockID:int = command.blockID;
			if( isBlockIsOnThisTrack( blockID ) )
			{
				removeBlock( blockID );
			}
		}


		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			if( model.getDataObjectByID( command.objectID ) is Project )
			{ 
				updateSelection();
			}
		}


		private function onBlockRepositioned( command:RepositionBlock ):void
		{
			var blockID:int = command.blockID;
			
			if( isBlockIsOnThisTrack( blockID ) )
			{
				positionBlock( model.getBlock( blockID ) );
			}
		}
		
		
		private function onBlockChangedTrack( command:SetBlockTrack ):void
		{
			repositionBlock( model.getBlock( command.blockID ) );
		}


		private function onTimlineStateChanged( command:SetTimelineState ):void
		{
			for( var blockID:String in _blockViews )
			{
				var block:Block = model.getBlock( int( blockID ) );
				if( block )
				{
					positionBlock( block );
				}
			}
		}
		
		
		private function clear():void
		{
			for each( var blockView:BlockView in _blockViews )
			{
				removeChild( blockView );
				blockView.free();
			}
			
			_blockViews = new Object;
			
			_lastDraggedBlocks = null;
		}


		private function updateSelection():void
		{
			setStyle( "backgroundAlpha", model.isTrackSelected( _trackID ) ? 0.1 : 0 );
		}

		
		private function revertBlock( blockID:int ):void
		{
			if( blockID >= 0 )
			{
				var block:Block = model.getBlock( blockID );
				repositionBlock( block );
			}
			else
			{
				if( isBlockIsOnThisTrack( blockID ) )
				{
					removeBlock( blockID );
				}						
			}
		}
		
		
		private function repositionBlock( block:Block, newTrackID:int = -1):void
		{
			var blockID:int = block.id;
			
			if( newTrackID < 0 )
			{
				newTrackID = model.getTrackFromBlock( blockID ).id;
			}
			
			if( newTrackID == _trackID )
			{
				if( isBlockIsOnThisTrack( blockID ) )
				{
					positionBlock( block );
				}
				else
				{
					addBlock( block );
				}
			}
			else
			{
				if( isBlockIsOnThisTrack( blockID ) )
				{
					removeBlock( blockID );
				}
			}
		}
		
		
		private function isBlockIsOnThisTrack( blockID:int ):Boolean
		{
			return _blockViews.hasOwnProperty( blockID );
		}
		
		
		private function addBlock( block:Block ):void
		{
			var blockID:int = block.id;
			var blockView:BlockView = new BlockView( blockID );
			addChild( blockView );
			
			_blockViews[ blockID ] = blockView;
			
			positionBlock( block );
		}

		
		private function positionBlock( block:Block ):void
		{
			var blockView:BlockView = _blockViews[ block.id ];
			if( !blockView )
			{
				Assert.assertTrue( false );
				return;
			}
			
			var timelineState:TimelineState = model.project.userData.timelineState;
			
			blockView.x = timelineState.ticksToPixels( block.start );
			blockView.width = block.length * timelineState.zoom;
			blockView.setStyle( "bottom", 0 );
			blockView.setStyle( "top", 0 );
		}
		
		
		private function removeBlock( blockID:int ):void
		{
			removeChild( _blockViews[ blockID ] );
			_blockViews[ blockID ].free();
			delete _blockViews[ blockID ];
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			selectTrack();
		}
		
		
		private function selectTrack():void
		{
			if( !model.selectedTrack || model.selectedTrack.id != _trackID )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.project.id, _trackID ) );
			}
		}
		
		
		private function onDragEnter( event:DragEvent ):void
		{
			if( !event.dragSource.hasFormat( Utilities.getClassNameFromClass( File ) ) )
			{
				return;
			}
			
			DragManager.acceptDragDrop( this );
			
			Assert.assertNull( _dragOverOutline );
			_dragOverOutline = new Canvas();
			_dragOverOutline.setStyle( "borderStyle", "solid" );
			_dragOverOutline.setStyle( "borderThickness", 1 );
			_dragOverOutline.setStyle( "borderColor", 0x808080 );
			_dragOverOutline.setStyle( "top", 0 );
			_dragOverOutline.setStyle( "bottom", 0 );
			
			_dragOverOutline.width = Block.newBlockSeconds * model.project.player.rate * model.project.userData.timelineState.zoom;
			_dragOverOutline.x = event.localX - _dragOverOutline.width / 2;
			
			addChild( _dragOverOutline );
		}
		
		
		private function onDragDrop( event:DragEvent ):void
		{
 			Assert.assertTrue( event.dragSource.hasFormat( Utilities.getClassNameFromClass( File ) ) );

			var file:File = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( File ) ) as File;
			Assert.assertNotNull( file ); 
			
			var blockStartTicks:int = Math.max( 0, model.project.userData.timelineState.pixelsToTicks( event.localX ) - Block.newBlockSeconds * model.project.player.rate / 2 );
			
			controller.processCommand( new ImportBlock( file.nativePath, trackID, blockStartTicks ) ); 
		}


		private function onDragOver( event:DragEvent ):void
		{
			if( !event.dragSource.hasFormat( Utilities.getClassNameFromClass( File ) ) ) return;

			Assert.assertNotNull( _dragOverOutline );
			_dragOverOutline.x = event.localX - _dragOverOutline.width / 2;
			
			DragImage.suppressDragImage();
		}


		private function onDragExit( event:DragEvent ):void
		{
			if( _dragOverOutline )
			{
				removeChild( _dragOverOutline );
				_dragOverOutline = null;
			}
		}


		private var _trackID:int;
		private var _track:Track = null;

		private var _blockViews:Object = new Object;

		private var _lastDraggedBlocks:Object = null;
		
		private var _dragOverOutline:Canvas = null;		
	}
}