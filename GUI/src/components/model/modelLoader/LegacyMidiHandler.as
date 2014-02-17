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



package components.model.modelLoader
{
	import flash.events.Event;
	
	import components.controller.IntegraController;
	import components.controller.serverCommands.AddMidiControlInput;
	import components.controller.serverCommands.RemoveConnection;
	import components.controller.serverCommands.RemoveScaledConnection;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetMidiControlInputValues;
	import components.controller.serverCommands.SetScalerInputRange;
	import components.controller.serverCommands.SetScalerOutputRange;
	import components.model.Connection;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.IntegraConnection;
	import components.utils.Trace;
	import components.views.RibbonBar.MidiInputIndicator;
	
	import flexunit.framework.Assert;

	public class LegacyMidiHandler
	{
		public function LegacyMidiHandler()
		{
			Assert.assertNull( _theInstance );
		}
		
		
		static public function get instance():LegacyMidiHandler
		{
			if( !_theInstance ) 
			{
				_theInstance = new LegacyMidiHandler;
			}
			
			return _theInstance;
		}
		
		
		public function set serverUrl( serverUrl:String ):void
		{
			_serverUrl = serverUrl;
		}		
		
		
		public function isLegacyMidiModule( interfaceDefinition:InterfaceDefinition ):Boolean
		{
			return ( interfaceDefinition.originGuid == LEGACY_MIDI_ORIGIN_GUID );
		}
		
		
		public function clear():void
		{
			_midiModulePaths.length = 0;
			_midiConnectionSources = new Object;
		}
			
			
		public function storeLegacyMidiModulePath( path:Array ):void
		{
			_midiModulePaths.push( path );
		}
		
		
		//returns true if missing connection source originates from a legacy midi module
		public function handleMissingConnectionSource( connectionID:int, sourcePath:Array, endpointName:String ):Boolean
		{
			if( isMidiModulePath( sourcePath ) >= 0 )
			{
				_midiConnectionSources[ connectionID ] = endpointName;
				return true;
			}
			
			return false; 			
		}
		
		
		public function translateToNewModules():void
		{
			deleteLegacyMidiModules();
			
			createAndConnectNewModules();
		}
		
		
		private function isMidiModulePath( path:Array ):Boolean
		{
			//deep compare
			for each( var midiModulePath:Array in _midiModulePaths )
			{
				if( path.length != midiModulePath.length ) 
				{
					return false;
				}
				
				for( var i:int = 0; i < path.length; i++ )
				{
					if( path[ i ] != midiModulePath[ i ] )
					{
						return false;
					}
				}
			}
			
			return true;
		}
		

		private function deleteLegacyMidiModules():void
		{
			/* 
			 Delete the legacy midi modules.  Do this by directly sending commands to the backend, since
			 they have no representation in the gui's model
			*/
			
			var multiCall:Array = new Array;
			for each( var midiModulePath:Array in _midiModulePaths )
			{
				var deleteCall:Object = new Object;
				deleteCall.methodName = "command.delete";
				deleteCall.params = [ midiModulePath ];
				multiCall.push( deleteCall );
			}
			
			Assert.assertNotNull( _serverUrl );
			var deleteObjectsCall:IntegraConnection = new IntegraConnection( _serverUrl );
			deleteObjectsCall.addArrayParam( multiCall );
			deleteObjectsCall.callQueued( "system.multicall" );
		}
		
		
		private function createAndConnectNewModules():void
		{
			var controller:IntegraController = IntegraController.singleInstance;
			var model:IntegraModel = IntegraModel.singleInstance;
			
			for( var oldConnectionIDString:String in _midiConnectionSources )
			{
				var oldConnectionID:int = int( oldConnectionIDString );
				var oldEndpointName:String = _midiConnectionSources[ oldConnectionID ];
				var messageType:String;
				var noteOrController:int;
				if( oldEndpointName.substr( 0, CC_PREFIX.length ) == CC_PREFIX ) 
				{
					messageType = MidiControlInput.CC;
					noteOrController = int( oldEndpointName.substr( CC_PREFIX.length ) );
				}
				else
				{
					if( oldEndpointName.substr( 0, NOTE_PREFIX.length ) == NOTE_PREFIX ) 
					{
						messageType = MidiControlInput.NOTEON;
						noteOrController = int( oldEndpointName.substr( NOTE_PREFIX.length ) );
					}
					else
					{
						Trace.error( "Failed to resolve legacy midi endpoint name", oldEndpointName );
						continue;
					}
				}
				
				var oldConnection:Connection = model.getConnection( oldConnectionID );
				Assert.assertNotNull( oldConnection );
				
				if( !model.doesObjectExist( oldConnection.targetObjectID ) )
				{
					//broken connection - remove it and don't create anything new
					controller.processCommand( new RemoveConnection( oldConnectionID ) );
					continue;
				}
				
				//create new midi control input
				var addMidiControlInputCommand:AddMidiControlInput = new AddMidiControlInput( oldConnection.parentID );
				controller.processCommand( addMidiControlInputCommand );
				var midiControlInputID:int = addMidiControlInputCommand.midiControlInputID;
				var midiControlInput:MidiControlInput = model.getMidiControlInput( midiControlInputID );
				Assert.assertNotNull( midiControlInput );
				
				//configure midi control input to relevent fields
				controller.processCommand( new SetMidiControlInputValues( midiControlInputID, MidiControlInput.ANY_DEVICE, 0, messageType, noteOrController ) );

				//connect everything 
				var oldMidiTarget:IntegraDataObject = model.getDataObjectByID( oldConnection.targetObjectID );
				var prevConnectionTargetID:int = -1;
				var prevConnectionTargetEndpointName:String = null;
				if( oldMidiTarget is Scaler )
				{
					//copy values into new scaler
					var oldScaler:Scaler = oldMidiTarget as Scaler;
					var newScaler:Scaler = midiControlInput.scaler;
					
					controller.processCommand( new SetScalerInputRange( newScaler.id, oldScaler.inRangeMin, oldScaler.inRangeMax ) );
					controller.processCommand( new SetScalerOutputRange( newScaler.id, oldScaler.outRangeMin, oldScaler.outRangeMax ) );
					
					//store target
					Assert.assertNotNull( oldScaler.downstreamConnection );
					prevConnectionTargetID = oldScaler.downstreamConnection.targetObjectID;
					prevConnectionTargetEndpointName = oldScaler.downstreamConnection.targetAttributeName;
					
					//delete old scaler
					controller.processCommand( new RemoveScaledConnection( oldScaler.id ) );
				}
				else
				{
					//store target
					prevConnectionTargetID = oldConnection.targetObjectID;
					prevConnectionTargetEndpointName = oldConnection.targetAttributeName;

					//delete connection
					controller.processCommand( new RemoveConnection( oldConnectionID ) );
				}
				
				//make new scaler control prev connection target
				var newDownstreamConnection:Connection = midiControlInput.scaler.downstreamConnection;
				Assert.assertNotNull( newDownstreamConnection );
				controller.processCommand( new SetConnectionRouting( newDownstreamConnection.id, newDownstreamConnection.sourceObjectID, newDownstreamConnection.sourceAttributeName, prevConnectionTargetID, prevConnectionTargetEndpointName ) );
				
			}			
		}

		
		private var _midiModulePaths:Vector.<Array> = new Vector.<Array>;	//paths of all legacy midi module instances
		
		private var _midiConnectionSources:Object = new Object;				//map of connection id -> unresolvable midi source endpoint

		private var _serverUrl:String = null;
		
		private static var _theInstance:LegacyMidiHandler = null;
		
		private static const LEGACY_MIDI_ORIGIN_GUID:String = "cb718748-f1ac-44fe-abbc-a997bcf06fe4";
		
		private static const CC_PREFIX:String = "cc";
		private static const NOTE_PREFIX:String = "note";
	}
}