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
	import components.controller.userDataCommands.DoTimelineAutoscroll;
	import components.model.IntegraModel;
	import components.model.Player;
	
	import flexunit.framework.Assert;

	public class SetPlayPosition extends ServerCommand
	{
		public function SetPlayPosition( playPosition:int, forceNoReplace:Boolean = false, shouldAutoScroll:Boolean = false )
		{
			super();
			
		 	_playPosition = playPosition;
			_canReplacePreviousCommand = !forceNoReplace;
			_shouldAutoScroll = shouldAutoScroll;
		}

		
		public function get playPosition():int { return _playPosition; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( _playPosition != model.project.player.playPosition );
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetPlayPosition( model.project.player.playPosition ) );
		}


		public override function execute( model:IntegraModel ):void
		{
			var player:Player = model.project.player;
			Assert.assertNotNull( player );
			
			player.playPosition = _playPosition;
		}			
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			if( _shouldAutoScroll )
			{
				controller.processCommand( new DoTimelineAutoscroll() );
			}
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( model.project.player.id ).concat( "tick" ) );
			connection.addParam( _playPosition, XMLRPCDataTypes.INT );
			connection.callQueued( "command.set" );
		}

		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( model.project.player.id ) + ".tick" );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}	
		

		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			return _canReplacePreviousCommand;
		}

		
		private var _playPosition:int;
		private var _canReplacePreviousCommand:Boolean;
		private var _shouldAutoScroll:Boolean;
	}
}