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


package components.views.viewContainers
{
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	
	import components.model.IntegraDataObject;
	import components.model.userData.ColorScheme;
	import components.utils.AggregateVUContainer;
	import components.utils.CursorSetter;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	import components.views.Skins.CloseButtonSkin;
	import components.views.Skins.CollapseButtonSkin;
	import components.views.Timeline.Timeline;
	import components.views.Timeline.TimelineMode;
	
	import flexunit.framework.Assert;
	
	public class ViewHolder extends Canvas
	{
		public function ViewHolder()
		{
			super();

			percentWidth = 100;
			percentHeight = 100;
			doubleClickEnabled = true;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			addEventListener( Event.RESIZE, onResize );
			addEventListener( MouseEvent.CLICK, onClick );
			addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
			
			_titleEdit.setStyle( "color", 0x777777 );
			_titleEdit.setStyle( "disabledColor", 0x777777 );
			_titleEdit.setStyle( "borderStyle", "none" );
			_titleEdit.setStyle( "focusAlpha", 0 );
			_titleEdit.setStyle( "backgroundAlpha", 0 );
			_titleEdit.setStyle( "paddingTop", 0 );
			_titleEdit.setStyle( "paddingBottom", 0 );
			_titleEdit.restrict = IntegraDataObject.legalObjectNameCharacterSet;
			_titleEdit.addEventListener( FocusEvent.FOCUS_OUT, onTitleEditChange );
			_titleEdit.addEventListener( KeyboardEvent.KEY_UP, onTitleEditKeyUp );

			setTitleEditable( false );

			_titleHBox.addElement( _titleEdit );

			_titleHBox.horizontalScrollPolicy = ScrollPolicy.OFF;
			_titleHBox.verticalScrollPolicy = ScrollPolicy.OFF;
			_titleHBox.setStyle( "verticalAlign", "middle" );
			
			addElement( _titleHBox );			
		}
		

		public function get view():IntegraView { return _view; }

		public function set view( view:IntegraView ):void
		{
			Assert.assertNotNull( view );
			
			if( _view )
			{
				_view.removeEventListener( IntegraViewEvent.TITLE_CHANGED, onTitleChanged );
				_view.removeEventListener( IntegraViewEvent.TITLEBAR_CHANGED, onTitlebarChanged );
				_view.removeEventListener( IntegraViewEvent.VUMETER_CONTAINER_CHANGED, onVuMeterContainerChanged );
				_view.removeEventListener( IntegraViewEvent.COLOR_CHANGED, onColorChanged );
				_view.removeEventListener( IntegraViewEvent.MINHEIGHT_CHANGED, onViewMinHeightChanged );
				_view.removeEventListener( IntegraViewEvent.COLLAPSE_CHANGED, onCollapseChanged );
				_view.removeEventListener( IntegraViewEvent.EXPAND_COLLAPSE_ENABLE_CHANGED, onExpandCollapseEnableChanged );
				_view.removeEventListener( IntegraViewEvent.RESIZED_BY_DIMENSION_SHARER, onResizedByDimensionSharer );
				_view.removeEventListener( Event.RESIZE, onResizeView );
				
				if( _view.parent == this )
				{
					removeElement( _view );
				}
			}

			_view = view;
			_view.addEventListener( IntegraViewEvent.TITLE_CHANGED, onTitleChanged );
			_view.addEventListener( IntegraViewEvent.TITLEBAR_CHANGED, onTitlebarChanged );
			_view.addEventListener( IntegraViewEvent.VUMETER_CONTAINER_CHANGED, onVuMeterContainerChanged );
			_view.addEventListener( IntegraViewEvent.COLOR_CHANGED, onColorChanged );
			_view.addEventListener( IntegraViewEvent.MINHEIGHT_CHANGED, onViewMinHeightChanged );
			_view.addEventListener( IntegraViewEvent.COLLAPSE_CHANGED, onCollapseChanged );
			_view.addEventListener( IntegraViewEvent.EXPAND_COLLAPSE_ENABLE_CHANGED, onExpandCollapseEnableChanged );
			_view.addEventListener( IntegraViewEvent.RESIZED_BY_DIMENSION_SHARER, onResizedByDimensionSharer );
			_view.addEventListener( Event.RESIZE, onResizeView );

			updateTitleText();
			updateTitlebarView();
			updateBreadcrumbsView();
			updateVuMeter();

			if( _collapseButton )
			{
				_collapseButton.selected = collapsed;
				_collapseButton.setStyle( "color", color );
			}

			positionChildren();
		}


		public function set canCollapse( canCollapse:Boolean ):void
		{
			if( canCollapse == _canCollapse ) return;
			
			_canCollapse = canCollapse;

			if( canCollapse )
			{
				_collapseButton = new Button;
				_collapseButton.toggle = true;
				_collapseButton.setStyle( "skin", CollapseButtonSkin );
				_collapseButton.setStyle( "color", color );
				_titleHBox.addElementAt( _collapseButton, 0 );
				
				_collapseButton.selected = collapsed;
				
				_collapseButton.addEventListener( MouseEvent.CLICK, onClickCollapseButton );
				_collapseButton.addEventListener( MouseEvent.DOUBLE_CLICK, onClickCollapseButton );
			}
			else
			{
				_collapseButton.removeEventListener( MouseEvent.CLICK, onClickCollapseButton );
				_collapseButton.removeEventListener( MouseEvent.DOUBLE_CLICK, onClickCollapseButton );
				_titleHBox.removeElement( _collapseButton );
				_collapseButton = null;
			}
			
			positionChildren();
		}


		public function get collapsed():Boolean
		{
			if( !_view ) return false;
			
			return _view.collapsed;
		}


		public function set hasCloseButton( hasCloseButton:Boolean ):void
		{
			if( hasCloseButton == _hasCloseButton ) return;
			
			_hasCloseButton = hasCloseButton;
			
			if( hasCloseButton )
			{
				_closeButton = new Button;
				_closeButton.setStyle( "skin", CloseButtonSkin );
				_closeButton.setStyle( "fillAlpha", 1 );
				updateCloseButtonColors();				
				addElement( _closeButton );
				
				_closeButton.addEventListener( MouseEvent.CLICK, onClickCloseButton );
			}
			else
			{
				_closeButton.removeEventListener( MouseEvent.CLICK, onClickCloseButton );
				removeElement( _closeButton );
				_closeButton = null;
			}
			
			positionChildren();
		}

		
		public function set changeHeightFromBottom( changeHeightFromBottom:Boolean ):void
		{
			if( changeHeightFromBottom == _changeHeightFromBottom ) return;

			if( changeHeightFromBottom && _changeHeightFromTop ) changeHeightFromTop = false; 
			
			_changeHeightFromBottom = changeHeightFromBottom;

			if( _changeHeightButton )
			{
				removeElement( _changeHeightButton );
				_changeHeightButton = null;
			}
			
			if( _changeHeightFromBottom )
			{
				_changeHeightButton = new Canvas;
				_changeHeightButton.width = _changeHeightButtonSize;
				_changeHeightButton.height = _changeHeightButtonSize;
				_changeHeightButton.setStyle( "right", 0 );
				_changeHeightButton.setStyle( "bottom", 0 );
				
				_changeHeightButton.graphics.clear();
				_changeHeightButton.graphics.beginFill( 0x606060 );
				_changeHeightButton.graphics.moveTo( 0, _changeHeightButtonSize );
				_changeHeightButton.graphics.lineTo( _changeHeightButtonSize, 0 );
				_changeHeightButton.graphics.lineTo( _changeHeightButtonSize, _changeHeightButtonSize );
				_changeHeightButton.graphics.lineTo( 0, _changeHeightButtonSize );
				_changeHeightButton.graphics.endFill();
				
				addElement( _changeHeightButton );
				_changeHeightButton.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDownChangeHeightButton );
				_changeHeightButton.addEventListener( MouseEvent.ROLL_OVER, onRollOverChangeHeightButton );
			}				
		}


		public function set changeHeightFromTop( changeHeightFromTop:Boolean ):void
		{
			if( changeHeightFromTop == _changeHeightFromTop ) return;

			if( changeHeightFromTop && _changeHeightFromBottom ) changeHeightFromBottom = false; 
			
			_changeHeightFromTop = changeHeightFromTop;

			if( _changeHeightButton )
			{
				removeElement( _changeHeightButton );
				_changeHeightButton = null;
			}
			
			if( _changeHeightFromTop )
			{
				_changeHeightButton = new Canvas;
				_changeHeightButton.setStyle( "left", 0 );
				_changeHeightButton.setStyle( "right", 0 );
				_changeHeightButton.setStyle( "top", 0 );
				_changeHeightButton.height = _resizeBarSize;
				
				addElement( _changeHeightButton );
				_changeHeightButton.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDownChangeHeightButton );
				_changeHeightButton.addEventListener( MouseEvent.ROLL_OVER, onRollOverChangeHeightButton );
			}				
		}
		
		
		public function set useHeightOfView( useHeightOfView:Boolean ):void
		{
			if( useHeightOfView == _useHeightOfView ) return;
			
			if( useHeightOfView )
			{
				if( _changeHeightFromBottom ) changeHeightFromBottom = false;
				if( _changeHeightFromTop ) changeHeightFromTop = false; 	
			}
			
			_useHeightOfView = useHeightOfView;
		}


		public function set changeWidthFromLeft( changeWidthFromLeft:Boolean ):void
		{
			if( changeWidthFromLeft == _changeWidthFromLeft ) return;

			_changeWidthFromLeft = changeWidthFromLeft;

			if( _changeWidthButton )
			{
				removeElement( _changeWidthButton );
				_changeWidthButton = null;
			}
			
			if( _changeWidthFromLeft )
			{
				_changeWidthButton = new Canvas;
				_changeWidthButton.setStyle( "left", 0 );
				_changeWidthButton.setStyle( "top", 0 );
				_changeWidthButton.setStyle( "bottom", 0 );
				_changeWidthButton.width = _resizeBarSize;
				
				addElement( _changeWidthButton );
				_changeWidthButton.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDownChangeWidthButton );
				_changeWidthButton.addEventListener( MouseEvent.MOUSE_OVER, onRollOverChangeWidthButton );
			}				
		}		
		
		
		public function set timelineMode( timelineMode:String ):void
		{
			var hasTimeline:Boolean = timelineMode != TimelineMode.NONE;
			var timelineIsEditable:Boolean = timelineMode == TimelineMode.EDITABLE;
			
			if( hasTimeline == _hasTimeline )
			{
				return;
			}
			
			_hasTimeline = hasTimeline;
			if( _hasTimeline )
			{
				Assert.assertNull( _timeline );
				_timeline = new Timeline( timelineIsEditable );
				_timeline.setStyle( "left", 0 );
				_timeline.setStyle( "right", 0 );
			}
			else
			{
				Assert.assertNotNull( _timeline );
				_timeline = null;
			}

			positionChildren();
		}
		
		
		public function changeHeight( height:Number ):void
		{
			if( !_view ) return;
			
			_view.height = Math.max( height, _view.minHeight );
			
			positionChildren();
		} 
		
		
		public function get color():uint 
		{
			if( _view )
			{
				return _view.color;
			}
			
			return 0;			
		}		
		
		
		public function isMouseInDragRect():Boolean
		{
			var dragRect:Rectangle = new Rectangle();
			
			dragRect.left = _view.isTitleEditable ? _titleEdit.x + _titleEdit.width : 0;
			dragRect.right = _vuMeter ? _vuMeter.x : width;
			dragRect.top = 0;
			dragRect.bottom = _titleHeight;
			
			return dragRect.contains( mouseX, mouseY );
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				updateVuMeterBackgroundColors();

				updateCloseButtonColors();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				_titleHeight = FontSize.getTextRowHeight( this );
				_titleControlOffset = _titleHeight * ( 1 - _titlebarHeightProportion ) / 2;
				callLater( positionChildren );
			}
		} 
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
        {
        	super.updateDisplayList( width, height );
            graphics.clear();

			const alphas:Array = [ 1, 1 ];
			const ratios:Array = [0x00, 0xFF];
       	
        	//draw title area
			var topCornerRadius:Number = 8;
        	
			var titleMatrix:Matrix = new Matrix();
  			titleMatrix.createGradientBox( width, _titleHeight, Math.PI / 2 );

			graphics.beginGradientFill( GradientType.LINEAR, titleColors, alphas, ratios, titleMatrix );
        	graphics.drawRoundRectComplex( 0, 0, width, _titleHeight, topCornerRadius, topCornerRadius, 0, 0 );
        	graphics.endFill();
        	
        	//draw main view background
			const bottomCornerRadius:Number = 8;

			var mainViewMatrix:Matrix = new Matrix();
  			mainViewMatrix.createGradientBox( width, height - _titleHeight, Math.PI / 2 );

			graphics.beginGradientFill( GradientType.LINEAR, mainViewColors, alphas, ratios, mainViewMatrix );
        	graphics.drawRoundRectComplex( 0, _titleHeight, width, height - _titleHeight, 0, 0, bottomCornerRadius, bottomCornerRadius );
        	graphics.endFill();
        }
        

        private function get titleColors():Array
        {
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					if( view && view.isSidebarColours )
					{
						return [ 0xb7b7b7, 0xcfcfcf ];
					}
					else
					{
						return [ 0xc0c0c0, 0xf8f8f8 ];
					}
					break;

				case ColorScheme.DARK:
					if( view && view.isSidebarColours )
					{
						return [ 0x494949, 0x313131 ];
					}
					else
					{
						return [ 0x313131, 0x030303 ];
					}
					break;
			}
        }		


        private function get mainViewColors():Array
        {
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					if( view && view.isSidebarColours )
					{
						return [ 0xcbcbcb, 0xd7d7d7 ];
					}
					else
					{
						return [ 0xf5f5f5, 0xeeeeee ];
					}
					break;

				case ColorScheme.DARK:
					if( view && view.isSidebarColours )
					{
						return [ 0x353535, 0x292929 ];
					}
					else
					{
						return [ 0x0b0b0b, 0x222222 ];
					}
					break;
			}
        }		
        
        
		private function onClickCollapseButton( event:Event ):void
		{
			_view.collapsed = !_view.collapsed;
		}
		
		
		private function onClickCloseButton( event:MouseEvent ):void
		{
			_view.closeButtonClicked();
		}

		
		private function onResize( event:Event ):void
		{
			positionChildren();
		} 


        private function onTitleChanged( event:IntegraViewEvent ):void
        {
        	Assert.assertNotNull( _titleEdit );
        	Assert.assertNotNull( _view );

			updateTitleText();
			positionChildren();
        }
        
        
        private function onTitlebarChanged( event:IntegraViewEvent ):void
        {
        	updateTitlebarView();
        	positionChildren();
        }


        private function onVuMeterContainerChanged( event:IntegraViewEvent ):void
        {
        	updateVuMeter();
        	positionChildren();
        }


        private function onColorChanged( event:IntegraViewEvent ):void
        {
        	Assert.assertNotNull( _view );

       		if( _collapseButton )
       		{
       			_collapseButton.setStyle( "color", color );
       		}
			
			if( _closeButton )
			{
				_closeButton.setStyle( "color", color );
			}
        }
        
        
        private function onViewMinHeightChanged( event:IntegraViewEvent ):void
        {
        	positionChildren();
        }
        
        
        private function onCollapseChanged( event:IntegraViewEvent ):void
        {
			if( _collapseButton )
			{
				_collapseButton.selected = collapsed;
			}
			
			positionChildren();
        }
		
		
		private function onExpandCollapseEnableChanged( event:IntegraViewEvent ):void
		{
			Assert.assertNotNull( _collapseButton );
			Assert.assertNotNull( _view );
			
			_collapseButton.enabled = _view.expandCollapseEnabled;
		}
		
		
		
		private function onResizedByDimensionSharer( event:IntegraViewEvent ):void
		{
			positionChildren();
		}
        
        
        private function updateTitlebarView():void
        {
        	var newTitlebarView:IntegraView = _view.titlebarView;
        	if( newTitlebarView == _titlebarView )
        	{
        		return;
        	}
        	
			if( _titlebarView )
			{
				if( _titlebarView.parent is DisplayObjectContainer )
				{
					( _titlebarView.parent as DisplayObjectContainer ).removeChild( _titlebarView );
				}
			}
			
			_titlebarView = newTitlebarView;
			if( _titlebarView )
			{
				_titlebarView.horizontalScrollPolicy = ScrollPolicy.OFF;
				_titlebarView.verticalScrollPolicy = ScrollPolicy.OFF;
				
				if( _view.rightAlignTitlebarView )
				{
					addElement( _titlebarView );
					positionChildren();
				}
				else
				{
					_titleHBox.addElementAt( _titlebarView, _titleHBox.numChildren );
				}

			}
        }
        
        
		private function updateBreadcrumbsView():void
		{
			var newBreadcrumbsView:IntegraView = _view.breadcrumbsView;
			if( newBreadcrumbsView == _breadcrumbsView )
			{
				return;
			}
			
			if( _breadcrumbsView )
			{
				if( _breadcrumbsView.parent == _titleHBox )
				{
					_titleHBox.removeElement( _breadcrumbsView );
				}
			}
			
			_breadcrumbsView = newBreadcrumbsView;
			if( _breadcrumbsView )
			{
				_breadcrumbsView.horizontalScrollPolicy = ScrollPolicy.OFF;
				_breadcrumbsView.verticalScrollPolicy = ScrollPolicy.OFF;  
				_titleHBox.addElementAt( _breadcrumbsView, _titleHBox.getChildIndex( _titleEdit ) );
			}
		}
		
		
		
        private function updateVuMeter():void
        {
        	var vuMeterContainerID:int = _view.vuMeterContainerID;
        	if( _vuMeter )
        	{
        		if( vuMeterContainerID >= 0 )
        		{
        			_vuMeter.containerID = vuMeterContainerID;
        		}
        		else
        		{
					removeElement( _vuMeter );
        			_vuMeter.free();
        			_vuMeter = null;
        		}
        	}
        	else
        	{
        		if( vuMeterContainerID >= 0 )
        		{
	        		_vuMeter = new AggregateVUContainer;
	        		_vuMeter.containerID = vuMeterContainerID;
					addElement( _vuMeter );
    	    		updateVuMeterBackgroundColors();
    	    	}
        	}
        }
        
        
        private function updateVuMeterBackgroundColors():void
        {
        	if( _vuMeter && _titleHeight > 0 )
        	{
        		var titleColors:Array = titleColors;
        		Assert.assertTrue( titleColors.length == 2 );
        		
        		var subsliceOfTitleColors:Array = new Array;
        		subsliceOfTitleColors.push( Utilities.interpolateColors( titleColors[ 0 ], titleColors[ 1 ], _titleControlOffset / _titleHeight ) ); 
        		subsliceOfTitleColors.push( Utilities.interpolateColors( titleColors[ 0 ], titleColors[ 1 ], ( _titleHeight - _titleControlOffset ) / _titleHeight ) ); 
        		
        		_vuMeter.backgroundColors = subsliceOfTitleColors;
        	}	
        }
        
		
		private function updateCloseButtonColors():void
		{
			if( _closeButton )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_closeButton.setStyle( "color", 0xcfcfcf );
						_closeButton.setStyle( "fillColor", 0x747474 );
						break;
					
					case ColorScheme.DARK:
						_closeButton.setStyle( "color", 0x313131 );
						_closeButton.setStyle( "fillColor", 0x8c8c8c );
						break;
				}
			}
		}
		

		public function positionChildren():void
		{
			if( collapsed )
			{
				height = _titleHeight;
				
				if( _view && _view.parent == this )
				{
					removeElement( _view );
				}
				
				if( _timeline && _timeline.parent == this )
				{
					removeElement( _timeline );
				}
				
				if( _changeHeightButton && _changeHeightButton.parent == this )
				{
					removeElement( _changeHeightButton );
				}
			}
			else
			{
				if( _view )
				{
					if( _changeHeightFromTop || _changeHeightFromBottom || _useHeightOfView )
					{
						height = _titleHeight + _view.height; 
					}
					else
					{
						percentHeight = 100;
						minHeight = _titleHeight + _view.minHeight;
					}					

					if( _changeWidthFromLeft )
					{
						width = _view.width; 
					}
					
					_view.x = 0;
					_view.y = _titleHeight;
					if( _hasTimeline ) _view.y += Timeline.timelineHeight;					
					
					if( _view.parent != this ) 
					{
						addElementAt( _view, 0 );
						updateTitleText();
					}
					
					if( _changeHeightButton && _changeHeightButton.parent != this )
					{
						addElement( _changeHeightButton );
					}
				}
				
				if( _timeline )
				{
					_timeline.y = _titleHeight;

					if( _timeline.parent != this ) 
					{
						addElement( _timeline );
					}					
				}
			}

			_titleHBox.height = _titleHeight;
			
			_titleHBox.setStyle( "horizontalGap", _titleControlOffset );
			_titleHBox.setStyle( "paddingLeft", _titleControlOffset );
			_titleHBox.setStyle( "paddingRight", _titleControlOffset );
			
			if( _canCollapse )
			{
				_collapseButton.width = _titleHeight * 0.6;
				_collapseButton.height = _titleHeight * 0.6;
			}

			if( _breadcrumbsView )
			{
				_breadcrumbsView.height = _titleHeight * _titlebarHeightProportion;
			}

			if( _titlebarView )
			{
				_titlebarView.height = _titleHeight * _titlebarHeightProportion;
				if( _view.rightAlignTitlebarView )
				{
					_titlebarView.percentWidth = NaN;
					_titlebarView.height = _titleHeight;
					_titlebarView.setStyle( "right", _titleControlOffset * 2 + FontSize.getButtonSize( this ) );
				}
				else
				{
					_titlebarView.height = _titleHeight * _titlebarHeightProportion;
				}
			}
			
			_titleEdit.width = getTitleEditWidth();
			_titleEdit.height = getTitleEditHeight();
			
			if( _vuMeter )
			{
				_vuMeter.y = _titleControlOffset;
				_vuMeter.setStyle( "right", _titleControlOffset );
				_vuMeter.height = _titleHeight - _titleControlOffset * 2;
				_vuMeter.width = _vuMeterWidth;
				updateVuMeterBackgroundColors();
			}
			
			if( _closeButton )
			{
				_closeButton.y = _titleControlOffset;
				_closeButton.setStyle( "right", _titleControlOffset );
				_closeButton.height = FontSize.getButtonSize( this );
				_closeButton.width = FontSize.getButtonSize( this );
			}
		}
		
		
		private function getTitleEditWidth():Number
		{
			if( !isNaN( _titleEdit.textWidth ) ) 
			{
				//trick the edit box into remeasuring its length
				var prevText:String = _titleEdit.text;
				_titleEdit.text += "!";
				_titleEdit.validateNow();
				_titleEdit.text = prevText;
				_titleEdit.validateNow();
			}
				
			return _titleEdit.textWidth + _titleHeight * 2;
		}

		
		private function getTitleEditHeight():Number
		{
			if( !isNaN( _titleEdit.textWidth ) ) 
			{
				//trick the edit box into remeasuring its length
				var prevText:String = _titleEdit.text;
				_titleEdit.text += "!";
				_titleEdit.validateNow();
				_titleEdit.text = prevText;
				_titleEdit.validateNow();
			}
			
			return _titleEdit.textHeight * 1.2;
		}
		
		
		private function onMouseDownChangeHeightButton( event:MouseEvent ):void
		{
			Assert.assertNotNull( _view );
			
			if( _changeHeightFromTop )
			{
				Assert.assertFalse( _changeHeightFromBottom );
				_resizeDragMouseOffset = _view.height + root.mouseY;
			}
			else
			{
				Assert.assertTrue( _changeHeightFromBottom );
				_resizeDragMouseOffset = _view.height - mouseY;
			}

			MouseCapture.instance.setCapture( this, onChangeHeight, onEndResize, CursorSetter.RESIZE_NS );
		}
		
		
		private function onChangeHeight( event:MouseEvent ):void
		{
			Assert.assertNotNull( _view );
			
			if( _changeHeightFromTop )
			{
				Assert.assertFalse( _changeHeightFromBottom );
				_view.height = Math.max( _view.minHeight, Math.min( _view.maxHeight, _resizeDragMouseOffset - root.mouseY ) );
			}
			else
			{
				Assert.assertTrue( _changeHeightFromBottom );
				_view.height = Math.max( _view.minHeight, Math.min( _view.maxHeight, mouseY + _resizeDragMouseOffset ) );
			}
			
			positionChildren();
		}


		private function onMouseDownChangeWidthButton( event:MouseEvent ):void
		{
			Assert.assertNotNull( _view );
			
			Assert.assertTrue( _changeWidthFromLeft );
			_resizeDragMouseOffset = _view.width + root.mouseX;

			MouseCapture.instance.setCapture( this, onChangeWidth, onEndResize, CursorSetter.RESIZE_EW );
		}
		
		
		private function onChangeWidth( event:MouseEvent ):void
		{
			Assert.assertNotNull( _view );
			
			Assert.assertTrue( _changeWidthFromLeft );
			_view.width = Math.max( _view.minWidth, Math.min( _view.maxWidth, _resizeDragMouseOffset - root.mouseX ) );
			
			positionChildren();
		}


		private function onEndResize():void
		{
			_view.resizeFinished();
		}
		
		
		private function onRollOverChangeHeightButton( event:MouseEvent ):void
		{
			CursorSetter.setCursor( CursorSetter.RESIZE_NS, event.target as UIComponent );
		}


		private function onRollOverChangeWidthButton( event:MouseEvent ):void
		{
			CursorSetter.setCursor( CursorSetter.RESIZE_EW, event.target as UIComponent );
		}


		private function onTitleEditChange( event:FocusEvent ):void
		{
			setTitleEditable( false );		

			Assert.assertNotNull( _view );
			if( _view.title != _titleEdit.text )
			{
				_view.title = _titleEdit.text;
				updateTitleText();
			}	
		}
		
		
		private function onTitleEditKeyUp( event:KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case Keyboard.ENTER:
					setFocus();				//end the edit operation and force changes to be committed
					break;

				case Keyboard.ESCAPE:
					updateTitleText();		//revert to previous text
					setFocus();				//end the edit operation
					break;
					
				default:
					positionChildren();		//reposition controls in case edit needs to be wider
					break;
			} 
		}
		
		
		private function setTitleEditable( editable:Boolean ):void
		{
			_titleEdit.editable = editable;			
			_titleEdit.focusEnabled = editable;
			_titleEdit.enabled = editable;
			
			if( editable )
			{
				_titleEdit.selectionBeginIndex = 0;
				_titleEdit.selectionEndIndex = _titleEdit.text.length;
				_titleEdit.setFocus();
			}
		}		


		private function updateTitleText():void
		{
  			_titleEdit.text = _view.title;
		}
		
		
		private function onClick( event:MouseEvent ):void
		{
			if( mouseY >= _titleHeight ) return;
			
			if( shouldHandleTitleClick( event.target ) )
			{
				_view.titleClicked();
			}
		}
		
		
		private function onDoubleClick( event:MouseEvent ):void
		{
			if( mouseY >= _titleHeight ) return;

			if( _view.isTitleEditable ) 
			{
				if( _titleEdit.getRect( this ).contains( mouseX, mouseY ) )
				{
					setTitleEditable( true );
					return;
				}
			}
			
			if( _canCollapse && shouldHandleTitleClick( event.target ) )
			{
				_view.collapsed = !_view.collapsed;
			}
		}
		
		
		private function shouldHandleTitleClick( clickObject:Object ):Boolean
		{
			if( clickObject is IntegraView ) return false;
				
			return true;
			
			/*if( clickObject == this ) return true;
			
			if( clickObject is UITextField ) return true;
			
			return false;*/
		}


		private function onResizeView( event:Event ):void
		{
			if( _useHeightOfView ) 
			{
				positionChildren();
			}
		}

		
		private var _view:IntegraView = null;
		private var _titleHBox:HBox = new HBox;
		private var _titlebarView:IntegraView = null;
		private var _breadcrumbsView:IntegraView = null;
		private var _vuMeter:AggregateVUContainer = null;

		private var _titleHeight:Number = 0;
		private var _titleControlOffset:Number = 0;
		private var _titleEdit:TextInput = new TextInput;
		
		private var _canCollapse:Boolean = false;
		private var _collapseButton:Button = null;

		private var _hasCloseButton:Boolean = false;
		private var _closeButton:Button = null;
		
		private var _changeHeightFromBottom:Boolean = false;
		private var _changeHeightFromTop:Boolean = false;
		private var _changeHeightButton:Canvas = null;
		private var _useHeightOfView:Boolean = false;

		private var _changeWidthFromLeft:Boolean = false;
		private var _changeWidthButton:Canvas = null;

		private var _resizeDragMouseOffset:Number;
		private var _resizeDragCursorID:int = -1;

		private var _hasTimeline:Boolean = false;
		private var _timeline:Timeline = null;

		private static const _changeHeightButtonSize:int = 10;
		private static const _resizeBarSize:int = 3;
		private static const _titlebarHeightProportion:Number = 0.8;
		private static const _vuMeterWidth:int = 128;
	}
}