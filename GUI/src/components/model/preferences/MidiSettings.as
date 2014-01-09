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


package components.model.preferences
{
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.utils.Utilities;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	public class MidiSettings extends IntegraDataObject
	{
		public function MidiSettings()
		{
			super();
		}

		public function get availableInputDevices():Vector.<String> { return _availableInputDevices; }
		public function get availableOutputDevices():Vector.<String> { return _availableOutputDevices; }
		
		public function get selectedInputDevice():String { return _selectedInputDevice; }
		public function get selectedOutputDevice():String { return _selectedOutputDevice; }

		public function get hasChangedSinceReset():Boolean { return _hasChangedSinceReset; }
		
		public function set availableInputDevices( inputDevices:Vector.<String> ):void { _availableInputDevices = inputDevices; }
		public function set availableOutputDevices( outputDevices:Vector.<String> ):void { _availableOutputDevices = outputDevices; }
		
		public function set selectedInputDevice( inputDevice:String ):void { _selectedInputDevice = inputDevice; }
		public function set selectedOutputDevice( outputDevice:String ):void { _selectedOutputDevice = outputDevice; }

		public function set hasChangedSinceReset( hasChangedSinceReset:Boolean ):void { _hasChangedSinceReset = hasChangedSinceReset; }
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
		
			if( !( value is String ) )
			{
				Assert.assertTrue( false );
				return false;
			}	

			var valueString:String = String( value );	
		
			switch( attributeName )
			{
				case "availableInputDevices":
					Utilities.makeStringVectorFromPackedString( valueString, _availableInputDevices );
					break;

				case "availableOutputDevices":
					Utilities.makeStringVectorFromPackedString( valueString, _availableOutputDevices );
					break;
				
				case "selectedInputDevice":
					_selectedInputDevice = valueString;
					break;
				
				case "selectedOutputDevice":
					_selectedOutputDevice = valueString;
					break;
				
				default:
					return false;
			}
			
			return true; 
		}
		
		
		public static function get defaultObjectName():String
		{
			var name:String = Utilities.getClassNameFromClass( MidiSettings ) + "_" + Utilities.integraLiveVersion;
			name = name.replace( /\./g, "_" );
			name = name.replace( /\s/g, "_" );
			return name;
		}
		
		
		public static function get localFile():File
		{
			return File.applicationStorageDirectory.resolvePath( defaultObjectName + "." +Utilities.integraFileExtension );
		}

		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "MidiSettings";
		
		private var _availableInputDevices:Vector.<String> = new Vector.<String>;
		private var _availableOutputDevices:Vector.<String> = new Vector.<String>;

		private var _selectedInputDevice:String = "";
		private var _selectedOutputDevice:String = "";

		private var _hasChangedSinceReset:Boolean = false;
		
	}
}
