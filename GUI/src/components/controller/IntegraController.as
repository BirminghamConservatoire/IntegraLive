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
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	
	import mx.controls.Alert;
	
	import __AS3__.vec.Vector;
	
	import components.controller.events.AllDataChangedEvent;
	import components.controller.events.IntegraCommandEvent;
	import components.controller.events.LoadCompleteEvent;
	import components.controller.events.LoadFailedEvent;
	import components.controller.events.SaveFailedEvent;
	import components.controller.events.ServerShutdownEvent;
	import components.controller.serverCommands.AddBlock;
	import components.controller.serverCommands.AddTrack;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.ResetAllBlocks;
	import components.controller.serverCommands.SetObjectInfo;
	import components.controller.serverCommands.StoreUserData;
	import components.controller.undostack.UndoManager;
	import components.controller.userDataCommands.PollForUpgradableModules;
	import components.controller.userDataCommands.SetProjectModified;
	import components.model.Block;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.Project;
	import components.model.modelLoader.ModelLoader;
	import components.model.preferences.AudioSettings;
	import components.model.preferences.MidiSettings;
	import components.utils.IntegraConnection;
	import components.utils.ModalState;
	import components.utils.Trace;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;

	
	public class IntegraController extends EventDispatcher
	{
		public function IntegraController()
		{
			Assert.assertNull( _singleInstance );	//shouldn't create more than one controller

			_model = IntegraModel.singleInstance;
			
			addEventListener( LoadCompleteEvent.EVENT_NAME, onLoadComplete );
			
			_modelLoader = new ModelLoader( this );
		}
		
		
		public static function get singleInstance():IntegraController
		{
			if( !_singleInstance ) _singleInstance = new IntegraController;
			return _singleInstance;
		} 


		public function get serverUrl():String 
		{ 
			return _serverUrl; 
		}
		
		
		public function set serverUrl( serverUrl:String ):void
		{
			_serverUrl = serverUrl;
			_modelLoader.serverUrl = serverUrl;
		}


		public function processCommand( command:Command ):Boolean
		{
			if( !command.initialize( _model ) )
			{
				return false;
			}

			if( command is ServerCommand )
			{
				RemoteCommandHandler.singleInstance.flushProcessQueue();
			}
			
			command.preChain( _model, this );
			
			command.generateInverse( _model );

			if( _activeUndoStack )
			{
				if( _undoManager.storeCommand( command ) )
				{
					_previousServerCommand = null;
				}
			}
			else
			{
				_undoManager.startInactivityTimer();
			}

			innerProcessMethod( command );
			
			command.postChain( _model, this );

			if( command is UserDataCommand )
			{
				var objectIDs:Vector.<int> = new Vector.<int>;
				( command as UserDataCommand ).getObjectsWhoseUserDataIsAffected( _model, objectIDs );
				for each( var objectID:int in objectIDs )
				{
					processCommand( new StoreUserData( objectID ) );
				}
			}

			if( _activeUndoStack && command.isNewUndoStep )
			{
				Assert.assertFalse( command is SetProjectModified );
				
				processCommand( new SetProjectModified( true ) );
			}
			
			return true;
		}	
		
		
		public function processRemoteCommand( commandResponse:RemoteCommandResponse ):void
		{
			Assert.assertNotNull( commandResponse );
			
			if( ModalState.isInModalState )
			{
				return;		//do nothing if already reloading
			}
			
			switch( commandResponse.response )
			{
				case RemoteCommandResponse.HANDLE_COMMAND:

					var guiCommand:ServerCommand = commandResponse.command;
					Assert.assertNotNull( guiCommand );

					activateUndoStack = false;
					guiCommand.preChain( _model, this );
					activateUndoStack = true;

					guiCommand.execute( _model );
					
					dispatchEvent( new IntegraCommandEvent( guiCommand ) );
					
					activateUndoStack = false;
					guiCommand.postChain( _model, this );
					activateUndoStack = true;

					return;
					
				case RemoteCommandResponse.RELOAD_ALL:
					
					loadModel();
					return;			
					
				case RemoteCommandResponse.IGNORE:
					
					return;
					
				default:
					Assert.assertTrue( false );
					return;			
			}
		}


		public function loadModel():void
		{
			_undoManager.clear();
			_model.clearAll();

			dispatchEvent( new AllDataChangedEvent( false ) );
			
			_modelLoader.loadModel();
		}


		public function newProject():void
		{
			//wipe the existing project
			var newProjectCall:IntegraConnection = new IntegraConnection( _serverUrl );
			newProjectCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			newProjectCall.addArrayParam( _model.getPathArrayFromID( _model.project.id ) );
			newProjectCall.callQueued( "command.delete" );
			
			//unload unused embedded modules
			var unloadUnusedEmbeddedModulesCall:IntegraConnection = new IntegraConnection( _serverUrl );
			unloadUnusedEmbeddedModulesCall.addEventListener( Event.COMPLETE, newProjectHandler );
			unloadUnusedEmbeddedModulesCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			unloadUnusedEmbeddedModulesCall.callQueued( "module.unloadunusedembedded" );
		}


		public function loadProject( filename:String ):void
		{
			//wipe the existing project
			var newProjectCall:IntegraConnection = new IntegraConnection( _serverUrl );
			newProjectCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			newProjectCall.addArrayParam( _model.getPathArrayFromID( _model.project.id ) );
			newProjectCall.callQueued( "command.delete" );

			//unload unused embedded modules
			var unloadUnusedEmbeddedModulesCall:IntegraConnection = new IntegraConnection( _serverUrl );
			unloadUnusedEmbeddedModulesCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			unloadUnusedEmbeddedModulesCall.callQueued( "module.unloadunusedembedded" );
			
			//load the new project
			var loadProjectCall:IntegraConnection = new IntegraConnection( _serverUrl );
			loadProjectCall.addEventListener( Event.COMPLETE, loadProjectHandler );
			loadProjectCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			loadProjectCall.addParam( filename, XMLRPCDataTypes.STRING );
			loadProjectCall.addArrayParam( new Array() );	//load into root level
			loadProjectCall.callQueued( "command.load" );
		}
		
		
		public function saveProject( filename:String ):void
		{
			var saveProjectCall:IntegraConnection = new IntegraConnection( _serverUrl );
			saveProjectCall.addEventListener( Event.COMPLETE, saveProjectHandler );
			saveProjectCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			saveProjectCall.addArrayParam( _model.getPathArrayFromID( _model.project.id ) ); //save from project node
			saveProjectCall.addParam( filename, XMLRPCDataTypes.STRING );
			saveProjectCall.callQueued( "command.save" );
		}
		
		
		public function exportModule( filename:String ):void
		{
			Assert.assertNotNull( _model.primarySelectedModule );
			
			var exportModuleCall:IntegraConnection = new IntegraConnection( _serverUrl );
			exportModuleCall.addEventListener( Event.COMPLETE, exportCompleteHandler );
			exportModuleCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			exportModuleCall.addArrayParam( _model.getPathArrayFromID( _model.primarySelectedModule.id ) );//save from block node
			exportModuleCall.addParam( filename, XMLRPCDataTypes.STRING );
			exportModuleCall.callQueued( "command.save" );
		}


		public function exportBlock( filename:String ):void
		{
			Assert.assertNotNull( _model.primarySelectedBlock );
			
			var exportBlockCall:IntegraConnection = new IntegraConnection( _serverUrl );
			exportBlockCall.addEventListener( Event.COMPLETE, exportCompleteHandler );
			exportBlockCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			exportBlockCall.addArrayParam( _model.getPathArrayFromID( _model.primarySelectedBlock.id ) );//save from block node
			exportBlockCall.addParam( filename, XMLRPCDataTypes.STRING );
			exportBlockCall.callQueued( "command.save" );
		}


		public function exportTrack( filename:String ):void
		{
			Assert.assertNotNull( _model.selectedTrack );
			
			var exportTrackCall:IntegraConnection = new IntegraConnection( _serverUrl );
			exportTrackCall.addEventListener( Event.COMPLETE, exportCompleteHandler );
			exportTrackCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			exportTrackCall.addArrayParam( _model.getPathArrayFromID( _model.selectedTrack.id ) );//save from track node
			exportTrackCall.addParam( filename, XMLRPCDataTypes.STRING );
			exportTrackCall.callQueued( "command.save" );
		}
		
		
		public function introspectServer():void
		{
			var listMethodsCall:IntegraConnection = new IntegraConnection( _serverUrl );
			listMethodsCall.addEventListener( Event.COMPLETE, listMethodsHandler );
			listMethodsCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			listMethodsCall.callQueued( "system.listMethods" );
		}

		
		public function dumpLibIntegraState():void
		{
			var dumpStateCall:IntegraConnection = new IntegraConnection( _serverUrl );
			dumpStateCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			dumpStateCall.callQueued( "system.dumplibintegrastate" );
		}

		
		public function dumpDspState( filepath:String ):void
		{
			var dumpStateCall:IntegraConnection = new IntegraConnection( _serverUrl );
			dumpStateCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			dumpStateCall.addParam( filepath, XMLRPCDataTypes.STRING );
			dumpStateCall.callQueued( "system.dumpdspstate" );
		}
		
		
		public function shutdownServer():void
		{
			saveAudioSettings();			
			saveMidiSettings();
			
			var shutdownCall:IntegraConnection = new IntegraConnection( _serverUrl );
			shutdownCall.addEventListener( Event.COMPLETE, serverShutdownHandler );
			shutdownCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
			shutdownCall.addParam( "shutdown by gui", XMLRPCDataTypes.STRING );
			shutdownCall.callQueued( "system.shutdown" );
		}

		
		public function get canUndo():Boolean
		{
			return _undoManager.canUndo;
		}

		public function get canRedo():Boolean
		{
			return _undoManager.canRedo;
		}


		public function doUndo():void
		{
			_undoManager.doUndo( innerProcessMethod );
		}


		public function doRedo():void
		{
			_undoManager.doRedo( innerProcessMethod );
		}


		public function set activateUndoStack( activeUndoStack:Boolean ):void
		{
			_activeUndoStack = activeUndoStack;
		}
		
		
		public function clearUndoStack():void
		{
			_undoManager.clear();
		}
		
		
		public function appendNextCommandsIntoPreviousTransaction():void
		{
			_undoManager.startInactivityTimer();
		}
		
		
		private function innerProcessMethod( command:Command ):void
		{
			if( command is ServerCommand )
			{
				var serverCommand:ServerCommand = command as ServerCommand;
				Assert.assertNotNull( serverCommand );
				
				var isReplacementOfPreviousCommand:Boolean = false;
				if( _previousServerCommand && Utilities.getClassNameFromObject( _previousServerCommand ) == Utilities.getClassNameFromObject( command ) )
				{
					if( serverCommand.canReplacePreviousCommand( _previousServerCommand ) )
					{
						isReplacementOfPreviousCommand = true;
						
						//this clause improves the performance of the outgoing xmlrpc command queue 
						//so that outgoing commands are dropped from the queue when a newer command 
						//entirely replaces the previous command (ie command.set on same attribute)
						IntegraConnection.removeLastQueuedCommand();
					}
				}
				
				_previousServerCommand = serverCommand;
				
				serverCommand.createConnection( _serverUrl );
				serverCommand.executeServerCommand( _model );
				
				var changedAttributes:Vector.<String> = new Vector.<String>;
				serverCommand.getAttributesChangedByThisCommand( _model, changedAttributes );
				RemoteCommandHandler.singleInstance.onAttributesChangedLocally( changedAttributes );
				
				if( !isReplacementOfPreviousCommand )
				{
					traceCommand( command as ServerCommand );
				}
			}
			
			command.execute( _model );
			

			//update views
			dispatchEvent( new IntegraCommandEvent( command ) );
		}

		
		private function traceCommand( command:ServerCommand ):void
		{
			if( command.omitFromTrace() )
			{
				return;
			}
						
			var className:String = Utilities.getClassNameFromObject( command );

			var traceString:String = className + "(";
			
			//trace value from all 'getter' methods (except those declared in a superclass)
			
			var commandAccessors:XMLList = describeType( command )..accessor;
			var first:Boolean = true;
			
			for each( var accessor:XML in commandAccessors )
			{
				if( accessor.@access == "writeonly" )
				{
					continue;	//skip if no getter is defined
				}
				
				if( Utilities.getClassNameFromQualifiedClassName( accessor.@declaredBy ) != className )
				{
					continue;	//skip if declared by a superclass 
				}
				
				var getterName:String = accessor.@name;

				if( first )
				{
					first = false;					
				}
				else
				{
					traceString += ",";
				}
				
				var value:Object = command[ getterName ];
				var valueString:String = "null";
				
				if( value )
				{
					valueString = value.toString();

					//if attribute seems to be an ID, try to retrieve the object name!
					if( accessor.@type == "int" && getterName.substr( -2 ) == "ID" )
					{
						var id:int = value as int; 
						if( _model.doesObjectExist( id ) )
						{
							valueString += ( "<" + _model.getDataObjectByID( id ).name + ">" );
						}
						else
						{
							valueString += "<object doesn't exist>";
						}
					}
				}
				
				traceString += ( " " + getterName + " = " + valueString ); 
			}

			traceString += ")";
			
			Trace.progress( traceString ); 
		}
		

		private function newProjectHandler( newProjectEvent:Event ):void
		{
			loadModel();			
		}


		private function loadProjectHandler( loadProjectEvent:Event ):void
		{
			var response:Object = loadProjectEvent.target.getResponse();
			if( response.response != "command.load" )
			{
				dispatchEvent( new LoadFailedEvent( "Cannot load project:\n\n" + response.errortext ) );
			}

			loadModel();			
		}


		private function saveProjectHandler( saveProjectEvent:Event ):void
		{
			var response:Object = saveProjectEvent.target.getResponse();
			if( response.response != "command.save" )
			{
				dispatchEvent( new SaveFailedEvent( "Cannot save project:\n\n" + response.errortext ) );
			}
			else
			{
				processCommand( new SetProjectModified( false ) );
			}
		}
		
		
		private function exportCompleteHandler( exportEvent:Event ):void
		{
			var response:Object = exportEvent.target.getResponse();
			Assert.assertTrue( response.response == "command.save" );
			
			dispatchEvent( new AllDataChangedEvent() );
		}
		
		
		private function listMethodsHandler( listMethodsEvent:Event ):void
		{
			var response:Array = listMethodsEvent.target.getResponse() as Array;
			Assert.assertNotNull( response );

			_serverMethodsToMethodSignatureCalls = new Object;
			_serverMethodsToMethodHelpCalls = new Object;
			_outstandingIntrospectionCalls = 0;
			
			for each( var methodName:String in response )
			{
				var methodSignatureCall:IntegraConnection = new IntegraConnection( _serverUrl );
				methodSignatureCall.addEventListener( Event.COMPLETE, receivedIntrospectionResult );
				methodSignatureCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
				methodSignatureCall.addParam( methodName, XMLRPCDataTypes.STRING ); 
				methodSignatureCall.callQueued( "system.methodSignature" );
				_serverMethodsToMethodSignatureCalls[ methodName ] = methodSignatureCall;
				_outstandingIntrospectionCalls++;			
				
				var methodHelpCall:IntegraConnection = new IntegraConnection( _serverUrl );
				methodHelpCall.addEventListener( Event.COMPLETE, receivedIntrospectionResult );
				methodHelpCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
				methodHelpCall.addParam( methodName, XMLRPCDataTypes.STRING ); 
				methodHelpCall.callQueued( "system.methodHelp" );
				_serverMethodsToMethodHelpCalls[ methodName ] = methodHelpCall;
				_outstandingIntrospectionCalls++;			
			}
		}


		private function receivedIntrospectionResult( event:Event ):void
		{
			_outstandingIntrospectionCalls--;
			if( _outstandingIntrospectionCalls == 0 )
			{
				for( var methodName:String in _serverMethodsToMethodHelpCalls )
				{
					Trace.progress( methodName + ": signature = [" + _serverMethodsToMethodSignatureCalls[ methodName ].getResponse().toString() + "], help = [" +_serverMethodsToMethodHelpCalls[ methodName ].getResponse().toString() + "]" );  
				}
			}
		}
		
		
		private function serverShutdownHandler( event:Event ):void
		{
			dispatchEvent( new ServerShutdownEvent ); 
		}
		
		
		private function rpcErrorHandler( event:ErrorEvent ):void
		{
			Alert.show( "xmlrpc error!\n", "Integra Live", mx.controls.Alert.OK );

			//todo - implement?			
		}
		
		
		private function onLoadComplete( event:LoadCompleteEvent ):void
		{
			processCommand( new ResetAllBlocks() );

			if( event.shouldCreateDefaultObjects )
			{
				createDefaultObjects();
			}

			processCommand( new SetProjectModified( false ) );
			
			processCommand( new PollForUpgradableModules( _model.project.id ) );
			
			_undoManager.clear();

			dispatchEvent( new AllDataChangedEvent() );
		}
		
		
		private function createDefaultObjects():void
		{
			processCommand( new SetObjectInfo( _model.project.id, InfoMarkupForViews.instance.getInfoForView( "ArrangeView/ArrangeView" ).markdown ) );
			
			var addTrackCommand:AddTrack = new AddTrack();
			processCommand( addTrackCommand );
			
			var addBlockCommand:AddBlock = new AddBlock( addTrackCommand.trackID, 0, Block.newBlockSeconds * _model.project.player.rate ); 
			processCommand( addBlockCommand );
		}
		
		
		private function saveAudioSettings():void
		{
			var audioSettings:AudioSettings = _model.audioSettings;
			
			if( audioSettings.hasChangedSinceReset )
			{
				var saveAudioSettingsCall:IntegraConnection = new IntegraConnection( _serverUrl );
				saveAudioSettingsCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
				saveAudioSettingsCall.addArrayParam( [ audioSettings.name ] );
				saveAudioSettingsCall.addParam( AudioSettings.localFile.nativePath, XMLRPCDataTypes.STRING );
				saveAudioSettingsCall.callQueued( "command.save" );
			}
		}
		
		
		private function saveMidiSettings():void
		{
			var midiSettings:MidiSettings = _model.midiSettings;
			
			if( midiSettings.hasChangedSinceReset )
			{
				var saveMidiSettingsCall:IntegraConnection = new IntegraConnection( _serverUrl );
				saveMidiSettingsCall.addEventListener( ErrorEvent.ERROR, rpcErrorHandler );
				saveMidiSettingsCall.addArrayParam( [ midiSettings.name ] );
				saveMidiSettingsCall.addParam( MidiSettings.localFile.nativePath, XMLRPCDataTypes.STRING );
				saveMidiSettingsCall.callQueued( "command.save" );	
			}
		}
		
		
		private var _serverUrl:String;

		private var _model:IntegraModel;
		private var _modelLoader:ModelLoader;

		private var _undoManager:UndoManager = new UndoManager();

		private var _serverMethodsToMethodSignatureCalls:Object = null;
		private var _serverMethodsToMethodHelpCalls:Object = null;
		private var _outstandingIntrospectionCalls:int = 0;
		
		private var _activeUndoStack:Boolean = true;
		
		private var _previousServerCommand:ServerCommand = null;

		private static var _singleInstance:IntegraController = null;
	}
}

