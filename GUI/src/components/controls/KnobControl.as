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
    import __AS3__.vec.Vector;
	
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
	
    import flexunit.framework.Assert;
	
    import mx.containers.Canvas;
	import components.controlSDK.core.*;
	import components.controlSDK.HelperClasses.AttributeLabel;
	import components.controlSDK.HelperClasses.RoundControl;
	

    public class KnobControl extends IntegraControl
    {
        public function KnobControl( controlManager:ControlManager )
        {
            super( controlManager );
			
            registerAttribute( _attributeName, ControlAttributeType.NUMBER );
			
            _attributeLabel = new AttributeLabel( _attributeName );
            _attributeLabel.setStyle( "horizontalAlign", "center" );
            _attributeLabel.setStyle( "horizontalCenter", -3 );
            _attributeLabel.setStyle( "verticalCenter", 0 );
            addChild( _attributeLabel );

            addEventListener( Event.RESIZE, onResize );
		
            _dial = new Canvas();
            addChild( _dial );

            _geometry = new RoundControl( width, height );
        }
		
		
        override public function get defaultSize():Point { return new Point( 120, 120 ); }
        override public function get minimumSize():Point { return new Point( 32, 32 ); }
        override public function get maximumSize():Point { return new Point( 320, 320 ); }

                
        override public function onValueChange( changedValues:Object ):void
        {
            Assert.assertTrue( changedValues.hasOwnProperty( _attributeName ) );
            
            _currentValue = changedValues[ _attributeName ];
            
            update();
        }
        

        override public function isActiveArea( point:Point ):Boolean
        {
            return _geometry.isActiveArea( point );
        }
		
		
        override public function onMouseDown( event:MouseEvent ):void
        {
            _valueAtClick = _currentValue;
            _mouseYAtClick = mouseY;
	
            startMouseDrag();
        }
		
		
        override public function onDrag( event:MouseEvent ):void
        {
            var newValue:Number = _valueAtClick + ( _mouseYAtClick - mouseY ) / _dragExtent;
            newValue = Math.max( 0, Math.min( 1, newValue ) );     
			
            var changedValues:Object = new Object;
            changedValues[ _attributeName ] = newValue;
            setValues( changedValues );
        }
		
		
        override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );
            graphics.clear();
			
            //dimensions			
            var drawArea:Rectangle = _geometry.drawArea;
            var knobCenter:Point = _geometry.controlCenter;
            var knobRadius:Number = _geometry.controlRadius;

            //knob			
            graphics.lineStyle( dialThickness, foregroundColor( LOW ) );
            graphics.drawCircle( knobCenter.x, knobCenter.y, knobRadius );

            //'allowed value' ticks
            var allowedValues:Vector.<Object> = getAllowedValues( _attributeName );
            if( allowedValues )
            {
                graphics.lineStyle( dialThickness, foregroundColor( LOW ) );
                var notchStartRadius:Number = knobRadius + dialThickness / 2;
                var notchEndRadius:Number = knobRadius + _markerLength;

                for each( var allowedValue:Number in allowedValues )
                {
                    var notchAngle:Number = allowedValue * Math.PI * 2;
                    var sinNotchAngle:Number = Math.sin( notchAngle );
                    var cosNotchAngle:Number = Math.cos( notchAngle );
                    graphics.moveTo( knobCenter.x - notchStartRadius * sinNotchAngle, knobCenter.y + notchStartRadius * cosNotchAngle );
                    graphics.lineTo( knobCenter.x - notchEndRadius * sinNotchAngle, knobCenter.y + notchEndRadius * cosNotchAngle );
                }
            }

            //current position marker
            var arcAngle:Number = _currentValue * Math.PI * 2;
            var markerStartRadius:Number = knobRadius;
            var markerEndRadius:Number = knobRadius + _markerLength;
			
            var sinArcAngle:Number = Math.sin( arcAngle );
            var cosArcAngle:Number = Math.cos( arcAngle );
			
            graphics.lineStyle( dialThickness, foregroundColor( FULL ) );
            graphics.moveTo( knobCenter.x - markerStartRadius * sinArcAngle, knobCenter.y + markerStartRadius * cosArcAngle );
            graphics.lineTo( knobCenter.x - markerEndRadius * sinArcAngle, knobCenter.y + markerEndRadius * cosArcAngle );
        }


        private function update():void
        {
            invalidateDisplayList();
           
            var drawArea:Rectangle = _geometry.drawArea;

            // dial
            var knobCenter:Point = _geometry.controlCenter;
            var knobRadius:Number = _geometry.controlRadius;

            var arcAngle:Number = _currentValue * Math.PI * 2;
			
            _dial.graphics.clear();
            _dial.graphics.lineStyle( dialThickness, foregroundColor( FULL ) );
            drawArc( knobCenter.x, knobCenter.y, knobRadius, 0, arcAngle, knobRadius );

            setGlow( _dial, _currentValue );
        }
		
		
        private function get dialThickness():Number
        {
            return _geometry.controlStrokeWeight;
        }


        private function drawArc( centerX:Number, centerY:Number, radius:Number, startAngle:Number, arcAngle:Number, steps:int ):void
        {
            var twoPI:Number = 2 * Math.PI;

            var angleStep:Number = arcAngle/steps;

            var startX:Number = centerX - Math.sin( startAngle ) * radius;
            var startY:Number = centerY + Math.cos( startAngle ) * radius;

            _dial.graphics.moveTo( startX, startY );

            for( var i:int = 1; i <= steps; i++ )
            {
                var angle:Number = startAngle + i * angleStep;
                
                var nextX:Number = centerX - Math.sin( angle ) * radius;
                var nextY:Number = centerY + Math.cos( angle ) * radius;
                
                _dial.graphics.lineTo( nextX, nextY );
            }
        }
	
	
        private function onResize( event:Event ):void
        {
            _attributeLabel.width = Math.min( 300, controlRadius() * 3.5 );  
            _attributeLabel.height = _attributeLabel.width * 0.25;  

            _geometry.width = width;
            _geometry.height = height;

            update();
        }
	
        
        private var _attributeLabel:AttributeLabel;
	
        private var _currentValue:Number = 0;
        private var _valueAtClick:Number = 0;
        private var _mouseYAtClick:Number = 0;
	
        private var _dial:Canvas;  
        private var _geometry:RoundControl;

        private static const _attributeName:String = "value";
        
        private static const _dragExtent:Number = 200;		
        private static const _markerLength:Number = 6;
    }
}