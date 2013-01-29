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


package components.controller.events
{
	import flash.events.Event;

	public class LoadCompleteEvent extends Event
	{
		public function LoadCompleteEvent( shouldCreateDefaultObjects:Boolean )
		{
			super( EVENT_NAME );
			
			_shouldCreateDefaultObjects = shouldCreateDefaultObjects;
		}
		
		public function get shouldCreateDefaultObjects():Boolean { return _shouldCreateDefaultObjects; } 


		public static const EVENT_NAME:String = "loadComplete";
		
		private var _shouldCreateDefaultObjects:Boolean = false; 
	}
}