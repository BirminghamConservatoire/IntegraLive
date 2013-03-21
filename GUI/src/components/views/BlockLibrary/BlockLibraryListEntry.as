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
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	import components.model.Info;
	import components.utils.Trace;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	

	public class BlockLibraryListEntry extends Object
	{
		public function BlockLibraryListEntry( file:File, tint:uint = 0 )
		{
			super();
			
			_filepath = file.nativePath;
			_modificationDate = file.modificationDate;
			_tint = tint;
			
			loadInfo( file );
		}
		
		
		public function get isValid():Boolean 		{ return _info != null; }		
		public function get filepath():String 		{ return _filepath; }
		public function get info():Info 			{ return _info; }
		public function get tint():uint 			{ return _tint; }
		
		public function isCurrent( file:File ):Boolean
		{
			if( !_modificationDate ) return false;
			
			return ( file.modificationDate.toUTCString() == _modificationDate.toUTCString() );
		}		
		
		public function toString():String { return _info ? _info.title : ""; }
		
		
		private function loadInfo( file:File ):void
		{
			var fileStream:FileStream = new FileStream();
			fileStream.open( file, FileMode.READ );
			var rawBytes:ByteArray = new ByteArray();
			fileStream.readBytes( rawBytes );
			fileStream.close();			
			
			var zipFile:FZip = new FZip();
			zipFile.loadBytes( rawBytes );
			
			var ixdFile:FZipFile = zipFile.getFileByName( _ixdFileName );
			if( !ixdFile )
			{
				Trace.error( "Can't extract ixd from block library item " + file.nativePath );
				return;
			}
			
			XML.ignoreWhitespace = true;
			var ixdXML:XML = new XML( ixdFile.content ); 
			
			var topLevelObjectXML:XML = ixdXML.children()[ 0 ];

			if( !topLevelObjectXML.hasOwnProperty( "@name" ) )
			{
				Trace.error( "Can't find name attribute" );
				return;
			}

			_info = new Info;
			
			_info.title = topLevelObjectXML.@name;
			var foundInfo:Boolean = false;
			
			for each( var child:XML in topLevelObjectXML.child( "attribute" ) )
			{
				if( child.hasOwnProperty( "@name" ) && child.@name == "info" )
				{
					_info.markdown = child.toString();
					foundInfo = true;
					break;
				}
			}
			
			if( !foundInfo )
			{
				_info.markdown = "No Info Available";
			}
		}
		

		
		private var _filepath:String = null;
		private var _modificationDate:Date = null;
		
		private var _info:Info = null;
		
		private var _tint:uint = 0;
		
		private static const _ixdFileName:String = "integra_data/nodes.ixd";
	}
}