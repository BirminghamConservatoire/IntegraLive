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


package components.views.viewContainers
{
	import components.controller.events.ScrollbarShowHideEvent;
	import components.utils.Utilities;
	import components.views.IntegraView;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import flashx.textLayout.container.ScrollPolicy;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.events.ScrollEvent;
	import mx.managers.DragManager;
	
	public class ViewTree extends Canvas
	{
		public function ViewTree()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.AUTO;

			_itemsHolder.setStyle( "left", 0 );
			_itemsHolder.setStyle( "right", 0 );
			_itemsHolder.percentHeight = 100;
			
			addChild( _itemsHolder );
			
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}
		
		
		public function set canReorder( canReorder:Boolean ):void { _canReorder = canReorder; }

		
     	override public function validateSize( recursive:Boolean=false ):void 
     	{ 
     		super.validateSize( recursive );
     		
			var hasVerticalScrollbar:Boolean = ( verticalScrollBar && verticalScrollBar.maxScrollPosition > 0 );
			if( hasVerticalScrollbar != _hasVerticalScrollbar )
			{
				_itemsHolder.setStyle( "right", hasVerticalScrollbar ? verticalScrollBar.minWidth : 0 );
				_hasVerticalScrollbar = hasVerticalScrollbar;
				
				dispatchEvent( new ScrollbarShowHideEvent( hasVerticalScrollbar ) );
			}
     	}		

		
		public function addItemAt( item:IntegraView, index:int, userCanChangeHeight:Boolean = false ):void
		{
			if( index < 0 || index > _items.length )
			{
				Assert.assertTrue( false );
				return;
			}			
			
			var viewHolder:ViewHolder = new ViewHolder;
			viewHolder.view = item;
			viewHolder.canCollapse = true;
			
			if( userCanChangeHeight )
			{
				viewHolder.changeHeightFromBottom = true;
			}
			else
			{
				viewHolder.useHeightOfView = true;				
			}

			_items.splice( index, 0, viewHolder );

			_itemsHolder.addElementAt( viewHolder, index );
			
			viewHolder.addEventListener( DragEvent.DRAG_DROP, onDragDrop );
			viewHolder.addEventListener( DragEvent.DRAG_ENTER, onDragEnter );
		}
		
		
		public function removeItem( index:int ):void
		{
			if( index < 0 || index >= _items.length )
			{
				Assert.assertTrue( false );
				return;
			}			
			
			var viewHolder:ViewHolder = _items[ index ];
			viewHolder.removeEventListener( DragEvent.DRAG_DROP, onDragDrop );
			viewHolder.removeEventListener( DragEvent.DRAG_ENTER, onDragEnter );
			
			_items.splice( index, 1 );

			_itemsHolder.removeElementAt( index );
			
			viewHolder.view.free();
		}


		public function setItemIndex( oldIndex:int, newIndex:int ):void
		{
			if( oldIndex < 0 || newIndex < 0 || oldIndex >= _items.length || newIndex >= _items.length )
			{
				Assert.assertTrue( false );
				return;
			}			
			
			var item:ViewHolder = _items[ oldIndex ];
			Assert.assertNotNull( item );

			_items.splice( oldIndex, 1 );
			_items.splice( newIndex, 0, item ); 
			
			_itemsHolder.setElementIndex( item, newIndex );
		}


		public function removeAllItems():void
		{
			_itemsHolder.removeAllElements();

			for each( var viewHolder:ViewHolder in _items )
			{
				viewHolder.removeEventListener( DragEvent.DRAG_DROP, onDragDrop );
				viewHolder.removeEventListener( DragEvent.DRAG_ENTER, onDragEnter );
				
				viewHolder.view.free();

			}

			_items.length = 0;
		}
		
		
		public function setItemHeight( index:int, height:uint ):void
		{
			if( index < 0 || index >= _items.length )
			{
				Assert.assertTrue( false );
				return;
			}			

			_items[ index ].changeHeight( height );
		} 


		public function getItemCount():int
		{
			return _items.length;			
		}


		public function getItem( index:int ):IntegraView
		{
			if( index < 0 || index >= _items.length )
			{
				Assert.assertTrue( false );
				return null;
			}			

			return _items[ index ].view;				
		}

		
		public function getItemRect( index:int ):Rectangle
		{
			if( index < 0 || index >= _items.length )
			{
				Assert.assertTrue( false );
				return null;
			}			

			return  _items[ index ].getRect( this ); 
		}
		

		public function getItemIndex( item:IntegraView ):int
		{
			for( var i:int = 0; i < _items.length; i++ )
			{
				var view:IntegraView = _items[ i ].view;
				if( view == item )
				{
					return i;
				}
			}
			
			return -1;	//not found
		}
		
		
		public function isItemCollapsed( index:int ):Boolean
		{
			Assert.assertTrue( index >= 0 && index < _items.length );	
			
			return _items[ index ].collapsed;
		}
		
		
		public function getExpandedItemCount():int
		{
			var count:int = 0;
			for each( var view:ViewHolder in _items )
			{
				if( !view.collapsed )
				{
					count++;
				}
			}
			
			return count;
		}
		
		
		public function getExpandedIndex( index:int ):int 
		{
			Assert.assertTrue( index >= 0 && index < _items.length );
			Assert.assertFalse( _items[ index ].collapsed );
			
			var expandedIndex:int = 0;
			
			for( var i:int = 0; i < index; i++ )
			{
				if( !_items[ i ].collapsed ) 
				{
					expandedIndex++;
				}
			} 
			
			return expandedIndex;
		}
		
		
		public function getItemFromExpandedIndex( expandedIndex:int ):IntegraView 
		{
			Assert.assertTrue( expandedIndex >= 0 && expandedIndex < getExpandedItemCount() );
			
			var itemsLeft:int = expandedIndex;
			
			for each( var item:ViewHolder in _items )
			{
				if( item.collapsed )
				{
					continue;
				}
				
				if( itemsLeft == 0 )
				{
					return item.view;
				}
				
				itemsLeft--;
			}
			
			Assert.assertTrue( false );
			return null;	
		} 
		
		
		public function getBottomOfItems( targetCoordinateSpace:DisplayObject ):Number
		{
			if( _items.length == 0 ) 
			{
				return 0; 
			}

			validateNow();
			
			return _items[ _items.length - 1 ].getRect( targetCoordinateSpace ).bottom;
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			if( !_canReorder ) 
			{
				return;
			}	
			
			for each( var item:ViewHolder in _items )
			{
				if( !Utilities.pointIsInRectangle( item.getRect( this ), mouseX, mouseY ) )
				{
					continue;
				}
				
				if( !item.isMouseInDragRect() )
				{
					continue;
				}
				
				var dragSource:DragSource = new DragSource;
				dragSource.addData( item, Utilities.getClassNameFromObject( item ) );
			
				DragManager.doDrag( item, dragSource, event, getDragImage( item ) );
				return;
			}
		}


		private function getDragImage( dragView:ViewHolder ):IFlexDisplayObject
		{
			var dragImage:UIComponent = new UIComponent;
			dragImage.width = dragView.width;
			dragImage.height = dragView.height;
			dragImage.graphics.beginFill( 0x808080, 0.2 );
			dragImage.graphics.drawRoundRect( 0, 0, dragImage.width, dragImage.height, 24, 18 );
			dragImage.graphics.endFill();
			
			return dragImage;
		}		
		
		
		private function onDragDrop( event:DragEvent ):void
		{
			var formatName:String = Utilities.getClassNameFromClass( ViewHolder );
			var draggedView:ViewHolder = event.dragSource.dataForFormat( formatName ) as ViewHolder;
			var droppedView:ViewHolder = event.target as ViewHolder;

			Assert.assertNotNull( draggedView );
			Assert.assertNotNull( droppedView );
			Assert.assertTrue( draggedView != droppedView );
			Assert.assertTrue( draggedView.parent == _itemsHolder );
			Assert.assertTrue( droppedView.parent == _itemsHolder );
			
			var draggedIndex:int = getItemIndex( draggedView.view ); 
			var droppedIndex:int = getItemIndex( droppedView.view );
			
			setItemIndex( draggedIndex, droppedIndex );
			
			dispatchEvent( new Event( TREE_REORDERED ) ); 
		}


		private function onDragEnter( event:DragEvent ):void
		{
			var formatName:String = Utilities.getClassNameFromClass( ViewHolder );
			if( !event.dragSource.hasFormat( formatName ) )
			{
				return;
			}
			
			var draggedView:ViewHolder = event.dragSource.dataForFormat( formatName ) as ViewHolder;
			Assert.assertNotNull( draggedView );

			var target:ViewHolder = event.target as ViewHolder;
			Assert.assertNotNull( target );
			
			if( draggedView.parent != _itemsHolder )
			{
				return;
			}
			
			if( draggedView == target )
			{
				return;
			}
			
			DragManager.acceptDragDrop( target );
		}				


		private var _itemsHolder:VBox = new VBox;
		
		private var _items:Vector.<ViewHolder> = new Vector.<ViewHolder>;	

		private var _canReorder:Boolean = false;
		
		private var _hasVerticalScrollbar:Boolean = false;
		
		public static const TREE_REORDERED:String = "treeReordered";		
	}
}