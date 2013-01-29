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
	
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.IntegraModel;
	import components.model.Player;
	
	import flexunit.framework.Assert;

	public class SelectScene extends ServerCommand
	{
		public function SelectScene( sceneID:int )
		{
			super();
			
		 	_sceneID = sceneID;
		}

		
		public function get sceneID():int { return _sceneID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( _sceneID < 0 || model.getScene( _sceneID ) != null );
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SelectScene( model.project.player.selectedSceneID ) );
		}


		public override function execute( model:IntegraModel ):void
		{
			var player:Player = model.project.player;
			Assert.assertNotNull( player );
			
			player.selectedSceneID = _sceneID;
		}			


		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( model.project.player.id ).concat( "scene" ) );
			var sceneName:String = ( _sceneID >= 0 ) ?  model.getScene( _sceneID ).name : "";
			
			connection.addParam( sceneName, XMLRPCDataTypes.STRING );	
			
			connection.callQueued( "command.set" );
		}

		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.project.player.id ) + ".scene" );
		}
		

		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			if( model.primarySelectedBlock )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.selectedTrack.id, -1 ) );	
			}
			
			if( model.selectedTrack )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.project.id, -1 ) );	
			}
		}

		
		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}	
		
		
		private var _sceneID:int;
	}
}
