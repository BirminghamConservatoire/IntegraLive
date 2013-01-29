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


package components.controller.serverCommands
{
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	

	public class ExecuteScript extends ServerCommand
	{
		public function ExecuteScript( scriptID:int )
		{
			super();
			
			_scriptID = scriptID;
		}

		public function get scriptID():int { return _scriptID; }
		

		public override function initialize( model:IntegraModel ):Boolean
		{
			return( model.getScript( _scriptID ) != null );
		}
	
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _scriptID ).concat( "trigger" ) );
			connection.callQueued( "command.set" );	
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return response.response == "command.set";
		}
		
		
		private var _scriptID:int;
	}
}