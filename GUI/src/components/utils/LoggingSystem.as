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
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
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
		
		
		public function getLogFiles( logFiles:Vector.<String> ):void
		{
			logFiles.push( serverLogfile );
			logFiles.push( guiLogfile );
			logFiles.push( pdLogfile );
		}
		
		
		public function handleServerOutput( serverOutput:String ):void
		{
			//first handle pd output tags which wrap output buffers
			if( _serverLogCarry )
			{
				serverOutput = _serverLogCarry + serverOutput;
			}
			
			var carryLength:int = getCharactersToCarry( serverOutput );
			if( carryLength > 0 )
			{
				var remainder:int = serverOutput.length - carryLength;
				Assert.assertTrue( remainder >= 0 );
				_serverLogCarry = serverOutput.substr( remainder );
				serverOutput = serverOutput.substr( 0, remainder );
			}
			else
			{
				_serverLogCarry = null;
			}
			
			//now split according to pd log tags
			splitByPDTags( serverOutput );
		}
		
		
		private function splitByPDTags( serverOutput:String ):void
		{
			if( serverOutput.length == 0 )
			{
				return;
			}
			
			if( _serverLogInPD )
			{
				var endTagPosition:int = serverOutput.indexOf( _pdEndTag );
				if( endTagPosition < 0 )
				{
					writeToLogfile( pdLogfile, serverOutput );
				}
				else
				{
					writeToLogfile( pdLogfile, serverOutput.substr( 0, endTagPosition ) + "\r\n" );
					_serverLogInPD = false;
					
					splitByPDTags( serverOutput.substr( endTagPosition + _pdEndTag.length ) );
				}
			}
			else
			{
				var startTagPosition:int = serverOutput.indexOf( _pdStartTag );
				if( startTagPosition < 0 )
				{
					writeToLogfile( serverLogfile, serverOutput );
				}
				else
				{
					writeToLogfile( serverLogfile, serverOutput.substr( 0, startTagPosition ) );
					_serverLogInPD = true;
						
					if( Config.singleInstance.timestampTrace )
					{
						writeToLogfile( pdLogfile, _trace.timestamp + " " );
					}
					
					splitByPDTags( serverOutput.substr( startTagPosition + _pdStartTag.length ) );
				}
			}
		}
		
		
		private function getCharactersToCarry( input:String ):int
		{
			//return the number of characters on the end of input which might constitute part of a split tag
			return Math.max( 
						getCharactersToCarryBySplitTag( input, _pdStartTag ), 
						getCharactersToCarryBySplitTag( input, _pdEndTag ) 
					);
		}

		
		private function getCharactersToCarryBySplitTag( input:String, tag:String ):int
		{
			//return the number of characters on the end of input which might constitute start of supplied tag
			
			//note this algorithm only works if no character appears twice in tag
			
			if( input.length == 0 ) return 0;
			
			var lastCharacter:String = input.charAt( input.length - 1 );
			
			var positionInTag:int = tag.indexOf( lastCharacter );
			if( positionInTag < 0 || positionInTag == tag.length - 1 ) return 0;
			
			var candidateTagSubsection:String = tag.substr( 0, positionInTag + 1 );
			
			if( input.substr( input.length - candidateTagSubsection.length ) == candidateTagSubsection )
			{
				return candidateTagSubsection.length;
			}
			else
			{
				return 0;
			}
		}
		
		
		private function writeToLogfile( logfile:String, content:String ):void
		{
			if( !logfile )
			{
				Trace.error( "No logfile" );
				return;
			}
			
			var stream:FileStream = new FileStream;
			stream.open( new File( logfile ), FileMode.APPEND );
			
			stream.writeUTFBytes( content );
			stream.close();
		}
		
		
		private function get serverLogfile():String
		{
			Assert.assertTrue( _initialized );
			
			var serverLog:File = _loggingDirectory.resolvePath( _serverLogfileName );
			return serverLog.nativePath;
		}
		
		
		private function get guiLogfile():String
		{
			var guiLog:File = _loggingDirectory.resolvePath( _guiLogfileName );
			return guiLog.nativePath;
		}

		
		private function get pdLogfile():String
		{
			var pdLog:File = _loggingDirectory.resolvePath( _pdLogfileName );
			return pdLog.nativePath;
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
		
		private var _serverLogInPD:Boolean = false; 
		private var _serverLogCarry:String = null; 
		
		private var _trace:Trace = new Trace;
		
		private static const _loggingDirectoryRootname:String = "runtime logs";
		private static const _sessionRootName:String = "session ";
		private static const _serverLogfileName:String = "server_log.txt" 
		private static const _guiLogfileName:String = "gui_log.txt"
		private static const _pdLogfileName:String = "pd_log.txt"

		//note - getCharactersToCarryBySplitTag will only work if no character appears twice in either tag
		private static const _pdStartTag:String = "<libpd>"; 
		private static const _pdEndTag:String = "</libpd>";	
			
			
		private static const _millisecondsPerDay:Number = 86400000;
	}
}