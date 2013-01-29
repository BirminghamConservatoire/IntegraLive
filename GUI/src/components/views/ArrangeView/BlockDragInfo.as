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


package components.views.ArrangeView
{
	import flash.display.DisplayObject;
	
	public class BlockDragInfo
	{
		public function BlockDragInfo( blockView:BlockView, trackID:int, dragType:String )
		{
			_blockView = blockView;
			_trackID = trackID;
			_dragType = dragType;
		}

		public function get blockView():BlockView { return _blockView; }
		public function get trackID():int { return _trackID; }
		public function get dragType():String { return _dragType; }

		public function set blockView( blockView:BlockView ):void { _blockView = blockView; }
		public function set trackID( trackID:int ):void { _trackID = trackID; }
		public function set dragType( dragType:String ):void { _dragType = dragType; }

		private var _blockView:BlockView = null;
		private var _trackID:int = -1;
		private var _dragType:String = null;
	}
}