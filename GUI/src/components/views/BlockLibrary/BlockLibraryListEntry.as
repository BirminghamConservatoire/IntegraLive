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
	import components.model.Block;
	
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	public class BlockLibraryListEntry extends Object
	{
		public function BlockLibraryListEntry( file:File, isUserBlock:Boolean )
		{
			super();
			
			_file = file;
			_isUserBlock = isUserBlock;
			
			var filename:String = file.name;
			
			//strip extension
			var indexOfLastDot:int = filename.lastIndexOf( "." );
			if( indexOfLastDot >= 0 )
			{
				_name = filename.substr( 0, indexOfLastDot );
			}
			else
			{
				_name = filename;
			}
			
			//strip leading number, if not user block
			if( !isUserBlock )
			{
				_name = stripLeadingNumber( _name );
			}
		}
		
		
		public function get isValid():Boolean { return _name != null; }		
		public function get file():File { return _file; }
		
		public function get isUserItem():Boolean { return _isUserBlock; }
		
		public function toString():String { return _name; }


		private function stripLeadingNumber( string:String ):String
		{
			const leadingCharactersToStrip:String = "0123456789 ";
			
			for( var stripIndex:int = 0; stripIndex < string.length; stripIndex++ )
			{
				if( leadingCharactersToStrip.indexOf( string.charAt( stripIndex ) ) < 0 )
				{
					break;
				}
			}
			
			return string.substr( stripIndex );
		}

		
		private var _file:File = null;
		private var _name:String = null;
		private var _isUserBlock:Boolean = false;
	}
}