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
	import components.controller.IntegraController;
	import components.controller.events.AllDataChangedEvent;
	import components.controller.serverCommands.NextScene;
	import components.controller.serverCommands.PreviousScene;
	import components.controller.userDataCommands.SetColorScheme;
	import components.controller.userDataCommands.SetContrast;
	import components.controller.userDataCommands.SetViewMode;
	import components.controller.userDataCommands.ShowInfoView;
	import components.model.IntegraModel;
	import components.model.userData.ColorScheme;
	import components.model.userData.ViewMode;
	import components.utils.Config;
	import components.utils.FontSize;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	

	public class MenuHandlers
	{
		public function MenuHandlers( application:IntegraLive )
		{
			_application = application;
			_model = IntegraModel.singleInstance;
			_controller = IntegraController.singleInstance;

			buildMenu();
		}
		
		
		public function enableMenus( enable:Boolean ):void
		{
			enableMenuItems( _menu.items, enable );
		}
		
		
		public function handleFunctionKey( event:KeyboardEvent, menu:NativeMenu = null ):void
		{
			//works around bug in air - function keys not automatically handled as menu shortcuts
			
			if( !menu ) menu = _menu;
			
			for each( var item:NativeMenuItem in menu.items )
			{
				if( item.submenu )
				{
					handleFunctionKey( event, item.submenu );
				}
				else
				{
					if( !item.keyEquivalent )
					{
						continue;
					}
					
					if( item.keyEquivalent.length != 3 )
					{
						continue;
					}
					
					var firstChar:String = item.keyEquivalent.charAt( 1 );
					var secondChar:String = item.keyEquivalent.charAt( 2 );
					
					if( firstChar.toLowerCase() != 'f' )
					{
						continue;
					}
					
					if( int( secondChar ) - 1 != event.keyCode - Keyboard.F1 )
					{
						continue;
					}
					
					var wantAlt:Boolean = false;
					var wantCommand:Boolean = Utilities.isMac;
					var wantCtrl:Boolean = Utilities.isWindows;
					var wantShift:Boolean = ( firstChar == firstChar.toUpperCase() );

					if( item.keyEquivalentModifiers )
					{
						wantCommand = ( item.keyEquivalentModifiers.indexOf( Keyboard.COMMAND ) >= 0 ); 
						wantAlt = ( item.keyEquivalentModifiers.indexOf( Keyboard.ALTERNATE ) >= 0 ); 
						wantCtrl = ( item.keyEquivalentModifiers.indexOf( Keyboard.CONTROL ) >= 0 ); 
					}

					if( wantAlt != event.altKey ) continue;
					if( wantCommand != event.commandKey ) continue;
					if( wantCtrl != event.ctrlKey ) continue;
					if( wantShift != event.shiftKey ) continue;
					
					item.dispatchEvent( new Event( Event.SELECT ) );					
				}
			}
		}
			
		
		private function buildMenu(): void
		{
			var menuInsertionIndex:int = 0;

			if( NativeApplication.supportsMenu )
			{
				createApplicationMenu();
				
				menuInsertionIndex = 1;
			}
			else
			{
				createNormalMenu();
			}
			
			//create top-level menus
			
			var showDebugMenu:Boolean = Config.singleInstance.showDebugMenu;
			if( showDebugMenu )
			{
				var debugMenu:NativeMenuItem = _menu.addSubmenuAt( new NativeMenu(), menuInsertionIndex, "Tests" );
			}
			
			var sceneMenu:NativeMenuItem = _menu.addSubmenuAt( new NativeMenu(), menuInsertionIndex, "Scene" );
			var viewMenu:NativeMenuItem = _menu.addSubmenuAt( new NativeMenu(), menuInsertionIndex, "View" );
			var editMenu:NativeMenuItem = _menu.addSubmenuAt( new NativeMenu(), menuInsertionIndex, "Edit" );
			var fileMenu:NativeMenuItem = _menu.addSubmenuAt( new NativeMenu(), menuInsertionIndex, "File" );
			
			var helpMenu:NativeMenuItem = _menu.addSubmenuAt( new NativeMenu(), _menu.numItems, "PlaceholderForHelp" );
			
			// Populate menus
			
			//File menu
			var newItem:NativeMenuItem = new NativeMenuItem( "New" );
			newItem.addEventListener(Event.SELECT, _application.newProject); 
			newItem.keyEquivalent = "n";
			fileMenu.submenu.addItem(newItem);
			
			var openItem:NativeMenuItem = new NativeMenuItem( "Open..." );
			openItem.addEventListener(Event.SELECT, _application.load); 
			openItem.keyEquivalent = "o";
			fileMenu.submenu.addItem(openItem);
			
			//separator
			fileMenu.submenu.addItem( new NativeMenuItem( "", true ) );
			
			var saveItem:NativeMenuItem = new NativeMenuItem( "Save" );
			saveItem.addEventListener(Event.SELECT, _application.save); 
			saveItem.keyEquivalent = "s";
			fileMenu.submenu.addItem(saveItem);
			
			var saveAsItem:NativeMenuItem = new NativeMenuItem( "Save As..." );
			saveAsItem.addEventListener(Event.SELECT, _application.saveAs); 
			saveAsItem.keyEquivalent = "S";
			fileMenu.submenu.addItem(saveAsItem);
			
			if( Utilities.isWindows )
			{
				//separator
				fileMenu.submenu.addItem( new NativeMenuItem("", true) );
				
				var preferencesItem:NativeMenuItem = new NativeMenuItem( "Preferences..." );
				preferencesItem.addEventListener( Event.SELECT, onShowPreferences ); 
				preferencesItem.addEventListener( Event.PREPARING, onUpdateShowPreferences ); 
				preferencesItem.keyEquivalent = ",";
				fileMenu.submenu.addItem( preferencesItem );
				
				//separator
				fileMenu.submenu.addItem( new NativeMenuItem( "", true ) );
				
				var exitItem:NativeMenuItem = new NativeMenuItem( "Exit" );
				exitItem.addEventListener( Event.SELECT, _application.quit ); 
				fileMenu.submenu.addItem( exitItem );
			}
			
			
			// Edit menu
			var undoItem:NativeMenuItem = new NativeMenuItem( "Undo" );
			undoItem.addEventListener(Event.SELECT, doUndo); 
			undoItem.addEventListener(Event.PREPARING, onUpdateUndoMenuItem ); 
			undoItem.keyEquivalent = "z";
			editMenu.submenu.addItem( undoItem );
			
			var redoItem:NativeMenuItem = new NativeMenuItem( "Redo" );
			redoItem.addEventListener(Event.SELECT, doRedo); 
			redoItem.addEventListener(Event.PREPARING, onUpdateRedoMenuItem); 
			redoItem.keyEquivalent = "Z";
			editMenu.submenu.addItem( redoItem );
			
			
			// View menu
			var arrangeViewItem:NativeMenuItem = new NativeMenuItem( "Arrange View" ); 
			arrangeViewItem.addEventListener( Event.SELECT, switchToArrangeView ); 
			arrangeViewItem.addEventListener( Event.PREPARING, onUpdateArrangeViewMenuItem ); 
			arrangeViewItem.keyEquivalent = "1";
			viewMenu.submenu.addItem( arrangeViewItem );
			
			var liveViewItem:NativeMenuItem = new NativeMenuItem( "Live View" ); 
			liveViewItem.addEventListener( Event.SELECT, switchToLiveView ); 
			liveViewItem.addEventListener( Event.PREPARING, onUpdateLiveViewMenuItem ); 
			liveViewItem.keyEquivalent = "2";
			viewMenu.submenu.addItem( liveViewItem);
			
			//separator 
			viewMenu.submenu.addItem( new NativeMenuItem( "", true ) );

			var infoViewItem:NativeMenuItem = new NativeMenuItem( "Info View" ); 
			infoViewItem.addEventListener(Event.SELECT, showInfoView ); 
			infoViewItem.addEventListener(Event.PREPARING, onUpdateInfoViewMenuItem ); 
			infoViewItem.keyEquivalent = "3";
			viewMenu.submenu.addItem( infoViewItem );
			
			//separator 
			viewMenu.submenu.addItem( new NativeMenuItem( "", true ) );
			
			var lightingItem:NativeMenuItem = new NativeMenuItem( "Lighting" ); 
			lightingItem.addEventListener(Event.SELECT, toggleLighting );
			lightingItem.addEventListener(Event.PREPARING, onUpdateLightingToggle ); 
			lightingItem.keyEquivalent = "l";
			viewMenu.submenu.addItem( lightingItem );

			var highContrastItem:NativeMenuItem = new NativeMenuItem( "High Contrast" ); 
			highContrastItem.addEventListener(Event.SELECT, toggleHighContrast );
			highContrastItem.addEventListener(Event.PREPARING, onUpdateHighContrastToggle ); 
			highContrastItem.keyEquivalent = "h";
			viewMenu.submenu.addItem( highContrastItem );
			
			var textSizeMenu:NativeMenuItem = viewMenu.submenu.addSubmenu( new NativeMenu(), "Text Size" );
			
			var largerItem:NativeMenuItem = new NativeMenuItem( "Larger" ); 
			largerItem.addEventListener(Event.SELECT, textLarger);
			largerItem.addEventListener(Event.PREPARING, onUpdateTextLargerMenuItem); 
			largerItem.keyEquivalent = "=";
			textSizeMenu.submenu.addItem(largerItem);
			
			var smallerItem:NativeMenuItem = new NativeMenuItem( "Smaller" ); 
			smallerItem.addEventListener(Event.SELECT, textSmaller);
			smallerItem.addEventListener(Event.PREPARING, onUpdateTextSmallerMenuItem); 
			smallerItem.keyEquivalent = "-";
			textSizeMenu.submenu.addItem(smallerItem);
			
			var resetItem:NativeMenuItem = new NativeMenuItem( "Reset" ); 
			resetItem.addEventListener(Event.SELECT, resetTextSize);
			resetItem.addEventListener(Event.PREPARING, onUpdateResetTextSizeMenuItem); 
			resetItem.keyEquivalent = "0";
			textSizeMenu.submenu.addItem(resetItem);
			
			// Scene menu
			var nextSceneItem:NativeMenuItem = new NativeMenuItem( "Next Scene" ); 
			nextSceneItem.addEventListener(Event.SELECT, switchToNextScene); 
			nextSceneItem.addEventListener(Event.PREPARING, onUpdateCycleScenesMenuItem); 
			nextSceneItem.keyEquivalent = "->";
			sceneMenu.submenu.addItem(nextSceneItem);
			
			var previousSceneItem:NativeMenuItem = new NativeMenuItem( "Previous Scene" ); 
			previousSceneItem.addEventListener(Event.SELECT, switchToPreviousScene); 
			previousSceneItem.addEventListener(Event.PREPARING, onUpdateCycleScenesMenuItem); 
			previousSceneItem.keyEquivalent = "<-";
			sceneMenu.submenu.addItem(previousSceneItem);
			
			
			if( Utilities.isMac )
			{
				// Integra Live menu
				var integraMenuItem:NativeMenuItem = _menu.getItemAt( 0 );
				var quitItem:NativeMenuItem = integraMenuItem.submenu.getItemAt( 6 );
				quitItem.addEventListener( Event.SELECT, _application.quit ); 
				
				integraMenuItem.submenu.removeItemAt( 0 );	//remove default About menuitem
				var aboutItem:NativeMenuItem = new NativeMenuItem( "About Integra Live" );
				aboutItem.addEventListener( Event.PREPARING, onUpdateAbout );
				aboutItem.addEventListener( Event.SELECT, onAbout );
				integraMenuItem.submenu.addItemAt( aboutItem, 0 );
						
				preferencesItem = new NativeMenuItem( "Preferences..." );
				preferencesItem.addEventListener( Event.SELECT, onShowPreferences ); 
				preferencesItem.addEventListener( Event.PREPARING, onUpdateShowPreferences ); 
				preferencesItem.keyEquivalent = ",";
				integraMenuItem.submenu.addItemAt( preferencesItem, 2 );
				
				//separator 
				integraMenuItem.submenu.addItemAt( new NativeMenuItem( "", true ), 3 );
			}
			
			// Help Menu
			var config:Config = Config.singleInstance;
			var helpLinks:Vector.<String> = config.helpLinks;

			var first:Boolean = true;
			
			for each( var helpLink:String in helpLinks )
			{
				if( first && Utilities.isWindows )
				{
					addHelpLink( helpMenu.submenu, helpLink, "\nf1", [] );
				}
				else
				{
					addHelpLink( helpMenu.submenu, helpLink );
				}

				first = false;
			}
				
			if( Utilities.isWindows )
			{
				//separator 
				helpMenu.submenu.addItem( new NativeMenuItem( "", true ) );
					
				var aboutMenuItem:NativeMenuItem = new NativeMenuItem( "About Integra Live" ); 
				aboutMenuItem.addEventListener(Event.SELECT, onAbout );
				aboutMenuItem.addEventListener(Event.PREPARING, onUpdateAbout );
				helpMenu.submenu.addItem( aboutMenuItem );
			}
			helpMenu.label = "Help";
			
			
			if( showDebugMenu )
			{
				var updateAllViewsItem:NativeMenuItem = new NativeMenuItem( "Update all views" ); 
				updateAllViewsItem.addEventListener( Event.SELECT, updateAllViews ); 
				debugMenu.submenu.addItem( updateAllViewsItem );
				
				var reloadAndUpdateItem:NativeMenuItem = new NativeMenuItem( "Reload from backend and update all views" ); 
				reloadAndUpdateItem.addEventListener( Event.SELECT, _application.reloadAndUpdate ); 
				debugMenu.submenu.addItem( reloadAndUpdateItem );
				
				var introspectServerItem:NativeMenuItem = new NativeMenuItem( "dump xmlrpc interface to gui log" ); 
				introspectServerItem.addEventListener( Event.SELECT, introspectServer ); 
				debugMenu.submenu.addItem( introspectServerItem );

				var dumpServerStateItem:NativeMenuItem = new NativeMenuItem( "dump server state to server log" ); 
				dumpServerStateItem.addEventListener( Event.SELECT, dumpServerState ); 
				debugMenu.submenu.addItem( dumpServerStateItem );
			}
		}

		
		private function addHelpLink( menu:NativeMenu, helpLink:String, keyboardEquivalent:String = null, keyboardModifiers:Array = null ):void
		{
			var separator:int = helpLink.indexOf( ";" );
			if( separator < 0 ) 
			{
				Trace.error( "can't add help link - no semicolon separating name and link" );
				return;
			}
			
			var name:String = helpLink.substr( 0, separator );
			var link:String = helpLink.substr( separator+1 );
			
			if( isWebLink( link ) )
			{
				//separator 
				menu.addItem( new NativeMenuItem( "", true ) );
			}
			
			var menuitem:NativeMenuItem = new NativeMenuItem( name );
			menuitem.data = link;
			menuitem.addEventListener( Event.SELECT, onHelpLink );
			menuitem.keyEquivalent = keyboardEquivalent;
			menuitem.keyEquivalentModifiers = keyboardModifiers;
			menu.addItem( menuitem );			
		}

		
		//creates menu for OS with application menu (ie Mac)
		private function createApplicationMenu():void
		{
			_menu = NativeApplication.nativeApplication.menu;
			
			//remove all but first and last items (leaving just Integra Live and Window menus)
			while( _menu.numItems > 2 )
			{
				_menu.removeItemAt( 1 );
			}
		}
		
		
		//creates menu for OS without application menu (ie Windows)
		private function createNormalMenu():void
		{
			_menu = new NativeMenu;
			
			_application.nativeWindow.menu = _menu;
		}
		
		
		private function enableMenuItems( items:Array, enable:Boolean ):void
		{
			for each( var menuItem:NativeMenuItem in items ) 
			{
				menuItem.enabled = enable;
				
				if( menuItem.hasOwnProperty( "submenu" ) )
				{
					if( menuItem.submenu != null ) 
					{
						enableMenuItems( menuItem.submenu.items, enable );
					}
				}
			}
		}		
		
		
		private function doUndo(event:Event):void
		{
			_controller.doUndo();
		}
		
		
		private function doRedo(event:Event):void
		{
			_controller.doRedo();
		}
		
		
		private function switchToNextScene(event:Event):void
		{
			_controller.processCommand( new NextScene() );
		}
		
		
		private function switchToPreviousScene(event:Event):void
		{
			_controller.processCommand( new PreviousScene() );
		}
		
		
		private function switchToArrangeView(event:Event):void
		{
			var viewMode:ViewMode = _model.project.userData.viewMode.clone();
			viewMode.mode = ViewMode.ARRANGE;
			_controller.processCommand( new SetViewMode( viewMode ) );
		}
		
		
		private function switchToLiveView( event:Event ):void
		{
			var viewMode:ViewMode = _model.project.userData.viewMode.clone();
			viewMode.mode = ViewMode.LIVE;
			_controller.processCommand( new SetViewMode( viewMode ) );
		}
		
		
		private function showInfoView( event:Event ):void
		{
			_controller.processCommand( new ShowInfoView( !_model.showInfoView ) );	
		}
		
		
		private function toggleLighting( event:Event ):void
		{
			switch( _model.project.userData.colorScheme )
			{
				case ColorScheme.LIGHT:
					_controller.processCommand( new SetColorScheme( ColorScheme.DARK ) );
					break;
				
				case ColorScheme.DARK:
					_controller.processCommand( new SetColorScheme( ColorScheme.LIGHT ) );
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}
		}
		
		
		private function toggleHighContrast( event:Event ):void
		{
			_controller.processCommand( new SetContrast( !_model.project.userData.highContrast ) );
		}
		
		
		private function updateAllViews( event:Event = null ):void
		{
			_controller.dispatchEvent( new AllDataChangedEvent() );
		}
		
		
		private function introspectServer( event:Event ):void
		{
			_controller.introspectServer();
		}
		
		
		private function dumpServerState( event:Event ):void
		{
			_controller.dumpServerState();
		}
		
		
		private function onShowPreferences(event:Event):void
		{ 
			var viewMode:ViewMode = _model.project.userData.viewMode.clone();
			viewMode.preferencesOpen = !viewMode.preferencesOpen;
			
			_controller.activateUndoStack = false;
			_controller.processCommand( new SetViewMode( viewMode ) );
			_controller.activateUndoStack = true;
		}

		
		private function textLarger(event:Event):void
		{
			_application.fontSize = FontSize.getLargerSize( _application.fontSize );
		}
		
		
		private function textSmaller(event:Event):void
		{
			_application.fontSize = FontSize.getSmallerSize( _application.fontSize );
		}
		
		
		private function resetTextSize(event:Event):void
		{
			_application.fontSize = FontSize.NORMAL;
		}	
		
		
		private function onUpdateUndoMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.enabled = _controller.canUndo;
		}     		
		
		
		private function onUpdateRedoMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.enabled = _controller.canRedo;
		}
		
		
		private function onUpdateCycleScenesMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.enabled = !Utilities.isObjectEmpty( _model.project.player.scenes );
		}
		
		private function onUpdateArrangeViewMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = ( _model.project.userData.viewMode.mode == ViewMode.ARRANGE );
			
		} 
		
		private function onUpdateLiveViewMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = ( _model.project.userData.viewMode.mode == ViewMode.LIVE );
		}
		
		
		private function onUpdateInfoViewMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = ( _model.showInfoView );
		}
				
		
		private function onUpdateLightingToggle( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = ( _model.project.userData.colorScheme == ColorScheme.LIGHT );				
		}     		
		
		
		private function onUpdateHighContrastToggle( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = ( _model.project.userData.highContrast );				
		}     		
		
		
		private function onUpdateTextLargerMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.enabled = ( _application.fontSize != FontSize.LARGEST );				
		}     		
		
		
		private function onUpdateTextSmallerMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.enabled = ( _application.fontSize != FontSize.SMALLEST );				
		}     		
		
		
		private function onUpdateResetTextSizeMenuItem( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.enabled = ( _application.fontSize != FontSize.NORMAL );				
		}
		
		
		private function onUpdateShowPreferences( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = _model.project.userData.viewMode.preferencesOpen; 
		}
		
		
		public function onAbout( event:Event ):void
		{
			_application.aboutBox.toggle( _application );
		}
		
		
		private function onUpdateAbout( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			menuItem.checked = ( _application.aboutBox.isShowing );				
		}     		
		
		
		private function onHelpLink( event:Event ):void
		{
			var link:String = event.target.data;
			if( !link )
			{
				Trace.error( "can't open help link" );
				return;
			}
			
			if( !isWebLink( link ) )
			{
				link = "file://" + link;
			}
			Trace.progress( "opening help link", link );

			navigateToURL( new URLRequest( link ), "_blank" );
		}
		
		
		private function isWebLink( link:String ):Boolean
		{
			return ( link.substr( 0, 7 ) == "http://" );			
		}				
		

		private var _application:IntegraLive;
		private var _model:IntegraModel; 
		private var _controller:IntegraController;
		
		private var _menu:NativeMenu;
	}
}
