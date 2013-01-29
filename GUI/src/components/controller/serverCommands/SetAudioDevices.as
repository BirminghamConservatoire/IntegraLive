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


package components.controller.serverCommands
{
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.preferences.AudioSettings;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	

	public class SetAudioDevices extends ServerCommand
	{
		public function SetAudioDevices( inputDevice:String, outputDevice:String )
		{
			super();

			_selectedInputDevice = inputDevice;
			_selectedOutputDevice = outputDevice;
		}
		
		
		public function get selectedInputDevice():String { return _selectedInputDevice; }
		public function get selectedOutputDevice():String { return _selectedOutputDevice; }
		
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			var audioSettings:AudioSettings = model.audioSettings;
			
			if( !Utilities.doesStringVectorContainString( audioSettings.availableInputDevices, _selectedInputDevice ) )
			{
				return false;
			}			

			if( !Utilities.doesStringVectorContainString( audioSettings.availableOutputDevices, _selectedOutputDevice ) )
			{
				return false;
			}			

			if( _selectedInputDevice != audioSettings.selectedInputDevice ) return true;
			if( _selectedOutputDevice != audioSettings.selectedOutputDevice ) return true;
			
			return false;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var audioSettings:AudioSettings = model.audioSettings;
			
			pushInverseCommand( new SetAudioDevices( audioSettings.selectedInputDevice, audioSettings.selectedOutputDevice ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var audioSettings:AudioSettings = model.audioSettings;
			Assert.assertNotNull( audioSettings );
			
			audioSettings.selectedInputDevice = _selectedInputDevice;
			audioSettings.selectedOutputDevice = _selectedOutputDevice;
			
			audioSettings.hasChangedSinceReset = true;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var audioSettingsPath:Array = [ model.audioSettings.name ];
			
			var methodCalls:Array = new Array;
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ audioSettingsPath.concat( "selectedInputDevice" ), _selectedInputDevice ]; 
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ audioSettingsPath.concat( "selectedOutputDevice" ), _selectedOutputDevice ]; 
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.audioSettings.id ) + ".selectedInputDevice" );
			changedAttributes.push( model.getPathStringFromID( model.audioSettings.id ) + ".selectedOutputDevice" );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			Assert.assertNotNull( responseArray );
			
			if( responseArray.length != 2 ) return false;
			
			if( responseArray[ 0 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 1 ][ 0 ].response != "command.set" ) return false;
			
			return true;		
		}

		
		private var _selectedInputDevice:String;
		private var _selectedOutputDevice:String;
	}
}
