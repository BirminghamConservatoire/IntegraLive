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
	import components.controller.IntegraController;
	import components.controller.serverCommands.SetPlayPosition;
	import components.controller.serverCommands.SetContainerActive;
	import components.model.IntegraModel;
	import components.model.Block;
	import components.model.Track;
	

	public class ResetAllBlocks extends ServerCommand
	{
		public function ResetAllBlocks()
		{
			super();
		}


		public override function initialize( model:IntegraModel ):Boolean
		{
			return true;
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					controller.processCommand( new SetContainerActive( block.id, false ) );
				}
			}

			//now move play head to before start of project, and back to previous position
			var previousPlayPosition:int = model.project.player.playPosition;
			controller.processCommand( new SetPlayPosition( -1, true ) );
			controller.processCommand( new SetPlayPosition( previousPlayPosition, true ) );
		}
	}
}