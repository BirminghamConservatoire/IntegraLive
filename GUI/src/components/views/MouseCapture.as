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

package components.views
{
	import components.utils.CursorSetter;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import flexunit.framework.Assert;
	
	import mx.managers.ISystemManager;
	

	public final class MouseCapture extends EventDispatcher
	{
		public function MouseCapture()
		{
			super();
		}
		
		
		public static function get instance():MouseCapture { return _singleInstance; }
		
		
		public function setCapture( captureObject:Object, capturedDragFunction:Function = null, captureFinishedFunction:Function = null, cursorType:String = null ):void
		{
			Assert.assertFalse( hasCapture );
			
			if( !cursorType ) cursorType = CursorSetter.ARROW;
			
			CursorSetter.setDragCursor( cursorType );
				
			_captureID++;
			_captureObject = captureObject;
			_capturedDragFunction = capturedDragFunction;
			_captureFinishedFunction = captureFinishedFunction;
			
			_systemManager.stage.addEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
			_systemManager.stage.addEventListener( MouseEvent.MOUSE_UP, onStageMouseUp );
			_systemManager.addEventListener( MouseEvent.MOUSE_MOVE, onSystemMouseMove );
		}

		
		public function get hasCapture():Boolean
		{
			return( _captureObject != null );
		}

		
		public function get captureID():int
		{
			if( !hasCapture ) return -1;	//no capture
			
			return _captureID; 
		}
		
		
		public function relinquishCapture():void
		{
			if( !hasCapture ) return;
			
			_captureObject = null;
			_capturedDragFunction = null;
			_captureFinishedFunction = null; 

			_systemManager.stage.removeEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
			_systemManager.stage.removeEventListener( MouseEvent.MOUSE_UP, onStageMouseUp, true );
			_systemManager.removeEventListener( MouseEvent.MOUSE_MOVE, onSystemMouseMove, true );
			
			CursorSetter.removeDragCursor();
			
			dispatchEvent( new Event( MOUSE_CAPTURE_FINISHED ) );
		}
		
		
		public function setSystemManager( manager:ISystemManager ):void
		{
			_systemManager = manager;
		}
		
		
		private function releaseCapture():void
		{
			if( _captureFinishedFunction != null && _captureObject != null )
			{
				_captureFinishedFunction.apply( _captureObject );
			}
			
			relinquishCapture();
		}


		private function onStageMouseLeave( event:Event ):void
		{
			releaseCapture();
		} 
		
		
		private function onSystemMouseMove( event:MouseEvent ):void
		{
			if( _capturedDragFunction != null && _captureObject != null )
			{
				_capturedDragFunction.apply( _captureObject, [ event ] );
			}
		}


		private function onStageMouseUp( event:MouseEvent ):void
		{
			releaseCapture();
		}
		
		
		private static var _singleInstance:MouseCapture = new MouseCapture;
		
		private var _systemManager:ISystemManager = null;
		
		private var _captureObject:Object = null;
		private var _capturedDragFunction:Function = null;
		private var _captureFinishedFunction:Function = null;
		private var _captureID:int = 0;
		
		public static const MOUSE_CAPTURE_FINISHED:String = "MOUSE_CAPTURE_FINISHED"; 
	}
}