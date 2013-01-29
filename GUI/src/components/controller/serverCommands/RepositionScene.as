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
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.UpdateProjectLength;	
	import components.model.IntegraModel;
	import components.model.Player;
	import components.model.Scene;
	
	import flexunit.framework.Assert;

	public class RepositionScene extends ServerCommand
	{
		public function RepositionScene( sceneID:int, start:int, length:int )
		{
			super();
			
			_sceneID = sceneID;
			_start = start;
			_length = length;
		}
		
		
		public function get sceneID():int { return _sceneID; }
		public function get start():int { return _start; }
		public function get length():int { return _length; }
		

		public override function initialize( model:IntegraModel ):Boolean
		{
			if( model.getScene( _sceneID ) == null )
			{
				return false;
			}
			
			if( _start < 0 || _length <= 0 )
			{
				return false;
			}

			return true;	
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );
			
			pushInverseCommand( new RepositionScene( _sceneID, scene.start, scene.length ) );
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );

			scene.start = _start;
			scene.length = _length;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var scenePath:Array = model.getPathArrayFromID( _sceneID );
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ scenePath.concat( "start" ), _start ];
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ scenePath.concat( "length" ), _length ];
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 2 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.set" ) return false;
			if( response[ 1 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}	
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new UpdateProjectLength() );
		}
		

		private var _sceneID:int;
		private var _start:int;
		private var _length:int;
	}
}