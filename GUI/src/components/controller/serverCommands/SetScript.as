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
	import components.model.Script;
	
	import flexunit.framework.Assert;
	

	public class SetScript extends ServerCommand
	{
		public function SetScript( scriptID:int, text:String )
		{
			super();
			
			_scriptID = scriptID;
			_text = text;
		}
		
		public function get scriptID():int { return _scriptID; }
		public function get text():String { return _text; }
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			var script:Script = model.getScript( _scriptID );
			if( !script )
			{
				Assert.assertTrue( false );
				return false;
			}
			
			return script.text != _text;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var script:Script = model.getScript( _scriptID );
			Assert.assertNotNull( script );
			
			pushInverseCommand( new SetScript( _scriptID, script.text ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var script:Script = model.getScript( _scriptID );
			Assert.assertNotNull( script );
			
			script.text = _text;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _scriptID ).concat( "text" ) );
			connection.addParam( _text, XMLRPCDataTypes.STRING );
			connection.callQueued( "command.set" );	
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return response.response == "command.set";
		}
		
		
		private var _scriptID:int;
		private var _text:String;
	}
}