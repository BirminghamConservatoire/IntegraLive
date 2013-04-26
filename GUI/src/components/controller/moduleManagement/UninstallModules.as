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


package components.controller.moduleManagement
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.InstallEvent;
	import components.controller.serverCommands.UnloadModule;
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	

	public class UninstallModules extends ServerCommand
	{
		public function UninstallModules( modulesGuidsToUninstall:Vector.<String> )
		{
			super();
			
			_modulesGuidsToUninstall = modulesGuidsToUninstall;  

			_loadCompleteDispatcher = new EventDispatcher;
			_modelLoader = new ModelLoader( _loadCompleteDispatcher );
			_modelLoader.serverUrl = IntegraController.singleInstance.serverUrl;
		}
		

		public function get modulesGuidsToUninstall():Vector.<String> { return _modulesGuidsToUninstall; }
		public function get deleteInstances():Boolean { return _deleteInstances; }
		
		public function set deleteInstances( deleteInstances:Boolean ):void { _deleteInstances = deleteInstances; }
		
		
		
		public static function doFileDialog( model:IntegraModel, modulesGuidsToUninstall:Vector.<String> ):void
		{
			Assert.assertNull( _uninstaller );
			
			_uninstaller = new UninstallModules( modulesGuidsToUninstall );
			
			var messageText:String = "You have chosen to uninstall ";
			if( modulesGuidsToUninstall.length == 1 )
			{
				messageText += model.getInterfaceDefinitionByModuleGuid( modulesGuidsToUninstall[ 0 ] ).interfaceInfo.name;
			}
			else
			{
				messageText += String( modulesGuidsToUninstall.length ) + " modules";
			}
			
			messageText += ".\n\nWarning: this operation cannot be undone.";
			
			if( _uninstaller.areAnyModulesInUse( model, modulesGuidsToUninstall ) )
			{
				messageText += "\n\nNote: there are instances of these modules in the current project!";
				var prevNoLabel:String = Alert.noLabel;
				var prevYesLabel:String = Alert.yesLabel;
				Alert.noLabel = "Embed";
				Alert.yesLabel = "Delete";
				
				var flags:uint = Alert.YES | Alert.NO | Alert.CANCEL;
			}
			else
			{
				messageText += "\n\nWould you like to proceed?";
				
				flags = Alert.OK | Alert.CANCEL;
			}
			
			var alert:Alert = Alert.show( messageText, "Uninstall Modules", flags, null, _uninstaller.alertCloseHandler );

			Alert.noLabel = prevNoLabel;
			Alert.yesLabel = prevYesLabel;
		}
				
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return ( _modulesGuidsToUninstall.length > 0 );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			if( _deleteInstances )
			{
				var guidMap:Object = new Object;
				for each( var guid:String in _modulesGuidsToUninstall )
				{
					guidMap[ guid ] = 1;
				}
	
				for each( var track:Track in model.project.tracks )
				{
					for each( var block:Block in track.blocks )
					{
						for each( var module:ModuleInstance in block.modules )
						{
							if( guidMap.hasOwnProperty( module.interfaceDefinition.moduleGuid ) )
							{
								controller.processCommand( new UnloadModule( module.id ) );
							}
						}
					}
				}			
			}
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			const maximumDescriptionItems:int = 3;
			
			var methodCalls:Array = new Array;
			
			var description:String = "Uninstalling...  ";
			var count:int = 0;
			
			for each( var moduleID:String in _modulesGuidsToUninstall )
			{
				if( count < maximumDescriptionItems )
				{
					var title:String = model.getInterfaceDefinitionByModuleGuid( moduleID ).interfaceInfo.name;
					if( count > 0 ) description += ", ";
					description += title;
					count++;
					if( count == maximumDescriptionItems )
					{
						description += ( " <more modules>" );
					}
				}
				
				var methodCall:Object = new Object;
				
				methodCall.methodName = "module.uninstallmodule";
				methodCall.params = [ moduleID ];
				
				methodCalls.push( methodCall );
			}
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
			
			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.STARTED, description ) );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			var removedModuleGuids:Array = [];
			var embeddedModuleGuids:Array = [];
			
			for( var i:int = 0; i < response.length; i++ )
			{
				var responseNode:Object = response[ i ][ 0 ];
				var moduleID:String = _modulesGuidsToUninstall[ i ];
				
				switch( responseNode.response )
				{
					case "module.uninstallmodule":
						if( responseNode.remainsasembedded )
						{
							embeddedModuleGuids.push( moduleID );
						}
						else
						{
							removedModuleGuids.push( moduleID );
						}
						break;
					
					case "error":
						Trace.error( responseNode.errortext );
						break;

					case "default":
						Trace.error( "unexpected response", responseNode.response );
						break;
				}
			}
			
			IntegraModel.singleInstance.removeInterfaceDefinitions( removedModuleGuids );
			IntegraModel.singleInstance.handleModuleSourcesChanged( embeddedModuleGuids, InterfaceDefinition.MODULE_THIRD_PARTY, InterfaceDefinition.MODULE_EMBEDDED );

			
			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.FINISHED ) );

			_uninstaller = null;
			
			return true;
		}
		
		
		private function alertCloseHandler( event:CloseEvent ):void
		{
			switch( event.detail )
			{
				case Alert.CANCEL:
					_uninstaller = null;
					break;
					
				case Alert.YES:
					_uninstaller.deleteInstances = true;
					//intentionally drop through to next case
					
				case Alert.NO:
				case Alert.OK:
					
					var controller:IntegraController = IntegraController.singleInstance;
					controller.processCommand( this );
					controller.clearUndoStack();
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}
		}
		
		
		private function areAnyModulesInUse( model:IntegraModel, modulesGuids:Vector.<String> ):Boolean
		{
			var guidMap:Object = new Object;
			for each( var guid:String in modulesGuids )
			{
				guidMap[ guid ] = 1;
			}
			
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					for each( var module:ModuleInstance in block.modules )
					{
						if( guidMap.hasOwnProperty( module.interfaceDefinition.moduleGuid ) )
						{
							return true;
						}
					}
				}
			}
			
			return false;
		}
		
		private var _modulesGuidsToUninstall:Vector.<String>;
		private var _deleteInstances:Boolean = false;

		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;
		
		static private var _uninstaller:UninstallModules = null;
	}
}