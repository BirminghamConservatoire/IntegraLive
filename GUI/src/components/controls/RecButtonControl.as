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
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.geom.Point;
	import components.controlSDK.BaseClasses.ToggleControl;
	import components.controlSDK.core.*;

    
    public class RecButtonControl extends ToggleControl
    {
        public function RecButtonControl( controlManager:ControlManager )
        {
            super( controlManager );
            
            _timer = new Timer( 500 );
            
            _timer.addEventListener( TimerEvent.TIMER, onTimer );
            _timer.addEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
        }
	
        
        override public function onValueChange( changedValues:Object ):void
        {
            super.onValueChange( changedValues );

            selected ? _timer.start() : _timer.stop();			
            _blinkFlag = selected;;

            update();
        }		


        private function onTimer( event:TimerEvent ):void
        {
            _blinkFlag = !_blinkFlag;
            update();
        }


        private function onTimerComplete( event:TimerEvent ):void
        {
            _blinkFlag = false;
            update();
        }
	
	
        override protected function update():void
        {
            var buttonCenter:Point = geometry.controlCenter;  
            var buttonRadius:Number = geometry.controlRadius; 
            var sizeModifier:Number = selected ? 0.9 : 1;

            button.graphics.clear();

            // button circle background
            button.graphics.lineStyle( buttonRadius * 0.2, mouseOver || selected ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
            button.graphics.beginFill( mouseOver ? foregroundColor( LOW ) : foregroundColor( NONE ) );
            button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius * sizeModifier );
            button.graphics.endFill();


            // blinking circle in the center
            button.graphics.lineStyle();

            if( selected )
            {
                button.graphics.beginFill( _blinkFlag ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
            }
            else
            {
                button.graphics.beginFill( mouseOver ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
            }

            button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius * 0.4 );
            button.graphics.endFill();
				
            setGlow( button, selected ? 0.6 : 0.2 );			
        }
		
		
        private var _blinkFlag:Boolean = false;
        private var _timer:Timer;
    }
}
