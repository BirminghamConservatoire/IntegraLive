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


package components.model
{
	import flexunit.framework.Assert;
	
	public class Script extends IntegraDataObject
	{
		public function Script()
		{
			super();
		}

		public function get text():String { return _text; }
		public function get info():Info { return _info; }

		public function set text( text:String ):void { _text = text; }
		
		
		override public function set id( id:int ):void 
		{ 	
			super.id = id;
			_info.ownerID = id;		
		}				
		
		override public function set name( name:String ):void 
		{ 	
			super.name = name;
			_info.title = name;		
		}		

		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{         
				case "text":
					_text = String( value );
					return true;

				case "info":
					_info.markdown = String( value );
					return true;
					
				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Script";
	
		private var _text:String = null;
		
		private var _info:Info = new Info; 
	}
}
