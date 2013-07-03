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
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.InstallEvent;
	import components.controller.events.LoadCompleteEvent;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
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
		
		
		public static function installModules( files:Array ):void
		{
			Assert.assertNull( _installer );
			
			_installer = new InstallModules();

			_installer.doInstall( files );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			const maximumDescriptionItems:int = 3;
			
			var methodCalls:Array = new Array;
			
			var description:String = "Installing...  ";
			var count:int = 0;
			
			for each( var file:File in _filesToInstall )
			{
				if( count < maximumDescriptionItems )
				{
					var title:String = getFileTitle( file );
					if( count > 0 ) description += ", ";
					description += title;
					count++;
					if( count == maximumDescriptionItems )
					{
						description += ( " <more files>" );
					}
				}
				
				var methodCall:Object = new Object;

				if( isModuleInDevelopment( file ) )
				{
					methodCall.methodName = "module.loadmoduleindevelopment";
					methodCall.params = [ file.nativePath ];
				}
				else
				{
					methodCall.methodName = "module.installintegramodulefile";
					methodCall.params = [ file.nativePath ];
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
			_resultsString = "Install Modules\n";
			
			var newModuleGuids:Array = [];
			var previouslyEmbeddedModuleGuids:Array = [];
			var previouslyInDevelopmentModuleGuids:Array = [];
			var removedModuleGuids:Array = [];
			
			var installedModuleInDevelopment:Boolean = false;

			
			for( var i:int = 0; i < response.length; i++ )
			{
				_resultsString += "\n* " + _fileTitles[ i ];
					
				var responseNode:Object = response[ i ][ 0 ];
				
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
					
					case "module.loadmoduleindevelopment":
						newModuleGuids.push( responseNode.moduleid );
						installedModuleInDevelopment = true;
						if( responseNode.hasOwnProperty( "previousmoduleid" ) )
						{
							if( responseNode.previousremainsasembedded )
							{
								previouslyInDevelopmentModuleGuids.push( responseNode.previousmoduleid );
							}
							else
							{
								removedModuleGuids.push( responseNode.previousmoduleid );
							}
						}
						
						break;
					
					case "error":
						Trace.error( responseNode.errortext );
						_resultsString += " " + responseNode.errortext;
						break;

					default:
						Trace.error( "unexpected response", responseNode.response );
						_resultsString += " unexpected response from server";
						break;
				}
			}
			
			if( installedModuleInDevelopment )
			{
				_resultsString = "##Loaded an in-development module";
			}
			
			IntegraModel.singleInstance.removeInterfaceDefinitions( removedModuleGuids );
			IntegraModel.singleInstance.handleModuleSourcesChanged( previouslyEmbeddedModuleGuids, InterfaceDefinition.MODULE_EMBEDDED, InterfaceDefinition.MODULE_THIRD_PARTY );
			IntegraModel.singleInstance.handleModuleSourcesChanged( previouslyInDevelopmentModuleGuids, InterfaceDefinition.MODULE_IN_DEVELOPMENT, InterfaceDefinition.MODULE_EMBEDDED );

			if( newModuleGuids.length > 0 )
			{
				_modelLoader.loadNewlyInstalledInterfaceDefinitions( newModuleGuids );
			}
			else
			{
				onInterfacesLoaded( null );
			}
			
			deleteUnpackedBundleModules();
			
			return true;
		}
		
		
		private function onSelectFilesToInstall( event:FileListEvent ):void
		{
			doInstall( event.files );
		}

		
		private function doInstall( files:Array ):void
		{
			getFilesToInstall( files );
			
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
			
			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.FINISHED, _resultsString ) );
		}

		
		private function getFileTitle( file:File ):String
		{
			if( file.extension )
			{
				return file.name.substr( 0, file.name.length - file.extension.length - 1 );
			}
			else
			{
				return file.name;
			}
		}
		
		private function getFilesToInstall( pickedFiles:Array ):void
		{
			_filesToInstall = new Array;
			_fileTitles = new Vector.<String>;
			_unpackedBundleFiles = new Array;
			
			for each( var file:File in pickedFiles )
			{
				if( file.isDirectory ) continue;

				switch( file.extension.toLowerCase() )
				{
					case Utilities.moduleFileExtension:
						_filesToInstall.push( file );
						_fileTitles.push( getFileTitle( file ) );
						break;
					
					case Utilities.bundleFileExtension:
						unpackBundleFile( file );
						break;
					
					default:
						Assert.assertTrue( false );	 //unhandled file extension
						break;
				}
			}
		}

		
		private function unpackBundleFile( bundleFile:File ):void
		{
			var fileStream:FileStream = new FileStream();
			fileStream.open( bundleFile, FileMode.READ );
			var rawBytes:ByteArray = new ByteArray();
			fileStream.readBytes( rawBytes );
			fileStream.close();			
			
			var bundleZipFile:FZip = new FZip();
			bundleZipFile.loadBytes( rawBytes );			

			var numberOfFiles:uint = bundleZipFile.getFileCount();
			for( var i:int = 0; i < numberOfFiles; i++ )
			{
				var moduleFile:FZipFile = bundleZipFile.getFileAt( i );
				var moduleFileName:String = moduleFile.filename;
				var moduleFileExtension:String = Utilities.moduleFileExtension;
				var moduleFileExtensionLength:int = moduleFileExtension.length;
				
				if( moduleFileName.length <= moduleFileExtensionLength || moduleFileName.substr( -moduleFileExtensionLength ) != moduleFileExtension )
				{
					Trace.error( "Found bundle content with incorrect extension", moduleFileName );
					continue;
				}
				
				var outputFile:File = File.createTempFile();
				
				var outputFileStream:FileStream = new FileStream;
				outputFileStream.open( outputFile, FileMode.WRITE );
				outputFileStream.writeBytes( moduleFile.content );
				outputFileStream.close();
					
				_unpackedBundleFiles.push( outputFile );
				_filesToInstall.push( outputFile );
				
				var title:String = moduleFileName.substr( 0, moduleFileName.length - moduleFileExtensionLength - 1 );
				_fileTitles.push( title );
			}	
		}
		
		
		private function deleteUnpackedBundleModules():void
		{
			for each( var file:File in _unpackedBundleFiles )
			{
				file.deleteFile();
			}
		}
		
		
		private function isModuleInDevelopment( file:File ):Boolean
		{
			return ( file.name == Utilities.moduleInDevelopmentFileName );
		}
		

		private var _fileDialog:File;
		private var _filesToInstall:Array;
		private var _fileTitles:Vector.<String>;

		private var _unpackedBundleFiles:Array;
		
		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;
		
		private var _resultsString:String;
		
		private static var _installer:InstallModules = null;
		
	}
}