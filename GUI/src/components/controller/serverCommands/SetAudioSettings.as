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
	import components.model.preferences.AudioSettings;
	
	import flexunit.framework.Assert;
	

	public class SetAudioSettings extends ServerCommand
	{
		public function SetAudioSettings ( sampleRate:int, inputChannels:int, outputChannels:int	 )
		{
			super();

			_sampleRate = sampleRate;
			_inputChannels = inputChannels;
			_outputChannels = outputChannels;
		}

		
		public function get sampleRate():int { return _sampleRate; }
		public function get inputChannels():int { return _inputChannels; }
		public function get outputChannels():int { return _outputChannels; }
		
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			var settings:AudioSettings = model.audioSettings;
			
			if( _sampleRate != settings.sampleRate ) return true;
			if( _inputChannels != settings.inputChannels ) return true;
			if( _outputChannels != settings.outputChannels ) return true;

			return false;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var settings:AudioSettings = model.audioSettings;
			
			pushInverseCommand( new SetAudioSettings( settings.sampleRate, settings.inputChannels, settings.outputChannels ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var settings:AudioSettings = model.audioSettings;
			Assert.assertNotNull( settings );
			
			settings.sampleRate = _sampleRate;
			settings.inputChannels = _inputChannels;
			settings.outputChannels = _outputChannels;
			
			settings.hasChangedSinceReset = true;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var settingsPath:Array = [ model.audioSettings.name ];

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ settingsPath.concat( "sampleRate" ), _sampleRate ]; 
	
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ settingsPath.concat( "inputChannels" ), _inputChannels ]; 

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ settingsPath.concat( "outputChannels" ), _outputChannels ]; 
	
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}

		
		override public function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.audioSettings.id ) + ".sampleRate" );
			changedAttributes.push( model.getPathStringFromID( model.audioSettings.id ) + ".inputChannels" );
			changedAttributes.push( model.getPathStringFromID( model.audioSettings.id ) + ".outputChannels" );
		}	
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			Assert.assertNotNull( responseArray );

			if( responseArray.length != 3 ) return false;

			if( responseArray[ 0 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 1 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 2 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}

		
		private var _sampleRate:int;
		private var _inputChannels:int;
		private var _outputChannels:int		
	}
}
