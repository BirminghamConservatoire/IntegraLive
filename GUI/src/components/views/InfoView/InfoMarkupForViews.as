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


package components.views.InfoView
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import components.model.Info;
	import components.utils.Trace;
	
	import flexunit.framework.Assert;

	public class InfoMarkupForViews
	{
		public function InfoMarkupForViews()
		{
			_default.title = "No View Info";
			_default.markdown = "error - can't find any info for this view";
		}
		
		
		public static function get instance():InfoMarkupForViews { return _singleInstance; }
		
		public function getInfoForView( viewName:String ):Info
		{
			if( _content.hasOwnProperty( viewName ) )
			{
				Assert.assertTrue( _content[ viewName ] is Info );
				return _content[ viewName ];
			}
			else
			{
				Trace.error( "unrecognised view name", viewName );
				return _default;
			}
		}
		
		
		public function loadContent():void
		{
			loadContentDirectoryBranch( File.applicationDirectory.resolvePath( _viewInfoDirectoryName ), "" );
		}
		
		
		private function loadContentDirectoryBranch( contentDirectory:File, path:String ):void
		{
			if( !contentDirectory.exists || !contentDirectory.isDirectory )
			{
				Trace.error( "can't find view info content directory", _viewInfoDirectoryName );
				return;
			}
			
			var content:Array = contentDirectory.getDirectoryListing();
			for each( var contentFile:File in content )
			{
				if( contentFile.isDirectory )
				{
					loadContentDirectoryBranch( contentFile, path + contentFile.name + "/" );
					continue;
				}
				
				if( contentFile.extension != _viewInfoFileExtension )
				{
					Trace.error( "skipping content file with incorrect extension", contentFile.nativePath );
					continue;
				}
				
				var contentName:String = path + contentFile.name;
				
				//strip extension
				contentName = contentName.substr( 0, contentName.length - _viewInfoFileExtension.length - 1 );
				var info:Info = new Info;
				
				//read content
				var fileSize:int = contentFile.size;
				var fileStream:FileStream = new FileStream();
				fileStream.open( contentFile, FileMode.READ );
				info.markdown = fileStream.readUTFBytes( fileSize );
				fileStream.close();		
				
				//store loaded info
				_content[ contentName ] = info;
			}
		}
		
		
		
		private var _content:Object = new Object;
		private var _default:Info = new Info;
		
		private static var _singleInstance:InfoMarkupForViews = new InfoMarkupForViews;
		
		private const _viewInfoDirectoryName:String = "assets/viewInfo/";
		private const _viewInfoFileExtension:String = "md";
	}
}