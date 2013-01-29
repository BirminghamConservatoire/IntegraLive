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
	import components.utils.Utilities;
	
	public class Transaction
	{
		public function Transaction()
		{
		}
		
		public function pushUndoList( command:Command ):void
		{
			if( _commands.length > 0 )
			{
				//see whether the command can replace the previous command
				var previousCommand:Command = _commands[ _commands.length - 1 ];
				if( Utilities.getClassNameFromObject( previousCommand ) == Utilities.getClassNameFromObject( command ) )
				{
					if( command.canReplacePreviousCommand( previousCommand ) )
					{
						command.inverseCommands.length = 0;
						for each( var previousInverse:Command in previousCommand.inverseCommands )
						{
							command.inverseCommands.push( previousInverse );
						}

						_commands[ _commands.length - 1 ] = command;
						return;
					}
				} 
			}
		
			//otherwise append the transaction
			_commands.push( command );
		}

		
		public function get commands():Vector.<Command> { return _commands; }

		private var _commands:Vector.<Command> = new Vector.<Command>;
	}
}