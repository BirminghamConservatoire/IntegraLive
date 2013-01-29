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
	import flexunit.framework.Assert;
	
	public class RemoteCommandResponse
	{
		public function RemoteCommandResponse( response:String, command:ServerCommand = null )
		{
			_response = response;
			_command = command;
			
			switch( _response )
			{
				case RELOAD_ALL:
				case IGNORE:
					Assert.assertNull( command );
					break;
					
				case HANDLE_COMMAND:
					Assert.assertNotNull( command );
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}
		}

		public function get response():String { return _response; }
		public function get command():ServerCommand { return _command; } 

		public static const RELOAD_ALL:String = "reloadAll";
		public static const HANDLE_COMMAND:String = "handle";
		public static const IGNORE:String = "ignore";

		private var _response:String = null;
		private var _command:ServerCommand = null;
	}
}