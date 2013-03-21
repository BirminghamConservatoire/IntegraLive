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
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.collections.IList;
	import mx.controls.List;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.ClassFactory;
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	import mx.utils.ObjectProxy;
	
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.LibraryRenderer;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;

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
			_moduleList.variableRowHeight = true; 
			_moduleList.setStyle( "backgroundAlpha", 0 );
			_moduleList.setStyle( "borderStyle", "none" );			
			_moduleList.itemRenderer = new ClassFactory( LibraryRenderer );
			addElement( _moduleList );
			
			_moduleList.addEventListener( DragEvent.DRAG_START, onDragStart );
		}


		override public function get title():String { return "Module Library"; }

		override public function get isSidebarColours():Boolean { return true; }


		override public function getInfoToDisplay( event:MouseEvent ):Info 
		{
			var items:IList = _moduleList.dataProvider as IList;
			Assert.assertNotNull( items );
			
			var numberOfItems:int = items.length;
			if( numberOfItems == 0 )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleLibrary" );
			}
			
			var lastRenderer:IListItemRenderer = _moduleList.indexToItemRenderer( numberOfItems - 1 );
			if( lastRenderer && mouseY >= lastRenderer.getRect( this ).bottom )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleLibrary" );
			}

			var libraryRenderer:LibraryRenderer = Utilities.getAncestorByType( event.target as DisplayObject, LibraryRenderer ) as LibraryRenderer;
			if( libraryRenderer )
			{
				var index:int = _moduleList.itemRendererToIndex( libraryRenderer );
				Assert.assertTrue( index >= 0 );
				
				var interfaceDefinition:InterfaceDefinition = getInterfaceFromListItem( items.getItemAt( index ) ); 
				Assert.assertNotNull( interfaceDefinition );
				
				_hoverInfo = interfaceDefinition.interfaceInfo.info;
			}

			return _hoverInfo;
		}		
		
		
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
			//first pass - build map of origin guid -> vector of interfaces
			var originGuidSet:Object = new Object;
			for each( var guid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( guid );
				Assert.assertNotNull( interfaceDefinition );

				if( !interfaceDefinition.hasAudioEndpoints )
				{
					//don't display modules with no endpoints
					continue;
				}
				
				if( originGuidSet.hasOwnProperty( interfaceDefinition.originGuid ) )
				{
					//already have this one
					continue;
				}
				
				var interfaces:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				Assert.assertNotNull( interfaces );
				
				originGuidSet[ interfaceDefinition.originGuid ] = interfaces;
					
			}

			//second pass - build list data
			var listData:Array = new Array;
			for( var originGuid:String in originGuidSet )
			{
				var group:Vector.<InterfaceDefinition> = originGuidSet[ originGuid ];
				Assert.assertTrue( group.length > 0 );
				
				var defaultInterface:InterfaceDefinition = group[ 0 ];

				var originItem:ModuleLibraryListEntry = createListEntry( defaultInterface );
				
				if( group.length > 1 )
				{
					var childItems:Array = new Array;
					for each( var childInterface:InterfaceDefinition in group )
					{
						childItems.push( new ObjectProxy( createListEntry( childInterface ) ) );				
					}
					originItem.childData = childItems;
				}
				
				listData.push( new ObjectProxy( originItem ) );
			}
			
			
			listData.sortOn( "label", Array.CASEINSENSITIVE );
			_moduleList.dataProvider = listData;
		}
		
		
		private function createListEntry( interfaceDefinition:InterfaceDefinition ):ModuleLibraryListEntry
		{
			return new ModuleLibraryListEntry( interfaceDefinition.interfaceInfo.label, interfaceDefinition.moduleGuid );			
		}

		
		private function onDragStart( event:DragEvent ):void
		{
			var draggedInterfaceDefinition:InterfaceDefinition = getInterfaceFromListItem( _moduleList.selectedItem );
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
		

		private function getInterfaceFromListItem( listItem:Object ):InterfaceDefinition 
		{
			if( !listItem ) return null;
			
			var objectProxy:ObjectProxy = listItem as ObjectProxy;
			Assert.assertNotNull( objectProxy );
			
			var item:ModuleLibraryListEntry = objectProxy.valueOf() as ModuleLibraryListEntry;
			Assert.assertNotNull( item );
			
			var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( item.guid );
			Assert.assertNotNull( interfaceDefinition );
			
			return interfaceDefinition;
		}

				
		private var _moduleList:List;
		
		private var _hoverInfo:Info = null;
	}
}
