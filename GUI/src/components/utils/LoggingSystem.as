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
	import flash.events.UncaughtErrorEvent;
	import flash.events.UncaughtErrorEvents;
	import flash.filesystem.File;
	
	import flexunit.framework.Assert;
	
	public class LoggingSystem
	{
		public function LoggingSystem()
		{
		}
		
		
		public function initialize( uncaughtErrorEvents:UncaughtErrorEvents ):void
		{
			Assert.assertFalse( _initialized );
			
			uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, _trace.uncaughtErrorHandler );
			
			findRootDirectory();
			findLoggingDirectory();

			_trace.traceFileName = guiLogfile;
			
			var config:Config = Config.singleInstance;

			_trace.traceErrors = config.traceErrors;
			_trace.traceProgress = config.traceProgress;
			_trace.traceVerbose = config.traceVerbose;
			_trace.timestampTrace = config.timestampTrace;
			_trace.locationstampTrace = config.locationstampTrace;
			_trace.callstackstampErrors = config.callstackstampErrors;

			pruneRootDirectory();
			
			_initialized = true;
		}

	
		public function shutdown():void
		{
		}
		
		
		public function get serverLogfile():String
		{
			Assert.assertTrue( _initialized );
			
			var serverLog:File = _loggingDirectory.resolvePath( _serverLogfileName );
			return serverLog.nativePath;
		}
		
		
		public function getLogFiles( logFiles:Vector.<String> ):void
		{
			logFiles.push( serverLogfile );
			logFiles.push( guiLogfile );
		}
		
		
		private function get guiLogfile():String
		{
			var guiLog:File = _loggingDirectory.resolvePath( _guiLogfileName );
			return guiLog.nativePath;
		}
		
		
		private function findRootDirectory():void
		{
			_rootDirectory = File.applicationStorageDirectory.resolvePath( _loggingDirectoryRootname );
			if( !_rootDirectory.exists )
			{
				_rootDirectory.createDirectory();
			}
		}
		
		
		private function pruneRootDirectory():void
		{
			var config:Config = Config.singleInstance;
			
			var minLogfileAge:Number = new Date().time - config.logfileRetentionDays * _millisecondsPerDay;
			
			var childItems:Array = _rootDirectory.getDirectoryListing();
			
			for each( var childItem:File in childItems ) 
			{
				if( childItem.creationDate.time < minLogfileAge )
				{
					childItem.deleteDirectoryAsync( true );
				}
			}
		}
		
		
		private function findLoggingDirectory():void
		{
			var now:Date = new Date();

			var sessionRoot:String = _sessionRootName + now.date.toString() + "-" + (now.month+1).toString() + "-" + now.fullYear.toString();
			
			for( var i:int = 1; true; i++ )
			{
				var sessionIndex:String = i.toString();
				while( sessionIndex.length < 4 ) sessionIndex = "0" + sessionIndex;
				
				var loggingDirectoryName:String = sessionRoot + " " + sessionIndex;
				
				_loggingDirectory = _rootDirectory.resolvePath( loggingDirectoryName );
				if( _loggingDirectory.exists )
				{
					continue;
				}
				
				_loggingDirectory.createDirectory();
				break;
			}
		}
		
		
		private var _initialized:Boolean = false;
		private var _rootDirectory:File = null;
		private var _loggingDirectory:File = null;
		
		private var _trace:Trace = new Trace;
		
		private static const _loggingDirectoryRootname:String = "runtime logs";
		private static const _sessionRootName:String = "session ";
		private static const _serverLogfileName:String = "server_log.txt" 
		private static const _guiLogfileName:String = "gui_log.txt"
			
		private static const _millisecondsPerDay:Number = 86400000;
	}
}