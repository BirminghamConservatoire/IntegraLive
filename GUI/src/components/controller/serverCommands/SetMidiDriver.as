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
	import components.model.preferences.MidiSettings;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	

	public class SetMidiDriver extends ServerCommand
	{
		public function SetMidiDriver( selectedDriver:String, shouldClearAvailableDevices:Boolean = true )
		{
			super();

			_selectedDriver = selectedDriver;
			_shouldClearAvailableDevices = shouldClearAvailableDevices;
		}
		
		
		public function get selectedDriver():String { return _selectedDriver; }
		
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			var midiSettings:MidiSettings = model.midiSettings;
			
			if( !Utilities.doesStringVectorContainString( midiSettings.availableDrivers, _selectedDriver ) )
			{
				return false;
			}
			
			return ( _selectedDriver != midiSettings.selectedDriver );
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var midiSettings:MidiSettings = model.midiSettings;
			
			pushInverseCommand( new SetMidiDriver( midiSettings.selectedDriver ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var midiSettings:MidiSettings = model.midiSettings;
			Assert.assertNotNull( midiSettings );
			
			midiSettings.selectedDriver = _selectedDriver;
			
			midiSettings.hasChangedSinceReset = true;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var midiSettingsPath:Array = [ model.midiSettings.name ];
			
			connection.addArrayParam( midiSettingsPath.concat( "selectedDriver" ) );
			connection.addParam( _selectedDriver, XMLRPCDataTypes.STRING );	
			
			connection.callQueued( "command.set" );		
		}
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void 
		{
			if( _shouldClearAvailableDevices )
			{
				controller.processCommand( new SetAvailableMidiDevices( new Vector.<String>, new Vector.<String> ) );
			}
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.midiSettings.id ) + ".selectedDriver" );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}

		
		private var _selectedDriver:String;
		private var _shouldClearAvailableDevices:Boolean;
	}
}
