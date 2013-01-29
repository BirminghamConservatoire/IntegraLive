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
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.Player;
	
	import flexunit.framework.Assert;

	public class SetPlaying extends ServerCommand
	{
		public function SetPlaying( playing:Boolean )
		{
			super();
			
		 	_playing = playing;
		}
		
		
		public function get playing():Boolean { return _playing; }

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( _playing != model.project.player.playing );
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetPlaying( model.project.player.playing ) );
		}


		public override function execute( model:IntegraModel ):void
		{
			var player:Player = model.project.player;
			Assert.assertNotNull( player );
			
			player.playing = _playing;
		}			


		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( model.project.player.id ).concat( "play" ) );
			connection.addParam( _playing ? 1 : 0, XMLRPCDataTypes.INT );
			connection.callQueued( "command.set" );
		}

		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.project.player.id ) + ".play" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}	
		

		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			return true;
		}
		
		
		private var _playing:Boolean;
	}
}
