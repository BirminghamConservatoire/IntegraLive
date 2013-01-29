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
	import flash.geom.Rectangle;
	
	public class LiveViewControl
	{
		public function LiveViewControl()
		{
		}
	
		static public function makeLiveViewControlID( moduleID:int, controlInstanceName:String ):String { return moduleID + "." + controlInstanceName; } 

		public function get id():String { return makeLiveViewControlID( _moduleID, _controlInstanceName ); }

		public function get moduleID():int { return _moduleID; }
		public function get controlInstanceName():String { return _controlInstanceName; }
		public function get position():Rectangle { return _position; }

		public function set moduleID( id:int ):void { _moduleID = id; }
		public function set controlInstanceName( name:String ):void { _controlInstanceName = name; }
		public function set position( position:Rectangle ):void { _position = position; }

		private var _moduleID:int = -1;;
		private var _controlInstanceName:String = new String;
		private var _position:Rectangle = null;
	}
}