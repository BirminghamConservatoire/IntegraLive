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
	import flash.errors.EOFError;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.events.Event; 
	import flash.events.TimerEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.DatagramSocketDataEvent;
	import flash.net.DatagramSocket; 
	import org.tuio.osc.OSCMessage;
	import flexunit.framework.Assert;
	import components.utils.Trace;

	public class OSCServer
	{
		public function OSCServer( url:String, commandHandler:Object )
		{
			if( !url || url.length == 0 )
			{
				Trace.error( "Can't start OSC Server - no url provided!" );
				return;
			}
			
			var indexOfColon:int = url.indexOf( ":" );
			Assert.assertTrue( indexOfColon >= 0 );

			_localPort = int( url.substr( indexOfColon + 1 ) );
			_localAddress = url.substr( 0, indexOfColon );
			_commandHandler = commandHandler;

			_attemptRebindTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onAttemptRebind );
			_datagramSocket.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			_datagramSocket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			_datagramSocket.addEventListener( Event.CLOSE, onSocketClosed );
			_datagramSocket.addEventListener( DatagramSocketDataEvent.DATA, onClientSocketData );
			bind();
		}

		
		public function close():void
		{
			if( _datagramSocketOpen )
			{
				_datagramSocket.close();
				_datagramSocketOpen = false;
			}
		}
		
		
		private function bind():void
		{
			try
			{
				_datagramSocket.bind( _localPort, _localAddress );
			}
			catch( error:Error )
			{
				Trace.error( "Error binding socket: " + error.message );
				_attemptRebindTimer.reset();
				_attemptRebindTimer.start();
				return;
			}
			
			_datagramSocket.receive();
			
			Trace.progress( "Bound to: " + _datagramSocket.localAddress + ":" + _datagramSocket.localPort );
			_datagramSocketOpen = true;
		}
		
		
		private function onAttemptRebind( event:TimerEvent ):void
		{
			bind();
		}

		
		private function onClientSocketData( event:DatagramSocketDataEvent ):void
		{
			var data:ByteArray = event.data;
			Assert.assertNotNull( data );
			var msg:OSCMessage = new OSCMessage( data );
			
			//Trace.verbose( "Received: " + msg.toString() );
			processFunctionCall( msg );
		}
		
		
		private function onSocketClosed( event:Event ):void
		{
			_datagramSocket.close(); // not sure about this  -jb
		}

		
		private function onIOError( event:IOErrorEvent ):void 
		{
			Trace.error( "IO Error: " + event );
		}

		
		private function onSecurityError( event:SecurityErrorEvent ):void 
		{
			Trace.error( "Security Error: " + event );
		}

		
		private function processFunctionCall( msg:OSCMessage ):void 
		{
			var address:String = msg.address.substring( 1 ); // remove leading '/'
			var methodName:String = makeCamelCase( address );
			var arguments:Array = msg.arguments;
			
			Trace.verbose( msg.argumentsToString() );

			if( !_commandHandler.hasOwnProperty( methodName ) || !_commandHandler[ methodName ] is Function )
			{
				Trace.error( "unhandled method: " + methodName );
				return;
			}

			var methodToCall:Function = _commandHandler[ methodName ] as Function;
			
			try
			{
				var result:String = methodToCall.apply( _commandHandler, arguments );	
			}
			catch( error:Error )
			{
				Trace.error( "method call failed: " + methodName, error.name, error.message );
				return;
			}
		}

		
		private function makeCamelCase( methodName:String ):String
		{
			var indexOfDot:int = methodName.indexOf( "." ); 
			while( indexOfDot >= 0 )
			{
				var newMethodName:String = methodName.slice( 0, indexOfDot ); 
				if( indexOfDot + 1 < methodName.length )
				{
					newMethodName += methodName.substr( indexOfDot + 1, 1 ).toUpperCase();
					
					if( indexOfDot + 2 < methodName.length )
					{
						newMethodName += methodName.substr( indexOfDot + 2 );
					}
				}
				
				methodName = newMethodName;
				
				indexOfDot = methodName.indexOf( "." );
			}
			
			return methodName;
		}
		

		private var _datagramSocket:DatagramSocket = new DatagramSocket(); 
		private var _datagramSocketOpen:Boolean = false;

		private var _localPort:int;
		private var _localAddress:String;
		private var _commandHandler:Object;

		private static const REBIND_MILLISECONDS:Number = 5000;
		private var _attemptRebindTimer:Timer = new Timer( REBIND_MILLISECONDS, 1 ); 
	}
}

