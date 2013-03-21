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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	import mx.utils.ObjectProxy;
	
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Library;
	import components.utils.LibraryItem;
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
			 
			_library.setStyle( "left", 0 );
			_library.setStyle( "right", 0 );
			addChild( _library );
			
			_library.addEventListener( DragEvent.DRAG_START, onDragStart );
			
			addEventListener( Event.RESIZE, onResize );
		}


		override public function get title():String { return "Module Library"; }

		override public function get isSidebarColours():Boolean { return true; }


		override public function getInfoToDisplay( event:MouseEvent ):Info 
		{
			if( _library.numChildren == 0 )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleLibrary" );
			}
			
			var lastItem:LibraryItem = _library.getLibraryItemAt( _library.numChildren - 1 );
			if( mouseY >= lastItem.getRect( this ).bottom )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleLibrary" );
			}

			var item:LibraryItem = Utilities.getAncestorByType( event.target as DisplayObject, LibraryItem ) as LibraryItem;
			if( item )
			{
				var entry:ModuleLibraryListEntry = getListEntryFromLibraryItem( item );
				Assert.assertNotNull( entry );
				
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( entry.guid );
				Assert.assertNotNull( interfaceDefinition );
				
				_hoverInfo = interfaceDefinition.interfaceInfo.info;
			}

			return _hoverInfo;
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
			_library.data = listData;
		}
		
		
		private function createListEntry( interfaceDefinition:InterfaceDefinition ):ModuleLibraryListEntry
		{
			return new ModuleLibraryListEntry( interfaceDefinition.interfaceInfo.label, interfaceDefinition.moduleGuid );			
		}

		
		private function onDragStart( event:DragEvent ):void
		{
			var item:LibraryItem = Utilities.getAncestorByType( event.target as DisplayObject, LibraryItem ) as LibraryItem;
			if( !item ) return;

			var listEntry:ModuleLibraryListEntry = getListEntryFromLibraryItem( item );
			Assert.assertNotNull( listEntry );

			var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( listEntry.guid );
			Assert.assertNotNull( interfaceDefinition );

			var dragSource:DragSource = new DragSource();
			dragSource.addData( interfaceDefinition, Utilities.getClassNameFromClass( InterfaceDefinition ) );
			
			var itemRect:Rectangle = item.getRect( this );
			
			DragManager.doDrag( _library, dragSource, event, getDragImage(), itemRect.x, itemRect.y );
		}
		
		
		
		private function getDragImage():IFlexDisplayObject
		{
			var dragImage:UIComponent = new UIComponent;

			return dragImage;
		}
		

		private function getListEntryFromLibraryItem( libraryItem:LibraryItem ):ModuleLibraryListEntry
		{
			Assert.assertNotNull( libraryItem );
			
			var objectProxy:ObjectProxy = libraryItem.data as ObjectProxy;
			Assert.assertNotNull( objectProxy );
			
			var entry:ModuleLibraryListEntry = objectProxy.valueOf() as ModuleLibraryListEntry;
			Assert.assertNotNull( entry );
			
			return entry;
		}

		
		private function onResize( event:Event ):void
		{
			_library.height = height;
		}
		
				
		private var _library:Library = new Library;
		
		private var _hoverInfo:Info = null;
	}
}
