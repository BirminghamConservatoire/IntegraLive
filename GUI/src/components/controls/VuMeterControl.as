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
    import components.controlSDK.core.*;
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Timer;
    
    import flexunit.framework.Assert;
    
    import mx.containers.Canvas;
	
    public class VuMeterControl extends IntegraControl
    {
        public function VuMeterControl( controlManager:ControlManager )
        {
            super( controlManager );
			
            registerAttribute( _attributeName, ControlAttributeType.NUMBER );
			
            addEventListener( Event.RESIZE, onResize );
			_attritionTimer.addEventListener( TimerEvent.TIMER, onAttritionTimer ); 
	
            _level = new Canvas();
            _levelMask = new Canvas();
            _peak = new Canvas();
			
            addChild( _level );
            addChild( _levelMask );
            _level.mask = _levelMask;
            addChild( _peak ); 
        }
		
		
        override public function get defaultSize():Point { return new Point( 20, 128 ); }
        override public function get minimumSize():Point { return new Point( 24, 24 ); }
        override public function get maximumSize():Point { return new Point( 512, 512 ); }


        override public function onValueChange( changedValues:Object ):void
        {
            Assert.assertTrue( changedValues.hasOwnProperty( _attributeName ) );
			
			if( changedValues[ _attributeName ] > _currentLevel )
			{
				_currentLevel = changedValues[ _attributeName ];
				_attritionTimer.reset();
				_attritionTimer.start();
				
				updateLevel();
			}
        }
		
		
        override public function isActiveArea( point:Point ):Boolean
        {
            return drawArea().containsPoint( point );
        }


        override public function onMouseDown( event:MouseEvent ):void
        {
            _currentPeak = _currentLevel;
            repositionPeak();
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
                graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, drawArea.height, drawArea.height );
                break;
					
            case VERTICAL:
                graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, drawArea.width, drawArea.width );
                break;
					
            default:
                Assert.assertTrue( false );
                break;
            }
			
            graphics.endFill();
        }
		
		
		private function onAttritionTimer( event:TimerEvent ):void
		{
			if( _attritionTimer.currentCount <= _attritionStartCount ) return;
			
			var attrition:Number = _attritionFullSpeed * Math.min( 1, ( _attritionTimer.currentCount - _attritionStartCount ) / ( _attritionFullSpeedCount - _attritionStartCount ) )
			
			_currentLevel -= attrition;
			
			if( _currentLevel <= 0 )
			{
				_currentLevel = 0;
				_attritionTimer.stop();
			}
			
			updateLevel();
		}
		
		
        private function get orientation():String 
        {
            return ( width >= height ) ? HORIZONTAL : VERTICAL; 
        }


        private function updateLevel():void
        {
            setGlow( _level, _currentLevel );
            setGlow( _peak, _currentLevel );

            _level.visible = ( _currentLevel > 0 );

            var drawArea:Rectangle = drawArea();
			
            switch( orientation )
            {
            case HORIZONTAL:
                var levelWidth:Number = drawArea.width * _currentLevel;
			
                //main lit area			
                _levelMask.graphics.clear();
                _levelMask.graphics.beginFill( foregroundColor( FULL ) );
                _levelMask.graphics.drawRect( drawArea.x, drawArea.y, levelWidth, drawArea.height );
                _levelMask.graphics.endFill();
                break;
					
            case VERTICAL:
                var levelHeight:Number = drawArea.height * _currentLevel;
			
                //main lit area			
                _levelMask.graphics.clear();
                _levelMask.graphics.beginFill( foregroundColor( FULL ) );
                _levelMask.graphics.drawRect( drawArea.x, drawArea.bottom - levelHeight, drawArea.width, levelHeight );
                _levelMask.graphics.endFill();
                break;
					
            default:
                Assert.assertTrue( false );
                break;
            }
			
			_currentPeak = Math.max( _currentPeak, _currentLevel );   
			repositionPeak();
        }


        private function renderLevel():void
        {
            var drawArea:Rectangle = drawArea();

            _level.graphics.clear();

            switch( orientation )
            {
            case HORIZONTAL:
                //main rounded area			
                _level.graphics.beginFill( foregroundColor( FULL ) );
                _level.graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, drawArea.height, drawArea.height );
                _level.graphics.endFill();
                break;

            case VERTICAL:
                //main rounded area			
                _level.graphics.beginFill( foregroundColor( FULL ) );
                _level.graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, drawArea.width, drawArea.width );
                _level.graphics.endFill();
                break;
					
            default:
                Assert.assertTrue( false );
                break;
            }
        }


        private function repositionPeak():void
        {
            _peak.graphics.clear();
            _peak.graphics.lineStyle( _peakMarkerWidth, foregroundColor( FULL ) );
			
            var drawArea:Rectangle = drawArea();
		
            switch( orientation )
            {
            case HORIZONTAL:
                _peak.graphics.moveTo( drawArea.left + _currentPeak * drawArea.width, 0 ); 	
                _peak.graphics.lineTo( drawArea.left + _currentPeak * drawArea.width, height );
                break;

            case VERTICAL:
                _peak.graphics.moveTo( 0, drawArea.bottom - _currentPeak * drawArea.height ); 	
                _peak.graphics.lineTo( width, drawArea.bottom - _currentPeak * drawArea.height );
                break;
					
            default:
                Assert.assertTrue( false );
                break;
            }
        }
		
		
        override protected function drawArea():Rectangle
        {
            var drawAreaWidth:Number;
            var drawAreaHeight:Number;
            var drawArea:Rectangle;
			
            switch( orientation )
            {
	            case HORIZONTAL:
	                return new Rectangle( 0, height / 3, width, height / 3 );
					
	            case VERTICAL:				
	                return new Rectangle( width / 3, 0, width / 3, height - _verticalBottomMargin );
	            default:
	                Assert.assertTrue( false );
	                return null;
            }
        }
		
		
        private function onResize( event:Event ):void
        {
            invalidateDisplayList();
            renderLevel();
            updateLevel();
            repositionPeak();
        }
		
        private var _currentLevel:Number = 0;
        private var _currentPeak:Number = 0;
		
        private var _level:Canvas;
        private var _levelMask:Canvas;    
        private var _peak:Canvas;    

		private var _attritionTimer:Timer = new Timer( _attritionInterval );    
		
        private static const _attributeName:String = "level";
		
        private static const _peakMarkerWidth:Number = 2;
		private static const _verticalBottomMargin:Number = 8;
		
		private static const _attritionInterval:Number = 100;
		private static const _attritionStartCount:int = 1;
		private static const _attritionFullSpeedCount:int = 3;
		private static const _attritionFullSpeed:Number = 0.1;
		
        private static const HORIZONTAL:String = "horizontal";
        private static const VERTICAL:String = "vertical";
    }
}