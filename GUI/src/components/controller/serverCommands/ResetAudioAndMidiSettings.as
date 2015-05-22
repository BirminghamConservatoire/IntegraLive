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
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.preferences.AudioSettings;
	import components.model.preferences.MidiSettings;
	
	import flexunit.framework.Assert;
	

	public class ResetAudioAndMidiSettings extends ServerCommand
	{
		public function ResetAudioAndMidiSettings()
		{
			super();
		}
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new ResetAudioAndMidiSettings() );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			/* do nothing - waits for response from host */ 
			
			model.audioSettings.hasChangedSinceReset = false;
			model.midiSettings.hasChangedSinceReset = false;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var audioSettingsPath:Array = [ model.audioSettings.name ];
			var midiSettingsPath:Array = [ model.midiSettings.name ];
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ audioSettingsPath.concat( "restoreDefaults" ) ]; 
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ midiSettingsPath.concat( "restoreDefaults" ) ]; 
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			/* 
			 delete the stored settings files as a precaution, so that if we have any more bugs where the settings 
			 modules stop working with certain settings, integra isn't permanently broken!
			*/
			
			if( AudioSettings.localFile.exists )
			{
				AudioSettings.localFile.deleteFileAsync();
			}
			
			if( MidiSettings.localFile.exists )
			{
				MidiSettings.localFile.deleteFileAsync();
			}
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

		
		private var _selectedDriver:String;
	}
}
