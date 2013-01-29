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
	import components.model.IntegraModel;
	
	
	public class SceneUserData extends UserData
	{
		public function SceneUserData()
		{
			super();
		}

		public function get keybinding():String { return _keybinding; }
		
		public function set keybinding( keybinding:String ):void { _keybinding = keybinding; }

		protected override function writeToXML( xml:XML, model:IntegraModel ):void
		{
			super.writeToXML( xml, model );
			
			if( _keybinding != NO_KEYBINDING )
			{
				xml.appendChild( <keybinding>{ _keybinding }</keybinding> );
			}
		}


		protected override function readFromXML( xml:XML, model:IntegraModel, myID:int ):void
		{
			super.readFromXML( xml, model, myID );
			
			if( xml.hasOwnProperty( "keybinding" ) )
			{
				_keybinding = xml.keybinding;
			}
		}


		protected override function clear():void
		{
			super.clear();
			
			_keybinding = NO_KEYBINDING;
		}

		public static const KEYBINDINGS:String = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		public static const NO_KEYBINDING:String = "";
		
		private var _keybinding:String = NO_KEYBINDING;
		
	}
}
