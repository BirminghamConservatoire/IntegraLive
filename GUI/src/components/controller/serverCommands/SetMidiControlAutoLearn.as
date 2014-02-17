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
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scaler;
	
	import flexunit.framework.Assert;

	public class SetMidiControlAutoLearn extends ServerCommand
	{
		public function SetMidiControlAutoLearn( midiControlInputID:int, autoLearn:Boolean )
		{
			super();

			_midiControlInputID = midiControlInputID;
			_autoLearn = autoLearn;
		}
		
		public function get midiControlInputID():int { return _midiControlInputID; }
		public function get autoLearn():Boolean { return _autoLearn; }
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !model.doesObjectExist( midiControlInputID ) || !( model.getDataObjectByID( midiControlInputID ) is MidiControlInput ) )
			{
				return false;
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			pushInverseCommand( new SetMidiControlAutoLearn( _midiControlInputID, midiControlInput.autoLearn ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			midiControlInput.autoLearn = _autoLearn;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var midiControlInputPath:Array = model.getPathArrayFromID( _midiControlInputID );
			
			connection.addArrayParam(  midiControlInputPath.concat( "autoLearn" ) );
			connection.addParam( _autoLearn ? 1 : 0, XMLRPCDataTypes.INT );
			
			connection.callQueued( "command.set" );						
		}
		
		
		override public function remoteCommandPostChain( model:IntegraModel, controller:IntegraController ):void
		{
			/*
			on end of autolearn, if scaler is set to ignore out-of range, restrict it's input range
			to the exact autolearnt value.  This automatically sorts out cc controls which send a 0 on release
			*/
			
			if( _autoLearn == false )
			{
				var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
				Assert.assertNotNull( midiControlInput );
				
				var scaler:Scaler = midiControlInput.scaler;
				Assert.assertNotNull( scaler );
				
				if( scaler.inMode == Scaler.INPUT_MODE_IGNORE )
				{
					controller.processCommand( new SetScalerInputRange( scaler.id, midiControlInput.value, midiControlInput.value ) );
				}
			}
		}

		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( _midiControlInputID ) + ".autoLearn" );
		}
		
		
		private var _midiControlInputID:int;
		private var _autoLearn:Boolean;
	}
}