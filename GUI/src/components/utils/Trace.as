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
	import flash.events.ErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.Capabilities;
	
	import flexunit.framework.Assert;

	
	public class Trace
	{
		public function Trace()
		{
			Assert.assertNull( _singleInstance );		//application should only instantiate one Trace instance
			
			//default values for tracing during startup (before initialize is called)
			
			_traceErrors = true;
			_locationstampTrace = true;
			_timestampTrace = true;
			_callstackstampErrors = true;
			
			_singleInstance = this;
		}

		
		public static function error( ...arguments ):void
		{
			if( !_singleInstance._traceErrors ) return;

			_singleInstance.doTrace( "Error", null, arguments, true );
		}
		

		public static function progress( ...arguments ):void
		{
			if( !_singleInstance._traceProgress ) return;
			
			_singleInstance.doTrace( "Progress", null, arguments, false );
		}
		
		
		public static function verbose( ...arguments ):void
		{
			if( !_singleInstance._traceVerbose ) return;
			
			_singleInstance.doTrace( "Verbose", null, arguments, false );
		}		

		
		public function set traceFileName( traceFileName:String ):void { _traceFileName = traceFileName; }
		
		public function set traceErrors( traceErrors:Boolean ):void { _traceErrors = traceErrors; }
		public function set traceProgress( traceProgress:Boolean ):void { _traceProgress = traceProgress; }
		public function set traceVerbose( traceVerbose:Boolean ):void { _traceVerbose = traceVerbose; }
		
		public function set timestampTrace( timestampTrace:Boolean ):void { _timestampTrace = timestampTrace; }
		public function set locationstampTrace( locationstampTrace:Boolean ):void { _locationstampTrace = locationstampTrace; }
		public function set callstackstampErrors( callstackstampErrors:Boolean ):void { _callstackstampErrors = callstackstampErrors; }

		
		public function uncaughtErrorHandler( event:UncaughtErrorEvent ):void
		{
			if( !Utilities.isDebugging )
			{
				//stop the annoying error box on non-debugging platforms
				event.preventDefault();
			}
			
			if( !_traceErrors ) return;
			
			var message:String;
			var error:Error = null;
			
			if( event.error is Error )
			{
				error = event.error as Error;
				message = error.getStackTrace();
				var indexOfNewline:int = message.indexOf( "\n" );
				if( indexOfNewline > 0 ) 
				{
					message = message.substr( 0, indexOfNewline );
				}
			}
			else 
			{
				if( event.error is ErrorEvent )
				{
					message = ErrorEvent( event.error ).text;
				}
				else
				{
					message = event.error.toString();
				}			
			}
			
			doTrace( "Unhandled Error", error, [ message ], true );
		}
		
		
		public function get timestamp():String
		{
			function makeTwoDigit( input:String ):String { while ( input.length < 2 ) input = "0" + input; return input; }
			
			var now:Date = new Date;
			
			var hours:String = makeTwoDigit( now.hours );
			var minutes:String = makeTwoDigit( now.minutes );
			var seconds:String = makeTwoDigit( now.seconds );
			var date:String = makeTwoDigit( now.date );
			var month:String = makeTwoDigit( now.month + 1 );
			var year:String = makeTwoDigit( String( now.fullYear ).substr( -1, 2 ) );
			
			return " [" + hours + ":" + minutes + ":" + seconds + " " + date + "/" + month + "/" + year + "]";			
		}
		
		
		private function doTrace( traceType:String, error:Error, arguments:Array, isError:Boolean ):void
		{
			var composite:String = traceType;
			
			if( _timestampTrace )
			{
				composite += timestamp;
			}
			
			if( _locationstampTrace || ( _callstackstampErrors && isError ) )
			{
				if( !error ) error = new Error;
				
				composite += ( " <" + getLocationstamp( error, isError ) + ">" );
			}
			
			composite += ":";
			for each( var argument:Object in arguments )
			{
				composite += " ";
				composite += argument.toString();
			}
			
			if( Capabilities.isDebugger )
			{
				trace( composite );
			}
			
			if( _singleInstance._traceFileName )
			{
				var stream:FileStream = new FileStream;
				stream.open( new File( _traceFileName ), FileMode.APPEND );
				stream.writeUTFBytes( composite + "\r\n" );
				stream.close();
			}
		}
		
		
		private function getLocationstamp( error:Error, isError:Boolean ):String
		{
			const callstackLineStart:String = "\tat ";
			const callstackLineEnd:String = "]"; 
			const classnameStartToken:String = "::"; 
			const pathStartToken:String = "[";
			const pathEndToken1:String = "/";
			const pathEndToken2:String = "\\";
			
			var thisClassName:String = Utilities.getClassNameFromObject( this );
			
			var callstack:String = error.getStackTrace();

			if( callstack )
			{
				if( isError && _callstackstampErrors )
				{
					return callstack;
				}
				
				//parse the callstack string to get a useful part of it
				
				var callstackLines:Array = callstack.split( "\n" );
	
				for each( var callstackLine:String in callstackLines )
				{
					if( callstackLine.substr( 0, callstackLineStart.length ) != callstackLineStart ) 
					{
						continue;
					}
					
					callstackLine = callstackLine.substr( callstackLineStart.length );
					
					if( callstackLine.substr( callstackLine.length - callstackLineEnd.length ) != callstackLineEnd )
					{
						continue;
					}
					
					callstackLine = callstackLine.substr( 0, callstackLine.length - callstackLineEnd.length );
					
					var indexOfClassname:int = callstackLine.indexOf( classnameStartToken );
					if( indexOfClassname > 0 )
					{
						callstackLine = callstackLine.substr( indexOfClassname + classnameStartToken.length );
					}
					
					if( callstackLine.substr( 0, thisClassName.length ) == thisClassName )
					{
						continue;
					}
										
					var indexOfStartOfPath:int = callstackLine.indexOf( pathStartToken );
					if( indexOfStartOfPath < 0 ) continue;

					var indexOfEndOfPath:int = Math.max( callstackLine.lastIndexOf( pathEndToken1 ), callstackLine.lastIndexOf( pathEndToken2 ) );
					if( indexOfEndOfPath < 0 ) continue;
			
					callstackLine = callstackLine.substr( 0, indexOfStartOfPath ) + " " + callstackLine.substr( indexOfEndOfPath + pathEndToken1.length );
					
					return callstackLine;			
				}
			}
			return "unknown location";
		}
		
		
		private static var _singleInstance:Trace = null;

		private var _traceFileName:String = null;
		
		private var _traceErrors:Boolean = false;
		private var _traceProgress:Boolean = false;
		private var _traceVerbose:Boolean = false;

		private var _timestampTrace:Boolean = false;
		private var _locationstampTrace:Boolean = false;
		private var _callstackstampErrors:Boolean = false;
	}
}