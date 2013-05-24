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
			_searchBox.setStyle( "top", 0 );
			_searchBox.addEventListener( SearchBox.SEARCH_CHANGE_EVENT, onSearchChange );
			addChild( _searchBox );

			_tagCloud.setStyle( "left", 0 );
			_tagCloud.setStyle( "right", 0 );
			_tagCloud.setStyle( "bottom", 0 );
			_tagCloud.addEventListener( Event.RESIZE, onResizeTagCloud );
			_tagCloud.addEventListener( TagCloud.TAG_SELECTION_CHANGED, onTagSelectionChanged );
			
			addChild( _tagCloud );
			
			_library.addEventListener( LibraryItem.INSTANTIATE_EVENT, onInstantiate );
			
			addEventListener( Event.RESIZE, onResize );
		}


		override public function get title():String { return "Module Library"; }

		override public function get isSidebarColours():Boolean { return true; }


		override public function getInfoToDisplay( event:MouseEvent ):Info 
		{
			if( Utilities.isEqualOrDescendant( event.target, _searchBox ) )
			{
				return _searchBox.getInfoToDisplay( event.target );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _tagCloud ) )
			{
				return _tagCloud.getInfoToDisplay( event.target );
			}
			
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
			updateLibrary();
			
			updateTagList();
			
			updateSearchBox();
		}
		
		
		private function updateLibrary():void
		{
			//first pass - build map of origin guid -> vector of interfaces and count tags
			var originGuidSet:Object = new Object;
			for each( var guid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( guid );
				Assert.assertNotNull( interfaceDefinition );
				
				if( !interfaceDefinition.hasAudioEndpoints )
				{
					//don't display modules with no audio endpoints
					continue;
				}
				
				if( originGuidSet.hasOwnProperty( interfaceDefinition.originGuid ) )
				{
					//already have this one
					continue;
				}
				
				var interfaces:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				Assert.assertNotNull( interfaces );
				
				var filteredInterfaces:Vector.<InterfaceDefinition> = interfaces.filter( shouldIncludeModule );
				if( filteredInterfaces.length > 0 )
				{
					originGuidSet[ interfaceDefinition.originGuid ] = filteredInterfaces;
				}
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
			
			_library.data = listData;		}
		
		
		
		private function updateTagList():void
		{
			//build map of tags to number of times used
			_tagSet = new Object;	
			
			for each( var guid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( guid );
				Assert.assertNotNull( interfaceDefinition );
				
				if( !interfaceDefinition.hasAudioEndpoints )
				{
					//don't include tags for modules with no audio endpoints
					continue;
				}

				for each( var tag:String in interfaceDefinition.interfaceInfo.tags )
				{
					if( tag.length == 0 ) continue;		//clean up slightly messy data
					
					if( _tagSet.hasOwnProperty( tag ) )
					{
						_tagSet[ tag ] = 1;	
					}
					else
					{
						_tagSet[ tag ] ++;
					}
				}
			}
			
			//now turn it into a vector of strings
			var tags:Vector.<String> = new Vector.<String>;
			for( tag in _tagSet )
			{
				tags.push( tag );
			}
			
			tags.sort( compareTags );
			
			_tagCloud.tags = tags;
		}
		
		
		private function compareTags( tag1:String, tag2:String ):int
		{
			var tag1Uses:int = _tagSet[ tag1 ];
			var tag2Uses:int = _tagSet[ tag2 ];
			
			if( tag1Uses > tag2Uses ) return -1;
			if( tag2Uses > tag1Uses ) return 1;
			
			if( tag1 > tag2 ) return 1;
			if( tag2 > tag1 ) return -1;
		
			return 0;
		}
		
		
		
		private function updateSearchBox():void
		{
			_searchBox.filteredEverything = ( _library.numChildren == 0 );
		}
		
		
		private function shouldIncludeModule( interfaceDefinition:InterfaceDefinition, index:int, vector:Vector.<InterfaceDefinition> ):Boolean
		{
			if( !interfaceDefinition.hasAudioEndpoints )
			{
				//don't display modules with no endpoints
				return false;
			}
			
			if( !shouldIncludeAccordingToSearchText( interfaceDefinition ) )
			{
				return false;
			}

			if( !shouldIncludeAccordingToTagCloud( interfaceDefinition ) )
			{
				return false;
			}
			
			return true;
		}
		
		
		private function shouldIncludeAccordingToSearchText( interfaceDefinition:InterfaceDefinition ):Boolean
		{
			var searchText:String = _searchBox.searchText;
			if( searchText.length == 0 ) return true;
			
			var needle:String = searchText.toUpperCase();
			var haystack:String = interfaceDefinition.interfaceInfo.label.toUpperCase();
			
			return ( haystack.indexOf( needle ) >= 0 );
		}
		
		
		private function shouldIncludeAccordingToTagCloud( interfaceDefinition:InterfaceDefinition ):Boolean
		{
			var selectedTags:Object = _tagCloud.selectedTags;
			if( Utilities.isObjectEmpty( selectedTags ) )
			{
				return true;
			}
			
			for each( var tag:String in interfaceDefinition.interfaceInfo.tags )
			{
				if( selectedTags.hasOwnProperty( tag ) )
				{
					return true;
				}
			}
			
			return false;
		}

		
		private function moduleCompareFunction( a:ModuleLibraryListEntry, b:ModuleLibraryListEntry ):Number
		{
			return a.compare( b );
		}

		
		private function onTagSelectionChanged( event:Event ):void
		{
			updateLibrary();
			updateSearchBox();
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
			_tagCloud.maxHeight = height / 2;

			positionControls();
		}
		
		
		private function onResizeTagCloud( event:Event ):void
		{
			positionControls();
		}
		
		
		private function positionControls():void
		{
			_searchBox.height = FontSize.getTextRowHeight( this );
			
			_library.y = _searchBox.height;
			_library.height = height - _searchBox.height - _tagCloud.height;
		}

		
		private function onSearchChange( event:Event ):void
		{
			onAllDataChanged();
		}

		
		private var _library:Library = new Library;
		private var _searchBox:SearchBox = new SearchBox;
		private var _tagCloud:TagCloud = new TagCloud;
		private var _tagSet:Object = null;
		
		private var _hoverInfo:Info = null;
		
	}
}
