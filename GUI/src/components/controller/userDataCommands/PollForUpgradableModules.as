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
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ViewMode;
	
	import flexunit.framework.Assert;

	public class PollForUpgradableModules extends UserDataCommand
	{
		public function PollForUpgradableModules()
		{
			super();
			
			isNewUndoStep = false;
		}
		
		
		public function get foundUpgradableModules():Boolean { return _foundUpgradableModules; }
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			_foundUpgradableModules = pollForUpgradableModules( model );

			if( _foundUpgradableModules )
			{
				var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
				if( !viewMode.moduleManagerOpen )
				{
					viewMode.moduleManagerOpen = true;
					controller.processCommand( new SetViewMode( viewMode ) );
				}
			}
		}

		
		override public function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void 
		{ 	
		}		

		
		private function pollForUpgradableModules( model:IntegraModel ):Boolean
		{
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					for each( var module:ModuleInstance in block.modules )
					{
						var interfaceDefinition:InterfaceDefinition = module.interfaceDefinition;
						var interfaceDefinitions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
						Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
						
						if( interfaceDefinition != interfaceDefinitions[ 0 ] )
						{
							return true;
						}
					}
				}		
			}
			
			return false;
		}
		
		
		private var _foundUpgradableModules:Boolean = false;
	}
}