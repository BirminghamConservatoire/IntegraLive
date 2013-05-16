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

package 
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.managers.ISystemManager;

	public final class MouseCapture
	{
		public static function setCapture( captureObject:Object, capturedDragFunction:Function = null, captureFinishedFunction:Function = null ):void
		{
			if( getCaptureID() >= 0 )
			{
				return;
			}
			
			_captureID++;
			_captureObject = captureObject;
			_capturedDragFunction = capturedDragFunction;
			_captureFinishedFunction = captureFinishedFunction;
			
			_systemManager.stage.addEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
			_systemManager.stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUp );
			_systemManager.addEventListener( MouseEvent.MOUSE_MOVE, onSystemMouseMove );
		}


		public static function getCaptureID():int
		{
			if( _captureObject == null ) return -1;	//no capture
			
			return _captureID; 
		}
		
		
		public static function relinquishCapture():void
		{
			if( _captureObject )
			{
				_captureObject = null;
				_capturedDragFunction = null;
				_captureFinishedFunction = null; 
	
				_systemManager.stage.removeEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
				_systemManager.stage.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUp, true );
				_systemManager.removeEventListener( MouseEvent.MOUSE_MOVE, onSystemMouseMove, true );
			}
		}
		
		
		public static function setSystemManager( manager:ISystemManager ):void
		{
			_systemManager = manager;
		}
		
		
		private static function releaseCapture():void
		{
			if( _captureFinishedFunction != null && _captureObject != null )
			{
				_captureFinishedFunction.apply( _captureObject );
			}
			
			relinquishCapture();
		}


		private static function onStageMouseLeave( event:Event ):void
		{
			releaseCapture();
		} 
		
		
		private static function onSystemMouseMove( event:MouseEvent ):void
		{
			if( _capturedDragFunction != null && _captureObject != null )
			{
				_capturedDragFunction.apply( _captureObject, [ event ] );
			}
		}


		private static function onStageMouseUp( event:MouseEvent ):void
		{
			releaseCapture();
		}
		
		
		private static var _systemManager:ISystemManager = null;
		
		private static var _captureObject:Object = null;
		private static var _capturedDragFunction:Function = null;
		private static var _captureFinishedFunction:Function = null;
		private static var _captureID:int = 0; 
	}
}