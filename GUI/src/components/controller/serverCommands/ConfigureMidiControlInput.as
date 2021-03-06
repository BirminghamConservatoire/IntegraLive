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
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scaler;
	
	import flexunit.framework.Assert;

	/*
	ConfigureMidiControlInput allows the caller to provide special 'ignore' values (null for strings, -1 for ints).
	These tell the command not to change these values.  When fired from the gui, these values are set by initialize.
	When used as a remote command response, they are simply ignored.
	*/
	
	public class ConfigureMidiControlInput extends ServerCommand
	{
		public function ConfigureMidiControlInput( midiControlInputID:int, device:String = null, channel:int = -1, messageType:String = null, messageValue:int = -1 )
		{
			super();

			_midiControlInputID = midiControlInputID;
			_device = device;
			_channel = channel;
			_messageType = messageType;
			_messageValue = messageValue;
		}
		
		public function get midiControlInputID():int { return _midiControlInputID; }
		public function get device():String { return _device; }
		public function get channel():int { return _channel; }
		public function get messageType():String { return _messageType; }
		public function get messageValue():int { return _messageValue; }
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !model.doesObjectExist( midiControlInputID ) || !( model.getDataObjectByID( midiControlInputID ) is MidiControlInput ) )
			{
				return false;
			}
			
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );

			if( !_device ) 			_device = midiControlInput.device;
			if( _channel < 0 ) 		_channel = midiControlInput.channel;
			if( !_messageType ) 	_messageType = midiControlInput.messageType;
			if( _messageValue < 0 ) _messageValue = midiControlInput.noteOrController;
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			pushInverseCommand( new ConfigureMidiControlInput( _midiControlInputID, midiControlInput.device, midiControlInput.channel, midiControlInput.messageType, midiControlInput.noteOrController ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			if( _device ) 				midiControlInput.device = _device;
			if( _channel >= 0 ) 		midiControlInput.channel = _channel;
			if( _messageType ) 			midiControlInput.messageType = _messageType;
			if( _messageValue >= 0 )	midiControlInput.noteOrController = _messageValue;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var midiControlInputPath:Array = model.getPathArrayFromID( _midiControlInputID );

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ midiControlInputPath.concat( "device" ), _device ]; 
	
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ midiControlInputPath.concat( "channel" ), _channel ]; 

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ midiControlInputPath.concat( "messageType" ), _messageType ]; 

			methodCalls[ 3 ] = new Object;
			methodCalls[ 3 ].methodName = "command.set";
			methodCalls[ 3 ].params = [ midiControlInputPath.concat( "noteOrController" ), _messageValue ]; 
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			var scaler:Scaler = midiControlInput.scaler;
			Assert.assertNotNull( scaler );
			
			var minValue:int = ( _messageType == MidiControlInput.NOTEON ) ? 1 : 0;	
			controller.processCommand( new SetScalerInputRange( scaler.id, minValue, 127 ) );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			Assert.assertNotNull( responseArray );

			if( responseArray.length != 4 ) return false;

			if( responseArray[ 0 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 1 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 2 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 3 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( _midiControlInputID ) + ".device" );
			changedAttributes.push( model.getPathStringFromID( _midiControlInputID ) + ".channel" );
			changedAttributes.push( model.getPathStringFromID( _midiControlInputID ) + ".messageType" );
			changedAttributes.push( model.getPathStringFromID( _midiControlInputID ) + ".noteOrController" );
		}
		
		
		
		private var _midiControlInputID:int;
		private var _device:String;
		private var _channel:int;
		private var _messageType:String;
		private var _messageValue:int;
	}
}