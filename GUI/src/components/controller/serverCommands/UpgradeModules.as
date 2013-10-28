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
	import flash.filesystem.File;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.Project;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	public class UpgradeModules extends ServerCommand
	{
		public function UpgradeModules( searchObjectID:int )
		{
			super();
			
			_searchObjectID = searchObjectID; 
		}
		
		
		public function get searchObjectID():int { return _searchObjectID; }

		public function get upgradedObjectIDs():Vector.<int> { return _upgradedObjectIDs; }
		public function get upgradedModuleGuids():Vector.<String> { return _upgradedModuleGuids; }
		public function get backupName():String { return _backupName; }
		
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			return model.doesObjectExist( _searchObjectID );				
		}
		
		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var searchObject:IntegraDataObject = model.getDataObjectByID( _searchObjectID );
			Assert.assertNotNull( searchObject );
			
			if( !model.areThereAnyUpgradableModules( searchObject ) )
			{
				return;
			}				
				
			_backupName = getBackupName( model );
			controller.saveProject( _backupName );	
			
			for each( var moduleGuid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( moduleGuid );
				Assert.assertNotNull( interfaceDefinition );
				
				var alternativeVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				
				Assert.assertTrue( alternativeVersions.length > 0 );
				var bestVersion:InterfaceDefinition = alternativeVersions[ 0 ];
				
				if( interfaceDefinition != bestVersion )
				{
					var switchVersionsCommand:SwitchAllObjectVersions = new SwitchAllObjectVersions( _searchObjectID, interfaceDefinition.moduleGuid, bestVersion.moduleGuid ); 
					controller.processCommand( switchVersionsCommand );
					
					var switchedObjectIDs:Vector.<int> = switchVersionsCommand.switchedObjectIDs;
					if( switchedObjectIDs.length > 0 )
					{
						_upgradedObjectIDs = _upgradedObjectIDs.concat( switchVersionsCommand.switchedObjectIDs );
						upgradedModuleGuids.push( moduleGuid );
					}
				}
			}
		}
		
		
		static public function getBackupName( model:IntegraModel ):String
		{
			if( model.filename )
			{
				//build filename in form  <filename>(backup <n>).integra
				
				var file:File = new File( model.filename );
				var name:String = file.name;
				
				//strip extension
				if( file.extension )
				{
					name = name.substr( 0, name.length - file.extension.length - 1 );
				}
				
				//determine the directory				
				var directory:File = file.parent;
				if( !directory || !directory.exists || !directory.isDirectory )
				{
					directory = File.desktopDirectory;
				}
				
				return getUniqueBackupFileName( name, directory );
			}
			else
			{
				//no filename
				return getUniqueBackupFileName( Project.defaultProjectName, File.desktopDirectory );
			}
		}
		
		
		static private function getUniqueBackupFileName( title:String, directory:File ):String
		{
			for( var i:int = 1; true; i++ )
			{
				var backupNumber:String = (i > 1 ) ? " " + String( i ) : "";
				
				var candidateFilename:String = title + " (backup" + backupNumber + ")." + Utilities.integraFileExtension;
				
				var candidateFile:File = directory.resolvePath( candidateFilename );
				
				if( !candidateFile.exists )
				{
					return candidateFile.nativePath;
				}
			}
			
			Assert.assertTrue( false );	//can never get here
			return null;
		}
		
		
		private var _searchObjectID:int;
		
		private var _upgradedObjectIDs:Vector.<int> = new Vector.<int>;
		private var _upgradedModuleGuids:Vector.<String> = new Vector.<String>;
		private var _backupName:String;
	}
}