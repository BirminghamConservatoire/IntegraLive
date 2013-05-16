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
	import mx.managers.CursorManager;
	
	public class CursorSetter
	{
		static public const HAND:String = "hand";
		static public const RESIZE_EW:String = "resizeEW";
		static public const RESIZE_NS:String = "resizeNS";
		static public const RESIZE_NESW:String = "resizeNESW";
		static public const RESIZE_SENW:String = "resizeSENW";

		static public function setCursor( cursorType:String, priority:int = 2 ):int
		{
			switch( cursorType )
			{
				case HAND:			return CursorManager.setCursor( _handCursor, priority, -4, 0 );
				case RESIZE_EW:		return CursorManager.setCursor( _resizeEWCursor, priority, -10, -5 );
				case RESIZE_NS:		return CursorManager.setCursor( _resizeNSCursor, priority, -5, -10 );
				case RESIZE_NESW:	return CursorManager.setCursor( _resizeNESWCursor, priority, -10, -10 );
				case RESIZE_SENW:	return CursorManager.setCursor( _resizeSENWCursor, priority, -10, -10 );
				
				default:
					return -1;
			}
		}
		
		
		static public function removeCursor( cursorID:int ):void
		{
			CursorManager.removeCursor( cursorID );
		}
		

		[Embed(source="/assets/handCursor.png")]
		static private var _handCursor:Class;

		[Embed(source="/assets/resizeEWCursor.png")]
		static private var _resizeEWCursor:Class;

		[Embed(source="/assets/resizeNSCursor.png")]
		static private var _resizeNSCursor:Class;

		[Embed(source="/assets/resizeNESWCursor.png")]
		static private var _resizeNESWCursor:Class;

		[Embed(source="/assets/resizeSENWCursor.png")]
		static private var _resizeSENWCursor:Class;
	}
}