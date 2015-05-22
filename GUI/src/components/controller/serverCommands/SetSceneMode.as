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
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.Player;
	import components.model.Scene;
	
	import flexunit.framework.Assert;

	public class SetSceneMode extends ServerCommand
	{
		public function SetSceneMode( sceneID:int, mode:String )
		{
			super();
			
			_sceneID = sceneID;
			_mode = mode;
		}
		
		
		public function get sceneID():int { return _sceneID; }
		public function get mode():String { return _mode; }


		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !model.getScene( _sceneID ) )
			{
				return false;
			}
			
			return true;	
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );
			
			pushInverseCommand( new SetSceneMode( _sceneID, scene.mode ) );
		}	
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );

			scene.mode = _mode;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var scenePath:Array = model.getPathArrayFromID( _sceneID );
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ scenePath.concat( "mode" ), _mode ];
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 1 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}	
		

		private var _sceneID:int;
		private var _mode:String;
	}
}