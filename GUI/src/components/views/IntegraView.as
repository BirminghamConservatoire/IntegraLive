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


package components.views
{
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.events.AllDataChangedEvent;
	import components.controller.events.IntegraCommandEvent;
	import components.model.Info;
	import components.model.IntegraModel;
	import components.model.userData.ColorScheme;
	import components.utils.Trace;
	import components.utils.Utilities;
	import components.views.viewContainers.IntegraViewEvent;
	
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.FlexNativeMenu;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	import mx.events.FlexNativeMenuEvent;
	
	public class IntegraView extends Canvas
	{
		public function IntegraView()
		{
			super();

			percentWidth = 100;
			percentHeight = 100;
			
			_currentTitle = title;
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
			
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			addEventListener( NativeDragEvent.NATIVE_DRAG_DROP, onDragDrop );
			
			controller.addEventListener( AllDataChangedEvent.EVENT_NAME, onAllDataChangedEvent ); 
			controller.addEventListener( IntegraCommandEvent.EVENT_NAME, onIntegraCommandEvent ); 
		}

		public function get title():String { return ""; }
		public function set title( title:String ):void { _currentTitle = title }		
		public function get isTitleEditable():Boolean { return false; }
		
		public function get titlebarView():IntegraView { return null; }
		public function get breadcrumbsView():IntegraView { return null; }
		public function get vuMeterContainerID():int { return -1; }
		public function get color():uint { return 0; }
		
		public function get isSidebarColours():Boolean { return false; }
		
		public function set collapsed( collapsed:Boolean ):void 
		{ 
			if( collapsed == _collapsed ) return;
			
			_collapsed = collapsed;
			dispatchEvent( new IntegraViewEvent( IntegraViewEvent.COLLAPSE_CHANGED ) ); 
		}
		
		public function set expanded( expanded:Boolean ):void
		{
			collapsed = !expanded;
		} 
		
		public function set expandCollapseEnabled( expandCollapseEnabled:Boolean ):void
		{
			if( expandCollapseEnabled == _expandCollapseEnabled ) return;
			
			_expandCollapseEnabled = expandCollapseEnabled;
			dispatchEvent( new IntegraViewEvent( IntegraViewEvent.EXPAND_COLLAPSE_ENABLE_CHANGED ) );
		}
		
		
		public function get collapsed():Boolean { return _collapsed; }
		public function get expanded():Boolean { return !collapsed; }
		public function get expandCollapseEnabled():Boolean { return _expandCollapseEnabled; }
		
		
		public function resizeFinished():void {}
		
		public function titleClicked():void {}

		public function closeButtonClicked():void {}
		
		
		public function free():void
		{
			controller.removeEventListener( AllDataChangedEvent.EVENT_NAME, onAllDataChangedEvent ); 
			controller.removeEventListener( IntegraCommandEvent.EVENT_NAME, onIntegraCommandEvent );
			
			_contextMenu = null;
			
			allDecorationMightHaveChanged();

			Assert.assertFalse( _freed );
			_freed = true;
		}
		
		
		override public function set minHeight( value:Number ):void
		{
			super.minHeight = value;
			dispatchEvent( new IntegraViewEvent( IntegraViewEvent.MINHEIGHT_CHANGED ) );	
		}
		
		
		public function getInfoToDisplay( event:MouseEvent ):Info { return null; }
		

		protected function get model():IntegraModel { return IntegraModel.singleInstance; }
		protected function get controller():IntegraController { return IntegraController.singleInstance; }
		
		
		protected function addUpdateMethod( command:Class, method:Function ):void
		{
			var className:String = Utilities.getClassNameFromClass( command );
			
			Assert.assertFalse( _updateMethods.hasOwnProperty( className ) );
			_updateMethods[ className ] = method;
		} 	


		protected function addTitleInvalidatingCommand( command:Class ):void
		{
			var className:String = Utilities.getClassNameFromClass( command );
			
			Assert.assertFalse( _titleInvalidatingCommands.hasOwnProperty( className ) );
			_titleInvalidatingCommands[ className ] = 1;
		} 	


		protected function addTitlebarInvalidatingCommand( command:Class ):void
		{
			var className:String = Utilities.getClassNameFromClass( command );
			
			Assert.assertFalse( _titlebarInvalidatingCommands.hasOwnProperty( className ) );
			_titlebarInvalidatingCommands[ className ] = 1;
		} 	


		protected function addVuMeterChangingCommand( command:Class ):void
		{
			var className:String = Utilities.getClassNameFromClass( command );
			
			Assert.assertFalse( _vuMeterChangingCommands.hasOwnProperty( className ) );
			_vuMeterChangingCommands[ className ] = 1;
		} 	
		
		
		protected function addColorChangingCommand( command:Class ):void
		{
			var className:String = Utilities.getClassNameFromClass( command );
			
			Assert.assertFalse( _colorChangingCommands.hasOwnProperty( className ) );
			_colorChangingCommands[ className ] = 1;
		}


		protected function set contextMenuDataProvider( contextMenuDataProvider:Array ):void
		{
			if( !_contextMenu )
			{
				_contextMenu = new FlexNativeMenu;
				_contextMenu.setContextMenu( this );
				_contextMenu.addEventListener( "itemClick", onClickContextMenu );
				_contextMenu.addEventListener( FlexNativeMenuEvent.MENU_SHOW, onUpdateContextMenu );
				_contextMenu.keyEquivalentModifiersFunction = Utilities.handlePlatformIndependantMenuModifiers;
			}

			_contextMenu.dataProvider = contextMenuDataProvider;
		}
		
		protected function onAllDataChanged():void {}

		
		protected function onUpdateContextMenu( event:FlexNativeMenuEvent ):void
		{
			updateContextMenuItems( event.nativeMenu.items );
		}

		
		private function onAllDataChangedEvent( event:AllDataChangedEvent ):void
		{
			if( !model ) return;
			
			if( _addedToStage )
			{
				onAllDataChanged();
			}
			else
			{
				_dirty = true;
			}

			allDecorationMightHaveChanged();
		}
		
		
		private function onIntegraCommandEvent( event:IntegraCommandEvent ):void
		{
			var command:Command = event.command;
			Assert.assertNotNull( command );

			var className:String = Utilities.getClassNameFromObject( command );
			
			if( _updateMethods.hasOwnProperty( className ) )
			{
				if( _addedToStage )
				{
					var updateMethod:Function  = _updateMethods[ className ] as Function;
					Assert.assertNotNull( updateMethod );
				 
					updateMethod.apply( this, [ event.command ] );
				}
				else
				{
					_dirty = true;
				}
			}

			if( _titleInvalidatingCommands.hasOwnProperty( className ) )
			{
				titleMightHaveChanged();
			}
			
			if( _titlebarInvalidatingCommands.hasOwnProperty( className ) )
			{
				titlebarMightHaveChanged();
			}
			
			if( _vuMeterChangingCommands.hasOwnProperty( className ) )
			{
				vuMeterContainerMightHaveChanged();
			}

			if( _colorChangingCommands.hasOwnProperty( className ) )
			{
				colorMightHaveChanged();
			}
		}


		private function onAddedToStage( event:Event ):void
		{
			if( _addedToStage )	return;
			
			_addedToStage = true; 			

			if( _dirty )
			{
				onAllDataChanged();	
				allDecorationMightHaveChanged();
				_dirty = false;
			}
		}


		private function onRemovedFromStage( event:Event ):void
		{
			if( !_addedToStage ) return;

			_addedToStage = false;
		}
		
		
		private function allDecorationMightHaveChanged():void
		{
			titleMightHaveChanged();
			titlebarMightHaveChanged();
			vuMeterContainerMightHaveChanged();
			colorMightHaveChanged();
		}


		private function titleMightHaveChanged():void
		{
			var newTitle:String = title;
			
			if( newTitle != _currentTitle )
			{
				_currentTitle = newTitle;
				dispatchEvent( new IntegraViewEvent( IntegraViewEvent.TITLE_CHANGED ) );
			}
		}


		private function titlebarMightHaveChanged():void
		{
			dispatchEvent( new IntegraViewEvent( IntegraViewEvent.TITLEBAR_CHANGED ) );			
		}


		private function vuMeterContainerMightHaveChanged():void
		{
			dispatchEvent( new IntegraViewEvent( IntegraViewEvent.VUMETER_CONTAINER_CHANGED ) );			
		}
		
		
		private function colorMightHaveChanged():void
		{
			var newColor:uint = color;
			if( newColor == _currentColor ) 
			{
				return;
			}
			
			_currentColor = newColor;
			dispatchEvent( new IntegraViewEvent( IntegraViewEvent.COLOR_CHANGED ) );			
		}


		private function onMouseDown( event:MouseEvent ):void
		{
			var focusObject:InteractiveObject = getFocus();
			if( focusObject /*&& Utilities.pointIsInRectangle( focusObject.getRect( this ), mouseX, mouseY ) */ )
			{
				if( Utilities.isDescendant( focusObject, this ) )
				{					
					return;
				}
			}

			//ensure that this view recieves subsequent keyboard input, for context menu accelerators
			setFocus();
		}
		
		
		private function onDragDrop( event:NativeDragEvent ):void
		{
			var focusObject:InteractiveObject = getFocus();
			if( focusObject && Utilities.pointIsInRectangle( focusObject.getRect( this ), mouseX, mouseY ) )
			{
				return;
			}

			//ensure that this view recieves subsequent keyboard input, for context menu accelerators
			setFocus();
		}
		
		
		private function isDescendant( object:InteractiveObject ):Boolean
		{
			if( !object ) return false;
			
			if( !object.parent ) return false;
			
			if( object.parent == this ) return true;
			
			return isDescendant( object.parent );
		}
		
		
		public function handleContextMenu( event:KeyboardEvent ):Boolean
		{
			if( contextMenu )
			{
				return fireContextMenuAccelerator( contextMenu.items, event );
			}
			
			return false;
		}
		

		private function fireContextMenuAccelerator( menuItems:Array, event:KeyboardEvent ):Boolean
		{
			for each( var menuItem:Object in menuItems )
			{
				if( menuItem.submenu )
				{
					fireContextMenuAccelerator( menuItem.submenu.items, event );
				}

				if( !menuItem.data )
				{
					continue;
				}
				
				if( event.keyCode == menuItem.data.keyCode )
				{
					var modifiers:Array = Utilities.handlePlatformIndependantMenuModifiers( menuItem.data );

					var controlKeyRequired:Boolean = ( modifiers.indexOf( Keyboard.CONTROL ) >= 0 ); 
					var commandKeyRequired:Boolean = ( modifiers.indexOf( Keyboard.COMMAND ) >= 0 ); 
					var shiftKeyRequired:Boolean = ( modifiers.indexOf( Keyboard.SHIFT ) >= 0 );

					if( controlKeyRequired != event.controlKey ) continue;
					if( commandKeyRequired != event.commandKey ) continue;
					if( shiftKeyRequired != event.shiftKey ) continue;
					
					if( menuItem.data.updater )
					{
						menuItem.data.updater( menuItem );
					}
	
					if( !menuItem.enabled )
					{
						continue;
					}
					
					if( menuItem.data.handler ) 
					{
						menuItem.data.handler();
						
						return true;
					}
				}
			}
			
			return false;
		}


		private function onClickContextMenu( event:FlexNativeMenuEvent ):void
		{
			if( event.item.handler ) 
			{
				event.item.handler();	
			}
		} 


		private function updateContextMenuItems( items:Array ):void
		{
			for each( var menuItem:Object in items )
			{
				if( menuItem.data )
				{
					if( menuItem.data.updater )
					{
						menuItem.data.updater( menuItem );
					}
				}
				
				if( menuItem.submenu )
				{
					updateContextMenuItems( menuItem.submenu.items );
				}
			}
		}
		
		
		private var _updateMethods:Object = new Object;
		private var _titleInvalidatingCommands:Object = new Object;
		private var _titlebarInvalidatingCommands:Object = new Object;
		private var _vuMeterChangingCommands:Object = new Object;
		private var _colorChangingCommands:Object = new Object;
		 
		private var _contextMenu:FlexNativeMenu = null;
		private var _addedToStage:Boolean = false;
		private var _dirty:Boolean = true;

		private var _currentTitle:String = new String;
		private var _currentColor:uint = 0;

		private var _collapsed:Boolean = false;
		private var _expandCollapseEnabled:Boolean = true;
		
		private var _freed:Boolean = false;
	}
}
