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
	import flash.events.Event;
	
	public final class StartControlRepositionEvent extends Event
	{
		public function StartControlRepositionEvent( control:ControlContainer, repositionType:String )
		{
			super( START_CONTROL_REPOSITION, true );
			_control = control;
			_repositionType = repositionType;
		}
		
		public function get control():ControlContainer { return _control; }
		public function get repositionType():String { return _repositionType; } 
		
		public static const START_CONTROL_REPOSITION:String = "StartControlReposition";
		
		private var _control:ControlContainer;
		private var _repositionType:String;
	}
}