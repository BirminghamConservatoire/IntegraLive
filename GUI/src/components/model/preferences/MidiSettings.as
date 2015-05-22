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
		
		public function get activeInputDevices():Vector.<String> { return _activeInputDevices; }
		public function get activeOutputDevices():Vector.<String> { return _activeOutputDevices; }

		public function get hasChangedSinceReset():Boolean { return _hasChangedSinceReset; }
		
		public function set availableInputDevices( inputDevices:Vector.<String> ):void { _availableInputDevices = inputDevices; }
		public function set availableOutputDevices( outputDevices:Vector.<String> ):void { _availableOutputDevices = outputDevices; }
		
		public function set activeInputDevices( inputDevices:Vector.<String> ):void { _activeInputDevices = inputDevices; }
		public function set activeOutputDevices( outputDevices:Vector.<String> ):void { _activeOutputDevices = outputDevices; }

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
				
				case "activeInputDevices":
					Utilities.makeStringVectorFromPackedString( valueString, _activeInputDevices );
					break;
				
				case "activeOutputDevices":
					Utilities.makeStringVectorFromPackedString( valueString, _activeOutputDevices );
					break;
				
				default:
					return false;
			}
			
			return true; 
		}
		
		
		public static function get defaultObjectName():String
		{
			return Utilities.getClassNameFromClass( MidiSettings );
		}
		
		
		public static function get localFile():File
		{
			return File.applicationStorageDirectory.resolvePath( defaultObjectName + "." +Utilities.integraFileExtension );
		}

		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "MidiSettings";
		
		private var _availableInputDevices:Vector.<String> = new Vector.<String>;
		private var _availableOutputDevices:Vector.<String> = new Vector.<String>;

		private var _activeInputDevices:Vector.<String> = new Vector.<String>;
		private var _activeOutputDevices:Vector.<String> = new Vector.<String>;

		private var _hasChangedSinceReset:Boolean = false;
		
	}
}
