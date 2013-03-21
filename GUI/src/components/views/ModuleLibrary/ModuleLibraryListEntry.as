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
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;

	public class ModuleLibraryListEntry extends Object
	{
		public function ModuleLibraryListEntry( interfaceDefinition:InterfaceDefinition, isDefaultEntry:Boolean )
		{
			super();
			
			_interfaceDefinition = interfaceDefinition;
			_isDefaultEntry = isDefaultEntry;
		}

		public function set childData( childData:Array ):void { _childData = childData; }
		public function set expanded( expanded:Boolean ):void { _expanded = expanded; }
		
		public function get guid():String { return _interfaceDefinition.moduleGuid; }
		public function get childData():Array { return _childData; }
		public function get expanded():Boolean { return _expanded; }

		public function get label():String 
		{ 
			var label:String = _interfaceDefinition.interfaceInfo.label;
			if( !_isDefaultEntry )
			{
				label += " (";
				switch( _interfaceDefinition.moduleSource )
				{
					case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	label += "system";			break;
					case InterfaceDefinition.MODULE_THIRD_PARTY:			label += "3rd party";		break;
					case InterfaceDefinition.MODULE_EMBEDDED:				label += "embedded";		break;
					default:												label += "unknown source";	break;
				}
				label += ")";
			}
			return label; 
		}


		public function get tint():uint
		{
			switch( _interfaceDefinition.moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	return _shippedWithIntegraTint;
				case InterfaceDefinition.MODULE_THIRD_PARTY:			return _thirdPartyTint;
				case InterfaceDefinition.MODULE_EMBEDDED:				return _embeddedTint;
					
				default:
					Assert.assertTrue( false );
					return 0;
			}		
		}
		
		
		public function compare( other:ModuleLibraryListEntry ):int
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


		public function toString():String { return label; }
		
		private var _interfaceDefinition:InterfaceDefinition;
		private var _isDefaultEntry:Boolean = false;
		private var _childData:Array = null;
		private var _expanded:Boolean = false;

	
		private static const _shippedWithIntegraTint:uint = 0x000000;
		private static const _thirdPartyTint:uint = 0x000020;
		private static const _embeddedTint:uint = 0x100010;
	}
}