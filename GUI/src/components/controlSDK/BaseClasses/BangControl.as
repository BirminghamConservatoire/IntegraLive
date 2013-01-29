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

package components.controlSDK.BaseClasses
{
    import components.controlSDK.core.ControlManager;
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.*;
    
    import flexunit.framework.Assert;
	

    public class BangControl extends GeneralButtonControl
    {
		public function BangControl( controlManager:ControlManager )
		{
		    super( controlManager );
			
			_autoTriggerUpTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onAutoTriggerUpTimer );
		}
		
		
		override public function onValueChange( changedValues:Object ):void
		{
			_autoTriggered = true;
			update();
			
			_autoTriggerUpTimer.reset();
			_autoTriggerUpTimer.start();
		}
		
	
		override public function onMouseDown( event:MouseEvent ):void
		{
			_mouseTriggered = true;
		    update();
	
		    var changedValues:Object = new Object;
		    changedValues[ attributeName ] = 1;
		    setValues( changedValues );
			
			startMouseDrag();
		}
		
		
		override public function onEndDrag():void
		{
			_mouseTriggered = false;
			update();
		}
		
		
		protected function get triggered():Boolean { return _mouseTriggered || _autoTriggered; }

		
		private function onAutoTriggerUpTimer( event:TimerEvent ):void
		{
			_autoTriggered = false;
			update();			
		}
		
		
		private var _mouseTriggered:Boolean = false;
		private var _autoTriggered:Boolean = false;
		
		private var _autoTriggerUpTimer:Timer = new Timer( 50, 1 );
    }
}