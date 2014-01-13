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
	import com.mattism.http.xmlrpc.ConnectionImpl;
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import flexunit.framework.Assert;

	public class IntegraConnection extends ConnectionImpl
	{
		public function IntegraConnection( url:String )
		{
			super( url );
		}
		
		
		public function callQueued( method:String ):void
		{
			_methodName = method;
			
			if( _queuedCallBeingProcessed )
			{
				_queuedCalls.push( this );
			}
			else
			{
				startCall();
			}
		} 
		
		
		static public function removeLastQueuedCommand():void
		{
			if( _queuedCalls.length > 0 )
			{
				_queuedCalls.splice( _queuedCalls.length - 1, 1 );
			}
		}
		
		
		//helper to build an array into the form expected by xmlrpc library 
		public function addArrayParam( array:Array ):void
		{
			addParam( buildArrayParam( array ), XMLRPCDataTypes.ARRAY );
		}
		
		
		private function buildArrayParam( inputArray:Array ):Array
		{
			var outputArray:Array = new Array;
			
			for each( var inputElement:Object in inputArray )
			{
				outputArray.push( constructInstrumentedElement( inputElement ) );
			}
			
			return outputArray;
		}
		

		private function constructInstrumentedElement( inputElement:Object ):Object
		{
			var outputElement:Object = new Object;
			
			if( inputElement is String )
			{
				outputElement.type = XMLRPCDataTypes.STRING;
				outputElement.value = inputElement;
			}
			else
			{
				if( inputElement is int )
				{
					outputElement.type = XMLRPCDataTypes.INT;
					outputElement.value = inputElement;
				}
				else
				{
					if( inputElement is Number )
					{
						outputElement.type = XMLRPCDataTypes.DOUBLE;
						outputElement.value = inputElement;
					}
					else
					{
						if( inputElement is Array )
						{
							outputElement.type = XMLRPCDataTypes.ARRAY;
							outputElement.value = buildArrayParam( inputElement as Array );
						}
						else
						{
							//object used as map
							if( !Utilities.isObjectEmpty( inputElement ) )
							{
								outputElement.type = XMLRPCDataTypes.STRUCT;
								outputElement.value = new Object;

								for( var key:String in inputElement )
								{
									outputElement.value[ key ] = constructInstrumentedElement( inputElement[ key ] );
								}								
							}
						}
					}
				}					
			}
			
			return outputElement;
		}
		
		
		private function onQueuedCallComplete( event:Event ):void
		{
			callFinished();
		}


		private function onQueuedCallError( event:ErrorEvent ):void
		{
			callFinished();
		}
		
		
		private function onQueuedCallTimeout( event:TimerEvent ):void
		{
			callFinished();
		}
		
		
		private function startCall():void
		{
			Assert.assertNull( _timer );
			
			_timer = new Timer( timeoutMilliseconds, 1 );
			_timer.addEventListener( TimerEvent.TIMER_COMPLETE, onQueuedCallTimeout );
			_timer.start();
			
			addEventListener( Event.COMPLETE, onQueuedCallComplete );
			addEventListener( ErrorEvent.ERROR, onQueuedCallError );
			
			_queuedCallBeingProcessed = this;
			
			Assert.assertNotNull( _methodName );
			call( _methodName );
		}
		
		
		private function callFinished():void
		{
			Assert.assertTrue( _queuedCallBeingProcessed == this );
			Assert.assertNotNull( _timer );
			
			_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onQueuedCallTimeout );
			_timer.stop();
			_timer = null;
			
			removeEventListener( Event.COMPLETE, onQueuedCallComplete );
			removeEventListener( ErrorEvent.ERROR, onQueuedCallError );
			
			_queuedCallBeingProcessed = null;
			
			sendNextQueuedCall();
		}
		
		
		private static function sendNextQueuedCall():void
		{
			Assert.assertNull( _queuedCallBeingProcessed );
			
			if( _queuedCalls.length > 0 )
			{
				var newCall:IntegraConnection = _queuedCalls[ 0 ];
				_queuedCalls.splice( 0, 1 );
				
				newCall.startCall();
			}
		}
		
		
		private var _methodName:String = null;
		private var _timer:Timer = null;

		private static var _queuedCallBeingProcessed:IntegraConnection = null;
		private static var _queuedCalls:Vector.<IntegraConnection> = new Vector.<IntegraConnection>;
		
		private static const timeoutMilliseconds:Number = 1000;
	}
}