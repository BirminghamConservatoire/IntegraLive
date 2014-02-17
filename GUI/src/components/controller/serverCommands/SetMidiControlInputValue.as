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
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scaler;
	
	import flexunit.framework.Assert;

	/* 
	note - this is an unusual ServerCommand, in that it is only ever used as a 'remote command' - ie
	dispatched by RemoteCommandHandler.  It is never dispatched by the user, via a view.  Therefore,
	some of it's methods (generateInverse / executeServerCommand / testServerResponse ) are not needed
	*/

	public class SetMidiControlInputValue extends ServerCommand
	{
		public function SetMidiControlInputValue( midiControlInputID:int, value:int )
		{
			super();

			_midiControlInputID = midiControlInputID;
			_value = value;
		}
		
		public function get midiControlInputID():int { return _midiControlInputID; }
		public function get value():int { return _value; }
	
		
		public override function execute( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			midiControlInput.value = _value;
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( _midiControlInputID ) + ".value" );
		}
		
		
		
		private var _midiControlInputID:int;
		private var _value:int;
	}
}