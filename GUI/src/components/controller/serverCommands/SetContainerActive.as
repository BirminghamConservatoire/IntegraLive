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
	import components.model.IntegraContainer;
	
	import flexunit.framework.Assert;
	

	public class SetContainerActive extends ServerCommand
	{
		public function SetContainerActive( containerID:int, active:Boolean )
		{
			super();
			
			_containerID = containerID;
			_active = active;
		}
		
		public function get containerID():int { return _containerID; }
		public function get active():Boolean { return _active; }
	
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var container:IntegraContainer = model.getContainer( _containerID );
			if( !container )
			{
				Assert.assertTrue( false );
				return false;
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var container:IntegraContainer = model.getContainer( _containerID );
			Assert.assertNotNull( container );
			
			pushInverseCommand( new SetContainerActive( _containerID, container.active ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var container:IntegraContainer = model.getContainer( _containerID );
			Assert.assertNotNull( container );
			
			container.active = _active;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _containerID ).concat( "active" ) );
			connection.addParam( _active ? 1 : 0, XMLRPCDataTypes.INT );
			connection.callQueued( "command.set" );	
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return response.response == "command.set";
		}
		
		
		private var _containerID:int;
		private var _active:Boolean;
	}
}