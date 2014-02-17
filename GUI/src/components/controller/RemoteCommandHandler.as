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


package components.controller
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import components.controller.serverCommands.ConfigureMidiControlInput;
	import components.controller.serverCommands.ReceiveRawMidiInput;
	import components.controller.serverCommands.SelectScene;
	import components.controller.serverCommands.SetAudioDriver;
	import components.controller.serverCommands.SetAudioInputDevice;
	import components.controller.serverCommands.SetAudioOutputDevice;
	import components.controller.serverCommands.SetAudioSettings;
	import components.controller.serverCommands.SetAvailableAudioDevices;
	import components.controller.serverCommands.SetAvailableAudioDrivers;
	import components.controller.serverCommands.SetAvailableMidiDevices;
	import components.controller.serverCommands.SetAvailableSampleRates;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetMidiControlAutoLearn;
	import components.controller.serverCommands.SetMidiControlInputValue;
	import components.controller.serverCommands.SetMidiInputDevices;
	import components.controller.serverCommands.SetMidiOutputDevices;
	import components.controller.serverCommands.SetModuleAttribute;
	import components.controller.serverCommands.SetObjectInfo;
	import components.controller.serverCommands.SetPlayPosition;
	import components.controller.serverCommands.SetPlaying;
	import components.controller.serverCommands.SetScalerInputRange;
	import components.controller.serverCommands.SetScalerOutputRange;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.MidiRawInput;
	import components.model.ModuleInstance;
	import components.model.Player;
	import components.model.Scaler;
	import components.model.Script;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.preferences.AudioSettings;
	import components.model.preferences.MidiSettings;
	import components.utils.ModalState;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	
	public class RemoteCommandHandler
	{
		public function RemoteCommandHandler()
		{
			Assert.assertNull( _singleInstance );
			_singleInstance = this;
			
			_processQueueTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onProcessQueueTimer );
		}
		
		
		static public function get singleInstance():RemoteCommandHandler 
		{ 
			if( !_singleInstance )
			{
				_singleInstance = new RemoteCommandHandler;
			}
			return _singleInstance; 
		}
		
		
		public function commandSet( commandOrigin:String, path:String, value:Object = null ):String
		{
			var attributePath:Array = path.split( "." );
			
			var shouldProcessCommand:Boolean = false;
			
			if( commandOrigin == XMLRPC_COMMAND )
			{
				if( _attributesLastTouchedRemotely.hasOwnProperty( path ) )
				{
					shouldProcessCommand = true;
					
					delete _attributesLastTouchedRemotely[ path ];
				}
				else
				{
					shouldProcessCommand = false;
				}
			}
			else
			{
				_attributesLastTouchedRemotely[ path ] = 1;
				shouldProcessCommand = true;					
			}
			
			if( shouldProcessCommand )
			{
				var remoteCommandResponse:RemoteCommandResponse = buildGUICommandFromSet( attributePath, value );
			
				switch( remoteCommandResponse.response )
				{
					case RemoteCommandResponse.HANDLE_COMMAND:
						for( var i:int = _setCommandQueue.length - 1; i >= 0; i-- )
						{
							if( _setCommandQueue[ i ].path == path )
							{
								_setCommandQueue.splice( i, 1 );
								break;	//can safely break here as we don't expect to encounter duplicates
							}
						}
						_setCommandQueue.push( new QueuedRemoteSetCommand( path, remoteCommandResponse ) );
						if( !_processQueueTimer.running )
						{
							_processQueueTimer.start();
						}
						break;
					
					case RemoteCommandResponse.RELOAD_ALL:
						clearSetCommandQueue();
						IntegraController.singleInstance.processRemoteCommand( remoteCommandResponse );
						break;
				}
			}
			
			return "command.set";
		}
		
		
		public function flushProcessQueue():void
		{
			if( _flushingProcessQueue ) return;
			
			_flushingProcessQueue = true;
			
			for each( var remoteSetCommand:QueuedRemoteSetCommand in _setCommandQueue )
			{
				IntegraController.singleInstance.processRemoteCommand( remoteSetCommand.response );
			}
			
			clearSetCommandQueue();
			
			_flushingProcessQueue = false;
		}
		
		
		private function onProcessQueueTimer( event:TimerEvent ):void
		{
			flushProcessQueue();
		}

		
		private function clearSetCommandQueue():void
		{
			_setCommandQueue.length = 0;
			_processQueueTimer.reset();
		}
		
		private function buildGUICommandFromSet( path:Array, value:Object ):RemoteCommandResponse
		{
			if( ModalState.isInModalState )
			{
				return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
			}
			
			var model:IntegraModel = IntegraModel.singleInstance;
			
			if( path.length < 2 )
			{
				return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
			}
			
			var endpointName:String = path[ path.length - 1 ];
			var objectPath:Array = path.slice( 0, path.length - 1 );
			
			var objectID:int = model.getIDFromPathArray( objectPath );
			if( objectID < 0 )
			{
				return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
			}
			
			var object:IntegraDataObject = model.getDataObjectByID( objectID );
			if( !object )
			{
				Assert.assertTrue( false );
				return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
			}
			
			var endpoint:EndpointDefinition = object.interfaceDefinition.getEndpointDefinition( endpointName );
			if( !endpoint || endpoint.type != EndpointDefinition.CONTROL )
			{
				Assert.assertTrue( false );
				return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
			}
			
			var command:ServerCommand = null;
			
			if( object is Player )
			{
				if( !objectID == model.project.player.id )
				{
					Assert.assertTrue( false );
					return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
				}
				
				switch( endpointName )
				{
					case "play":
						command = new SetPlaying( int( value ) != 0 );
						break;
						
					case "tick":
						command = new SetPlayPosition( int( value ), false, true );
						break;
						
					case "scene":
						var playerPath:Array = model.getPathArrayFromID( model.project.player.id );
						var scenePath:Array = playerPath.concat( value );
						command = new SelectScene( model.getIDFromPathArray( scenePath ), false );
						break;
						
					default:
						break;
				}
			}
			else if( object is ModuleInstance )
			{
				switch( endpoint.controlInfo.type )
				{
					case ControlInfo.STATE:
						command = new SetModuleAttribute( objectID, endpointName, value, endpoint.controlInfo.stateInfo.type );
						break;
					
					case ControlInfo.BANG:
						command = new SetModuleAttribute( objectID, endpointName );
						break;
					
					default:
						Assert.assertTrue( false );
						break;
				}
			}
			else if( object is MidiRawInput )
			{
				command = new ReceiveRawMidiInput( object.id, uint( value ) );
			}
			else if( object is IntegraContainer )
			{
				switch( endpointName )
				{
					case "active":
						command = new SetContainerActive( object.id, ( value != 0 ) );
						break;
				}
			}
			else if( object is Script )
			{
				switch( endpointName )
				{
					case "info":
						command = new SetObjectInfo( objectID, String( value ) );
						break;
					
					default:
						break;
				}
			}
			else if( object is AudioSettings )
			{
				var audioSettings:AudioSettings = model.audioSettings;
				
				switch( endpointName )
				{
					case "availableDrivers":
						var availableDrivers:Vector.<String> = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), availableDrivers );
						command = new SetAvailableAudioDrivers( availableDrivers );
						break;
						
					case "availableInputDevices":
						var availableInputDevices:Vector.<String> = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), availableInputDevices );
						command = new SetAvailableAudioDevices( availableInputDevices, null );
						break;

					case "availableOutputDevices":
						var availableOutputDevices:Vector.<String> = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), availableOutputDevices );
						command = new SetAvailableAudioDevices( null, availableOutputDevices );
						break;
					
					case "availableSampleRates":
						var availableSampleRates:Vector.<int> = new Vector.<int>;
						var stringVector:Vector.<String> = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), stringVector );
						Utilities.stringVectorToIntVector( stringVector, availableSampleRates );
						command = new SetAvailableSampleRates( availableSampleRates );
						break;

					case "selectedDriver":
						command = new SetAudioDriver( String( value ), false );
						break;
						
					case "selectedInputDevice":
						command = new SetAudioInputDevice( String( value ) );
						break;

					case "selectedOutputDevice":
						command = new SetAudioOutputDevice( String( value ) );
						break;
					
					case "sampleRate":
						command = new SetAudioSettings( int( value ), -1, -1 ); 
						break;
						
					case "inputChannels":
						command = new SetAudioSettings( -1, int( value ), -1 ); 
						break;
						
					case "outputChannels":
						command = new SetAudioSettings( -1, -1, int( value ) ); 
						break;

					default:
						break;					
				}
			}
			else if( object is MidiSettings )
			{
				switch( endpointName )
				{
					case "availableInputDevices":
						availableInputDevices = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), availableInputDevices );
						command = new SetAvailableMidiDevices( availableInputDevices, null );
						break;
					
					case "availableOutputDevices":
						availableOutputDevices = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), availableOutputDevices );
						command = new SetAvailableMidiDevices( null, availableOutputDevices );
						break;
					
					case "activeInputDevices":
						var activeInputDevices:Vector.<String> = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), activeInputDevices );
						command = new SetMidiInputDevices( activeInputDevices );
						break;
					
					case "activeOutputDevices":
						var activeOutputDevices:Vector.<String> = new Vector.<String>;
						Utilities.makeStringVectorFromPackedString( String( value ), activeOutputDevices );
						command = new SetMidiOutputDevices( activeOutputDevices );
						break;
					
					default:
						break;					
				}
			}
			else if( object is MidiControlInput )
			{
				switch( endpointName )
				{
					case "value":
						command = new SetMidiControlInputValue( object.id, int( value ) );
						break;
					
					case "autoLearn":
						command = new SetMidiControlAutoLearn( object.id, ( value != 0 ) );
						break;
					
					case "device":
						command = new ConfigureMidiControlInput( object.id, String( value ) );
						break;

					case "channel":
						command = new ConfigureMidiControlInput( object.id, null, int( value ) );
						break;

					case "messageType":
						command = new ConfigureMidiControlInput( object.id, null, -1, String( value ) );
						break;

					case "noteOrController":
						command = new ConfigureMidiControlInput( object.id, null, -1, null, int( value ) );
						break;
				}
			}
				

			/*
			Note:
			
			This function does not support all possible attribute set commands.  Support for other commands
			should be added here as and when it is needed
			
			Note also that every ServerCommand returned by this method must implement
			getAttributesChangedByThisCommand!
			*/
			
			if( command )
			{
				//selftest that getAttributesChangedByThisCommand has been implemented by all commands
				//used by RemoveCommandHandler
				var changedAttributes:Vector.<String> = new Vector.<String>;
				command.getAttributesChangedByThisCommand( model, changedAttributes );
				
				//if this assertion fails, it is likely that the specific class of 'command' has failed to
				//implement getAttributesChangedByThisCommand
				Assert.assertTrue( changedAttributes.length > 0 );		
				
				return new RemoteCommandResponse( RemoteCommandResponse.HANDLE_COMMAND, command);		
			}
			else
			{
				return new RemoteCommandResponse( RemoteCommandResponse.IGNORE );
			}
			
		}
		
		
		public function onAttributesChangedLocally( changedAttributes:Vector.<String> ):void
		{
			for each( var changedAttribute:String in changedAttributes )
			{
				if( _attributesLastTouchedRemotely.hasOwnProperty( changedAttribute ) )
				{
					delete _attributesLastTouchedRemotely[ changedAttribute ];
				}
			}
		}

		
		private var _attributesLastTouchedRemotely:Object = new Object;
		
		private var _setCommandQueue:Vector.<QueuedRemoteSetCommand> = new Vector.<QueuedRemoteSetCommand>;
		private var _processQueueTimer:Timer = new Timer( 1, 1 );
		private var _flushingProcessQueue:Boolean = false;

		private static var _singleInstance:RemoteCommandHandler = null;
		
		private static const XMLRPC_COMMAND:String = "public_api";
	}
}
