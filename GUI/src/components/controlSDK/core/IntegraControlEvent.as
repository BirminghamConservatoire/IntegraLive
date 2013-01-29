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

package components.controlSDK.core
{
	import flash.events.Event;

	public final class IntegraControlEvent extends Event
	{
		public function IntegraControlEvent( type:String, data:Object = null )
		{
			super( type, true );
			
			_data = data;
		}
		
		public function get data():Object { return _data; }

		public static const CONTROL_START_DRAG:String = "controlStartDrag";
		public static const CONTROL_VALUES_CHANGED:String = "controlValuesChanged";
		public static const CONTROL_TEXT_EQUIVALENTS_CHANGED:String = "controlTextEquivalentsChanged";
		public static const ATTRIBUTE_LABEL_POSITIONED:String = "attributeLabelPositioned";
		public static const ATTRIBUTE_LABEL_EDITSTATE_CHANGED:String = "attributeLabelEditStateChanged";

		public static const HOST_ATTRIBUTE_LABELS_CHANGED:String = "hostAttributeLabelsChanged";
		public static const HOST_TEXT_EQUIVALENTS_CHANGED:String = "hostTextEquivalentsChanged";
		public static const HOST_WRITABLE_FLAGS_CHANGED:String = "hostWritableFlagsChanged";
		
		private var _data:Object;
	}
}