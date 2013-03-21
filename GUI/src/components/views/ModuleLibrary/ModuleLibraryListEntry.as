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


package components.views.ModuleLibrary
{
	public class ModuleLibraryListEntry extends Object
	{
		public function ModuleLibraryListEntry( label:String, guid:String )
		{
			super();
			
			_label = label;
			_guid = guid;
		}

		public function set childData( childData:Array ):void { _childData = childData; }
		public function set expanded( expanded:Boolean ):void { _expanded = expanded; }
		
		public function get label():String { return _label; }
		public function get guid():String { return _guid; }
		public function get childData():Array { return _childData; }
		public function get expanded():Boolean { return _expanded; }

		public function toString():String { return _label; }
		
		private var _label:String = null;
		private var _guid:String = null;
		private var _childData:Array = null;
		private var _expanded:Boolean = false;
	}
}