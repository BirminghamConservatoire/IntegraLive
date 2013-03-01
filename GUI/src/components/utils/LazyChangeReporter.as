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


package components.utils
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import flexunit.framework.Assert;
	
	public class LazyChangeReporter
	{
		public function LazyChangeReporter( target:DisplayObject, callback:Function )
		{
			Assert.assertNotNull( target );
			Assert.assertNotNull( callback );
		
			_target = target;
			_callback = callback;

			target.addEventListener( KeyboardEvent.KEY_UP, onTargetKeyUp );
		}
		
		
		public function reset():void
		{
			stopTimer();
		}

		
		public function close():void
		{
			if( _timer )
			{
				reportChange();
			}
			
			_target.removeEventListener( KeyboardEvent.KEY_DOWN, onTargetKeyUp );
			_callback = null;
		}
		
		
		private function onTargetKeyUp( event:KeyboardEvent ):void
		{
			if( _nonEditKeys.indexOf( event.keyCode ) >= 0 || event.ctrlKey || event.commandKey || event.altKey ) 
			{
				return;
			}
			
			var ticksSinceReport:int = getTimer() - _lastReportTicks;
			if( ticksSinceReport >= _reportInterval )
			{
				reportChange();
			}
			else
			{
				if( !_timer )
				{
					_timer = new Timer( _reportInterval - ticksSinceReport, 1 );
					_timer.addEventListener( TimerEvent.TIMER_COMPLETE, onTimer );
					_timer.start();
				}				
			}
			
		}
		
		
		private function onTimer( event:TimerEvent ):void
		{
			reportChange();
		}
		
		
		private function reportChange():void
		{
			stopTimer();
			_lastReportTicks = getTimer();

			_callback();
		}
		
		
		private function stopTimer():void
		{
			if( _timer )
			{
				if( _timer.running ) _timer.stop();
				_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onTimer );
				_timer = null;
			}
		}		
		

		private var _target:DisplayObject;
		private var _callback:Function;
		
		private var _lastReportTicks:int = 0;
		private var _timer:Timer = null;
		
		private var _nonEditKeys:Array = 
			[ 
				Keyboard.UP, Keyboard.DOWN, Keyboard.LEFT, Keyboard.RIGHT,
				Keyboard.PAGE_UP, Keyboard.PAGE_DOWN, Keyboard.HOME, Keyboard.END, Keyboard.INSERT,
				Keyboard.SHIFT, Keyboard.CONTROL, Keyboard.COMMAND, Keyboard.ALTERNATE
			];
		
		private static const _reportInterval:int = 500;
	}
}