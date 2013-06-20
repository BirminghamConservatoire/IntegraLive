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
	public final class ViewMode
	{
		public function ViewMode()
		{
			clear();
		}
		
		public function get mode():String { return _mode; }
		public function get blockPropertiesOpen():Boolean { return _blockPropertiesOpen; }
		public function get preferencesOpen():Boolean { return ( _openPopup == PREFERENCES ); }
		public function get moduleManagerOpen():Boolean { return ( _openPopup == MODULE_MANAGER ); }
		public function get upgradeDialogOpen():Boolean { return ( _openPopup == UPGRADE_DIALOG); }

		public function set mode( mode:String ):void { _mode = mode; }
		public function set blockPropertiesOpen( blockPropertiesOpen:Boolean ):void { _blockPropertiesOpen = blockPropertiesOpen; }

		public function set preferencesOpen( preferencesOpen:Boolean ):void 
		{ 
			setOpenPopup( PREFERENCES, preferencesOpen );
		}

		public function set moduleManagerOpen( moduleManagerOpen:Boolean ):void 
		{ 
			setOpenPopup( MODULE_MANAGER, moduleManagerOpen );
		}

		
		public function set upgradeDialogOpen( upgradeDialogOpen:Boolean ):void 
		{ 
			setOpenPopup( UPGRADE_DIALOG, upgradeDialogOpen );
		}
		
		
		public function clear():void
		{
			_mode = ARRANGE;
			_blockPropertiesOpen = false;		
			_openPopup = null;
		}
		
		
		public function clone():ViewMode
		{
			var clone:ViewMode = new ViewMode();
			clone._mode = _mode;
			clone._blockPropertiesOpen = _blockPropertiesOpen;
			clone._openPopup = _openPopup; 
			
			return clone;
		}
		
		
		private function setOpenPopup( popup:String, open:Boolean ):void
		{
			if( open )
			{
				_openPopup = popup;
			}
			else
			{
				if( _openPopup == popup )
				{
					_openPopup = null;
				}
			}
		}

		
		
	    private var _mode:String;
	    private var _blockPropertiesOpen:Boolean;
		
		private var _openPopup:String = null;

		private static const PREFERENCES:String = "preferences";
		private static const MODULE_MANAGER:String = "moduleManager";
		private static const UPGRADE_DIALOG:String = "upgradeDialog";
		
		public static const ARRANGE:String = "arrange";
		public static const LIVE:String = "live";
		
	}
}