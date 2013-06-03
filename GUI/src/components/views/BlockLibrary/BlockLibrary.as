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


package components.views.BlockLibrary
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	import mx.controls.Image;
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import components.controller.serverCommands.ImportBlock;
	import components.model.Info;
	import components.model.Track;
	import components.utils.libraries.Library;
	import components.utils.libraries.LibraryItem;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;


	public class BlockLibrary extends IntegraView
	{
		public function BlockLibrary()
		{
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    
			
			width = 200;
			minWidth = 100;
			maxWidth = 400;
			
			_library.setStyle( "left", 0 );
			_library.setStyle( "right", 0 );
			addChild( _library );
			
			_library.addEventListener( LibraryItem.INSTANTIATE_EVENT, onInstantiate );
			
			addEventListener( Event.RESIZE, onResize );
			
			contextMenuDataProvider = contextMenuData;
		}


		override public function get title():String { return "Block Library"; }

		override public function get isSidebarColours():Boolean { return true; }

		
		override public function getInfoToDisplay( event:Event ):Info 
		{
			if( _library.numChildren == 0 )
			{
				return InfoMarkupForViews.instance.getInfoForView( "BlockLibrary" );
			}
			
			var lastItem:LibraryItem = _library.getLibraryItemAt( _library.numChildren - 1 );
			if( mouseY >= lastItem.getRect( this ).bottom )
			{
				return InfoMarkupForViews.instance.getInfoForView( "BlockLibrary" );
			}
			
			var item:LibraryItem = Utilities.getAncestorByType( event.target as DisplayObject, LibraryItem ) as LibraryItem;
			if( item )
			{
				var entry:BlockLibraryListEntry = getListEntryFromLibraryItem( item );
				Assert.assertNotNull( entry );
				
				_hoverInfo = entry.info;
			}
			
			return _hoverInfo;
		}		
		

		override protected function onAllDataChanged():void
		{
			var listData:Array = new Array;
			
			var systemBlockLibraryDirectory:File = new File( Utilities.getSystemBlockLibraryDirectory() );
			if( systemBlockLibraryDirectory.exists )
			{
				addBlockLibraryDirectory( listData, systemBlockLibraryDirectory.getDirectoryListing(), false );
			}

			var userBlockLibraryDirectory:File = new File( Utilities.getUserBlockLibraryDirectory() );
			if( userBlockLibraryDirectory.exists )
			{
				addBlockLibraryDirectory( listData, userBlockLibraryDirectory.getDirectoryListing(), true );
			}
			
			_library.data = listData;
		}
		
		
		private function addBlockLibraryDirectory( listData:Array, directoryListing:Array, isUserBlock:Boolean ):void
		{
			for each( var file:File in directoryListing )
			{
				if( file.isDirectory )
				{
					continue;
				}
				
				var listEntry:BlockLibraryListEntry = null;
				if( _mapFileNameToListEntry.hasOwnProperty( file.nativePath ) )
				{
					listEntry = _mapFileNameToListEntry[ file.nativePath ];
				}

				if( !listEntry || !listEntry.isCurrent( file ) )
				{
					listEntry = new BlockLibraryListEntry( file, isUserBlock );
					_mapFileNameToListEntry[ file.nativePath ] = listEntry;
				}
				
				listData.push( listEntry );
			}
		}

		
		private function onInstantiate( event:Event ):void
		{
			var item:LibraryItem = event.target as LibraryItem;
			Assert.assertNotNull( item );

			var listEntry:BlockLibraryListEntry = getListEntryFromLibraryItem( item );
			Assert.assertNotNull( listEntry );

			var selectedTrack:Track = model.selectedTrack;
			if( !selectedTrack ) return;
			
			controller.processCommand( new ImportBlock( listEntry.filepath, selectedTrack.id, model.project.player.playPosition ) );
		}
		
		
		private function onUpdateRemove( menuItem:Object ):void
		{
			var selectedItem:LibraryItem = _library.selectedItem;
			if( !selectedItem )
			{
				menuItem.enabled = false;
				return;
			}

			var listEntry:BlockLibraryListEntry = getListEntryFromLibraryItem( selectedItem );
			Assert.assertNotNull( listEntry );
			
			menuItem.enabled = listEntry.isUserBlock;
		}
		
		
		private function remove():void
		{
			var selectedItem:LibraryItem = _library.selectedItem;
			if( !selectedItem )	return;
			
			var listEntry:BlockLibraryListEntry = getListEntryFromLibraryItem( selectedItem );
			Assert.assertNotNull( listEntry );
			Assert.assertTrue( listEntry.isUserBlock );
			
			var file:File = new File( listEntry.filepath );
			Assert.assertNotNull( file );
			Assert.assertTrue( file.exists );
			
			file.deleteFile();
			
			onAllDataChanged();
		}
		
		
		private function onResize( event:Event ):void
		{
			_library.height = height;
		}
		
		
		private function getListEntryFromLibraryItem( libraryItem:LibraryItem ):BlockLibraryListEntry
		{
			Assert.assertNotNull( libraryItem );
			
			var entry:BlockLibraryListEntry = libraryItem.data as BlockLibraryListEntry;
			Assert.assertNotNull( entry );
			
			return entry;
		}		
		
				
		private var _library:Library = new Library;

		private var _mapFileNameToListEntry:Object = new Object;

		private var _hoverInfo:Info = null;
		
		[Bindable] 
        private var contextMenuData:Array = 
        [
            { label: "Remove from Block Library", handler: remove, updater: onUpdateRemove } 
        ];
	}
}

