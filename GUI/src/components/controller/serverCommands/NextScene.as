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
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.utils.Utilities;
	
	public class NextScene extends ServerCommand
	{
		public function NextScene()
		{
			super();
		}

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( !Utilities.isObjectEmpty( model.project.player.scenes ) );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			if( model.selectedScene ) 	
			{
				pushInverseCommand( new PreviousScene() );
			}
			else
			{
				pushInverseCommand( new SelectScene( -1 ) );
				pushInverseCommand( new SetPlayPosition( model.project.player.playPosition ) );
			}
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( model.project.player.id ).concat( "next" ) );
			connection.callQueued( "command.set" );

		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}	
	}
}
