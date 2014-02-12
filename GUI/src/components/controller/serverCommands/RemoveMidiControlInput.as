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
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scaler;
	
	import flexunit.framework.Assert;

	public class RemoveMidiControlInput extends ServerCommand
	{
		public function RemoveMidiControlInput( midiControlInputID:int )
		{
			super();

			_midiControlInputID = midiControlInputID;
		}

		public function get midiControlInputID():int { return _midiControlInputID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			if( !midiControlInput )
			{
				return false;
			}
			
			return true;
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new SetMidiControlInputValues( _midiControlInputID, "", 1, MidiControlInput.CC, 0 ) );
			
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			var scaler:Scaler = midiControlInput.scaler;
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetConnectionRouting( scaler.upstreamConnection.id, -1, null, scaler.id, "inValue" ) );
		}
		

		public override function generateInverse( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			var container:IntegraContainer = model.getContainerFromMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			Assert.assertNotNull( container );
			
			pushInverseCommand( new AddMidiControlInput( container.id, _midiControlInputID, midiControlInput.name, midiControlInput.scaler.id ) );	
		}

		
		public override function execute( model:IntegraModel ):void
		{
			//remove cross-references
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );

			var scaler:Scaler = midiControlInput.scaler;
			Assert.assertNotNull( scaler );
			
			_scalerID = scaler.id;
			
			scaler.midiControlInput = null;
			midiControlInput.scaler = null;

			//remove the midi control input
			model.removeDataObject( _midiControlInputID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _midiControlInputID ) );
			connection.callQueued( "command.delete" );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.delete" );
		}

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			Assert.assertTrue( _scalerID >= 0 );
			
			controller.processCommand( new RemoveScaledConnection( _scalerID ) );
		}
		

		private var _midiControlInputID:int;
		private var _scalerID:int = -1;
	}
}