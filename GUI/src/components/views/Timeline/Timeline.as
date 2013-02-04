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


package components.views.Timeline
{
	import __AS3__.vec.Vector;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddBlock;
	import components.controller.serverCommands.AddScene;
	import components.controller.serverCommands.ImportBlock;
	import components.controller.serverCommands.RemoveBlock;
	import components.controller.serverCommands.RemoveBlockImport;
	import components.controller.serverCommands.RemoveScene;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.RepositionBlock;
	import components.controller.serverCommands.RepositionScene;
	import components.controller.serverCommands.SelectScene;
	import components.controller.serverCommands.SetPlayPosition;
	import components.controller.userDataCommands.SetTimeDomainSnaplines;
	import components.controller.userDataCommands.SetTimelineState;
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.Block;
	import components.model.Info;
	import components.model.IntegraModel;
	import components.model.Player;
	import components.model.Scene;
	import components.model.Track;
	import components.model.userData.ColorScheme;
	import components.model.userData.TimelineState;
	import components.utils.CursorSetter;
	import components.utils.Snapper;
	import components.utils.TimeDomainSnapLines;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import flexunit.framework.Assert;
	
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	import mx.core.UITextField;
	

	public class Timeline extends IntegraView
	{
		public function Timeline( editable:Boolean )
		{
			super();
			
			_editable = editable;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			height = _timelineHeight;
			
			_playPositionMarker = new PlayPositionMarker( true, editable );
			addElement( _playPositionMarker );
			
			addEventListener( MouseEvent.ROLL_OVER, onRollOver );
			addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );

			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			addEventListener( Event.RESIZE, onResize );
			_scrollTimer.addEventListener( TimerEvent.TIMER, onScrollTimer );
			
			addUpdateMethod( SetTimelineState, onTimelineStateChanged );
			addUpdateMethod( SetPlayPosition, onPlayPositionChanged );
			addUpdateMethod( SelectScene, onSceneSelected );
			addUpdateMethod( AddScene, onSceneAdded );
			addUpdateMethod( RemoveScene, onSceneRemoved );
			addUpdateMethod( RepositionScene, onSceneRepositioned );
			addUpdateMethod( RenameObject, onObjectRenamed );
			addUpdateMethod( UpdateProjectLength, onProjectLengthChanged );

			addUpdateMethod( SetTimeDomainSnaplines, onSetTimeDomainSnaplines );
			
			contextMenuDataProvider = contextMenuData;
			
			addChild( _snapLines );
		}
		
		
		public static function get timelineHeight():int { return _timelineHeight; }
		public static function get timelineWidth():int { return _timelineWidth; }
		

		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_markingTopColor = 0xD1D1D1;
						_markingBottomColor = 0xEDEDED;
						_labelColor = 0xA8A8A8;
						_scrollBarColor = 0xA8A8A8;
						opaqueBackground = 0xFFFFFF;
						break;
						
					case ColorScheme.DARK:
						_markingTopColor = 0x2F2F2F;
						_markingBottomColor = 0x131313;
						_labelColor = 0x585858;
						_scrollBarColor = 0x585858;
						opaqueBackground = 0x000000;
						break;
				}
				
				invalidateDisplayList();
				
				for each( var label:Label in _labels )
				{
					label.setStyle( "color", _labelColor );
				}
			}
		} 
		
		
		public override function getInfoToDisplay( event:MouseEvent ):Info
		{
			var viewInfos:InfoMarkupForViews = InfoMarkupForViews.instance;
			if( mouseY < _markingTop )
			{
				return viewInfos.getInfoForView( "TimelineZoomScrollArea" );
			}
			
			if( mouseY < _markingBottom )
			{
				var sceneBar:SceneBar = Utilities.getAncestorByType( event.target, SceneBar ) as SceneBar;
				if( sceneBar && sceneBar.hasOwnProperty( "id" ) && int( sceneBar.id ) >= 0 )
				{
					return model.getScene( int( sceneBar.id ) ).info;
				}
				
				if( _editable )
				{
					return viewInfos.getInfoForView( "TimelineEditableSceneBar" );
				}
				else
				{
					return viewInfos.getInfoForView( "TimelineNonEditableSceneBar" );
				}
			}
			
			return viewInfos.getInfoForView( "TimelinePlayheadArea" );
		}
		
		
		protected override function onAllDataChanged():void
		{
			updateLabels();
			updateScenes();
			updatePlayPositionMarker();
			invalidateDisplayList();
		}


		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			const markingHorizontalGap:Number = 1;
			const logarithmicGranularity:uint = 10;
			const smallestMarkingWidth:Number = 20;
			const cornerSize:Number = 4;

			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			var timelineState:TimelineState = model.project.userData.timelineState;

			var smallestMarkingSizeTicks:Number = smallestMarkingWidth / timelineState.zoom;
			var smallestMarkingSizeSeconds:Number = smallestMarkingSizeTicks / model.project.player.rate;
			
			var markingSizeSeconds:Number = Math.pow( logarithmicGranularity, Math.ceil( Math.log( smallestMarkingSizeSeconds ) / Math.log( logarithmicGranularity ) ) );
			var markingSizeTicks:Number = markingSizeSeconds * model.project.player.rate;

			if( markingSizeTicks / 2 > smallestMarkingSizeTicks )
			{
				markingSizeTicks /= 2;	
			}

			var markingSizePixels:Number = markingSizeTicks * timelineState.zoom;

			var markingWidth:Number = markingSizePixels - markingHorizontalGap * 2;
			var markingHeight:Number = _markingBottom - _markingTop;  
			 
			var zeroPosition:Number = timelineState.pixelsToTicks( 0 ) / markingSizeTicks;
			var zeroOffset:Number = ( Math.floor( zeroPosition ) - zeroPosition ) * markingSizePixels;

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( markingWidth, markingHeight, Math.PI / 2 );
			const alphas:Array = [ 1, 1 ];
			const ratios:Array = [ 0x00, 0xFF ];
			const colors:Array = [ _markingTopColor, _markingBottomColor ];

			for( var x:Number = zeroOffset; x < width + markingSizePixels; x += markingSizePixels )
			{
				var markingStart:Number = x + markingHorizontalGap;
			
				graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
				graphics.drawRoundRect( markingStart, _markingTop, markingWidth, markingHeight, cornerSize, cornerSize );
				graphics.endFill(); 
			}  
			
			var scrollBarRect:Rectangle = getScrollBarRect();
			if( scrollBarRect )
			{
				graphics.lineStyle( 2, _scrollBarColor );
				graphics.drawRect( scrollBarRect.x, scrollBarRect.y, scrollBarRect.width, scrollBarRect.height );
			}
		}
	
		
		private function onTimelineStateChanged( command:SetTimelineState ):void
		{
			updateLabels();
			repositionScenes();
			updatePlayPositionMarker();
			invalidateDisplayList();
		}
		
		
		private function onPlayPositionChanged( command:SetPlayPosition ):void
		{
			updatePlayPositionMarker();
		}
		
		
		private function onSceneAdded( command:AddScene ):void
		{
			addScene( model.getScene( command.sceneID ) );
		}
		
		
		private function onSceneRemoved( command:RemoveScene ):void
		{
			removeScene( command.sceneID );
		}
		
		
		private function onSceneRepositioned( command:RepositionScene ):void
		{
			repositionScene( model.getScene( command.sceneID ) );
		}


		private function onSceneSelected( command:SelectScene ):void
		{
			var selectedSceneID:int = -1;
			var selectedScene:Scene = model.selectedScene;
			if( selectedScene )
			{
				selectedSceneID = selectedScene.id;
			}
			
			if( selectedSceneID == _selectedSceneID )
			{
				return;
			}
			
			if( _scenes.hasOwnProperty( _selectedSceneID ) )
			{
				( _scenes[ _selectedSceneID ] as SceneBar ).isSelected = false;
			}

			_selectedSceneID = -1;
			
			if( _scenes.hasOwnProperty( selectedSceneID ) )
			{
				( _scenes[ selectedSceneID ] as SceneBar ).isSelected = true;
				_selectedSceneID = selectedSceneID;
			}
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			var sceneID:int = command.objectID;
			if( _scenes.hasOwnProperty( sceneID ) )
			{
				var scene:Scene = model.getScene( sceneID );
				Assert.assertNotNull( scene );
				( _scenes[ sceneID ] as SceneBar ).sceneName = scene.name;
			}
		}
		
		
		private function onProjectLengthChanged( command:UpdateProjectLength ):void
		{
			invalidateDisplayList();
		}
		
		
		private function onSetTimeDomainSnaplines( command:SetTimeDomainSnaplines ):void
		{
			_snapLines.update( command, model.project.userData.timelineState );
		}
		
		
		private function updateScenes():void
		{
			removeAllScenes();

			for each( var scene:Scene in model.project.player.scenes )
			{
				addScene( scene );
			}	
		}
		
		
		private function repositionScenes():void
		{
			for each( var scene:Scene in model.project.player.scenes )
			{
				repositionScene( scene );
			}	
		}
		
		
		private function repositionScene( scene:Scene ):void
		{
			var sceneID:int = scene.id;
			if( _repositionedScenes && _repositionedScenes.hasOwnProperty( sceneID ) )
			{
				scene = _repositionedScenes[ sceneID ];
			} 
			
			if( !_scenes.hasOwnProperty( sceneID ) )
			{
				addScene( scene );
				return;
			}
			
			var sceneBar:SceneBar = _scenes[ sceneID ];
			Assert.assertNotNull( sceneBar );
			
			var timelineState:TimelineState = model.project.userData.timelineState;
			var sceneStartPixels:Number = timelineState.ticksToPixels( scene.start ); 
			var sceneEndPixels:Number = timelineState.ticksToPixels( scene.end ); 

			if( sceneStartPixels > width || sceneEndPixels < 0 )
			{
				removeScene( sceneID )
				return;
			}
			
			sceneBar.x = sceneStartPixels;
			sceneBar.width = sceneEndPixels - sceneStartPixels;
		}
		
		
		private function addScene( scene:Scene ):void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			var sceneStartPixels:Number = timelineState.ticksToPixels( scene.start ); 
			var sceneEndPixels:Number = timelineState.ticksToPixels( scene.end ); 

			if( sceneStartPixels > width || sceneEndPixels < 0 )
			{
				return;
			}

			var sceneBar:SceneBar = new SceneBar( _editable );
			sceneBar.id = String( scene.id );
			sceneBar.sceneName = scene.name;
			sceneBar.x = sceneStartPixels
			sceneBar.y = _markingTop;
			sceneBar.width = sceneEndPixels - sceneStartPixels;
			sceneBar.height = _markingBottom - _markingTop;
			sceneBar.addEventListener( FocusEvent.FOCUS_OUT, onNameEditChange );
			
			if( model.selectedScene )
			{
				if( scene.id == model.selectedScene.id )
				{
					_selectedSceneID = scene.id;
					sceneBar.isSelected = true;					
				}
			}
			
			addElement( sceneBar );
			_scenes[ scene.id ] = sceneBar;
		}
		
		
		private function removeScene( sceneID:int ):void
		{
			if( !_scenes.hasOwnProperty( sceneID ) )
			{
				return;
			}

			removeElement( _scenes[ sceneID ] );
			delete _scenes[ sceneID ];

			if( sceneID == _selectedSceneID )
			{
				_selectedSceneID = -1;
			}
		}
		
		
		private function removeAllScenes():void
		{
			for each( var sceneBar:SceneBar in _scenes )
			{
				removeElement( sceneBar );
			}
			
			_scenes = new Object;
			_selectedSceneID = -1;
		}
		
		
		private function updateLabels():void
		{
			const logarithmicGranularity:uint = 10;
			const smallestLabelSpacing:Number = 50;
			
			if( !model.project ) return;
			var timelineState:TimelineState = model.project.userData.timelineState;

			var smallestLabelSpacingTicks:Number = smallestLabelSpacing / timelineState.zoom;
			var smallestLabelSpacingSeconds:Number = smallestLabelSpacingTicks / model.project.player.rate;
			
			var labelSpacingSeconds:Number = Math.pow( logarithmicGranularity, Math.ceil( Math.log( smallestLabelSpacingSeconds ) / Math.log( logarithmicGranularity ) ) );
			var labelSpacingTicks:Number = labelSpacingSeconds *  model.project.player.rate;
			var labelSpacingPixels:Number = labelSpacingTicks * timelineState.zoom;
			if( labelSpacingPixels / 5 > smallestLabelSpacing )
			{
				labelSpacingTicks /= 5;	
			}
			else
			{
				if( labelSpacingPixels / 2 > smallestLabelSpacing )
				{
					labelSpacingTicks /= 2;	
				}
			}
			
			labelSpacingTicks = Math.max( 1, labelSpacingTicks ); 
			
			var firstLabelTicks:Number = Math.floor( timelineState.pixelsToTicks( 0 ) / labelSpacingTicks ) * labelSpacingTicks;  

			var numberOfLabels:uint = 0;
			
			for( var labelTicks:Number = firstLabelTicks; ; labelTicks += labelSpacingTicks )
			{
				var label:Label = null;

				if( numberOfLabels >= _labels.length )
				{
					label = new Label;
					
					label.y = 0;
					label.height = _markingTop;
					label.setStyle( "fontSize", 9 );
					label.setStyle( "textAlign", "center" );
					label.setStyle( "color", _labelColor );
					
					addElement( label );
					_labels.push( label );										
				}
				else
				{
					label = _labels[ numberOfLabels ];
				}
				
				Assert.assertNotNull( label );

				label.x = timelineState.ticksToPixels( labelTicks );
				label.text = String( labelTicks / model.project.player.rate );
								 			
				numberOfLabels++;
				
				if( label.x > width )
				{
					break;
				}
			}
			
			for( var i:uint = numberOfLabels; i < _labels.length; i++ )
			{
				removeElement( _labels[ i ] );
			}
			
			_labels.length = numberOfLabels;
		}
		
		
		private function updatePlayPositionMarker():void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			var playPosition:int = model.project.player.playPosition;

			_playPositionMarker.x = timelineState.ticksToPixels( playPosition );
			if( _editable )
			{
				_playPositionMarker.y = _markingBottom;
				_playPositionMarker.height = ( height - _markingBottom );
			}
			else 
			{
				_playPositionMarker.y = 0;
				_playPositionMarker.height = height;
			}
		}
		
		
		private function getScrollBarRect():Rectangle
		{
			var timelineState:TimelineState = model.project.userData.timelineState;

			var projectLength:int = model.projectLength;
			
			Assert.assertTrue( timelineState.zoom > 0 );
			
			var barWidth:int = width * width / ( projectLength * timelineState.zoom );
			barWidth = Math.min( barWidth, width );

			var maximumScrollTicks:int = Math.max( 1, projectLength - width / timelineState.zoom );
			
			var proportionThrough:Number = Math.min( 1, timelineState.scroll / maximumScrollTicks );

			var barLeft:int = proportionThrough * ( width - barWidth );			

			var barRight:int = barLeft + barWidth;
			
			if( barRight < 0 ) return null;
			if( barLeft >= width ) return null;
			
			barLeft = Math.max( 0, barLeft );
			barRight = Math.min( barRight, width );
			
			return new Rectangle( barLeft, 0, barRight - barLeft, _markingTop );
		}
		
		
		private function onResize( event:Event ):void
		{
			if( model && model.project )
			{
				updateLabels();
				repositionScenes();
				updatePlayPositionMarker();
			}	
			
			_timelineWidth = width;
			
			updateMask();
		}
		
		
		private function updateMask():void
		{
			if( !this.mask ) 
			{	
				this.mask = new Sprite;
				rawChildren.addChild( this.mask );
			}
			
			var mask:Sprite = this.mask as Sprite;
			Assert.assertNotNull( mask );
			
			mask.graphics.clear();
			mask.graphics.beginFill( 0x808080 );
			mask.graphics.drawRect( 0, 0, width, height );
			mask.graphics.endFill();
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			if( mouseY < _markingTop )
			{
				startTimelineDrag( event );
				return;
			}

			if( mouseY < _markingBottom )
			{
				onClickSceneArea();
				return;
			}
			
			
			startPlayPositionDrag();
		}


		private function startPlayPositionDrag():void
		{
			Assert.assertFalse( MouseCapture.instance.hasCapture );

			//deselect scene
			if( model.selectedScene != null )
			{
				controller.processCommand( new SelectScene( -1 ) );
			}

			MouseCapture.instance.setCapture( this, onPlayPositionDrag, onPlayPositionDragFinished );
			_scrollTimer.start();

			setPlayPositionToMousePosition();
		}
		
		
		private function startTimelineDrag( event:MouseEvent ):void
		{
			_timelineDragHasShift = event.shiftKey;

			stampTimelineDragState();
			
			MouseCapture.instance.setCapture( this, onTimelineDrag, onTimelineDragFinished, CursorSetter.HIDDEN );
		}

		
		private function stampTimelineDragState():void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;

			_timelineDragClickPoint = new Point( mouseX, mouseY );
			_timelineDragInitialState = new TimelineState;
			_timelineDragInitialState.copyFrom( timelineState );
			_timelineDragMouseTicks = _timelineDragInitialState.pixelsToTicks( _timelineDragClickPoint.x );
		}

		
		private function setPlayPositionToMousePosition():void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			var mousePosition:Number = Math.max( 0, Math.min( width, mouseX ) );
			
			controller.processCommand( new SetPlayPosition( timelineState.pixelsToTicks( mousePosition ) ) );
		}
		
		
		private function onPlayPositionDrag( event:MouseEvent ):void
		{
			setPlayPositionToMousePosition();
		}
		
		
		private function onPlayPositionDragFinished():void
		{
			_scrollTimer.stop();
		}
		
		
		private function onTimelineDrag( event:MouseEvent ):void
		{
			Assert.assertNotNull( _timelineDragClickPoint );
			
			if( event.shiftKey != _timelineDragHasShift )
			{
				_timelineDragHasShift = event.shiftKey;
				
				stampTimelineDragState();
			}
			
			var zoomPixels:int = _timelineDragClickPoint.y - mouseY;
			var zoomSnap:int = Math.min( _markingTop, Math.abs( zoomPixels ) );
			if( zoomPixels < 0 ) zoomPixels += zoomSnap;
			else zoomPixels -= zoomSnap;
			
			var zoomChange:Number = Math.pow( 2, ( -zoomPixels ) / _zoomCoefficient );;
			
			var draggedTimeline:TimelineState = new TimelineState;
			draggedTimeline.copyFrom( _timelineDragInitialState );
			
			var xMouseToUse:Number = mouseX;
			
			if( event.shiftKey )
			{
				if( Math.abs( mouseX - _timelineDragClickPoint.x ) > Math.abs( mouseY - _timelineDragClickPoint.y ) )
				{
					//lock y
					zoomChange = 1;
				}
				else
				{
					//lock x
					xMouseToUse = _timelineDragClickPoint.x;
				}
			}
			
			draggedTimeline.zoom *= zoomChange;
			draggedTimeline.scroll = _timelineDragMouseTicks - xMouseToUse / draggedTimeline.zoom;

			controller.processCommand( new SetTimelineState( draggedTimeline ) );
		}


		private function onTimelineDragFinished():void
		{
			_timelineDragClickPoint = null;
			_timelineDragInitialState = null;
		}
		
		
		private function onClickSceneArea():void
		{
			for( var sceneID:String in _scenes )
			{
				var sceneBar:SceneBar = _scenes[ sceneID ];
				Assert.assertNotNull( sceneBar );
				if( Utilities.pointIsInRectangle( sceneBar.getRect( this ), mouseX, mouseY ) )
				{
					controller.processCommand( new SelectScene( int( sceneID ) ) );
					
					if( _editable )
					{
						startSceneRepositionDrag( sceneBar );
					}
					
					return;
				}
			}
			
			//if no existing scene selected, start creation of a new one
			if( _editable )
			{
				startSceneCreationDrag();
			}
			else
			{
				startPlayPositionDrag();
			}

			if( model.selectedScene != null )
			{
				//deselect existing scene 
				controller.processCommand( new SelectScene( -1 ) ); 
			}
		}
		
		
		private function startSceneCreationDrag():void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			
			_sceneCreationClickPixels = Math.max( 0, mouseX );
			_sceneCreationClickTicks = -1;
			_sceneCreationDragTicks = -1;
			MouseCapture.instance.setCapture( this, onSceneCreationDrag, onSceneCreationDragFinished, CursorSetter.HAND );
			_scrollTimer.start();
			
			Assert.assertNull( _sceneBeingCreated );
			_sceneBeingCreated = new SceneBar;
			_sceneBeingCreated.id = String( -1 );
			_sceneBeingCreated.y = _markingTop;
			_sceneBeingCreated.height = _markingBottom - _markingTop;
			_sceneBeingCreated.isSelected = true;
			_sceneBeingCreated.visible = false;
			addElement( _sceneBeingCreated );
		}
		
		
		private function onSceneCreationDrag( event:MouseEvent ):void
		{
			setSceneCreationToMousePosition();
		}


		private function setSceneCreationToMousePosition():void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			var mousePosition:Number = Math.max( 0, Math.min( width, mouseX ) );
			
			var clickSnap:Snapper = getSnap( timelineState.pixelsToTicks( _sceneCreationClickPixels ) );
			var dragSnap:Snapper = getSnap( timelineState.pixelsToTicks( mousePosition ) );
			
			_sceneCreationClickTicks = clickSnap.value;
			_sceneCreationDragTicks = dragSnap.value;
			
			var startTicks:int = Math.min( _sceneCreationClickTicks, _sceneCreationDragTicks );
			var endTicks:int = Math.max( _sceneCreationClickTicks, _sceneCreationDragTicks );
			
			_sceneBeingCreated.visible = ( startTicks != endTicks );
			_sceneBeingCreated.x = timelineState.ticksToPixels( startTicks );
			_sceneBeingCreated.width = ( endTicks - startTicks ) * timelineState.zoom;

			//nudge any neighbouring scenes			
			_repositionedScenes = new Object;
			doSceneRescheduling( startTicks, endTicks, _sceneCreationDragTicks > _sceneCreationClickTicks );
			repositionScenes();
			
			//drag the playhead as well
			controller.processCommand( new SetPlayPosition( startTicks ) );
			
			//set the snap lines
			var snapTicks:Vector.<int> = new Vector.<int>;
			if( clickSnap.snapped ) snapTicks.push( clickSnap.value );
			if( dragSnap.snapped ) snapTicks.push( dragSnap.value );
			
			controller.processCommand( new SetTimeDomainSnaplines( snapTicks ) );
		}

		
		private function onSceneCreationDragFinished():void
		{
			removeElement( _sceneBeingCreated );
			_sceneBeingCreated = null;

			if( _sceneCreationClickTicks >= 0 && _sceneCreationDragTicks >= 0 )
			{
				var startTicks:int = Math.min( _sceneCreationClickTicks, _sceneCreationDragTicks );
				var endTicks:int = Math.max( _sceneCreationClickTicks, _sceneCreationDragTicks );
				if( startTicks != endTicks )
				{
					controller.processCommand( new AddScene( startTicks, endTicks - startTicks ) );
				}
			}
			
			onSceneRepositionDragFinished();			
		}
		
		
		private function startSceneRepositionDrag( sceneBar:SceneBar ):void
		{
			var cursorType:String;
			
			if( Utilities.pointIsInRectangle( sceneBar.getResizeEndRect( this ), mouseX, mouseY ) )
			{
				_repositionDragType = SceneDragType.CHANGE_END;
				_repositionPixelOffset = sceneBar.x + sceneBar.width - mouseX; 
				cursorType = CursorSetter.RESIZE_EW;
			}
			else
			{
				if( Utilities.pointIsInRectangle( sceneBar.getResizeStartRect( this ), mouseX, mouseY ) )
				{
					_repositionDragType = SceneDragType.CHANGE_START;
					cursorType = CursorSetter.RESIZE_EW;
				}
				else
				{
					_repositionDragType = SceneDragType.MOVE;
					cursorType = CursorSetter.MOVE_EW;
				}
				
				_repositionPixelOffset = mouseX - sceneBar.x;
			}
			
			MouseCapture.instance.setCapture( this, onSceneRepositionDrag, onSceneRepositionDragFinished, cursorType );
			_scrollTimer.start();
		}
		
		
		private function onSceneRepositionDrag( event:MouseEvent ):void
		{
			repositionSceneToMousePosition();
		}
		
		
		private function repositionSceneToMousePosition():void
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			var mousePosition:Number = Math.max( 0, Math.min( width, mouseX ) );
			
			var selectedScene:Scene = model.selectedScene;
			Assert.assertNotNull( selectedScene );
			
			var snapTicks:Vector.<int> = new Vector.<int>;
			
			_repositionedScenes = new Object;
			
			var draggedScene:Scene = new Scene;
			draggedScene.copySceneProperties( selectedScene );
			
			var isMovingRight:Boolean = false;
			
			switch( _repositionDragType )
			{
				case SceneDragType.MOVE:
					
					var startTicks:int = Math.max( 0, timelineState.pixelsToTicks( mousePosition - _repositionPixelOffset ) );
					
					var startSnap:Snapper = getSnap( startTicks );
					var endSnap:Snapper = getSnap( startTicks + selectedScene.length );
					
					if( startSnap.snapped )
					{
						if( endSnap.snapped )
						{
							if( endSnap.snappedDistance < startSnap.snappedDistance )
							{
								startTicks = endSnap.value - selectedScene.length;			
								snapTicks.push( endSnap.value );
							}
							else
							{
								startTicks = startSnap.value;			
								snapTicks.push( startSnap.value );

								if( endSnap.snappedDistance == startSnap.snappedDistance )
								{
									snapTicks.push( endSnap.value );
								}
							}
						}
						else
						{
							startTicks = startSnap.value;
							snapTicks.push( startSnap.value );
						}
					}
					else
					{
						if( endSnap.snapped )
						{						
							startTicks = endSnap.value - selectedScene.length;			
							snapTicks.push( endSnap.value );
						}
					}
					
					draggedScene.start = Math.max( 0, startTicks );
					isMovingRight = ( draggedScene.start > selectedScene.start );
					break;
				
				case SceneDragType.CHANGE_START:
					var previousEnd:int = draggedScene.end;
					var snap:Snapper = getSnap( Math.min( previousEnd - 1, timelineState.pixelsToTicks( mousePosition - _repositionPixelOffset ) ) );

					draggedScene.start = snap.value;
					draggedScene.length = previousEnd - draggedScene.start;

					isMovingRight = ( draggedScene.start > selectedScene.start );
					
					if( snap.snapped ) snapTicks.push( snap.value );
					break;  
				
				case SceneDragType.CHANGE_END:
					snap = getSnap( Math.max( draggedScene.start + 1, timelineState.pixelsToTicks( mousePosition + _repositionPixelOffset ) ) );
					draggedScene.length = Math.max( 1, snap.value - draggedScene.start );
					isMovingRight = ( draggedScene.end > selectedScene.end );
					
					if( snap.snapped ) snapTicks.push( snap.value );
					break;					
					
				default:
					Assert.assertTrue( false );
					break;
			}		
			
			_repositionedScenes[ draggedScene.id ] = draggedScene;
			
			doSceneRescheduling( draggedScene.start, draggedScene.end, isMovingRight );
			repositionScenes();
			
			//set the snap lines
			controller.processCommand( new SetTimeDomainSnaplines( snapTicks ) );
		}

		
		private function getSnap( ticks:int ):Snapper
		{
			var timelineState:TimelineState = model.project.userData.timelineState;
			var tickMargin:Number = _snapToBlockMargin / timelineState.zoom;
			
			ticks = Math.max( 0, ticks );

			var snapper:Snapper = new Snapper( ticks, tickMargin );
			
			for each( var track:Track in model.project.tracks )
			{
				if( track.userData.arrangeViewCollapsed ) continue;		
				
				for each( var block:Block in track.blocks )
				{
					snapper.doSnap( block.start );
					snapper.doSnap( block.end );
				}
			}

			return snapper;			
		}

		
		private function onSceneRepositionDragFinished():void
		{
			for each( var scene:Scene in _repositionedScenes )
			{
				controller.processCommand( new RepositionScene( scene.id, scene.start, scene.length ) );	
			}

			_repositionDragType = null;
			_repositionedScenes = null;
			_scrollTimer.stop();

			repositionScenes();
			
			//set the snap lines
			controller.processCommand( new SetTimeDomainSnaplines() );
		}
		
		
		private function doSceneRescheduling( rescheduleZoneStart:int, rescheduleZoneEnd:int, isMovingRight:Boolean ):void
		{
			//find undragged scenes
			var undraggedScenes:Vector.<Scene> = new Vector.<Scene>;
			for each( var scene:Scene in model.project.player.scenes )
			{
				if( !_repositionedScenes.hasOwnProperty( scene.id ) )
				{
					undraggedScenes.push( scene );
				}
			}
			
			//sort undragged scenes
			undraggedScenes.sort( compareScenesByCentre );
			
			//find 'insertion index' for dragged block in undragged blocks
			var insertionIndex:int = getInsertionIndex( rescheduleZoneStart, rescheduleZoneEnd, isMovingRight, undraggedScenes );
			
			//find total duration of scenes before insertion index
			var totalDurationToLeft:int = 0;
			for( var i:int = 0; i < insertionIndex; i++ )
			{
				totalDurationToLeft += undraggedScenes[ i ].length;
			}
			
			//decrement insertion index to bump scenes to the right until there's enough room to the left
			while( totalDurationToLeft > rescheduleZoneStart )
			{
				insertionIndex--;
				Assert.assertTrue( insertionIndex >= 0 );
				
				totalDurationToLeft -= undraggedScenes[ insertionIndex ].length;
				Assert.assertTrue( totalDurationToLeft >= 0 );
			}
			
			//walk to left through previous undragged scenes moving left until don't need to
			var maximumEnd:int = rescheduleZoneStart;
			for( i = insertionIndex - 1; i >= 0; i-- )
			{
				var moveCandidate:Scene = undraggedScenes[ i ];
				if( moveCandidate.end <= maximumEnd )
				{
					break;
				}

				var moved:Scene = new Scene;
				moved.copySceneProperties( moveCandidate );
				moved.start = maximumEnd - moved.length;
				maximumEnd = moved.start;
				_repositionedScenes[ moved.id ] = moved;
			}
			
			//walk to right through subsequent dragged blocks moving right until don't need to
			var minimumStart:Number = rescheduleZoneEnd;
			for( i = insertionIndex; i < undraggedScenes.length; i++ )
			{
				moveCandidate = undraggedScenes[ i ];
				if( moveCandidate.start >= minimumStart )
				{
					break;
				}

				moved = new Scene;
				moved.copySceneProperties( moveCandidate );
				moved.start = minimumStart;
				minimumStart = moved.end;
				_repositionedScenes[ moved.id ] = moved;
			}
		} 
		
		
		private function compareScenesByCentre( scene1:Scene, scene2:Scene ):Number
		{
			if( scene1.centre < scene2.centre ) return -1;
			if( scene1.centre > scene2.centre ) return 1;
			return 0;
		}


		private function getInsertionIndex( rescheduleZoneStart:int, rescheduleZoneEnd:int, isMovingRight:Boolean, undraggedScenes:Vector.<Scene> ):int
		{
			if( isMovingRight )
			{
				for( var i:int = 0; i < undraggedScenes.length; i++ )
				{
					if( undraggedScenes[ i ].end > rescheduleZoneStart )
					{
						return i;
					}
				}  
			}
			else
			{
				for( i = 0; i < undraggedScenes.length; i++ )
				{
					if( undraggedScenes[ i ].start >= rescheduleZoneEnd )
					{
						return i;
					}  
				}
			}
			
			return undraggedScenes.length;
		}

		
		private function onScrollTimer( event:TimerEvent ):void
		{
			const scrollMargin:int = 5;
			const scrollPixels:int = 25;
			
			var timelineState:TimelineState = model.project.userData.timelineState;
			
			var scrollAmount:Number = 0; 
			
			if( mouseX < scrollMargin )
			{
				scrollAmount = -scrollPixels / timelineState.zoom;
			}
			else
			{
				if( mouseX > width - scrollMargin )
				{
					scrollAmount = scrollPixels / timelineState.zoom;
				}
			}
			
			if( scrollAmount != 0 )
			{
				var scrolledState:TimelineState = new TimelineState;
				scrolledState.copyFrom( timelineState );
				scrolledState.scroll = Math.max( 0, scrolledState.scroll + scrollAmount );

				if( scrolledState.scroll != timelineState.scroll )
				{
					controller.processCommand( new SetTimelineState( scrolledState ) );
					
					if( _sceneBeingCreated )
					{
						setSceneCreationToMousePosition();
					}
					else
					{
						if( _repositionDragType )
						{
							repositionSceneToMousePosition();
						}
						else
						{
							setPlayPositionToMousePosition();
						}
					}
				}
			}
		}
		
		
		private function onNameEditChange( event:FocusEvent ):void
		{
			if( !( event.target is UITextField ) )
			{
				return;
			}
			
			var scene:Scene = model.getScene( int( event.currentTarget.id ) );
			Assert.assertNotNull( scene );
			
			var newName:String = event.target.text;
			if( newName != scene.name )
			{
				controller.processCommand( new RenameObject( scene.id, event.target.text ) );
			}
		}
		
		
		private function onRollOver( event:MouseEvent ):void
		{
			updateCursor();
		}

		
		private function onMouseMove( event:MouseEvent ):void
		{
			updateCursor();
		}

		
		private function updateCursor():void
		{
			if( mouseY < _markingTop )
			{
				CursorSetter.setCursor( CursorSetter.MAGNIFY_MOVE, this );
			}
			else
			{
				for( var sceneID:String in _scenes )
				{
					var sceneBar:SceneBar = _scenes[ sceneID ];
					Assert.assertNotNull( sceneBar );
					if( Utilities.pointIsInRectangle( sceneBar.getRect( this ), mouseX, mouseY ) )
					{
						return;
					}
				}
				
				CursorSetter.setCursor( CursorSetter.ARROW, this );
			}
		}
		
		
		private function onUpdateDeleteSceneMenuItem( menuItem:Object ):void
		{
			if( _selectedSceneID < 0 ) 
			{
				menuItem.enabled = false;
				return;
			}

			//only enable if scene is visible
			for each( var sceneBar:SceneBar in _scenes )
			{
				if( sceneBar.id == _selectedSceneID.toString() )
				{
					menuItem.enabled = sceneBar.getRect( this ).intersects( getRect( this ) );
					return;
				}
			}
			
			Assert.assertTrue( false );		//selected scene not found
		}
		
		
		private function deleteScene():void
		{
			Assert.assertTrue( _selectedSceneID >= 0 );
			
			controller.processCommand( new RemoveScene( _selectedSceneID ) );
		}
		
		
		private var _editable:Boolean = false; 
		
		private var _markingTopColor:uint = 0;
		private var _markingBottomColor:uint = 0;
		private var _labelColor:uint = 0;
		private var _scrollBarColor:uint = 0;

		private var _labels:Vector.<Label> = new Vector.<Label>;
		
		private var _playPositionMarker:PlayPositionMarker = null;

		private var _scenes:Object = new Object;
		private var _selectedSceneID:int = -1;

		private var _sceneCreationClickPixels:int = -1;
		private var _sceneCreationClickTicks:int = -1;
		private var _sceneCreationDragTicks:int = -1;
		private var _sceneBeingCreated:SceneBar = null;
		
		private var _repositionPixelOffset:Number;
		private var _repositionDragType:String = null;
		private var _repositionedScenes:Object = null;
		
		private var _timelineDragMouseTicks:int = 0;  
		private var _timelineDragClickPoint:Point = null;
		private var _timelineDragInitialState:TimelineState = null;
		private var _scrollTimer:Timer = new Timer( 100 );
		private var _timelineDragHasShift:Boolean = false;

		private var _snapLines:TimeDomainSnapLines = new TimeDomainSnapLines;

		[Bindable] 
		private var contextMenuData:Array = 
			[
				{ label: "Delete Scene", keyEquivalent: "backspace", keyCode: Keyboard.BACKSPACE, handler: deleteScene, updater: onUpdateDeleteSceneMenuItem } 
			];
		
		private static var _timelineWidth:int = 0;
		
		private static const _timelineHeight:int = 55;
		private static const _markingTop:Number = 15;
		private static const _markingBottom:Number = 45;
		private static const _zoomCoefficient:Number = 50;		//number of vertical pixels of mouse movement to cause doubling or halving of zoom
		private static const _snapToBlockMargin:int = 10;
	}
}
