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


package 
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import flexunit.framework.Assert;
	
	public class Config
	{
		public function Config()
		{
			Assert.assertNull( _singleInstance );	//no need to create more than one Config instance
			
			loadConfig();
		}

		
		public static function get singleInstance():Config
		{
			if( !_singleInstance ) _singleInstance = new Config;
			return _singleInstance;
		} 		

		public function get hasIntegraDeveloperPrivileges():Boolean { return _hasIntegraDeveloperPrivileges; }
		public function get standardTags():Vector.<String>			{ return _standardTags; }

		public function get templatesPath():String					{ return _templatesPath; }
		public function get hostPath():String						{ return _hostPath; }
		public function get fileViewerPath():String					{ return _fileViewerPath; }
		public function get documentationPath():String				{ return _documentationPath; }
		public function get integraLiveExecutable():File			{ return _integraLiveExecutable; } 
		public function get hostArguments():Vector.<String>			{ return _hostArguments; }
		public function get helpLinks():Vector.<String>				{ return _helpLinks; }
		
		public function get widgets():Vector.<WidgetDefinition> 	{ return _widgetDefinitions; }

		private function loadConfig():void
		{
			var file:File = File.applicationDirectory.resolvePath( _configFileName );
			if( !file.exists )
			{
				trace( "failed to load config file ", file.nativePath );
				return;	
			}				
			
			var fileSize:int = file.size;
			var fileStream:FileStream = new FileStream();
			fileStream.open( file, FileMode.READ );
			var xmlString:String = fileStream.readUTFBytes( fileSize );
			fileStream.close();			
			
			XML.ignoreWhitespace = true;
			
			var xml:XML = new XML( xmlString );	

			if( xml.hasOwnProperty( "integradeveloper" ) )
			{
				_hasIntegraDeveloperPrivileges = true;
			}
			
			if( xml.hasOwnProperty( "standardtags" ) )
			{
				for each( var standardTag:XML in xml.standardtags.standardtag ) 
				{ 
					_standardTags.push( standardTag.toString() );
				}
			}
			
			
			if( xml.hasOwnProperty( "paths" ) )
			{
				var paths:XMLList = xml.paths;
				
				var osKey:String;
				if( Globals.isWindows ) osKey = "windows";
				if( Globals.isMac ) osKey = "mac";
				
				if( paths.hasOwnProperty( osKey ) )
				{
					var osSpecificPaths:XMLList = paths[ osKey ];
					if( osSpecificPaths.hasOwnProperty( "templatespath" ) )
					{
						_templatesPath = osSpecificPaths.templatespath;						
					}

					if( osSpecificPaths.hasOwnProperty( "hostpath" ) )
					{
						_hostPath = osSpecificPaths.hostpath;						
					}

					if( osSpecificPaths.hasOwnProperty( "fileviewerpath" ) )
					{
						_fileViewerPath = osSpecificPaths.fileviewerpath;						
					}
					
					if( osSpecificPaths.hasOwnProperty( "documentspath" ) )
					{
						_documentationPath = osSpecificPaths.documentspath;
						
						var applicationDirectory:String = File.applicationDirectory.nativePath; 
						_documentationDirectory = new File( applicationDirectory ).resolvePath( documentationPath );
						if( !_documentationDirectory.exists )
						{
							trace( "can't find documentation directory", _documentationDirectory.nativePath );
							_documentationDirectory = null;
						}
					}
					
					if( osSpecificPaths.hasOwnProperty( "integralivepath" ) )
					{
						var integraLivePath:String = osSpecificPaths.integralivepath;
						applicationDirectory = File.applicationDirectory.nativePath; 
						_integraLiveExecutable = new File( applicationDirectory ).resolvePath( integraLivePath );
						if( !_integraLiveExecutable.exists )
						{
							trace( "can't find integralive executable", _integraLiveExecutable.nativePath );
							_integraLiveExecutable = null;
						}
					}
					
				}
			}
			
			if( xml.hasOwnProperty( "hostargs" ) )
			{
				for each( var hostArg:XML in xml.hostargs.hostarg ) 
				{ 
					_hostArguments.push( hostArg.toString() );
				}
			}
			
			
			if( xml.hasOwnProperty( "helplinks" ) )
			{
				for each( var helpLink:XML in xml.helplinks.helplink ) 
				{ 
					if( !helpLink.hasOwnProperty( "@name" ) )
					{
						trace( "helplink missing a name attribute" );
						continue;
					}
					
					var name:String = helpLink.@name;
					_helpLinks.push( name + ";" + resolveDocumentationPath( helpLink.toString() ) );
				}
			}					
			
			if( xml.hasOwnProperty( "widgets" ) )
			{
				for each( var widget:XML in xml.widgets.widget ) 
				{ 
					if( !widget.hasOwnProperty( "@name" ) 
						|| !widget.hasOwnProperty( "@defaultWidth" )
						|| !widget.hasOwnProperty( "@defaultHeight" )
						|| !widget.hasOwnProperty( "@minWidth" )
						|| !widget.hasOwnProperty( "@minHeight" )
						|| !widget.hasOwnProperty( "@maxWidth" )
						|| !widget.hasOwnProperty( "@maxHeight" )
						|| !widget.hasOwnProperty( "attribute" ) )
					{
						trace( "Error in config file - widget definition incomplete: ", widget.toString() );		
						continue;
					}
					
					var widgetDefinition:WidgetDefinition = new WidgetDefinition;

					widgetDefinition.name = widget.@name;
					
					widgetDefinition.defaultSize.x = widget.@defaultWidth;
					widgetDefinition.defaultSize.y = widget.@defaultHeight;

					widgetDefinition.minimumSize.x = widget.@minWidth;
					widgetDefinition.minimumSize.y = widget.@minHeight;
					
					widgetDefinition.maximumSize.x = widget.@maxWidth;
					widgetDefinition.maximumSize.y = widget.@maxHeight;
					
					for each( var attribute:XML in widget.attribute )
					{
						widgetDefinition.attributes.push( attribute.toString() );
					}
					
					_widgetDefinitions.push( widgetDefinition );
				}
			}
		}
	
		
		private function resolveDocumentationPath( relativePath:String ):String
		{
			if( !_documentationDirectory )
			{
				trace( "documentation directory not defined" );
				return null;
			}
			
			var path:File = _documentationDirectory.resolvePath( relativePath );
			if( path.exists )
			{
				trace( "found documentation at", path.nativePath );
				return path.nativePath;
			}
			else
			{
				//assume it's a web link
				trace( "interpreting", relativePath, "as weblink" );
				
				return relativePath;
			}
		}
		
	
		private static var _singleInstance:Config = null;

		private var _hasIntegraDeveloperPrivileges:Boolean = false;
		
		private var _standardTags:Vector.<String> = new Vector.<String>;

		private var _templatesPath:String = "";
		private var _hostPath:String = "";
		private var _fileViewerPath:String = "";

		private var _documentationPath:String = "";
		private var _documentationDirectory:File = null;

		private var _integraLiveExecutable:File = null;
		
		private var _hostArguments:Vector.<String> = new Vector.<String>;
		private var _helpLinks:Vector.<String> = new Vector.<String>;
		
		private var _widgetDefinitions:Vector.<WidgetDefinition> = new Vector.<WidgetDefinition>;
		
		private const _configFileName:String = "assets/ModuleCreator_config.xml";
	}
}