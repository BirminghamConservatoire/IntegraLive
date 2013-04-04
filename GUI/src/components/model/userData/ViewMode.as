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
		public function get preferencesOpen():Boolean { return _preferencesOpen; }
		public function get moduleManagerOpen():Boolean { return _moduleManagerOpen; }

		public function set mode( mode:String ):void { _mode = mode; }
		public function set blockPropertiesOpen( blockPropertiesOpen:Boolean ):void { _blockPropertiesOpen = blockPropertiesOpen; }

		public function set preferencesOpen( preferencesOpen:Boolean ):void 
		{ 
			_preferencesOpen = preferencesOpen;
			if( _preferencesOpen ) _moduleManagerOpen = false;
		}

		public function set moduleManagerOpen( moduleManagerOpen:Boolean ):void 
		{ 
			_moduleManagerOpen = moduleManagerOpen;
			if( _moduleManagerOpen ) _preferencesOpen = false;
		}

		
		public function clear():void
		{
			_mode = ARRANGE;
			_blockPropertiesOpen = false;		
			_preferencesOpen = false;
			_moduleManagerOpen = false;
		}
		
		
		public function clone():ViewMode
		{
			var clone:ViewMode = new ViewMode();
			clone._mode = _mode;
			clone._blockPropertiesOpen = _blockPropertiesOpen;
			clone._preferencesOpen = _preferencesOpen; 
			clone._moduleManagerOpen = _moduleManagerOpen;
			
			return clone;
		}
		
		
	    public static const ARRANGE:String = "arrange";
	    public static const LIVE:String = "live";
	    
	    private var _mode:String;
	    private var _blockPropertiesOpen:Boolean;
	    private var _preferencesOpen:Boolean;
		private var _moduleManagerOpen:Boolean;
	}
}