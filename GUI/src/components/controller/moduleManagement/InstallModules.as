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
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.ImportEvent;
	import components.controller.events.InstallEvent;
	import components.controller.events.LoadCompleteEvent;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	
	public class InstallModules extends ServerCommand
	{
		public function InstallModules()
		{
			super();

			_loadCompleteDispatcher = new EventDispatcher;
			_modelLoader = new ModelLoader( _loadCompleteDispatcher );
			_modelLoader.serverUrl = IntegraController.singleInstance.serverUrl;
			
			_loadCompleteDispatcher.addEventListener( LoadCompleteEvent.EVENT_NAME, onInterfacesLoaded );
		}
		
		
		public static function doFileDialog():void
		{
			Assert.assertNull( _installer );
			
			_installer = new InstallModules();
			
			var typeFilter:Array = 
				[
					new FileFilter( "Modules and Module Bundles", "*." + Utilities.moduleFileExtension + ";*." + Utilities.bundleFileExtension ),
					new FileFilter( "Modules", "*." + Utilities.moduleFileExtension ),
					new FileFilter( "Module Bundles", "*." + Utilities.bundleFileExtension )
				];
			
			_installer._fileDialog = new File();
			_installer._fileDialog.addEventListener( FileListEvent.SELECT_MULTIPLE, _installer.onSelectFilesToInstall );
			_installer._fileDialog.addEventListener( Event.CANCEL, _installer.onCancelImport );
			_installer._fileDialog.browseForOpenMultiple( "Install Integra Module(s)", typeFilter )
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			const maximumDescriptionItems:int = 3;
			
			var methodCalls:Array = new Array;
			
			var description:String = "Installing...  ";
			var count:int = 0;
			
			for each( var file:File in _fileArray )
			{
				if( file.isDirectory ) continue;

				if( count < maximumDescriptionItems )
				{
					var title:String = file.name.substr( 0, file.name.length - file.extension.length - 1 );
					if( count > 0 ) description += ", ";
					description += title;
					count++;
					if( count == maximumDescriptionItems )
					{
						description += ( "  ... <more files>" );
					}
				}
				
				var methodCall:Object = new Object;
				
				switch( file.extension.toLowerCase() )
				{
					case Utilities.moduleFileExtension:
						methodCall.methodName = "module.installintegramodulefile";
						methodCall.params = [ file.nativePath ];
						break;

					case Utilities.bundleFileExtension:
						methodCall.methodName = "module.installintegrabundlefile";
						methodCall.params = [ file.nativePath ];
						break;
						
					default:
						Assert.assertTrue( false );
				}
				
				methodCalls.push( methodCall );
			}
			
			if( methodCalls.length == 0 )
			{
				_installer = null;
				return;
			}
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
			
			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.STARTED, description ) );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			var newModuleGuids:Array = [];
			var previouslyEmbeddedModuleGuids:Array = [];
			
			for each( var responseItem:Object in response )
			{
				var responseNode:Object = responseItem[ 0 ];
				
				switch( responseNode.response )
				{
					case "module.installintegramodulefile":
						if( responseNode.waspreviouslyembedded )
						{
							previouslyEmbeddedModuleGuids.push( responseNode.moduleid );
						}
						else
						{
							newModuleGuids.push( responseNode.moduleid );
						}
					
						break;
					
					case "module.installintegrabundlefile":
						newModuleGuids = newModuleGuids.concat( responseNode.newmoduleids );
						previouslyEmbeddedModuleGuids = newModuleGuids.concat( responseNode.previouslyembeddedmoduleids );
						break;
					
					case "error":
						Trace.error( responseNode.errortext );
						break;

					case "default":
						Trace.error( "unexpected response", responseNode.response );
						break;
				}
			}
			
			_modelLoader.handleModuleSourcesChanged( previouslyEmbeddedModuleGuids, InterfaceDefinition.MODULE_EMBEDDED, InterfaceDefinition.MODULE_THIRD_PARTY );

			if( newModuleGuids.length > 0 )
			{
				_modelLoader.loadNewlyInstalledInterfaceDefinitions( newModuleGuids );
			}
			else
			{
				onInterfacesLoaded( null );
			}
			
			return true;
		}
		
		
		private function onSelectFilesToInstall( event:FileListEvent ):void
		{
			_fileArray = event.files;
			
			var controller:IntegraController = IntegraController.singleInstance;
			controller.activateUndoStack = false;
			controller.processCommand( this );
			controller.activateUndoStack = true;
		}
		
		
		private function onCancelImport( event:Event ):void
		{
			_installer = null;
		}
		
		
		private function onInterfacesLoaded( event:Event ):void
		{
			_installer = null;
			
			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.FINISHED ) );
		}
				
		

		private var _fileDialog:File;
		private var _fileArray:Array;

		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;
		
		private static var _installer:InstallModules = null;
		
	}
}