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
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Midi;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	public class RemoveMidi extends ServerCommand
	{
		public function RemoveMidi( midiID:int )
		{
			super();

			_midiID = midiID; 
		}

		public function get midiID():int { return _midiID; }
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var midi:Midi = model.getMidi( _midiID );
			var container:IntegraContainer = model.getContainerFromMidi( _midiID );
			Assert.assertNotNull( midi );
			Assert.assertNotNull( container );
			
			pushInverseCommand( new AddMidi( container.id, _midiID, midi.name ) );	
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _midiID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _midiID ) );
			connection.callQueued( "command.delete" );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.delete" );
		}


		private var _midiID:int;
	}
}