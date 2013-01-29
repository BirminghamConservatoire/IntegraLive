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
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	import flexunit.framework.Assert;
	
	import mx.core.UIComponent;
	import mx.managers.CursorManager;
	
	public class CursorSetter
	{
		static public const ARROW:String = "arrow";
		
		static public const HIDDEN:String = "hidden";

		static public const HAND:String = "hand";
		static public const MOVE_EW:String = "moveEW";
		static public const MOVE_NSEW:String = "moveNSEW";
		static public const RESIZE_EW:String = "resizeEW";
		static public const RESIZE_NS:String = "resizeNS";
		static public const RESIZE_NESW:String = "resizeNESW";
		static public const RESIZE_SENW:String = "resizeSENW";
		static public const MAGNIFY_MOVE:String = "magnifyMove";

		
		static public function setCursor( cursorType:String, object:UIComponent ):void
		{
			if( cursorType == ARROW )
			{
				removeRollOutHandler( object );
			}
			else
			{
				addRollOutHandler( object );
			}
			
			_normalCursorType = cursorType;
			if( !_dragCursorType )
			{
				updateCursor( cursorType );
			}
		}

		
		static public function setDragCursor( cursorType:String ):void
		{
			_dragCursorType = cursorType;
			updateCursor( cursorType );
		}

		
		static public function removeDragCursor():void
		{
			_dragCursorType = null;
			updateCursor( _normalCursorType );
		}
		
		
		
		static private function updateCursor( cursorType:String ):void
		{
			if( cursorType == _currentCursorType ) return;
			
			//first restore 
			switch( _currentCursorType )
			{
				case ARROW:
					break;
				
				case HIDDEN:
					Mouse.show();
					break;
				
				default:
					CursorManager.removeCursor( _currentCursorID );
					break;
			}

			_currentCursorType = cursorType;

			switch( _currentCursorType )
			{
				case ARROW:
					break;
				
				case HIDDEN:
					Mouse.hide();
					break;
				
				default:
					Assert.assertTrue( _cursorMap.hasOwnProperty( cursorType ) );
					
					var cursorData:Object = _cursorMap[ cursorType ];
					_currentCursorID = CursorManager.setCursor( cursorData.cursor, 2, -cursorData.xCenter, -cursorData.yCenter );
					
					break;
			}			
		}
		
		
		static private function addRollOutHandler( object:UIComponent ):void
		{
			if( !_objectMap.hasOwnProperty( object.id ) )			
			{
				object.addEventListener( MouseEvent.ROLL_OUT, onRollOutObject );
				_objectMap[ object.id ] = 1;
			}
		}

		
		static private function removeRollOutHandler( object:UIComponent ):void
		{
			if( _objectMap.hasOwnProperty( object.id ) )			
			{
				object.removeEventListener( MouseEvent.ROLL_OUT, onRollOutObject );
				delete _objectMap[ object.id ];
			}
		}
		
		
		static private function onRollOutObject( event:MouseEvent ):void
		{
			_normalCursorType = ARROW;
			if( !_dragCursorType )
			{
				updateCursor( _normalCursorType );
			}			

			removeRollOutHandler( event.target as UIComponent );
		}
		
		
		static private var _normalCursorType:String = ARROW;
		static private var _dragCursorType:String = null;

		static private var _currentCursorType:String = ARROW;
		static private var _currentCursorID:int = -1;
		
		static private var _objectMap:Object = new Object;
		
		
		[Embed(source="/assets/handCursor.png")]
		static private var _handCursor:Class;

		[Embed(source="/assets/moveEWCursor.png")]
		static private var _moveEWCursor:Class;
		
		[Embed(source="/assets/moveNSEWCursor.png")]
		static private var _moveNSEWCursor:Class;

		[Embed(source="/assets/resizeEWCursor.png")]
		static private var _resizeEWCursor:Class;

		[Embed(source="/assets/resizeNSCursor.png")]
		static private var _resizeNSCursor:Class;

		[Embed(source="/assets/resizeNESWCursor.png")]
		static private var _resizeNESWCursor:Class;

		[Embed(source="/assets/resizeSENWCursor.png")]
		static private var _resizeSENWCursor:Class;

		[Embed(source="/assets/magnifyMoveCursor.png")]
		static private var _magnifyMoveCursor:Class;


		
		static private var _cursorMap:Object =
			{
				hand:			{ cursor: _handCursor, 			xCenter: 4, 	yCenter: 0 	 }, 
				moveEW:			{ cursor: _moveEWCursor, 		xCenter: 9, 	yCenter: 0	 }, 
				moveNSEW:		{ cursor: _moveNSEWCursor, 		xCenter: 11, 	yCenter: 11	 }, 
				resizeEW:		{ cursor: _resizeEWCursor, 		xCenter: 10, 	yCenter: 5	 }, 
				resizeNS:		{ cursor: _resizeNSCursor, 		xCenter: 5, 	yCenter: 10	 }, 
				resizeNESW:		{ cursor: _resizeNESWCursor, 	xCenter: 10, 	yCenter: 10	 }, 
				resizeSENW:		{ cursor: _resizeSENWCursor, 	xCenter: 10, 	yCenter: 10	 }, 
				magnifyMove:	{ cursor: _magnifyMoveCursor, 	xCenter: 12, 	yCenter: 12	 }
			};
	}
}