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


package components.views.viewContainers
{
	import flash.events.Event;

	public class IntegraViewEvent extends Event
	{
		public function IntegraViewEvent( type:String )
		{
			super( type );
		}
		
		public static const TITLE_CHANGED:String = "TITLE_CHANGED";
		public static const TITLEBAR_CHANGED:String = "TITLEBAR_CHANGED";
		public static const VUMETER_CONTAINER_CHANGED:String = "VUMETER_CONTAINER_CHANGED";
		public static const COLOR_CHANGED:String = "COLOR_CHANGED";
		public static const MINHEIGHT_CHANGED:String = "MINHEIGHT_CHANGED";
		public static const COLLAPSE_CHANGED:String = "COLLAPSE_CHANGED";
		public static const ACTIVE_CHANGED:String = "ACTIVE_CHANGED";
		public static const EXPAND_COLLAPSE_ENABLE_CHANGED:String = "EXPAND_COLLAPSE_ENABLE_CHANGED";
		public static const RESIZED_BY_DIMENSION_SHARER:String = "RESIZED_BY_DIMENSION_SHARER"; 
	}
}