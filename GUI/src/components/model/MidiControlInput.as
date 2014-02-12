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


package components.model
{
	public class MidiControlInput extends IntegraDataObject
	{
		public function MidiControlInput()
		{
			super();
		}

		
		public function get device():String { return _device; }
		public function get channel():int { return _channel; }
		public function get messageType():String { return _messageType; }
		public function get noteOrController():int { return _noteOrController; }
		public function get value():int { return _value; }
		public function get autoLearn():Boolean { return _autoLearn; }
		
		public function get scaler():Scaler { return _scaler; }
		
		public function set device( device:String ):void { _device = device; }
		public function set channel( channel:int ):void { _channel = channel; }
		public function set messageType( messageType:String ):void { _messageType = messageType; }
		public function set noteOrController( noteOrController:int ):void { _noteOrController = noteOrController; }
		public function set value( value:int ):void { _value = value; }
		public function set autoLearn( autoLearn:Boolean ):void { _autoLearn = autoLearn; }

		public function set scaler( scaler:Scaler ):void { _scaler = scaler; }
		
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{
				case "device":				_device = String( value );			return true;
				case "channel":				_channel = int( value );			return true;
				case "messageType":			_messageType = String( value );		return true;
				case "noteOrController":	_noteOrController = int( value );	return true;
				case "value":				_value = int( value );				return true;
				case "autoLearn":			_autoLearn = ( int( value ) > 0 );	return true;
			}
			
			
			return false;
		}
		
		private var _device:String;
		private var _channel:int;
		private var _messageType:String;
		private var _noteOrController:int;
		private var _value:int;
		private var _autoLearn:Boolean;
		
		private var _scaler:Scaler = null;
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "MidiInput";
		
		public static const defaultMidiControlInputName:String = "MidiControlInput";
		
		public static const NOTEON:String = "noteon";
		public static const CC:String = "cc";
	}
}
