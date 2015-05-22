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


package components.controller
{
	import __AS3__.vec.Vector;
	
	import components.model.IntegraModel;
	
	
	public class Command
	{
		public function Command()
		{
			_isNewUndoStep = true;
			
			_nextCommandID++;
			_commandID = _nextCommandID;
		}

		
		public function get id():uint { return _commandID; }
		public function get inverseCommands():Vector.<Command> { return _inverseCommands; }

		/* 
		Ephemeral commands (eg object selection) can set isNewUndoStep to false in their constructor 
		if they should not constitute their own undo step 
		*/
		public function set isNewUndoStep( isNewUndoStep:Boolean ):void { _isNewUndoStep = isNewUndoStep; }
		public function get isNewUndoStep():Boolean { return _isNewUndoStep; }

		/* 
		Implement initialize() for two reasons:
			1) to initialize any members whose initial values are not always specified 
				by the sender of the command
			
			2) to return false and reject the command if the parameters are invalid or 
				if the command would do nothing (ie replace a value with the same value
		*/ 
		public function initialize( model:IntegraModel ):Boolean { return true; }

		/* 
		Implement generateInverse() to make successive (typically 1) calls to pushInverseCommand 
		with a set of commands	which do the exact opposite of this command
		*/
		public function generateInverse( model:IntegraModel ):void {}	

		/* 
		Implement preChain when a command needs to execute other commands before executing itself 
		(for example removing connections before removing a module)
		*/
		public function preChain( model:IntegraModel, controller:IntegraController ):void {}
		
		/* 
		Implement execute to update the model from previous state to new state according to this command 
		*/
		public function execute( model:IntegraModel ):void {} 	
		
		/* 
		Implement postChain when a command needs to execute other commands after executing itself 
		(for example selecting an object after it was created)
		*/
		public function postChain( model:IntegraModel, controller:IntegraController ):void {}


		/* 
		Implement remoteCommandPostChain when a command needs to execute other commands after it is 
		execute as a server-originating command
		*/
		
		public function remoteCommandPostChain( model:IntegraModel, controller:IntegraController ):void {}
		
		/*
		Implement canReplacePreviousCommand for commands which replace a value, to minimise size of 
		transactions in which a single value changes many times.  canReplacePreviousCommand must only
		return true when the effect of the previous command is entirely replaced by the effect of this 
		command (eg setting the same attribute of the same module instance)   
		*/
		public function canReplacePreviousCommand( previousCommand:Command ):Boolean { return false; }


		/*
		call pushInverseCommand from generateInverse to provide a set of commands
		which do the exact opposite of this command
		*/
		protected function pushInverseCommand( inverseCommand:Command ):void
		{
			_inverseCommands.push( inverseCommand );	
		}		
		
		
		private var _isNewUndoStep:Boolean = true;
		private var _inverseCommands:Vector.<Command> = new Vector.<Command>;
		private var _commandID:uint = 0;
		
		static private var _nextCommandID:uint = 0;
	}
}