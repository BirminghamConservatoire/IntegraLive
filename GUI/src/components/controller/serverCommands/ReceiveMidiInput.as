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
	import components.model.Midi;
	import components.model.preferences.AudioSettings;
	
	import flexunit.framework.Assert;
	

	/* 
	note - this is an unusual ServerCommand, in that it is only ever used as a 'remote command' - ie
	dispatched by RemoteCommandHandler.  It is never dispatched by the user, via a view.  Therefore,
	some of it's methods (generateInverse / executeServerCommand / testServerResponse ) are not needed
	*/
	
	public class ReceiveMidiInput extends ServerCommand
	{
		public function ReceiveMidiInput( midiID:int, midiEndpoint:String, value:int = 0 )
		{
			super();

			_midiID = midiID;
			_midiEndpoint = midiEndpoint;
			_value = value;

			const ccTagLength:int = CC.length;
			if( midiEndpoint.substr( 0, ccTagLength ) == CC )
			{
				_index = int( midiEndpoint.substr( ccTagLength ) );
				_type = CC;
				return;
			}

			const noteOnTagLength:int = NOTE_ON.length;
			if( midiEndpoint.substr( 0, noteOnTagLength ) == NOTE_ON )
			{
				_index = int( midiEndpoint.substr( noteOnTagLength ) );
				_type = NOTE_ON;
			}
		}
		
		
		public function get midiID():int			{ return _midiID; } 
		public function get midiEndpoint():String	{ return _midiEndpoint; } 
		public function get type():String 			{ return _type; }
		public function get index():int 			{ return _index; }
		public function get value():int 			{ return _value; }
		
		public function get valid():Boolean 			
		{ 
			switch( _type )
			{
				case CC:
				case NOTE_ON:
					return true;
					
				default:
					return false;
			}
		}
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !model.getMidi( _midiID ) ) return false;
			
			switch( _type )
			{
				case CC:
					if( index < 0 || index >= Midi.numberOfCCNumbers ) return false;
					if( value < 0 || value > 127 ) return false;
					break;
				
				case NOTE_ON:
					if( index < 0 || index >= Midi.numberOfMidiNotes ) return false;
					if( value != 0 ) return false;
					break;
				
				default:
					return false;
			}

			return true;
        }
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			//not needed - see note above				
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			if( _type == CC )
			{
				model.getMidi( _midiID ).setCCState( _index, _value );
			}
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			//not needed - see note above				
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			//not needed - see note above				
        	return true;
		}

		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( _midiID ) + "." + _type + String( _index ) );
		}	
		

		private var _midiID:int;
		private var _midiEndpoint:String;
		private var _type:String;
		private var _index:int;
		private var _value:int;
		
		public static const CC:String = "cc";
		public static const NOTE_ON:String = "note";
	}
}
