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


package components.controller.undostack
{
	import __AS3__.vec.Vector;
	
	import components.controller.Command;
	import components.views.MouseCapture;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import flexunit.framework.Assert;

	
	public class UndoManager extends EventDispatcher
	{
		public function UndoManager()
		{
			clear();
		}
		

		public function clear():void
		{
			_undoStack.length = 0;
			_redoStack.length = 0;
			
			if( _inactivityTimer )
			{
				if( _inactivityTimer.running )
				{
					_inactivityTimer.stop();
				}
				_inactivityTimer.removeEventListener( TimerEvent.TIMER, onInactivity );
				_inactivityTimer = null;
			}
			
			_previousCaptureID = -1;
		}


		public function get canUndo():Boolean 
		{
			return _undoStack.length > 0;
		}


		public function get canRedo():Boolean
		{
			return _redoStack.length > 0;
		}


		public function doUndo( innerProcessMethod:Function ):void
		{
			var transaction:Transaction = _undoStack.pop();
			if( !transaction )
			{
				Assert.assertTrue( false );
				return;
			}

			_redoStack.push( transaction );
			
			for( var i:int = transaction.commands.length - 1; i >= 0; i-- )
			{
				applyInverse( transaction.commands[ i ], innerProcessMethod );
			}
		}


		public function doRedo( innerProcessMethod:Function ):void
		{
			var transaction:Transaction = _redoStack.pop();
			if( !transaction )
			{
				Assert.assertTrue( false );
				return;
			}

			_undoStack.push( transaction );

			for( var i:int = 0; i < transaction.commands.length; i++ )
			{
				apply( transaction.commands[ i ], innerProcessMethod );
			}
		}


		public function storeCommand( command:Command ):Boolean 	//returns true if command is start of a new transaction
		{
			var newTransaction:Boolean = false;
			
			if( isNewTransaction( command ) )
			{
				//start transaction
				_redoStack.length = 0;
				_undoStack.push( new Transaction );
				
				//store mouse capture
				_previousCaptureID = MouseCapture.instance.captureID;  
				
				//start inactivity timer
				startInactivityTimer();
				
				newTransaction = true;
			}

			Assert.assertTrue( _undoStack.length > 0 );
			
			_undoStack[ _undoStack.length - 1 ].pushUndoList( command );
			
			return newTransaction;
		}
			
		
		public function startInactivityTimer():void
		{
			_inactivityTimer = new Timer( 1, 1 );
			_inactivityTimer.addEventListener( TimerEvent.TIMER, onInactivity );
			_inactivityTimer.start();
		}

		
		private function applyInverse( command:Command, innerProcessMethod:Function ):void
		{
			var inverse:Vector.<Command> = command.inverseCommands;
			
			for( var i:int = inverse.length - 1; i >= 0; i-- )
			{
				apply( inverse[ i ], innerProcessMethod );
			}	
		}
		
		
		private function apply( command:Command, innerProcessMethod:Function ):void
		{
			innerProcessMethod( command );
		}


		private function isNewTransaction( command:Command ):Boolean
		{
			if( _undoStack.length == 0 )
			{
				return true;
			}
			
			if( !command.isNewUndoStep )
			{
				return false;
			}
			
			if( _inactivityTimer ) 
			{
				return false;
			}

			if( MouseCapture.instance.hasCapture )
			{
				var captureID:int = MouseCapture.instance.captureID;
				if( captureID == _previousCaptureID )
				{
					return false;
				}
			}
			
			return true;
		}
		
		
		private function onInactivity( event:TimerEvent ):void
		{
			if( _inactivityTimer )
			{
				_inactivityTimer.stop();
				_inactivityTimer.removeEventListener( TimerEvent.TIMER, onInactivity );
				_inactivityTimer = null;
			}
		}

		
		private var _undoStack:Vector.<Transaction> = new Vector.<Transaction>;
		private var _redoStack:Vector.<Transaction> = new Vector.<Transaction>;
		
		private var _inactivityTimer:Timer;
		private var _previousCaptureID:int;
	}
}