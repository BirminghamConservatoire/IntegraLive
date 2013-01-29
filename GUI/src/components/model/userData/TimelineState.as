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


package components.model.userData
{
	public class TimelineState
	{
		public function TimelineState()
		{
			clear();
		}

		//scroll is the tick count of the leftmost edge of the timeline
		//zoom is in 'pixels per tick'
		
		public function get scroll():Number { return _scroll; }
		public function get zoom():Number { return _zoom; }

		public function set scroll( scroll:Number ):void { _scroll = Math.max( 0, scroll ); }
		public function set zoom( zoom:Number ):void { _zoom = Math.max( _minZoom, Math.min( _maxZoom, zoom ) ) }
		
		public function clear():void
		{
			_scroll = 0;
			_zoom = _initialZoom;
		}
		
		
		public function deepCompare( toCompare:TimelineState ):Boolean
		{
			if( _scroll != toCompare._scroll ) return false;
			if( _zoom != toCompare._zoom ) return false;
			
			return true;
		}
		
		
		public function copyFrom( toCopy:TimelineState ):void
		{
			_scroll = toCopy._scroll;
			_zoom = toCopy._zoom;
		}
		
		
		public function pixelsToTicks( pixels:Number ):int 
		{
			return pixels / zoom + scroll;
 		}


		public function ticksToPixels( ticks:int ):Number 
		{
			return ( ticks - scroll ) * zoom;
 		}
		
		
		private var _scroll:Number;		
		private var _zoom:Number;
		
		//zoom is in 'pixels per tick'
		private static const _initialZoom:Number = 0.4;
		private static const _minZoom:Number = 0.04;		
		private static const _maxZoom:Number = 25;
	}
}