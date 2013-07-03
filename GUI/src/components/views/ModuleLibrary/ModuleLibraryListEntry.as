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
	import mx.core.DragSource;
	
	import components.model.Info;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Utilities;
	
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

		public function toString():String { return _interfaceDefinition.interfaceInfo.label; }
		
		public function get guid():String { return _interfaceDefinition.moduleGuid; }
		public function get moduleSource():String { return _interfaceDefinition.moduleSource; }

		public function get childData():Array { return _childData; }
		public function get expanded():Boolean { return _expanded; }


		public function get tint():uint
		{
			switch( _interfaceDefinition.moduleSource )
			{
				case InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA:	return shippedWithIntegraTint;
				case InterfaceDefinition.MODULE_THIRD_PARTY:			return thirdPartyTint;
				case InterfaceDefinition.MODULE_EMBEDDED:				return embeddedTint;
				case InterfaceDefinition.MODULE_IN_DEVELOPMENT:			return inDevelopmentTint;
					
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
		
		
		public function get dragSource():DragSource
		{
			var interfaceDefinition:InterfaceDefinition = IntegraModel.singleInstance.getInterfaceDefinitionByModuleGuid( guid );
			if( !interfaceDefinition ) return null;
			
			var dragSource:DragSource = new DragSource();
			dragSource.addData( interfaceDefinition, Utilities.getClassNameFromClass( InterfaceDefinition ) );
			return dragSource;
		}
		
		
		public function compare( other:ModuleLibraryListEntry ):int
		{
			//first compare source
			var sourcePriority:Object = new Object;
			sourcePriority[ InterfaceDefinition.MODULE_IN_DEVELOPMENT ] = 3;
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
			if( _isDefaultEntry && _interfaceDefinition.moduleSource == InterfaceDefinition.MODULE_SHIPPED_WITH_INTEGRA )
			{
				//use standard info when it's a default AND system module
				return _interfaceDefinition.interfaceInfo.info;
			}
			else
			{
				var extendedInfo:Info = new Info;
				extendedInfo.markdown = _interfaceDefinition.makeExtendedInfoMarkdown( !_isDefaultEntry );
				return extendedInfo;				
			}
		}


		private var _interfaceDefinition:InterfaceDefinition;
		private var _isDefaultEntry:Boolean = false;
		private var _childData:Array = null;
		private var _expanded:Boolean = false;
		
		private var _info:Info;

	
		public static const shippedWithIntegraTint:uint = 0x000000;
		public static const thirdPartyTint:uint = 0x000420;
		public static const embeddedTint:uint = 0x100010;
		public static const inDevelopmentTint:uint = 0x400000;
	}
}