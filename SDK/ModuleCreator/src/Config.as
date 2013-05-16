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

		public function get templatesPath():String	{ return _templatesPath; }
		
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
	
	
		private static var _singleInstance:Config = null;

		private var _hasIntegraDeveloperPrivileges:Boolean = false;

		private var _templatesPath:String = "";
		
		private var _widgetDefinitions:Vector.<WidgetDefinition> = new Vector.<WidgetDefinition>;
		
		private const _configFileName:String = "assets/ModuleCreator_config.xml";
	}
}