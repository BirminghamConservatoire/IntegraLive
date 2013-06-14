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
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;

	public class UpgradeAllModules extends ServerCommand
	{
		public function UpgradeAllModules()
		{
			super();
		}
		
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			return true;				
		}
		
		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			for each( var moduleGuid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( moduleGuid );
				Assert.assertNotNull( interfaceDefinition );
				
				var alternativeVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				
				Assert.assertTrue( alternativeVersions.length > 0 );
				var bestVersion:InterfaceDefinition = alternativeVersions[ 0 ];
				
				if( interfaceDefinition != bestVersion )
				{
					controller.processCommand( new SwitchAllObjectVersions( interfaceDefinition.moduleGuid, bestVersion.moduleGuid ) );
				}
			}
		}
	}
}