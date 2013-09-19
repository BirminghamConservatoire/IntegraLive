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
	import flash.filesystem.File;
	
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.utils.Utilities;
	
	public class AudioSettings extends IntegraDataObject
	{
		public function AudioSettings()
		{
			super();
		}

		public function get availableDrivers():Vector.<String> { return _availableDrivers; }
		public function get availableInputDevices():Vector.<String> { return _availableInputDevices; }
		public function get availableOutputDevices():Vector.<String> { return _availableOutputDevices; }
		public function get availableSampleRates():Vector.<int> { return _availableSampleRates; }
		
		public function get selectedDriver():String { return _selectedDriver; }
		public function get selectedInputDevice():String { return _selectedInputDevice; }
		public function get selectedOutputDevice():String { return _selectedOutputDevice; }
		public function get sampleRate():int { return _sampleRate; }

		public function get inputChannels():int { return _inputChannels; }
		public function get outputChannels():int { return _outputChannels; }

		public function get hasChangedSinceReset():Boolean { return _hasChangedSinceReset; }
		
		public function set availableDrivers( drivers:Vector.<String> ):void { _availableDrivers = drivers; }
		public function set availableInputDevices( inputDevices:Vector.<String> ):void { _availableInputDevices = inputDevices; }
		public function set availableOutputDevices( outputDevices:Vector.<String> ):void { _availableOutputDevices = outputDevices; }
		public function set availableSampleRates( sampleRates:Vector.<int> ):void { _availableSampleRates = sampleRates; }
		
		public function set selectedDriver( driver:String ):void { _selectedDriver = driver; }
		public function set selectedInputDevice( inputDevice:String ):void { _selectedInputDevice = inputDevice; }
		public function set selectedOutputDevice( outputDevice:String ):void { _selectedOutputDevice = outputDevice; }
		public function set sampleRate( sampleRate:int ):void { _sampleRate = sampleRate; }
		
		public function set inputChannels( inputChannels:int ):void { _inputChannels = inputChannels; }
		public function set outputChannels( outputChannels:int ):void { _outputChannels = outputChannels; }
		
		public function set hasChangedSinceReset( hasChangedSinceReset:Boolean ):void { _hasChangedSinceReset = hasChangedSinceReset; }
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
		
			switch( attributeName )
			{
				case "availableDrivers":
					Utilities.makeStringVectorFromPackedString( String( value ), _availableDrivers );
					break;

				case "availableInputDevices":
					Utilities.makeStringVectorFromPackedString( String( value ), _availableInputDevices );
					break;

				case "availableOutputDevices":
					Utilities.makeStringVectorFromPackedString( String( value ), _availableOutputDevices );
					break;

				case "availableSampleRates":
					var stringVector:Vector.<String> = new Vector.<String>;
					Utilities.makeStringVectorFromPackedString( String( value ), stringVector );
					Utilities.stringVectorToIntVector( stringVector, _availableSampleRates );
					break;
				
				case "selectedDriver":
					_selectedDriver = String( value );
					break;

				case "selectedInputDevice":
					_selectedInputDevice = String( value );
					break;
				
				case "selectedOutputDevice":
					_selectedOutputDevice = String( value );
					break;
				
				case "sampleRate":
					_sampleRate = int( value );
					break;

				case "inputChannels":
					_inputChannels = int( value );
					break;

				case "outputChannels":
					_outputChannels = int( value );
					break;

				default:
					return false;
			}
			
			return true; 
		}

		
		public static function get defaultObjectName():String
		{
			var name:String = Utilities.getClassNameFromClass( AudioSettings ) + "_" + Utilities.integraLiveVersion;
			name = name.replace( /\./g, "_" );
			name = name.replace( /\s/g, "_" );
			return name;
		}
		
		
		public static function get localFile():File
		{
			return File.applicationStorageDirectory.resolvePath( defaultObjectName + "." +Utilities.integraFileExtension );
		}
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "AudioSettings";
		
		private var _availableDrivers:Vector.<String> = new Vector.<String>;
		private var _availableInputDevices:Vector.<String> = new Vector.<String>;
		private var _availableOutputDevices:Vector.<String> = new Vector.<String>;
		private var _availableSampleRates:Vector.<int> = new Vector.<int>;

		private var _selectedDriver:String = "";
		private var _selectedInputDevice:String = "";
		private var _selectedOutputDevice:String = "";
		
		private var _sampleRate:int = 0
		private var _inputChannels:int = 0;
		private var _outputChannels:int = 0;
		
		private var _hasChangedSinceReset:Boolean = false;
	}
}
