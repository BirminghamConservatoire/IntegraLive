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


package components.model.interfaceDefinitions
{
	import flash.geom.Rectangle;
	
	public class WidgetDefinition
	{
		public function WidgetDefinition()
		{
		}

		public function get type():String { return _type; }
		public function get label():String { return _label; }
		public function get position():Rectangle { return _position; }
		public function get attributeToEndpointMap():Object { return _attributeToEndpointMap; }

		public function set type( type:String ):void { _type = type; }
		public function set label( label:String ):void { _label = label; }
		public function set position( position:Rectangle ):void { _position = position; }
		
		
		private var _type:String;
		private var _label:String;
		private var _position:Rectangle;
		private var _attributeToEndpointMap:Object = new Object;
	}
}
