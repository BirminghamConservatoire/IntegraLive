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


package components.controller.userDataCommands
{	
	import components.controller.IntegraController;
	import components.controller.UserDataCommand;
	import components.controller.serverCommands.UpgradeModules;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ViewMode;
	
	import flexunit.framework.Assert;

	public class PollForUpgradableModules extends UserDataCommand
	{
		public function PollForUpgradableModules( searchObjectID:int )
		{
			super();
			
			_searchObjectID = searchObjectID;
			isNewUndoStep = false;
		}
		
		
		public function get foundUpgradableModules():Boolean { return _foundUpgradableModules; }
		public function get searchObjectID():int { return _searchObjectID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return model.doesObjectExist( _searchObjectID );
		}
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var searchObject:IntegraDataObject = model.getDataObjectByID( _searchObjectID );
			Assert.assertNotNull( searchObject );
			
			_foundUpgradableModules = searchForUpgradableModules( searchObject, model );

			if( _foundUpgradableModules )
			{
				if( model.alwaysUpgrade )
				{
					controller.processCommand( new UpgradeModules( _searchObjectID ) );
				}
				else
				{
					var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
					if( !viewMode.upgradeDialogOpen )
					{
						viewMode.upgradeDialogOpen = true;
						controller.processCommand( new SetViewMode( viewMode ) );
					}
				}
			}
		}

		
		override public function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void 
		{ 	
		}		

		
		private function searchForUpgradableModules( searchObject:IntegraDataObject, model:IntegraModel ):Boolean
		{
			if( searchObject is IntegraContainer )
			{
				var container:IntegraContainer = searchObject as IntegraContainer;
				for each( var child:IntegraDataObject in container.children )
				{
					if( searchForUpgradableModules( child, model ) )
					{
						return true;
					}
				}
			}
			else
			{
				var interfaceDefinition:InterfaceDefinition = searchObject.interfaceDefinition;
				var interfaceDefinitions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
				
				if( interfaceDefinition != interfaceDefinitions[ 0 ] )
				{
					return true;
				}
			}
			
			return false;
		}
		
		private var _searchObjectID:int;
		
		private var _foundUpgradableModules:Boolean = false;
	}
}