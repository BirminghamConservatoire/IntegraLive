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

package components.controls
{
    import components.controlSDK.HelperClasses.AttributeLabel;
    import components.controlSDK.core.*;
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import mx.containers.Canvas;

	
    public class RangeSliderControl extends IntegraControl
    {
		public function RangeSliderControl( controlManager:ControlManager )
		{
		    super( controlManager );
		    
		    registerAttribute( _minAttributeName, ControlAttributeType.NUMBER );
		    registerAttribute( _maxAttributeName, ControlAttributeType.NUMBER );
		    
		    _minAttributeLabel = new AttributeLabel( _minAttributeName, true );
		    _maxAttributeLabel = new AttributeLabel( _maxAttributeName, true );
	
			_minAttributeLabel.setStyle( "left", 0 );
			_minAttributeLabel.setStyle( "right", 0 );
			_maxAttributeLabel.setStyle( "left", 0 );
			_maxAttributeLabel.setStyle( "right", 0 );
			
			addChild( _minAttributeLabel );
		    addChild( _maxAttributeLabel );
		    
		    addEventListener( Event.RESIZE, onResize );
			addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
	
		    _slider = new Canvas();
		    
		    addChild( _slider );
		}
		
		
		override public function get defaultSize():Point { return new Point( 256, 80 ); }
		override public function get minimumSize():Point { return new Point( 64, 48 ); }
		override public function get maximumSize():Point { return new Point( 1024, 1024 ); }
		
	
	
		override public function onValueChange( changedValues:Object ):void
		{
		    if( changedValues.hasOwnProperty( _minAttributeName ) )
		    {
				_min = changedValues[ _minAttributeName ];
		    }
				
		    if( changedValues.hasOwnProperty( _maxAttributeName ) )
		    {
				_max = changedValues[ _maxAttributeName ];
		    }
		    
		    updateSlider();
			updateLabels();
		}
		
		
		override public function isActiveArea( point:Point ):Boolean
		{
		    return drawArea().containsPoint( point );
		}
		
	
		override public function onMouseDown( event:MouseEvent ):void
		{
	        var drawArea:Rectangle = drawArea();
	
			var grabEndThreshold:Number = grabEndPixels / ( ( orientation == HORIZONTAL ) ? drawArea.width : drawArea.height );
	
			var mouseValue:Number = this.mouseValue;
			
			_previousRange = _max - _min;
			
			if( Math.abs( mouseValue - _min ) < grabEndThreshold )
			{
				_dragMode = DRAG_MIN;
				_clickOffset = _min - mouseValue;
			}
			else if( Math.abs( mouseValue - _max ) < grabEndThreshold )
			{
				_dragMode = DRAG_MAX;
				_clickOffset = _max - mouseValue;
			}
			else if( mouseValue > Math.min( _min, _max ) && mouseValue < Math.max( _min, _max ) )
			{
				_dragMode = DRAG_BOTH;
				_clickOffset = ( _min + _max ) / 2 - mouseValue;
			}
			else
			{
				//'draw' mode - set min to mouseValue, then drag max
				
				var changedValues:Object = new Object;
				changedValues[ _minAttributeName ] = mouseValue;
				
				setValues( changedValues );
				
				_dragMode = DRAG_MAX;
				_clickOffset = 0;
			}
			
			startMouseDrag();
			
			onDrag( event );
		}
		
		
		override public function onDrag( event:MouseEvent ):void
		{
		    var changedValues:Object = new Object;
			
			var mouseValue:Number = this.mouseValue + _clickOffset;
	
		    switch( _dragMode )
		    {
	            case DRAG_MIN:
	                changedValues[ _minAttributeName ] = Math.max( 0, Math.min( 1, mouseValue ) );
	                break;
			
	            case DRAG_MAX:
					changedValues[ _maxAttributeName ] = Math.max( 0, Math.min( 1, mouseValue ) );
	                break;
			
	            case DRAG_BOTH:
					changedValues[ _minAttributeName ] = Math.max( 0, Math.min( 1, mouseValue - _previousRange / 2 ) );
					changedValues[ _maxAttributeName ] = Math.max( 0, Math.min( 1, mouseValue + _previousRange / 2 ) );
	                break;
	
	            default:
	                Assert.assertTrue( false );
	                break;
		    }
	
		    setValues( changedValues );
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
		    super.updateDisplayList( width, height );
		    graphics.clear();
		    
		    //dimensions			
		    var drawArea:Rectangle = drawArea();
		    
		    //background			
		    graphics.beginFill( foregroundColor( LOW ) );
		    
		    switch( orientation )
		    {
	            case HORIZONTAL:
	                graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, drawArea.height * 0.8, drawArea.height * 0.8 );
	                break;
						
	            case VERTICAL:
	                graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, drawArea.width * 0.8, drawArea.width * 0.8 );
	                break;
						
	            default:
	                Assert.assertTrue( false );
	                break;
		    }
				
		    // TODO!!!!!
		    //'allowed value' ticks
		    var allowedValues:Vector.<Object> = getAllowedValues( _maxAttributeName );
		    if( allowedValues )
		    {
	            graphics.lineStyle( positionMarkerWidth, foregroundColor( LOW ) );
			
				switch( orientation )
				{
	                case HORIZONTAL:
	                    for each( var allowedValue:Number in allowedValues )
                        {
                            var x:Number = drawArea.x + allowedValue * drawArea.width;
                            graphics.moveTo( x, drawArea.top );
                            graphics.lineTo( x, drawArea.top - notchMarkerLength );
                        }
	                    break;
					
	                case VERTICAL:
	                    for each( allowedValue in allowedValues )
                        {
                            var y:Number = drawArea.bottom - allowedValue * drawArea.height;
                            graphics.moveTo( drawArea.left, y );
                            graphics.lineTo( drawArea.left - notchMarkerLength, y );
                        }
	                    break;
				
	                default:
	                    Assert.assertTrue( false );
	                    break;
				}
		    }
				
		    
		    graphics.endFill();
		}

		
		private function onDoubleClick( event:MouseEvent ):void
		{
			if( _dragMode == DRAG_BOTH )
			{
				//invert on double-click
				
				_previousRange = -_previousRange;
				
				var changedValues:Object = new Object;
				changedValues[ _minAttributeName ] = _max;
				changedValues[ _maxAttributeName ] = _min;
				
				setValues( changedValues );
			}
		}
		
		
			
		private function get orientation():String 
		{
		    return ( width >= height ) ? HORIZONTAL : VERTICAL; 
		}
		
		
		private function get mouseValue():Number
		{
			var drawArea:Rectangle = drawArea();
			if( drawArea.width <= 0 || drawArea.height <= 0 )
			{
				Assert.assertTrue( false );
				return 0;
			}
			
			switch( orientation )
			{
				case HORIZONTAL:
					return ( mouseX - drawArea.x ) / drawArea.width;
					break;
				
				case VERTICAL:
					return 1 - ( mouseY - drawArea.y ) / drawArea.height;
					break;
				
				default:
					Assert.assertTrue( false );
					return 0;
			}		
		}
	
	
		private function updateSlider():void
		{
		    setGlow( _slider, Math.abs( _max - _min ) );
		    
		    var drawArea:Rectangle = drawArea();
			
			var minPosition:Number = Math.min( _min, _max );
			var maxPosition:Number = Math.max( _min, _max );
		    
		    switch( orientation )
		    {
	            case HORIZONTAL:
	                var sliderWidth:Number = Math.max( 1, drawArea.width * Math.abs( _max - _min ) );
			    
	                //main lit area			
	                _slider.graphics.clear();
					_slider.graphics.lineStyle( 0, foregroundColor( FULL ) );
					_slider.graphics.beginFill( foregroundColor( FULL ) );
					_slider.graphics.drawRect( drawArea.x + ( drawArea.width * minPosition ), 
	                                               drawArea.y + sliderBodyOffset, 
	                                               sliderWidth, 
	                                               drawArea.height - ( sliderBodyOffset * 2 ) );
	
					_slider.graphics.drawRect( drawArea.x + ( drawArea.width * minPosition ) - 1,
	                                               drawArea.y,
	                                               2,
	                                               drawArea.height );			 
	
					_slider.graphics.drawRect( drawArea.x + ( drawArea.width * minPosition ) + sliderWidth - 1,
	                                               drawArea.y,
	                                               2,
	                                               drawArea.height );			 
	
					_slider.graphics.endFill();
					
					//arrow
					var arrowLength:Number = Math.min( maxArrowheadLength, sliderWidth * 0.75 );
					var arrowHeadSize:Number = ( drawArea.height - ( sliderBodyOffset * 2 ) ) / 3;
					_slider.graphics.lineStyle( arrowThickness, foregroundColor( NONE ) );
					_slider.graphics.moveTo( drawArea.x + drawArea.width * minPosition + ( sliderWidth - arrowLength ) * 0.5, drawArea.y + drawArea.height / 2 );
					_slider.graphics.lineTo( drawArea.x + drawArea.width * minPosition + ( sliderWidth + arrowLength ) * 0.5, drawArea.y + drawArea.height / 2 );
					
					if( _max > _min )
					{
						var tipX:Number = drawArea.x + drawArea.width * minPosition + ( sliderWidth + arrowLength ) * 0.5;

						_slider.graphics.moveTo( tipX, drawArea.y + drawArea.height / 2 );
						_slider.graphics.lineTo( tipX - arrowHeadSize, drawArea.y + drawArea.height / 2 - arrowHeadSize );
						_slider.graphics.moveTo( tipX, drawArea.y + drawArea.height / 2 );
						_slider.graphics.lineTo( tipX - arrowHeadSize, drawArea.y + drawArea.height / 2 + arrowHeadSize );
					}
					else
					{
						tipX = drawArea.x + drawArea.width * minPosition + ( sliderWidth - arrowLength ) * 0.5;

						_slider.graphics.moveTo( tipX, drawArea.y + drawArea.height / 2 );
						_slider.graphics.lineTo( tipX + arrowHeadSize, drawArea.y + drawArea.height / 2 - arrowHeadSize );
						_slider.graphics.moveTo( tipX, drawArea.y + drawArea.height / 2 );
						_slider.graphics.lineTo( tipX + arrowHeadSize, drawArea.y + drawArea.height / 2 + arrowHeadSize );
					}
					
					break;
			    
	            case VERTICAL:
					var sliderHeight:Number = Math.max( 1, drawArea.height * Math.abs( _max - _min ) );
			    
	                //main lit area			
					_slider.graphics.clear();
					_slider.graphics.lineStyle( 0, foregroundColor( FULL ) );
					_slider.graphics.beginFill( foregroundColor( FULL ) );
					_slider.graphics.drawRect( drawArea.x + sliderBodyOffset, 
	                                               drawArea.bottom - ( drawArea.height * maxPosition ), 
	                                               drawArea.width - ( sliderBodyOffset * 2 ), 
	                                               sliderHeight );
	
					_slider.graphics.drawRect( drawArea.x,
	                                               drawArea.bottom - ( drawArea.height * maxPosition ) - 1,
	                                               drawArea.width,
	                                               2 );			 
	
					_slider.graphics.drawRect( drawArea.x,
	                                               drawArea.bottom - ( drawArea.height * maxPosition ) + sliderHeight - 1,
	                                               drawArea.width,
	                                               2 );
	
					_slider.graphics.endFill();

					//arrow
					arrowLength = Math.min( maxArrowheadLength, sliderHeight * 0.75 );
					arrowHeadSize = ( drawArea.width - ( sliderBodyOffset * 2 ) ) / 3;
					_slider.graphics.lineStyle( arrowThickness, foregroundColor( NONE ) );
					_slider.graphics.moveTo( drawArea.x + drawArea.width / 2, drawArea.bottom - drawArea.height * minPosition - ( sliderHeight - arrowLength ) * 0.5 );
					_slider.graphics.lineTo( drawArea.x + drawArea.width / 2, drawArea.bottom - drawArea.height * minPosition - ( sliderHeight + arrowLength ) * 0.5 );
					
					if( _max > _min )
					{
						var tipY:Number = drawArea.bottom - drawArea.height * minPosition - ( sliderHeight + arrowLength ) * 0.5;
						
						_slider.graphics.moveTo( drawArea.x + drawArea.width / 2, tipY );
						_slider.graphics.lineTo( drawArea.x + drawArea.width / 2 - arrowHeadSize, tipY + arrowHeadSize );
						_slider.graphics.moveTo( drawArea.x + drawArea.width / 2, tipY );
						_slider.graphics.lineTo( drawArea.x + drawArea.width / 2 + arrowHeadSize, tipY + arrowHeadSize );
					}
					else
					{
						tipY = drawArea.bottom - drawArea.height * minPosition - ( sliderHeight - arrowLength ) * 0.5;
						
						_slider.graphics.moveTo( drawArea.x + drawArea.width / 2, tipY );
						_slider.graphics.lineTo( drawArea.x + drawArea.width / 2 - arrowHeadSize, tipY - arrowHeadSize );
						_slider.graphics.moveTo( drawArea.x + drawArea.width / 2, tipY );
						_slider.graphics.lineTo( drawArea.x + drawArea.width / 2 + arrowHeadSize, tipY - arrowHeadSize );
					}
					break;
			    
	            default:
	                Assert.assertTrue( false );
	                break;
		    }
		}
		
	
        private function updateLabels():void
        {
            var drawArea:Rectangle = drawArea();

			switch( orientation )
			{
				case HORIZONTAL:
					_minAttributeLabel.y = Math.max( 0, drawArea.top - _maxLabelHeight );
					_minAttributeLabel.height = drawArea.top - _minAttributeLabel.y;
					
					_maxAttributeLabel.y = drawArea.bottom;
					_maxAttributeLabel.height = Math.min( height - drawArea.bottom, _maxLabelHeight );
					
					if( _min < _max )
					{
						_minAttributeLabel.setStyle( "horizontalAlign", "left" );
						_maxAttributeLabel.setStyle( "horizontalAlign", "right" );
					}
					else
					{
						_minAttributeLabel.setStyle( "horizontalAlign", "right" );
						_maxAttributeLabel.setStyle( "horizontalAlign", "left" );
					}
					
					break;

				case VERTICAL:

					if( _min < _max )
					{
						_maxAttributeLabel.y = Math.max( 0, drawArea.top - _maxLabelHeight );
						_maxAttributeLabel.height = drawArea.top - _maxAttributeLabel.y;
						
						_minAttributeLabel.y = drawArea.bottom;
						_minAttributeLabel.height = Math.min( height - drawArea.bottom, _maxLabelHeight );
					}
					else
					{
						_minAttributeLabel.y = Math.max( 0, drawArea.top - _maxLabelHeight );
						_minAttributeLabel.height = drawArea.top - _minAttributeLabel.y;
						
						_maxAttributeLabel.y = drawArea.bottom;
						_maxAttributeLabel.height = Math.min( height - drawArea.bottom, _maxLabelHeight );
					}

					_minAttributeLabel.setStyle( "horizontalAlign", "center" );
					_maxAttributeLabel.setStyle( "horizontalAlign", "center" );
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}
        }
			
		
        override protected function drawArea():Rectangle
        {
			var thickness:Number = 0;
			
            switch( orientation )
            {
	            case HORIZONTAL:
						
					thickness = Math.min( Math.min( height - _minLabelHeight * 2, height * _thicknessProportion ), _maximumThickness );
					return new Rectangle( 0, ( height - thickness ) / 2, width, thickness ); 
				
	            case VERTICAL:
					
					var labelHeight:Number = Math.min( ( _minLabelHeight + _maxLabelHeight ) / 2, height / 3 ); 
					thickness = Math.min( width * _thicknessProportion, _maximumThickness );
					return new Rectangle( ( width - thickness ) / 2, labelHeight, thickness, height - labelHeight * 2 ); 
					
            default:
                Assert.assertTrue( false );
                return null;
            }
			 
        }
			
			
		private function onResize( event:Event ):void
		{
	        invalidateDisplayList();
	        updateSlider();
	        updateLabels();
		}
			
			
		private var _minAttributeLabel:AttributeLabel;
		private var _maxAttributeLabel:AttributeLabel;
		
		private var _min:Number = 0;
		private var _max:Number = 1;
		
		private var _slider:Canvas;
	
		private var _dragMode:String;
		private var _previousRange:Number = 0;
		private var _clickOffset:Number = 0;
	
		private static const _minAttributeName:String = "min";
		private static const _maxAttributeName:String = "max";
		
		private static const _minLabelHeight:Number = 15;
		private static const _maxLabelHeight:Number = 30;
		
		private static const _thicknessProportion:Number = 0.33;
		private static const _maximumThickness:Number = 40;
		
		private static const positionMarkerWidth:Number = 1;
		private static const positionMarkerLength:Number = 8;
		private static const notchMarkerLength:Number = 6;
		private static const sliderBodyOffset:Number = 4;
		
		private static const grabEndPixels:Number = 4;
		private static const arrowThickness:Number = 3;
		private static const maxArrowheadLength:Number = 64;
		
		private static const DRAG_MIN:String = "dragmin";
		private static const DRAG_MAX:String = "dragmax";
		private static const DRAG_BOTH:String = "both";
		
		private static const HORIZONTAL:String = "horizontal";
		private static const VERTICAL:String = "vertical";
    }
}