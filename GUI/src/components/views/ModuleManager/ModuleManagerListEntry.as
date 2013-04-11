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


package components.views.ModuleManager
{
	import components.model.Info;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.InterfaceInfo;
	import components.utils.Utilities;
	import components.views.ModuleLibrary.ModuleLibraryListEntry;
	
	import flexunit.framework.Assert;

	public class ModuleManagerListEntry extends Object
	{
		public function ModuleManagerListEntry( interfaceDefinition:InterfaceDefinition )
		{
			super();
			
			_interfaceDefinition = interfaceDefinition;
		}

		public function toString():String { return _interfaceDefinition.interfaceInfo.label; }
		
		public function get guid():String { return _interfaceDefinition.moduleGuid; }
		public function get moduleSource():String { return _interfaceDefinition.moduleSource; }

		public function get hasTickbox():Boolean { return true; }
		public function get ticked():Boolean { return _ticked; }
		public function set ticked( ticked:Boolean ):void { _ticked = ticked; }
		
		
		public function get tint():uint
		{
			switch( _interfaceDefinition.moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	return ModuleLibraryListEntry.shippedWithIntegraTint;
				case InterfaceDefinition.MODULE_THIRD_PARTY:			return ModuleLibraryListEntry.thirdPartyTint;
				case InterfaceDefinition.MODULE_EMBEDDED:				return ModuleLibraryListEntry.embeddedTint;
					
				default:
					Assert.assertTrue( false );
					return 0;
			}		
		}
		
		
		public function get info():Info
		{
			if( !_info )
			{
				_info = makeInfo();				
			}
			
			return _info;
		}
		
		
		public function compare( other:ModuleManagerListEntry ):int
		{
			//first compare source
			var sourcePriority:Object = new Object;
			sourcePriority[ InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA ] = 2;
			sourcePriority[ InterfaceDefinition.MODULE_THIRD_PARTY ] = 1;
			sourcePriority[ InterfaceDefinition.MODULE_EMBEDDED ] = 0;
			
			var mySourcePriority:Number = sourcePriority[ _interfaceDefinition.moduleSource ];
			var otherSourcePriority:Number = sourcePriority[ other._interfaceDefinition.moduleSource ];
			
			if( mySourcePriority > otherSourcePriority ) return -1;
			if( otherSourcePriority > mySourcePriority ) return 1;
			
			//then compare label
			var myUpperLabel:String = toString().toUpperCase();
			var otherUpperLabel:String = other.toString().toUpperCase();

			if( myUpperLabel < otherUpperLabel ) return -1;
			if( otherUpperLabel < myUpperLabel ) return 1;

			//then compare modification time
			var myModificationTime:Number = _interfaceDefinition.interfaceInfo.modifiedDate.getTime();
			var otherModificationTime:Number = other._interfaceDefinition.interfaceInfo.modifiedDate.getTime();

			if( myModificationTime > otherModificationTime ) return -1;
			if( otherModificationTime > myModificationTime ) return 1;
			
			//then give up
			return 0;
		}
		
		
		private function makeInfo():Info
		{
			var interfaceInfo:InterfaceInfo = _interfaceDefinition.interfaceInfo;

			var info:Info = new Info;
			info.title = interfaceInfo.label;
			
			var markdown:String = "##";
			
			switch( _interfaceDefinition.moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:
					markdown += "System Module";
					break;
				case InterfaceDefinition.MODULE_THIRD_PARTY:
					markdown += "Third Party Module";
					break;
				case InterfaceDefinition.MODULE_EMBEDDED:
					markdown += "Embedded in Project";
					break;
			}
			markdown += "\n\n";
			
			markdown += "**Last modified:** " + interfaceInfo.modifiedDate.toLocaleDateString() + "\n\n";
			
			var author:String = interfaceInfo.author;
			if( author.length == 0 )
			{
				author = "&lt;unknown&gt;";
			}
			
			markdown += "**Author:** " + author + "\n\n";
			
			markdown += interfaceInfo.description;
			
			info.markdown = markdown;
			return info;
		}


		private var _interfaceDefinition:InterfaceDefinition;
		
		private var _info:Info;
		
		private var _ticked:Boolean = false;
	}
}