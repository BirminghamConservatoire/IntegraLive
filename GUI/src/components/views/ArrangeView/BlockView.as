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
	import flash.display.GradientType;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	
	import components.controller.serverCommands.AddEnvelope;
	import components.controller.serverCommands.RemoveEnvelope;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.userDataCommands.SetCurvatureMode;
	import components.controller.userDataCommands.SetEnvelopeLock;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.controller.userDataCommands.SetViewMode;
	import components.model.Block;
	import components.model.Envelope;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.Project;
	import components.model.Track;
	import components.model.userData.ColorScheme;
	import components.model.userData.ViewMode;
	import components.utils.CursorSetter;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.AddButtonSkin;
	import components.views.Skins.CurveButtonSkin;
	import components.views.Skins.LockButtonSkin;
	
	import flexunit.framework.Assert;


	public class BlockView extends IntegraView
	{
		public function BlockView( blockID:int )
		{
			super();
			
			_blockID = blockID;
			
		 	horizontalScrollPolicy = ScrollPolicy.OFF;  // FL4U
			verticalScrollPolicy = ScrollPolicy.OFF;    // FL4U
			
			_envelopeCanvas.percentWidth = 100;
			_envelopeCanvas.percentHeight = 100;
			addChild( _envelopeCanvas );
			
			_nameEdit.setStyle( "bottom", 0 );
			_nameEdit.setStyle( "left", lengthAdjustmentAreaWidth );
			_nameEdit.setStyle( "right", lengthAdjustmentAreaWidth );
			_nameEdit.setStyle( "textAlign", "center" );
			_nameEdit.setStyle( "borderStyle", "none" );
			_nameEdit.setStyle( "focusAlpha", 0 );
			_nameEdit.setStyle( "backgroundAlpha", 0 );
			_nameEdit.addEventListener( FocusEvent.FOCUS_OUT, onNameEditChange );
			_nameEdit.addEventListener( KeyboardEvent.KEY_UP, onNameEditKeyUp );
			_nameEdit.restrict = IntegraDataObject.legalObjectNameCharacterSet;
			setNameEditable( false );
			addChild( _nameEdit );
	
			_openButton.setStyle( "skin", AddButtonSkin );
			_openButton.setStyle( "fillAlpha", 1 );
			_openButton.addEventListener( MouseEvent.CLICK, onClickOpenButton );
			_openButton.setStyle( "bottom", 0 );
			_openButton.setStyle( "left", 0 );
			addChild( _openButton );

			_curvatureModeButton.toggle = true;
			_curvatureModeButton.addEventListener( MouseEvent.CLICK, onClickCurvatureModeButton );
			_curvatureModeButton.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClickCurvatureModeButton );
			_curvatureModeButton.setStyle( "bottom", 0 );
			_curvatureModeButton.setStyle( "right", 0 );
			_curvatureModeButton.setStyle( "skin", CurveButtonSkin );
			_curvatureModeButton.setStyle( "fillAlpha", 1 );
			addChild( _curvatureModeButton );

			_envelopeLockButton.toggle = true;
			_envelopeLockButton.addEventListener( MouseEvent.CLICK, onClickEnvelopeLockButton );
			_envelopeLockButton.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClickEnvelopeLockButton );
			_envelopeLockButton.setStyle( "bottom", 0 );
			_envelopeLockButton.setStyle( "right", 0 );
			_envelopeLockButton.setStyle( "skin", LockButtonSkin );
			_envelopeLockButton.setStyle( "fillAlpha", 1 );
			addChild( _envelopeLockButton );
	
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
			addEventListener( MouseEvent.MOUSE_OVER, onMouseoverBlockView );
			addEventListener( MouseEvent.MOUSE_OUT, onMouseoutBlockView );
					
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( SetObjectSelection, onSelectionChanged );
			addUpdateMethod( RenameObject, onObjectRenamed );
			addUpdateMethod( AddEnvelope, onEnvelopeAdded );
			addUpdateMethod( RemoveEnvelope, onEnvelopeRemoved );
			addUpdateMethod( SetTrackColor, onTrackColorChanged );
			addUpdateMethod( SetEnvelopeLock, onSetEnvelopeLock );
			addUpdateMethod( SetCurvatureMode, onSetCurvatureMode );
			addUpdateMethod( SetContainerActive, onSetContainerActive );

			if( _blockID >= 0 )
			{
				updateNameEdit();
			}			
		}
		
		public function get blockID():int { return _blockID; }
		

		override public function free():void
		{
			super.free();
			
			removeAllEnvelopes();
			
			if( _stageKeyboardHandlerOwner )
			{
				removeStageKeyboardHandlers();
			}
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info 
		{
			if( getEnvelopeViewForClick() != null )
			{
				if( _curvatureModeButton.selected )
				{
					return InfoMarkupForViews.instance.getInfoForView( "EnvelopeInCurvatureMode" );
				}
				else				
				{
					return InfoMarkupForViews.instance.getInfoForView( "Envelope" );
				}
			}
			
			if( event.target == _openButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "OpenBlockButton" );				
			}

			if( event.target == _envelopeLockButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "EnvelopeLockButton" );				
			}

			if( event.target == _curvatureModeButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "CurvatureModeButton" );				
			}
			
			return model.getBlock( _blockID ).info; 
		}

		
		override public function get color():uint
		{
			return model.getContainerColor( _blockID );
		}
		
		
		public function getDragInfo():BlockDragInfo
		{
			if( Utilities.pointIsInRectangle( _nameEdit.getRect( this ), mouseX, mouseY ) )
			{
				if( !_nameEdit.editable ) 
				{
					return new BlockDragInfo( this, model.getTrackFromBlock( _blockID ).id, BlockDragType.MOVE );
				}
			}

			if( Utilities.pointIsInRectangle( endAdjustRectangle, mouseX, mouseY ) )
			{
				return new BlockDragInfo( this, model.getTrackFromBlock( _blockID ).id, BlockDragType.CHANGE_END );
			}
			
			if( Utilities.pointIsInRectangle( startAdjustRectangle, mouseX, mouseY ) )
			{
				return new BlockDragInfo( this, model.getTrackFromBlock( _blockID ).id, BlockDragType.CHANGE_START );
			}

			if( Utilities.pointIsInRectangle( getRect( this ), mouseX, mouseY ) )
			{
				return new BlockDragInfo( this, model.getTrackFromBlock( _blockID ).id, BlockDragType.SELECT );
			}

			return null;
		}


		public function handleDoubleClick():void
		{
			if( Utilities.pointIsInRectangle( _nameEdit.getRect( this ), mouseX, mouseY ) )
			{
				setNameEditable( true );
			}
			else
			{
				if( _mouseDownOffEnvelopeCounter >= 2 )
				{
 					var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
 					viewMode.blockPropertiesOpen = true;
 					controller.processCommand( new SetViewMode( viewMode ) );
 				}
 			}			
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_nameEdit.setStyle( "color", 0x000000 );
						_nameEdit.setStyle( "disabledColor", 0x000000 );
						
						_openButton.setStyle( "color", 0xcfcfcf );
						_openButton.setStyle( "fillColor", 0x747474 );
						
						_envelopeLockButton.setStyle( "fillColor", 0x747474 );
						_curvatureModeButton.setStyle( "fillColor", 0x747474 );
						
						break;
						
					case ColorScheme.DARK:
						_nameEdit.setStyle( "color", 0xffffff );
						_nameEdit.setStyle( "disabledColor", 0xffffff );

						_openButton.setStyle( "color", 0x313131 );
						_openButton.setStyle( "fillColor", 0x8c8c8c );

						_envelopeLockButton.setStyle( "fillColor", 0x8c8c8c );
						_curvatureModeButton.setStyle( "fillColor", 0x8c8c8c );

						break;
				}
			}

			if( !style || style == FontSize.STYLENAME )
			{
				nameEditHeight = FontSize.getTextRowHeight( this );
			}
		} 


		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			var backgroundAlpha:Number = _isSelected ? selectedBackgroundAlpha : normalBackgroundAlpha;
			
			//active area
			var activeRectangle:Rectangle = activeRectangle;

			graphics.beginFill( backgroundColor, backgroundAlpha );
			graphics.drawRect( activeRectangle.x, activeRectangle.y, activeRectangle.width, activeRectangle.height );
			graphics.endFill();

			//label area
			var labelRectangle:Rectangle = labelRectangle;
			const alphas:Array = [ backgroundAlpha * 2, 0, backgroundAlpha * 2 ];
			const ratios:Array = [0x00, 0x80, 0xFF];
			const colors:Array = [ backgroundColor, backgroundColor, backgroundColor ];
        	
			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( labelRectangle.width, labelRectangle.height, Math.PI / 2, labelRectangle.x, labelRectangle.y );
			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
			graphics.drawRect( labelRectangle.x, labelRectangle.y, labelRectangle.width, labelRectangle.height );
			graphics.endFill();
			
			//edges
			graphics.lineStyle( _isPrimarySelected ? 3 : 1, backgroundColor, _isPrimarySelected ? 0.8 : 0.5 );
			graphics.moveTo( 0, 0 );
			graphics.lineTo( 0, height );
			graphics.moveTo( width, 0 );
			graphics.lineTo( width, height );
		}
		
		
		
		override protected function onAllDataChanged():void
		{
			updateSelection();
			
			removeAllEnvelopes();
			addAllEnvelopes();
			
			updateEnvelopeLock();
			updateCurvatureMode();
		}
		
		
		private function get activeRectangle():Rectangle
		{
			return new Rectangle( 0, 0, width, Math.max( 0, _nameEdit.y ) );
		}		


		private function get labelRectangle():Rectangle
		{
			return new Rectangle( 0, Math.max( 0, _nameEdit.y ), width, Math.min( _nameEdit.height, height ) );
		}	
		
		
		private function get startAdjustRectangle():Rectangle
		{
			return new Rectangle( 0, 0, Math.min( width, lengthAdjustmentAreaWidth ), Math.max( 0, _nameEdit.y ) );
		}


		private function get endAdjustRectangle():Rectangle
		{
			return new Rectangle( Math.max( 0, width - lengthAdjustmentAreaWidth ), 0, Math.min( width, lengthAdjustmentAreaWidth ), Math.max( 0, _nameEdit.y ) );
		}
		
		
		private function set nameEditHeight( nameEditHeight:Number ):void
		{
			_nameEdit.height = nameEditHeight;

			_nameEdit.setStyle( "left", nameEditHeight );
			_nameEdit.setStyle( "right", nameEditHeight * 2 );
			
			_openButton.setStyle( "left", nameEditHeight / 4 );
			_openButton.setStyle( "bottom", nameEditHeight / 4 );
			_openButton.width = nameEditHeight / 2;
			_openButton.height = nameEditHeight / 2;

			_envelopeLockButton.setStyle( "right", nameEditHeight );
			_envelopeLockButton.setStyle( "bottom", nameEditHeight / 4 );
			_envelopeLockButton.width = nameEditHeight / 2;
			_envelopeLockButton.height = nameEditHeight / 2;

			_curvatureModeButton.setStyle( "right", nameEditHeight / 4 );
			_curvatureModeButton.setStyle( "bottom", nameEditHeight / 4 );
			_curvatureModeButton.width = nameEditHeight / 2;
			_curvatureModeButton.height = nameEditHeight / 2;
			
			for each( var envelopeView:EnvelopeView in _envelopeViews )
			{
				envelopeView.setStyle( "bottom", nameEditHeight );
			}
		} 


		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			var container:IntegraContainer = model.getContainer( command.containerID );
			if( container is Track )
			{
				updateSelection();
			}
			
			if( container is Project )
			{
				updateSelection();
			}
		}


		private function onSelectionChanged( command:SetObjectSelection ):void
		{
			if( command.objectID == _blockID )
			{
				updateSelection();
			}
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			if( command.objectID == _blockID )
			{
				updateNameEdit();
			}
		}
		
		
		private function onEnvelopeAdded( command:AddEnvelope ):void
		{
			if( command.blockID == _blockID )
			{
				addEnvelope( model.getEnvelope( command.envelopeID ) );
				updateEnvelopeLock();
				updateCurvatureMode();
			}			
		}
		
		
		private function onEnvelopeRemoved( command:RemoveEnvelope ):void
		{
			if( _envelopeViews.hasOwnProperty( command.envelopeID ) )
			{
				removeEnvelope( command.envelopeID );
				updateEnvelopeLock();
				updateCurvatureMode();
			}	
		}
		
		
		private function onTrackColorChanged( command:SetTrackColor ):void
		{
			if( command.trackID == model.getTrackFromBlock( _blockID ).id )
			{
				updateEnvelopeLock();
				updateCurvatureMode();
			}
		}
		
		
		private function onSetEnvelopeLock( command:SetEnvelopeLock ):void
		{
			if( command.blockID == _blockID )
			{
				updateEnvelopeLock();
			}
		}

		
		private function onSetCurvatureMode( command:SetCurvatureMode ):void
		{
			if( command.blockID == _blockID )
			{
				updateCurvatureMode();
			}
		}
		
		
		private function onSetContainerActive( command:SetContainerActive ):void
		{
			if( model.isEqualOrAncestor( command.containerID, _blockID ) )
			{
				updateEnvelopeLock();
				updateCurvatureMode();
			}
		}

		
		private function getEnvelopeViewForClick():EnvelopeView
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			var selectedEnvelope:Envelope = model.selectedEnvelope;
			var selectedEnvelopeView:EnvelopeView = null;
			
			if( selectedEnvelope )
			{
				var selectedEnvelopeID:int = selectedEnvelope.id;
				if( _envelopeViews.hasOwnProperty( selectedEnvelopeID ) )
				{
					selectedEnvelopeView = _envelopeViews[ selectedEnvelopeID ];
				}
			}

			var globalMouse:Point = localToGlobal( new Point( mouseX, mouseY ) );
			
			if( isEnvelopeLock )
			{
				if( selectedEnvelopeView && selectedEnvelopeView.getHitTestDistance( globalMouse.x, globalMouse.y ) >= 0 )
				{
					return selectedEnvelopeView;
				}
				else
				{
					return null;
				}
			}

			//if envelope lock not on, hit test all envelope views 
			var bestEnvelopeView:EnvelopeView = null;
			var bestDistance:Number = 0;
			
			for each( var envelopeView:EnvelopeView in _envelopeViews )
			{
				var distance:Number = envelopeView.getHitTestDistance( globalMouse.x, globalMouse.y );
				if( distance < 0 )
				{
					continue;
				}
				
				if( envelopeView == selectedEnvelopeView ) 
				{
					distance -= 1.5;		//prioritise selected envelope when it's neck&neck	
				}
				
				if( !bestEnvelopeView || distance < bestDistance )
				{
					bestEnvelopeView = envelopeView;
					bestDistance = distance;
				}
			}
			
			return bestEnvelopeView;
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			var envelopeToClick:EnvelopeView = getEnvelopeViewForClick();
			
			if( envelopeToClick )
			{
				envelopeToClick.handleMouseDown( event );
				_mouseDownOffEnvelopeCounter = 0;
			}
			else
			{
				_mouseDownOffEnvelopeCounter++;
			}
		}
		
		
		private function onDoubleClick( event:MouseEvent ):void
		{
			var selectedEnvelope:Envelope = model.selectedEnvelope;
			if( !selectedEnvelope ) return;
			
			var selectedEnvelopeID:int = selectedEnvelope.id;
			if( _envelopeViews.hasOwnProperty( selectedEnvelopeID ) )
			{
				var selectedEnvelopeView:EnvelopeView = _envelopeViews[ selectedEnvelopeID ];
				selectedEnvelopeView.handleDoubleClick( event );
			}
		}
		
		
		private function updateSelection():void
		{
			if( _blockID < 0 ) 
			{
				return;
			}

			var isPrimarySelected:Boolean = model.isBlockPrimarySelected( _blockID );
			var isSelected:Boolean = model.isObjectSelected( _blockID );
			
			if( isPrimarySelected == _isPrimarySelected && isSelected == _isSelected )
			{
				return;
			}

			_isPrimarySelected = isPrimarySelected;
			_isSelected = isSelected;
			
			invalidateDisplayList();
		}


		private function onMouseMove( event:MouseEvent ):void
		{
			updateCursor();
		}


		private function onMouseoverBlockView( event:MouseEvent ):void
		{
			updateCursor();
			
			updateOverrides( event.controlKey, event.shiftKey );
			
			if( !_stageKeyboardHandlerOwner )
			{
				addStageKeyboardHandlers();
			}
		}


		private function onMouseoutBlockView( event:MouseEvent ):void
		{
			updateOverrides( false, false );
			
			if( _stageKeyboardHandlerOwner )
			{
				removeStageKeyboardHandlers();
			}
		}
		
		
		private function addStageKeyboardHandlers():void
		{
			Assert.assertNull( _stageKeyboardHandlerOwner );
			
			stage.addEventListener( KeyboardEvent.KEY_DOWN, onStageKeyboardHandler );
			stage.addEventListener( KeyboardEvent.KEY_UP, onStageKeyboardHandler );
			_stageKeyboardHandlerOwner = stage;					
		}
		
		
		private function removeStageKeyboardHandlers():void
		{
			Assert.assertNotNull( _stageKeyboardHandlerOwner );
			
			_stageKeyboardHandlerOwner.removeEventListener( KeyboardEvent.KEY_DOWN, onStageKeyboardHandler );
			_stageKeyboardHandlerOwner.removeEventListener( KeyboardEvent.KEY_UP, onStageKeyboardHandler );
			_stageKeyboardHandlerOwner = null;					
		}
	
		
		private function updateCursor():void
		{
			CursorSetter.setCursor( getCursorType(), this );
		}
		
		
		private function get isEnvelopeLock():Boolean 
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
	
			return block.blockUserData.envelopeLock != _envelopeLockOverride;
		}

		
		private function get isCurvatureMode():Boolean 
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			return block.blockUserData.curvatureMode != _curvatureModeOverride;
		}
		
		
		private function getCursorType():String
		{
			var globalMouse:Point = localToGlobal( new Point( mouseX, mouseY ) );

			if( isEnvelopeLock )
			{
				var selectedEnvelope:Envelope = model.selectedEnvelope;
				if( selectedEnvelope )
				{
					var selectedEnvelopeID:int = selectedEnvelope.id;
					if( _envelopeViews.hasOwnProperty( selectedEnvelopeID ) )
					{
						var selectedEnvelopeView:EnvelopeView = _envelopeViews[ selectedEnvelopeID ];
						if( selectedEnvelopeView.getHitTestDistance( globalMouse.x, globalMouse.y ) >= 0 )
						{
							return CursorSetter.HAND;
						} 							
					}
				}
			}
			else
			{
				for each( var envelopeView:EnvelopeView in _envelopeViews )
				{
					if( envelopeView.getHitTestDistance( globalMouse.x, globalMouse.y ) >= 0 )
					{
						return CursorSetter.HAND;
					} 
				}
			}
		
			if( Utilities.pointIsInRectangle( startAdjustRectangle, mouseX, mouseY ) )
			{
				return CursorSetter.RESIZE_EW;
			}

			if( Utilities.pointIsInRectangle( endAdjustRectangle, mouseX, mouseY ) )
			{
				return CursorSetter.RESIZE_EW;
			}
			
			if( !_nameEdit.editable && Utilities.pointIsInRectangle( _nameEdit.getRect( this ), mouseX, mouseY ) )
			{
				return CursorSetter.MOVE_EW;
			}
			
			return CursorSetter.ARROW;
		}
		
		
		private function onNameEditChange( event:FocusEvent ):void
		{
			if( _nameEdit.text != model.getBlock( _blockID ).name )
			{
				controller.processCommand( new RenameObject( _blockID, _nameEdit.text ) );
				updateNameEdit();
			} 

			setNameEditable( false );
		}
		

		private function onNameEditKeyUp( event:KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case Keyboard.ENTER:
					setFocus();			//force changes to be committed
					break;

				case Keyboard.ESCAPE:
					updateNameEdit();
					setNameEditable( false );
					break;
					
				default:
					break;
			} 
		}
		
		
		private function updateNameEdit():void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			_nameEdit.text = block.name; 
		}
		
		
		private function setNameEditable( editable:Boolean ):void
		{
			_nameEdit.editable = editable;			
			_nameEdit.focusEnabled = editable;
			_nameEdit.enabled = editable;
			
			if( editable )
			{
				_nameEdit.selectionBeginIndex = 0;
				_nameEdit.selectionEndIndex = _nameEdit.text.length;
				_nameEdit.setFocus();
			}
			else
			{
				_nameEdit.selectionBeginIndex = NaN;
				_nameEdit.selectionEndIndex = NaN;
				setFocus();
			}
		}
		
		
		private function onClickOpenButton( event:MouseEvent ):void
		{
 			var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
 			viewMode.blockPropertiesOpen = true;
 			controller.processCommand( new SetViewMode( viewMode ) );
		}
		
		
		private function onClickEnvelopeLockButton( event:MouseEvent ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );

			controller.processCommand( new SetEnvelopeLock( _blockID, !block.blockUserData.envelopeLock ) );
		}

		
		private function onDoubleClickEnvelopeLockButton( event:MouseEvent ):void
		{
			event.stopImmediatePropagation();
		}

		
		private function onClickCurvatureModeButton( event:MouseEvent ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			controller.processCommand( new SetCurvatureMode( _blockID, !block.blockUserData.curvatureMode ) );
		}
		
		
		private function onDoubleClickCurvatureModeButton( event:MouseEvent ):void
		{
			event.stopImmediatePropagation();
		}
		
		
		private function addAllEnvelopes():void
		{
			if( _blockID < 0 ) return;
			
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			for each( var envelope:Envelope in block.envelopes )
			{
				addEnvelope( envelope );
			} 
		}


		private function removeAllEnvelopes():void
		{
			for each( var envelopeView:EnvelopeView in _envelopeViews )
			{
				removeEnvelope( envelopeView.envelopeID );
			}
		}


		private function addEnvelope( envelope:Envelope ):void
		{
			Assert.assertNotNull( envelope );
			
			var envelopeID:int = envelope.id;
			Assert.assertFalse( _envelopeViews.hasOwnProperty( envelopeID ) );
			
			var envelopeView:EnvelopeView = new EnvelopeView( envelopeID );
			
			envelopeView.setStyle( "left", 0 );
			envelopeView.setStyle( "right", 0 );
			envelopeView.setStyle( "top", 0 );
			envelopeView.setStyle( "bottom", _nameEdit.height );
			envelopeView.curvatureMode = isCurvatureMode;
			
			_envelopeCanvas.addChildAt( envelopeView, 0 );

			_envelopeViews[ envelopeID ] = envelopeView;
		}			


		private function removeEnvelope( envelopeID:int ):void
		{
			var envelopeView:EnvelopeView = _envelopeViews[ envelopeID ];
			Assert.assertNotNull( envelopeView );
			
			_envelopeCanvas.removeChild( envelopeView );
			envelopeView.free();
			
			delete _envelopeViews[ envelopeID ];			
		}			

		
		private function updateOverrides( isControl:Boolean, isShift:Boolean ):void
		{
			//temporarily removed curvature mode override due to ctrl button already being in use 
			
			/*if( isControl != _curvatureModeOverride )
			{
				_curvatureModeOverride = isControl;
				updateCurvatureMode();
			}*/

			if( isShift != _envelopeLockOverride )
			{
				_envelopeLockOverride = isShift;
				updateEnvelopeLock();
			}
		}

		
		private function onStageKeyboardHandler( event:KeyboardEvent ):void
		{
			updateOverrides( event.controlKey, event.shiftKey );
		}
		
		
		private function updateEnvelopeLock():void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			var track:Track = model.getTrackFromBlock( _blockID );
			Assert.assertNotNull( track );
			
			_envelopeLockButton.setStyle( "color", color );
			_envelopeLockButton.setStyle( LockButtonSkin.glowOverrideStyleName, _envelopeLockOverride );
			_envelopeLockButton.selected = isEnvelopeLock;
			
			_envelopeLockButton.visible = ( Utilities.getNumberOfProperties( block.envelopes ) > 1 );
		}

		
		private function updateCurvatureMode():void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			var track:Track = model.getTrackFromBlock( _blockID );
			Assert.assertNotNull( track );
			
			_curvatureModeButton.setStyle( "color", color );
			_curvatureModeButton.setStyle( CurveButtonSkin.glowOverrideStyleName, _curvatureModeOverride );
			_curvatureModeButton.selected = isCurvatureMode;
			
			_curvatureModeButton.visible = ( Utilities.getNumberOfProperties( block.envelopes ) >= 1 );
			
			for each( var envelopeView:EnvelopeView in _envelopeViews )
			{
				envelopeView.curvatureMode = isCurvatureMode;
			}
		}
		
	
		private var _nameEdit:TextInput = new TextInput;
		private var _openButton:Button = new Button;
		private var _envelopeLockButton:Button = new Button;
		private var _curvatureModeButton:Button = new Button;
		
		private var _blockID:int;
		private var _isPrimarySelected:Boolean = false;
		private var _isSelected:Boolean = false;
		
		private var _envelopeCanvas:Canvas = new Canvas;
		private var _envelopeViews:Object = new Object;
		private var _mouseDownOffEnvelopeCounter:int = 0;
		
		private var _stageKeyboardHandlerOwner:Stage = null;
		private var _envelopeLockOverride:Boolean = false;
		private var _curvatureModeOverride:Boolean = false;
		
		private const backgroundColor:uint = 0x808080;
		private const selectedBackgroundAlpha:Number = 0.25;
		private const normalBackgroundAlpha:Number = 0.1;
		private const lengthAdjustmentAreaWidth:Number = 10;
		private const envelopeCollisionRadius:Number = 4;
	}
}