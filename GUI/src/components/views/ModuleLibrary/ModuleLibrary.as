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
	
	import mx.controls.Button;
	import mx.core.ScrollPolicy;
	
	import components.controller.serverCommands.LoadModule;
	import components.model.Block;
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.utils.libraries.Library;
	import components.utils.libraries.LibraryItem;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CollapseButtonSkin;
	
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
			
			_searchBox.setStyle( "left", 0 );
			_searchBox.setStyle( "right", 0 );
			_searchBox.setStyle( "bottom", 0 );
			_searchBox.addEventListener( SearchBox.SEARCH_CHANGE_EVENT, onSearchChange );
			_searchBox.addEventListener( SearchBox.SEARCH_NEXT_EVENT, onSearchNext );
			_searchBox.addEventListener( SearchBox.SEARCH_PREV_EVENT, onSearchPrev );
			addChild( _searchBox );
			
			_library.addEventListener( LibraryItem.INSTANTIATE_EVENT, onInstantiate );
			
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

			if( event.target is Button && ( event.target as Button ).getStyle( "skin" ) == CollapseButtonSkin )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ExpandModuleVersions" );
			}
			
			var item:LibraryItem = Utilities.getAncestorByType( event.target as DisplayObject, LibraryItem ) as LibraryItem;
			if( item && item.data.hasOwnProperty( "info" ) )
			{
				_hoverInfo = item.data.info;
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

				var originItem:ModuleLibraryListEntry = new ModuleLibraryListEntry( defaultInterface, true );
				
				if( group.length > 1 )
				{
					var childItems:Array = new Array;
					for each( var childInterface:InterfaceDefinition in group )
					{
						childItems.push( new ModuleLibraryListEntry( childInterface, false ) );
					}
					
					insertLabels( childItems );
					
					originItem.childData = childItems;
				}
				
				listData.push( originItem );
			}
			
			
			listData.sort( moduleCompareFunction );
			
			_library.data = listData;
		}
		
		
		private function moduleCompareFunction( a:ModuleLibraryListEntry, b:ModuleLibraryListEntry ):Number
		{
			return a.compare( b );
		}

		
		private function insertLabels( listData:Array ):void
		{
			var prevModuleSource:String = null;
			
			for( var i:int = 0; i < listData.length; i++ )
			{
				var listEntry:ModuleLibraryListEntry = listData[ i ] as ModuleLibraryListEntry;
				if( !listEntry ) continue;
				
				var moduleSource:String = listEntry.moduleSource;
				if( moduleSource == prevModuleSource ) continue;
				
				listData.splice( i, 0, new ModuleLibraryListLabel( moduleSource ) );
				prevModuleSource = moduleSource; 
			}
		}
		
		
		private function onInstantiate( event:Event ):void
		{
			var item:LibraryItem = event.target as LibraryItem;
			Assert.assertNotNull( item );
			
			var listEntry:ModuleLibraryListEntry = getListEntryFromLibraryItem( item );
			Assert.assertNotNull( listEntry );
			
			var selectedBlock:Block = model.primarySelectedBlock;
			if( !selectedBlock ) return;
			
			controller.processCommand( new LoadModule( listEntry.guid, selectedBlock.id ) );
		}

		
		private function getListEntryFromLibraryItem( libraryItem:LibraryItem ):ModuleLibraryListEntry
		{
			Assert.assertNotNull( libraryItem );

			var entry:ModuleLibraryListEntry = libraryItem.data as ModuleLibraryListEntry;
			Assert.assertNotNull( entry );
			
			return entry;
		}

		
		private function onResize( event:Event ):void
		{
			_searchBox.height = FontSize.getTextRowHeight( this );

			_library.height = height - _searchBox.height;
		}

		
		private function onSearchChange( event:Event ):void
		{
			_library.search( _searchBox.searchText, 1, 0 );
		}

		
		private function onSearchNext( event:Event ):void
		{
			_library.search( _searchBox.searchText, 1, 1 );
		}

		
		private function onSearchPrev( event:Event ):void
		{
			_library.search( _searchBox.searchText, -1, -1 );
		}
		
		
		private var _library:Library = new Library;
		private var _searchBox:SearchBox = new SearchBox;
		
		private var _hoverInfo:Info = null;
	}
}
