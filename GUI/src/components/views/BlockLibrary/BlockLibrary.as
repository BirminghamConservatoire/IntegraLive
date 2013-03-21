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
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import components.model.Info;
	import components.utils.Library;
	import components.utils.LibraryItem;
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
			
			_library.addEventListener( DragEvent.DRAG_START, onDragStart );
			
			addEventListener( Event.RESIZE, onResize );
			
			contextMenuDataProvider = contextMenuData;
		}


		override public function get title():String { return "Block Library"; }

		override public function get isSidebarColours():Boolean { return true; }

		
		override public function getInfoToDisplay( event:MouseEvent ):Info 
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
				addBlockLibraryDirectory( listData, systemBlockLibraryDirectory.getDirectoryListing(), _systemBlockTint );
			}

			var userBlockLibraryDirectory:File = new File( Utilities.getUserBlockLibraryDirectory() );
			if( userBlockLibraryDirectory.exists )
			{
				addBlockLibraryDirectory( listData, userBlockLibraryDirectory.getDirectoryListing(), _userBlockTint );
			}
			
			_library.data = listData;
		}
		
		
		private function addBlockLibraryDirectory( listData:Array, directoryListing:Array, tint:uint ):void
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
					listEntry = new BlockLibraryListEntry( file, tint );
					_mapFileNameToListEntry[ file.nativePath ] = listEntry;
				}
				
				listData.push( listEntry );
			}
		}

		
		private function onDragStart( event:DragEvent ):void
		{
			var item:LibraryItem = Utilities.getAncestorByType( event.target as DisplayObject, LibraryItem ) as LibraryItem;
			if( !item ) return;
			
			var listEntry:BlockLibraryListEntry = getListEntryFromLibraryItem( item );
			Assert.assertNotNull( listEntry );
			
			var draggedFile:File = new File( listEntry.filepath );
			Assert.assertTrue( draggedFile.exists );
			
			var dragSource:DragSource = new DragSource();
			dragSource.addData( draggedFile, Utilities.getClassNameFromClass( File ) );
			
			var itemRect:Rectangle = item.getRect( this );
			
			DragManager.doDrag( _library, dragSource, event, getDragImage(), itemRect.x, itemRect.y );
		}
		
		
		private function getDragImage():IFlexDisplayObject
		{
			var dragImage:UIComponent = new UIComponent;
			//dragImage.width = _moduleList.width;
			//dragImage.height = _moduleList.rowHeight;
			//dragImage.graphics.beginFill( 0xffffff, 0.4 );
			//dragImage.graphics.drawRect( 0, 0, dragImage.width, dragImage.height );
			//dragImage.graphics.endFill();
			
			return dragImage;
		}
		
		
		private function onUpdateRemove( menuItem:Object ):void
		{
			/*
			selectItemUnderMouse();
			
			if( !_blockList.selectedItem )
			{
				menuItem.enabled = false;
				return;
			}

			var objectProxy:ObjectProxy = _blockList.selectedItem as ObjectProxy;
			Assert.assertNotNull( objectProxy );
			
			var item:BlockLibraryListEntry = objectProxy.valueOf() as BlockLibraryListEntry;
			Assert.assertNotNull( item );
			
			menuItem.enabled = item.isUserItem;
			*/
		}
		
		
		private function remove():void
		{
			/*var objectProxy:ObjectProxy = _blockList.selectedItem as ObjectProxy;
			Assert.assertNotNull( objectProxy );
			
			var item:BlockLibraryListEntry = objectProxy.valueOf() as BlockLibraryListEntry;
			Assert.assertNotNull( item );
			Assert.assertTrue( item.isUserItem );
			
			var file:File = new File( item.filepath );
			Assert.assertNotNull( file );
			Assert.assertTrue( file.exists );
			
			file.deleteFile();
			
			onAllDataChanged();
			*/
		}
		
		
		private function selectItemUnderMouse():void
		{
			/*
			var index:int = ( _blockList.mouseY + _blockList.verticalScrollPosition ) / _blockList.rowHeight;
			if( index < _blockList.dataProvider.length )
			{
				_blockList.selectedIndex = index;
			} 
			*/
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
		
		
		private static const _systemBlockTint:uint = 0x000000;
		private static const _userBlockTint:uint = 0x000020;
	}
}

