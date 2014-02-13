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

	public class MidiLearnEvent extends Event
	{
		public function MidiLearnEvent( event_name:String, endpointName:String )
		{
			super( event_name, true );
			
			_endpointName = endpointName;
		}
		
		
		public function get endpointName():String { return _endpointName; }

		private var _endpointName:String;
		
		public static const ADD_MIDI_LEARN:String = "addMidiLearnEvent";		
		public static const REMOVE_MIDI_LEARN:String = "removeMidiLearnEvent";		
	}
}