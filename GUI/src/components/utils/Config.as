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


package components.utils
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


		public function get serverPath():String 			{ return _serverPath; }
		public function get modulesPath():String			{ return _modulesPath; }
		public function get fileViewerPath():String			{ return _fileViewerPath; }
		
		public function get serverUrl():String				{ return _serverUrl; }
		public function get guiUrl():String					{ return _guiUrl; }
		public function get xmlrpcServerPort():int			{ return _xmlrpcServerPort; }
		public function get oscClientPort():int				{ return _oscClientPort; }

		public function get helpLinks():Vector.<String>		{ return _helpLinks; }
		public function get acknowledgementsLink():String 	{ return _acknowledgementsLink; }
		public function get moduleUpgradeHelpLink():String	{ return _moduleUpgradeHelpLink; } 	
		
		public function get traceErrors():Boolean			{ return _traceErrors; }
		public function get traceProgress():Boolean			{ return _traceProgress; }
		public function get traceVerbose():Boolean			{ return _traceVerbose; }
		public function get timestampTrace():Boolean 		{ return _timestampTrace; }
		public function get locationstampTrace():Boolean	{ return _locationstampTrace; }
		public function get threadstampTrace():Boolean		{ return _threadstampTrace; }
		public function get callstackstampErrors():Boolean	{ return _callstackstampErrors; }
		public function get logfileRetentionDays():int		{ return _logfileRetentionDays; }
		public function get crashReportUrl():String			{ return _crashReportUrl; }
		
		public function get showDebugMenu():Boolean
		{
			if( Utilities.isDebugging ) 
			{
				return true;
			}
			else
			{
				return _showDebugMenu;
			}
		}
		
		public function get upgradeInformationUrl():String 	{ return _upgradeInformationUrl; }
		
		public function get hasModuleBundles():Boolean		{ return _hasModuleBundles; }
		
		
		private function loadConfig():void
		{
			var file:File = File.applicationDirectory.resolvePath( _configFileName );
			if( !file.exists )
			{
				Trace.error( "failed to load config file " + file.nativePath );
				return;	
			}				
			
			var fileSize:int = file.size;
			var fileStream:FileStream = new FileStream();
			fileStream.open( file, FileMode.READ );
			var xmlString:String = fileStream.readUTFBytes( fileSize );
			fileStream.close();			
			
			XML.ignoreWhitespace = true;
			
			try
			{ 
				var xml:XML = new XML( xmlString );
			}
			catch( error:Error )
			{
				Trace.error( "Can't parse config xml:\n", xmlString );
				return;
			}
				
			
			if( xml.hasOwnProperty( "startup" ) )
			{
				var startup:XMLList = xml.child( "startup" );
				
				if( Utilities.isWindows )
				{
					if( startup.hasOwnProperty( "windows" ) )
					{
						loadOsSpecificStartupFields( startup.child( "windows" ) );
					}
				}
				
				if( Utilities.isMac )
				{
					if( startup.hasOwnProperty( "mac" ) )
					{
						loadOsSpecificStartupFields( startup.child( "mac" ) );
					}
				}
			}

			if( xml.hasOwnProperty( "connections" ) )
			{
				var connections:XMLList = xml.child( "connections" );
				
				if( connections.hasOwnProperty( "serverurl" ) )
				{
					_serverUrl = connections.child( "serverurl" ).toString();
				}
				
				if( connections.hasOwnProperty( "guiurl" ) )
				{
					_guiUrl = connections.child( "guiurl" ).toString();
				}				

				if( connections.hasOwnProperty( "xmlrpcserverport" ) )
				{
					_xmlrpcServerPort = connections.child( "xmlrpcserverport" ).toString();
				}				

				if( connections.hasOwnProperty( "oscclientport" ) )
				{
					_oscClientPort = connections.child( "oscclientport" ).toString();
				}				
			}
			
			if( xml.hasOwnProperty( "documentation" ) )
			{
				var documentation:XMLList = xml.child( "documentation" );
				
				if( Utilities.isWindows )
				{
					if( documentation.hasOwnProperty( "windows" ) )
					{
						findDocumentationDirectory( documentation.child( "windows" ) );
					}
				}
				
				if( Utilities.isMac )
				{
					if( documentation.hasOwnProperty( "mac" ) )
					{
						findDocumentationDirectory( documentation.child( "mac" ) );
					}
				}				
				
				if( documentation.hasOwnProperty( "helplinks" ) )
				{
					for each( var helpLink:XML in documentation.helplinks.helplink ) 
					{ 
						if( !helpLink.hasOwnProperty( "@name" ) )
						{
							Trace.error( "helplink missing a name attribute" );
							continue;
						}
						
						var name:String = helpLink.@name;
						_helpLinks.push( name + ";" + resolveDocumentationPath( helpLink.toString() ) );
					}
				}
				
				if( documentation.hasOwnProperty( "acknowledgementspath" ) )
				{
					_acknowledgementsLink = resolveDocumentationPath( documentation.child( "acknowledgementspath" ).toString() );
				}				

				if( documentation.hasOwnProperty( "moduleupgradehelp" ) )
				{
					_moduleUpgradeHelpLink = resolveDocumentationPath( documentation.child( "moduleupgradehelp" ).toString() );
				}				
			}
			
			
			if( xml.hasOwnProperty( "debugging" ) )
			{
				var debugging:XMLList = xml.child( "debugging" );
				
				if( debugging.hasOwnProperty( "traceerrors" ) )
				{
					_traceErrors = debugging.child( "traceerrors" ).toString() == "true";
				}

				if( debugging.hasOwnProperty( "traceprogress" ) )
				{
					_traceProgress = debugging.child( "traceprogress" ).toString() == "true";
				}
				
				if( debugging.hasOwnProperty( "traceverbose" ) )
				{
					_traceVerbose = debugging.child( "traceverbose" ).toString() == "true";
				}
				
				if( debugging.hasOwnProperty( "timestamptrace" ) )
				{
					_timestampTrace = debugging.child( "timestamptrace" ).toString() == "true";
				}
				
				if( debugging.hasOwnProperty( "locationstamptrace" ) )
				{
					_locationstampTrace = debugging.child( "locationstamptrace" ).toString() == "true";
				}

				if( debugging.hasOwnProperty( "threadstamptrace" ) )
				{
					_threadstampTrace = debugging.child( "threadstamptrace" ).toString() == "true";
				}

				if( debugging.hasOwnProperty( "callstackstamperrors" ) )
				{
					_callstackstampErrors = debugging.child( "callstackstamperrors" ).toString() == "true";
				}

				if( debugging.hasOwnProperty( "logfileretentiondays" ) )
				{
					_logfileRetentionDays = debugging.child( "logfileretentiondays" ).toString();
				}
				
				if( debugging.hasOwnProperty( "crashreporturl" ) )
				{
					_crashReportUrl = debugging.child( "crashreporturl" ).toString();
				}

				if( debugging.hasOwnProperty( "showdebugmenu" ) )
				{
					_showDebugMenu = debugging.child( "showdebugmenu" ).toString() == "true";
				}
			}	

			if( xml.hasOwnProperty( "upgrades" ) )
			{
				var upgrades:XMLList = xml.child( "upgrades" );
				
				if( upgrades.hasOwnProperty( "upgradeinformationurl" ) )
				{
					_upgradeInformationUrl = upgrades.child( "upgradeinformationurl" ).toString();
				}
			}	
			
			_hasModuleBundles = xml.hasOwnProperty( "hasModuleBundles" );
		}

		
		private function loadOsSpecificStartupFields( osSpecificStartupFields:XMLList ):void
		{
			if( osSpecificStartupFields.hasOwnProperty( "serverpath" ) )
			{
				_serverPath = osSpecificStartupFields.child( "serverpath" ).toString();
			}
			
			if( osSpecificStartupFields.hasOwnProperty( "modulespath" ) )
			{
				_modulesPath = osSpecificStartupFields.child( "modulespath" ).toString();
			}
			
			if( osSpecificStartupFields.hasOwnProperty( "fileviewerpath" ) )
			{
				_fileViewerPath = osSpecificStartupFields.fileviewerpath;						
			}
		}
		
		
		private function findDocumentationDirectory( osSpecificDocumentationFields:XMLList ):void
		{
			if( osSpecificDocumentationFields.hasOwnProperty( "documentspath" ) )
			{
				var documentationPath:String = osSpecificDocumentationFields.child( "documentspath" ).toString();
				
				var applicationDirectory:String = File.applicationDirectory.nativePath; 
				_documentationDirectory = new File( applicationDirectory ).resolvePath( documentationPath );
				if( !_documentationDirectory.exists )
				{
					Trace.error( "can't find documentation directory", _documentationDirectory.nativePath );
					_documentationDirectory = null;
					
				}
			}			
		}
		
		
		private function resolveDocumentationPath( relativePath:String ):String
		{
			if( !_documentationDirectory )
			{
				Trace.error( "documentation directory not defined" );
				return null;
			}
			
			var anchorIndex:int = relativePath.indexOf( "#" );
			var pathWithoutAnchors:String;
			var anchors:String;
			if( anchorIndex >= 0 )
			{
				pathWithoutAnchors = relativePath.substr( 0, anchorIndex );
				anchors = relativePath.substr( anchorIndex );
			}
			else
			{
				pathWithoutAnchors = relativePath;
				anchors = "";
			}
			
			var path:File = _documentationDirectory.resolvePath( pathWithoutAnchors );
			if( path.exists )
			{
				Trace.progress( "found documentation at", path.nativePath );
				
				return "file://" + path.nativePath + anchors;
			}
			else
			{
				//assume it's a web link
				Trace.progress( "interpreting", relativePath, "as weblink" );
				
				return relativePath;
			}
		}
		
		
		private static var _singleInstance:Config = null;
		
		private var _serverPath:String = null;
		private var _modulesPath:String = null;
		private var _fileViewerPath:String = null;
		
		private var _serverUrl:String = null;
		private var _guiUrl:String = null;
		private var _xmlrpcServerPort:int = 0;
		private var _oscClientPort:int = 0;
		
		private var _documentationDirectory:File = null;
		
		private var _helpLinks:Vector.<String> = new Vector.<String>;
		private var _acknowledgementsLink:String = null;
		private var _moduleUpgradeHelpLink:String = null;
		
		private var _traceErrors:Boolean = false;
		private var _traceProgress:Boolean = false;
		private var _traceVerbose:Boolean = false;
		private var _timestampTrace:Boolean = false;
		private var _locationstampTrace:Boolean = false;
		private var _threadstampTrace:Boolean = false;
		private var _callstackstampErrors:Boolean = false;
		private var _logfileRetentionDays:int = -1;
		private var _crashReportUrl:String = null;
		private var _showDebugMenu:Boolean = false;

		private var _upgradeInformationUrl:String = null;
		
		private var _hasModuleBundles:Boolean = false;

		private const _configFileName:String = "assets/IntegraLiveConfig.xml";
	}
}