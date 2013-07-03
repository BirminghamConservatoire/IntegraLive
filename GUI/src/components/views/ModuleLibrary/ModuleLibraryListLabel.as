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


package components.views.ModuleLibrary
{
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;

	public class ModuleLibraryListLabel extends Object
	{
		public function ModuleLibraryListLabel( moduleSource:String )
		{
			super();
			
			_moduleSource = moduleSource;
		}

		
		public function get isLabel():Boolean 
		{ 
			return true; 
		}

		
		public function get tint():uint
		{
			switch( _moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	return ModuleLibraryListEntry.shippedWithIntegraTint;
				case InterfaceDefinition.MODULE_THIRD_PARTY:			return ModuleLibraryListEntry.thirdPartyTint;
				case InterfaceDefinition.MODULE_EMBEDDED:				return ModuleLibraryListEntry.embeddedTint;
				case InterfaceDefinition.MODULE_IN_DEVELOPMENT:			return ModuleLibraryListEntry.inDevelopmentTint;
					
				default:
					Assert.assertTrue( false );
					return 0;
			}		
		}
		
		
		public function get info():Info
		{
			switch( _moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	
					return InfoMarkupForViews.instance.getInfoForView( "ModulesShippedWithIntegra" );
					
				case InterfaceDefinition.MODULE_THIRD_PARTY:
					return InfoMarkupForViews.instance.getInfoForView( "ThirdPartyModules" );

				case InterfaceDefinition.MODULE_EMBEDDED:
					return InfoMarkupForViews.instance.getInfoForView( "EmbeddedModules" );
					
				case InterfaceDefinition.MODULE_IN_DEVELOPMENT:
					return InfoMarkupForViews.instance.getInfoForView( "InDevelopmentModules" );

				default:
					Assert.assertTrue( false );
					return null;
			}		
		}
		
		
		public function toString():String 
		{ 
			switch( _moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	return "LATEST OFFICIAL";
				case InterfaceDefinition.MODULE_THIRD_PARTY:			return "THIRD PARTY";
				case InterfaceDefinition.MODULE_EMBEDDED:				return "EMBEDDED";
				case InterfaceDefinition.MODULE_IN_DEVELOPMENT:			return "IN DEVELOPMENT";
				
				default:
					Assert.assertTrue( false );
					return null;
			}
		}
		
		private var _moduleSource:String;
	}
}