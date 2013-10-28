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
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.ScrollPolicy;
	
	import components.controller.serverCommands.AddBlock;
	import components.controller.serverCommands.AddTrack;
	import components.controller.serverCommands.RemoveBlock;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.RepositionBlock;
	import components.controller.serverCommands.SetBlockTrack;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetPlayPosition;
	import components.controller.userDataCommands.SetLiveViewControlPosition;
	import components.controller.userDataCommands.SetLiveViewControls;
	import components.controller.userDataCommands.SetTrackColor;
	import components.controller.userDataCommands.SetTrackExpanded;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Block;
	import components.model.Track;
	import components.model.userData.LiveViewControl;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	
	import flexunit.framework.Assert;


	public class LiveViewTrack extends IntegraView
	{
		public function LiveViewTrack( trackID:int )
		{
			super();
			
			_trackID = trackID;

			addUpdateMethod( AddBlock, onBlockAdded );
			addUpdateMethod( RemoveBlock, onBlockRemoved );
			addUpdateMethod( RepositionBlock, onBlockRepositioned );
			addUpdateMethod( SetBlockTrack, onBlockChangedTrack );
			addUpdateMethod( SetPlayPosition, onPlayPositionChanged );
			addUpdateMethod( SetTrackColor, onTrackColorChanged );
			addUpdateMethod( SetLiveViewControlPosition, onLiveViewControlPositioned );
			addUpdateMethod( SetLiveViewControls, onLiveViewControlsChanged );
			addUpdateMethod( ToggleLiveViewControl, onLiveViewControlToggled );
			addUpdateMethod( SetContainerActive, onSetContainerActive );
			
			addTitleInvalidatingCommand( RenameObject );
			addTitleInvalidatingCommand( SetPlayPosition );
			addColorChangingCommand( SetTrackColor );
			addColorChangingCommand( SetContainerActive );
			addActiveChangingCommand( SetContainerActive );

			addEventListener( Event.RESIZE, onResize );
			
			_transitionTimer.addEventListener( TimerEvent.TIMER, onTransitionTimer );  
			_transitionTimer.addEventListener( TimerEvent.TIMER_COMPLETE, transitionComplete );  
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    
		}
		
		public function get trackID():int { return _trackID; }
		
		
		override public function get title():String
		{
			if( !model.doesObjectExist( _trackID ) ) return "";
			if( !( model.getDataObjectByID( _trackID ) is Track ) ) return "";
				
			var title:String = model.getTrack( _trackID ).name;
			
			if( _activeLiveViewBlock )
			{
				var activeBlockID:int = _activeLiveViewBlock.blockID;
				if( model.doesObjectExist( activeBlockID ) && model.getDataObjectByID( activeBlockID ) is Block )
				{
					title += "." + model.getBlock( activeBlockID ).name;
				}
			}
			
			return title;
		}


		override public function get vuMeterContainerID():int
		{
			if( !model.doesObjectExist( _trackID ) ) return -1;
			if( !( model.getDataObjectByID( _trackID ) is Track ) ) return -1;

			return _trackID;
		}	


		override public function get color():uint
		{
			if( !model.doesObjectExist( _trackID ) ) return 0;
			if( !( model.getDataObjectByID( _trackID ) is Track ) ) return 0;
				
			return model.getContainerColor( _trackID );
		}
		
		
		override public function set collapsed( collapsed:Boolean ):void 
		{
			super.collapsed = collapsed; 

			controller.processCommand( new SetTrackExpanded( _trackID, !collapsed, SetTrackExpanded.LIVE_VIEW ) );
		}
		
		
		override public function get active():Boolean
		{
			if( !model.doesObjectExist( _trackID ) ) return false;
			if( !( model.getDataObjectByID( _trackID ) is Track ) ) return false;

			return model.getTrack( _trackID ).active;
		}
		
		
		override public function set active( active:Boolean ):void 
		{
			controller.processCommand( new SetContainerActive( _trackID, active ) );
		}
		
		
		

		override public function free():void
		{
			_trackID = -1;

			super.free();
			
			if( _activeLiveViewBlock )
			{
				removeChild( _activeLiveViewBlock );
				_activeLiveViewBlock.free();
				_activeLiveViewBlock = null;
			}
		
			if( _previousLiveViewBlock )
			{
				removeChild( _previousLiveViewBlock );
				_previousLiveViewBlock.free();
				_previousLiveViewBlock = null;
			}
		}

		
		override protected function onAllDataChanged():void
		{
			_previousPlayPosition = model.project.player.playPosition;
			
			updateActiveBlock();
			
			updateHeight();
			
			updateColor();
		}
		
		
		private function onBlockAdded( command:AddBlock ):void
		{
			if( command.trackID == _trackID )
			{
				updateActiveBlock();
			}
		}


		private function onBlockRemoved( command:RemoveBlock ):void
		{
			updateActiveBlock();
		}


		private function onBlockRepositioned( command:RepositionBlock ):void
		{
			var blockID:int = command.blockID;
			
			if( model.getTrackFromBlock( command.blockID ).id == _trackID )
			{
				updateActiveBlock();
			}
		}
		
		
		private function onBlockChangedTrack( command:SetBlockTrack ):void
		{
			updateActiveBlock();
		}


		
		private function onPlayPositionChanged( command:SetPlayPosition ):void
		{
			var playPosition:int = model.project.player.playPosition; 

			var transitionDirection:int = 0;
			if( !MouseCapture.instance.hasCapture )
			{
				transitionDirection = ( playPosition > _previousPlayPosition ) ? 1 : -1;
			}
			
			updateActiveBlock( transitionDirection );
			
			_previousPlayPosition = playPosition;
		}
		
		
		private function onTrackColorChanged( command:SetTrackColor ):void
		{
			updateColor();
		}
		
		
		private function onSetContainerActive( command:SetContainerActive ):void
		{
			updateColor();
		}
		
		
		private function updateColor():void
		{
			if( !model.doesObjectExist( _trackID ) ) return;
			if( !model.getDataObjectByID( _trackID ) is Track ) return;
				
			setStyle( "color", model.getContainerColor( _trackID ) );
		}
		
		
		private function updateActiveBlock( transitionDirection:int = 0 ):void
		{
			var currentBlock:Block = getActiveBlock();
			
			if( currentBlock )
			{
				if( _activeLiveViewBlock )
				{
					if( _activeLiveViewBlock.blockID == currentBlock.id )
					{
						return;
					}
					else
					{
						removeActiveBlock( transitionDirection );
					}
				}

				addActiveBlock( currentBlock, transitionDirection );
				
				expandCollapseEnabled = true;
			}
			else
			{
				if( _activeLiveViewBlock )
				{
					removeActiveBlock( transitionDirection );
				}
				
				expandCollapseEnabled = false;
			}
			
			updateHeight();
		}
		
		
		private function addActiveBlock( block:Block, direction:int ):void
		{
			Assert.assertNull( _activeLiveViewBlock );
			
			_activeLiveViewBlock = new LiveViewBlock( block.id );
			
			addChild( _activeLiveViewBlock );

			if( direction != 0 )
			{
				_transitionDirection = direction;				
				_transitionTimer.reset();
				_transitionTimer.start();
				doTransition( 0 );
			}
		}
		
		
		private function removeActiveBlock( direction:int ):void
		{
			Assert.assertNotNull( _activeLiveViewBlock );

			if( _previousLiveViewBlock )
			{
				removeChild( _previousLiveViewBlock );
				_previousLiveViewBlock.free();
				_previousLiveViewBlock = null;
			}

			if( direction == 0 )
			{
				removeChild( _activeLiveViewBlock );
				_activeLiveViewBlock = null;
			}
			else
			{
				_transitionDirection = direction;

				_previousLiveViewBlock = _activeLiveViewBlock;
				_activeLiveViewBlock = null;
			
				_transitionTimer.reset();
				_transitionTimer.start();
				doTransition( 0 );
			}				
		}


		private function getActiveBlock():Block
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );
			
			var playPosition:int = model.project.player.playPosition;
			
			for each( var block:Block in track.blocks )
			{
				if( playPosition >= block.start && playPosition < block.end )
				{
					return block;
				} 
			} 
			
			return null;
		}		


		
		private function onTransitionTimer( event:TimerEvent ):void
		{
			doTransition( _transitionTimer.currentCount / _transitionTimer.repeatCount );
		}
		
		
		private function doTransition( proportion:Number ):void
		{
			Assert.assertTrue( _transitionDirection != 0 );
			
			if( _activeLiveViewBlock )
			{
				_activeLiveViewBlock.x = ( width - proportion * width ) * _transitionDirection;
				_activeLiveViewBlock.width = width;
			}
			
			if( _previousLiveViewBlock )
			{
				_previousLiveViewBlock.x = ( 0 - proportion * width ) * _transitionDirection;
				_previousLiveViewBlock.width = width;
			}
			
			height = _previousHeight + ( _targetHeight - _previousHeight ) * proportion;
		}


		private function transitionComplete( event:TimerEvent ):void
		{
			if( _activeLiveViewBlock )
			{
				Assert.assertTrue( _activeLiveViewBlock.x == 0 );
			}
			
			if( _previousLiveViewBlock )
			{
				if( stage && stage.focus == _previousLiveViewBlock )
				{
					setFocus();		//claim focus to ensure stage keybindings don't get lost
				}

				removeChild( _previousLiveViewBlock );
				_previousLiveViewBlock.free();
				_previousLiveViewBlock = null;
			}
			
			height = _targetHeight;
			
			_transitionTimer.reset();
			_transitionDirection = 0;
		}
		
		
		private function updateHeight():void
		{
			_targetHeight = 0;

			if( _activeLiveViewBlock )
			{
				_targetHeight = getBlockHeight( _activeLiveViewBlock );
			}
			
			if( _transitionDirection == 0 )
			{
				height = _targetHeight;
			}
			else
			{
				_previousHeight = height;
			}
		}
		
		
		private function onResize( event:Event ):void
		{
			updateHeight();
		}
		
		
		private function onLiveViewControlPositioned( command:SetLiveViewControlPosition ):void
		{
			if( _activeLiveViewBlock )
			{
				if( model.getBlockFromModuleInstance( command.moduleID ).id == _activeLiveViewBlock.blockID )
				{
					updateHeight();
				}
			}			
		}

		
		private function onLiveViewControlsChanged( command:SetLiveViewControls ):void
		{
			if( _activeLiveViewBlock )
			{
				if( command.blockID  == _activeLiveViewBlock.blockID )
				{
					updateHeight();
				}
			}			
		}

		
		private function onLiveViewControlToggled( command:ToggleLiveViewControl ):void
		{
			if( _activeLiveViewBlock )
			{
				if( model.getBlockFromModuleInstance( command.liveViewControl.moduleID ).id == _activeLiveViewBlock.blockID )
				{
					updateHeight();
				}
			}			
		}
		

		private function getBlockHeight( liveViewBlock:LiveViewBlock ):Number
		{
			const minimumBlockHeight:Number = 100;
			var bottomMargin:Number = 10;
			
			if( liveViewBlock.horizontalScrollBar )
			{
				bottomMargin += liveViewBlock.horizontalScrollBar.height;
			}
			
			var maximumControlBottom:Number = 0;
			
			var block:Block = model.getBlock( liveViewBlock.blockID );
			Assert.assertNotNull( block );
			
			for each( var liveViewControl:LiveViewControl in block.blockUserData.liveViewControls )
			{
				maximumControlBottom = Math.max( maximumControlBottom, liveViewControl.position.bottom );
			}
			
			return Math.max( maximumControlBottom + bottomMargin, minimumBlockHeight );		
		}
		
		
		private var _trackID:int;

		private var _activeLiveViewBlock:LiveViewBlock = null;
		private var _previousLiveViewBlock:LiveViewBlock = null;
		
		private var _transitionTimer:Timer = new Timer( 20, 20 );
		private var _transitionDirection:int = 0;

		private var _targetHeight:Number = 0;
		private var _previousHeight:Number = 0;
		
		
		private var _previousPlayPosition:int = 0;
	}
}