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
	import components.model.userData.SceneUserData;
	
	import flexunit.framework.Assert;
	
	public class Scene extends IntegraDataObject
	{
		public function Scene()
		{
			super();
			
			internalUserData = new SceneUserData; 
			
			_info.canEdit = true;
		}


		public function get start():int { return _start; } 
		public function get length():int { return _length; }
		public function get mode():String { return _mode; }
		
		public function get end():int { return _start + _length; }
		public function get centre():Number { return _start + _length / 2; }
		public function get keybinding():String { return userData.keybinding; }

		public function get info():Info { return _info; }
		
		public function set start( start:int ):void { _start = start; } 
		public function set length( length:int ):void { _length = length; }
		public function set mode( mode:String ):void { _mode = mode; }
		
		public function get userData():SceneUserData { return internalUserData as SceneUserData; }

		
		public function copySceneProperties( toCopy:Scene ):void
		{
			copyDataObjectProperties( toCopy );
			
			_start = toCopy.start;
			_length = toCopy.length;
			_mode = toCopy.mode;
			_info = toCopy.info;
		}		
	

		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{        
				case "start":
					_start = int( value );
					return true;
					
				case "length":
					_length = int( value );
					return true;
					
				case "mode":
					_mode = String( value );
					return true;
					
				case "info":
					_info.markdown = String( value );
					return true;
					
				default:
					Assert.assertTrue( false );
					return false;
			}
		}
	
		
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
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Scene";
		
		private var _start:int = 0;
		private var _length:int = 0;
		private var _mode:String = "";
		private var _info:Info = new Info; 
	}
}