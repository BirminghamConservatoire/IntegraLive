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


package components.model.userData
{
	import flexunit.framework.Assert;

	public final class ViewMode
	{
		public function ViewMode()
		{
			clear();
		}
		
		public function get mode():String { return _mode; }
		public function get blockPropertiesOpen():Boolean { return _blockPropertiesOpen; }
		public function get popupStack():Vector.<String> { return _popupStack; }
		
		public function get preferencesOpen():Boolean { return ( openPopup == PREFERENCES ); }
		public function get moduleManagerOpen():Boolean { return ( openPopup == MODULE_MANAGER ); }
		public function get upgradeDialogOpen():Boolean { return ( openPopup == UPGRADE_DIALOG); }

		public function set mode( mode:String ):void { _mode = mode; }
		public function set blockPropertiesOpen( blockPropertiesOpen:Boolean ):void { _blockPropertiesOpen = blockPropertiesOpen; }

		public function openPreferences():void 
		{
			clearPopupStack();
			pushPopupStack( PREFERENCES );
		}
		
		
		public function closePreferences():void
		{
			removeFromPopupStack( PREFERENCES );
		}

		
		public function openModuleManager( onTopOfOthers:Boolean = false ):void 
		{
			if( !onTopOfOthers )
			{
				clearPopupStack();
			}
			
			pushPopupStack( MODULE_MANAGER );
		}

		
		public function closeModuleManager():void
		{
			removeFromPopupStack( MODULE_MANAGER );
		}
		
		
		public function openUpgradeDialog():void 
		{
			clearPopupStack();
			pushPopupStack( UPGRADE_DIALOG );
		}

		
		public function closeUpgradeDialog():void
		{
			removeFromPopupStack( UPGRADE_DIALOG );
		}
		
		
		public function clear():void
		{
			_mode = ARRANGE;
			_blockPropertiesOpen = false;
			clearPopupStack();
		}
		
		
		public function clone():ViewMode
		{
			var clone:ViewMode = new ViewMode();
			clone._mode = _mode;
			clone._blockPropertiesOpen = _blockPropertiesOpen;
			clone._popupStack = _popupStack.concat(); 
			
			return clone;
		}
		
		
		private function get openPopup():String
		{
			if( _popupStack.length > 0 )
			{
				return _popupStack[ _popupStack.length - 1 ];
			}
			else
			{
				return null;
			}
		}
		
		
		private function clearPopupStack():void
		{
			_popupStack.length = 0;
		}

		
		private function pushPopupStack( popup:String ):void
		{
			_popupStack.push( popup );
		}

		
		
		private function removeFromPopupStack( popup:String ):void
		{
			var index:int = _popupStack.lastIndexOf( popup );
			if( index >= 0 )
			{
				_popupStack.splice( index, 1 );
			}
		}
		
		
		
	    private var _mode:String;
	    private var _blockPropertiesOpen:Boolean;
		
		private var _popupStack:Vector.<String> = new Vector.<String>;

		private static const PREFERENCES:String = "preferences";
		private static const MODULE_MANAGER:String = "moduleManager";
		private static const UPGRADE_DIALOG:String = "upgradeDialog";
		
		public static const ARRANGE:String = "arrange";
		public static const LIVE:String = "live";
		
	}
}