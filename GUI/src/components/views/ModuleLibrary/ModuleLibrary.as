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
	import components.model.interfaceDefinitions.InterfaceInfo;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.model.userData.ColorScheme;
	import components.utils.LibraryRenderer;
	import components.utils.Utilities;
	import components.views.IntegraView;
	
	import flexunit.framework.Assert;
	
	import mx.controls.List;
	import mx.core.ClassFactory;
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	import mx.utils.ObjectProxy;

	public class ModuleLibrary extends IntegraView
	{
		public function ModuleLibrary()
		{
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    
			
			width = 200;
			minWidth = 100;
			maxWidth = 400;
			 
			_moduleList = new List;
			_moduleList.opaqueBackground = null;
			_moduleList.percentWidth = 100;
			_moduleList.percentHeight = 100;
			_moduleList.dragEnabled = true;
			_moduleList.dragMoveEnabled = false;
			_moduleList.setStyle( "backgroundAlpha", 0 );
			_moduleList.setStyle( "borderStyle", "none" );			
			_moduleList.itemRenderer = new ClassFactory( LibraryRenderer );
			addElement( _moduleList );
			
			_moduleList.addEventListener( DragEvent.DRAG_START, onDragStart );
		}


		override public function get title():String { return "Module Library"; }

		override public function get isSidebarColours():Boolean { return true; }

		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_moduleList.setStyle( "rollOverColor", 0xd0d0d0 );
						_moduleList.setStyle( "selectionColor", 0xd0d0d0 );
						_moduleList.setStyle( "color", 0x808080 );
						break;
						
					case ColorScheme.DARK:
						_moduleList.setStyle( "rollOverColor", 0x303030 );
						_moduleList.setStyle( "selectionColor", 0x303030 );
						_moduleList.setStyle( "color", 0x808080 );
						break;
				}
			}			
		}


		override protected function onAllDataChanged():void
		{
			var listData:Array = new Array;

			for each( var guid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByGuid( guid );
				Assert.assertNotNull( interfaceDefinition );

				if( interfaceDefinition.hasAudioEndpoints )
				{
					listData.push( new ObjectProxy( new ModuleLibraryListEntry( interfaceDefinition.info.label, guid ) ) );
				}
			}
			
			listData.sortOn( "label", Array.CASEINSENSITIVE );
			_moduleList.dataProvider = listData;
		}

		
		private function onDragStart( event:DragEvent ):void
		{
			var objectProxy:ObjectProxy = _moduleList.selectedItem as ObjectProxy;
			Assert.assertNotNull( objectProxy );
			
			var item:ModuleLibraryListEntry = objectProxy.valueOf() as ModuleLibraryListEntry;
			Assert.assertNotNull( item );
			
			var draggedInterfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByGuid( item.guid );
			Assert.assertNotNull( draggedInterfaceDefinition );
			
			var dragSource:DragSource = new DragSource();
			dragSource.addData( draggedInterfaceDefinition, Utilities.getClassNameFromClass( InterfaceDefinition ) );
			
			DragManager.doDrag( _moduleList, dragSource, event, getDragImage(), 0, ( _moduleList.selectedIndex - _moduleList.verticalScrollPosition ) * _moduleList.rowHeight );
		}
		
		
		
		private function getDragImage():IFlexDisplayObject
		{
			var dragImage:UIComponent = new UIComponent;

			return dragImage;
		}

				
		private var _moduleList:List;
	}
}
