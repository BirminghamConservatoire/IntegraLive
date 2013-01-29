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

	
    public class SliderControl extends IntegraControl
    {
        public function SliderControl( controlManager:ControlManager )
        {
            super( controlManager );
			
            registerAttribute( _attributeName, ControlAttributeType.NUMBER );
			
            _attributeLabel = new AttributeLabel( _attributeName, true );
			_attributeLabel.setStyle( "left", 0 );
			_attributeLabel.setStyle( "right", 0 );
			_attributeLabel.setStyle( "horizontalAlign", "center" );
            addChild( _attributeLabel );

            addEventListener( Event.RESIZE, onResize );

            _slider = new Canvas();
            _sliderMask = new Canvas();
			
            addChild( _slider );
            addChild( _sliderMask );
            _slider.mask = _sliderMask;
			
            renderSlider();
        }
		
		
        override public function get defaultSize():Point { return new Point( 256, 48 ); }
        override public function get minimumSize():Point { return new Point( 32, 32 ); }
        override public function get maximumSize():Point { return new Point( 1024, 1024 ); }


        override public function onValueChange( changedValues:Object ):void
        {
            Assert.assertTrue( changedValues.hasOwnProperty( _attributeName ) );
			
            _value = changedValues[ _attributeName ];
			
            updateSlider();
        }
		
		
        override public function onTextEquivalentChange( changedTextEquivalents:Object ):void
        {
            Assert.assertTrue( changedTextEquivalents.hasOwnProperty( _attributeName ) );
        }


        override public function isActiveArea( point:Point ):Boolean
        {
            return sliderArea.containsPoint( point );
        }


        override public function onMouseDown( event:MouseEvent ):void
        {
            startMouseDrag();
			
            onDrag( event );
        }


        override public function onDrag( event:MouseEvent ):void
        {
            var sliderArea:Rectangle = sliderArea;

            if( sliderArea.width <= 0 || sliderArea.height <= 0 )
            {
                Assert.assertTrue( false );
                return;
            }

            var newValue:Number = 0;

            switch( orientation )
            {
	            case HORIZONTAL:
	                newValue = ( mouseX - sliderArea.x ) / sliderArea.width;
	                break;
						
	            case VERTICAL:
	                newValue = 1 - ( mouseY - sliderArea.y ) / sliderArea.height;
	                break;
						
	            default:
	                Assert.assertTrue( false );
	                break;
            }

            var changedValues:Object = new Object;
            changedValues[ _attributeName ] = Math.max( 0, Math.min( 1, newValue ) );
            setValues( changedValues );
        }
		
		
        override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );
            graphics.clear();
			
            //dimensions			
            var sliderArea:Rectangle = sliderArea;

            //background			
            graphics.beginFill( foregroundColor( LOW ) );
			
            switch( orientation )
            {
	            case HORIZONTAL:
	                graphics.drawRoundRect( sliderArea.x, sliderArea.y, sliderArea.width, sliderArea.height, sliderArea.height * 0.8, sliderArea.height * 0.8 );
	                break;
						
	            case VERTICAL:
	                graphics.drawRoundRect( sliderArea.x, sliderArea.y, sliderArea.width, sliderArea.height, sliderArea.width * 0.8, sliderArea.width  * 0.8 );
	                break;
						
	            default:
	                Assert.assertTrue( false );
	                break;
            }
			
            //'allowed value' ticks
            var allowedValues:Vector.<Object> = getAllowedValues( _attributeName );
            if( allowedValues )
            {
                graphics.lineStyle( positionMarkerWidth, foregroundColor( LOW ) );

                switch( orientation )
                {
	                case HORIZONTAL:
	                    for each( var allowedValue:Number in allowedValues )
                        {
                            var x:Number = sliderArea.x + allowedValue * sliderArea.width;
                            graphics.moveTo( x, sliderArea.top );
                            graphics.lineTo( x, sliderArea.top - notchMarkerLength );
                        }
	                    break;
							
	                case VERTICAL:
	                    for each( allowedValue in allowedValues )
                        {
                            var y:Number = sliderArea.bottom - allowedValue * sliderArea.height;
                            graphics.moveTo( sliderArea.left, y );
                            graphics.lineTo( sliderArea.left - notchMarkerLength, y );
                        }
	                    break;
							
	                default:
	                    Assert.assertTrue( false );
	                    break;
                }
            }
			
			
            graphics.endFill();
        }
		
		
        private function get orientation():String 
        {
            return ( width >= height - minimumAttributeLabelHeight ) ? HORIZONTAL : VERTICAL; 
        }


        private function updateSlider():void
        {
            setGlow( _slider, _value );

            var sliderArea:Rectangle = sliderArea;
			
            switch( orientation )
            {
	            case HORIZONTAL:
	                var sliderWidth:Number = sliderArea.width * _value;
				
	                //main lit area			
	                _sliderMask.graphics.clear();
	                _sliderMask.graphics.beginFill( foregroundColor( FULL ) );
	                _sliderMask.graphics.drawRect( sliderArea.x, sliderArea.y, sliderWidth, sliderArea.height );
	                _sliderMask.graphics.endFill();
			
	                break;
						
	            case VERTICAL:
	                var sliderHeight:Number = sliderArea.height * _value;
				
	                //main lit area			
	                _sliderMask.graphics.clear();
	                _sliderMask.graphics.beginFill( foregroundColor( FULL ) );
	                _sliderMask.graphics.drawRect( sliderArea.x, sliderArea.bottom - sliderHeight, sliderArea.width, sliderHeight );
	                _sliderMask.graphics.endFill();
			
	                break;
						
	            default:
	                Assert.assertTrue( false );
	                break;
            }
        }


        private function renderSlider():void
        {
            var sliderArea:Rectangle = sliderArea;

            _slider.graphics.clear();

            switch( orientation )
            {
	            case HORIZONTAL:
	                //main rounded area			
	                _slider.graphics.beginFill( foregroundColor( FULL ) );
	                _slider.graphics.drawRoundRect( sliderArea.x, sliderArea.y, sliderArea.width, sliderArea.height, sliderArea.height * 0.8, sliderArea.height * 0.8 );
	                _slider.graphics.endFill();
	
	                break;
	
	            case VERTICAL:
	                // main rounded area			
	                _slider.graphics.beginFill( foregroundColor( FULL ) );
	                _slider.graphics.drawRoundRect( sliderArea.x, sliderArea.y, sliderArea.width, sliderArea.height, sliderArea.width * 0.8, sliderArea.width * 0.8 );
	                _slider.graphics.endFill();
	
	                break;
						
	            default:
	                Assert.assertTrue( false );
	                break;
            }
        }
		
		
        private function updateLabel():void
        {
            _attributeLabel.y = sliderArea.bottom;
			_attributeLabel.height = Math.min( 30, height - _attributeLabel.y );
        }
			
		
        private function get sliderArea():Rectangle
        {
            switch( orientation )
            {
	            case HORIZONTAL:

					var sliderHeight:Number = Math.max( minimumSize.y - minimumAttributeLabelHeight, Math.min( maximumSliderThickness, height * idealSliderThicknessProportion ) );
					var remainingHeight:Number = height - sliderHeight;
					
					return new Rectangle( 0, Math.min( remainingHeight - minimumAttributeLabelHeight, remainingHeight / 2 ), width, sliderHeight );
					
	            case VERTICAL:				

					var sliderWidth:Number = Math.max( minimumSize.y - minimumAttributeLabelHeight, Math.min( maximumSliderThickness, width * idealSliderThicknessProportion ) );
					var remainingWidth:Number = width - sliderWidth;
					
					return new Rectangle( remainingWidth / 2, 0, sliderWidth, height - minimumAttributeLabelHeight );
						
	            default:
	                Assert.assertTrue( false );
	                return null;
            }
        }
		
		
        private function onResize( event:Event ):void
        {
            invalidateDisplayList();
            renderSlider();
            updateSlider();
            updateLabel();
        }
		
		
        private var _attributeLabel:AttributeLabel;

        private var _value:Number = 0;

        private var _slider:Canvas;
        private var _sliderMask:Canvas;    

        private static const _attributeName:String = "value";
		
        private static const positionMarkerWidth:Number = 1;
        private static const positionMarkerLength:Number = 8;
        private static const notchMarkerLength:Number = 6;
		private static const minimumAttributeLabelHeight:Number = 20;
		private static const maximumSliderThickness:Number = 30;
		private static const idealSliderThicknessProportion:Number = 0.4;
		
        private static const HORIZONTAL:String = "horizontal";
        private static const VERTICAL:String = "vertical";
    }
}