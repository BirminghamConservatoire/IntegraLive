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
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.preferences.MidiSettings;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	

	public class SetMidiOutputDevices extends ServerCommand
	{
		public function SetMidiOutputDevices( outputDevices:Vector.<String> )
		{
			super();

			_activeOutputDevices = outputDevices;
		}
		
		
		public function get activeOutputDevices():Vector.<String> { return _activeOutputDevices; }
		
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			var midiSettings:MidiSettings = model.midiSettings;
			
			for each( var outputDevice:String in _activeOutputDevices )
			{
				if( !Utilities.doesStringVectorContainString( midiSettings.availableOutputDevices, outputDevice ) )
				{
					return false;
				}
			}
			
			if( Utilities.areStringVectorsEqual( _activeOutputDevices, midiSettings.activeOutputDevices ) )
			{
				return false;
			}
			
			return true;

		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var midiSettings:MidiSettings = model.midiSettings;
			
			pushInverseCommand( new SetMidiOutputDevices( midiSettings.activeOutputDevices ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var midiSettings:MidiSettings = model.midiSettings;
			Assert.assertNotNull( midiSettings );
			
			midiSettings.activeOutputDevices = _activeOutputDevices;
			
			midiSettings.hasChangedSinceReset = true;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var midiSettingsPath:Array = [ model.midiSettings.name ];
			
			var methodCalls:Array = new Array;
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ midiSettingsPath.concat( "activeOutputDevices" ), Utilities.makePackedStringFromStringVector( _activeOutputDevices ) ]; 
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.midiSettings.id ) + ".activeOutputDevices" );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			Assert.assertNotNull( responseArray );
			
			if( responseArray.length != 1 ) return false;
			
			if( responseArray[ 0 ][ 0 ].response != "command.set" ) return false;
			
			return true;		
		}

		
		private var _activeOutputDevices:Vector.<String>;
	}
}
