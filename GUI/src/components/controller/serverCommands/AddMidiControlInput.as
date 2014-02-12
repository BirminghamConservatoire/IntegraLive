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
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.MidiControlInput;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;

	public class AddMidiControlInput extends ServerCommand
	{
		public function AddMidiControlInput( containerID:int, midiControlInputID:int = -1, midiControlInputName:String = null, scalerID:int = -1 )
		{
			super();

			_containerID = containerID;			
			_midiControlInputID = midiControlInputID;
			_midiControlInputName = midiControlInputName;
			_scalerID = scalerID;
		}
		
		public function get containerID():int { return _containerID; }
		public function get midiControlInputID():int { return _midiControlInputID; }
		public function get midiControlInputName():String { return _midiControlInputName; }
	
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _midiControlInputID < 0 )
			{
				_midiControlInputID = model.generateNewID();
			} 
			
			if( !_midiControlInputName )
			{
				var container:IntegraContainer = model.getContainer( _containerID );
				Assert.assertNotNull( container );
				
				var midiControlInputInterface:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( MidiControlInput._serverInterfaceName );
				Assert.assertNotNull( midiControlInputInterface );
				_midiControlInputName = container.getNewChildName( MidiControlInput._serverInterfaceName, midiControlInputInterface.moduleGuid ); 				
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveMidiControlInput( _midiControlInputID ) );
		}

		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			Assert.assertTrue( _scalerID < 0 );

			var addScaledConnection:AddScaledConnection = new AddScaledConnection( _containerID );
			controller.processCommand( addScaledConnection );
			_scalerID = addScaledConnection.scalerID;
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var midiControlInput:MidiControlInput = new MidiControlInput();
			
			midiControlInput.id = _midiControlInputID;
			midiControlInput.name = _midiControlInputName;
			midiControlInput.device = "";
			midiControlInput.channel = 1;
			midiControlInput.messageType = MidiControlInput.CC;
			midiControlInput.noteOrController = 0;

			model.addDataObject( _containerID, midiControlInput );

			//add cross-references
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );

			scaler.midiControlInput = midiControlInput;
			midiControlInput.scaler = scaler;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var containerPath:Array = model.getPathArrayFromID( _containerID );
			
			connection.addParam( model.getCoreInterfaceGuid( MidiControlInput._serverInterfaceName ), XMLRPCDataTypes.STRING );
			connection.addParam( _midiControlInputName, XMLRPCDataTypes.STRING );
			connection.addArrayParam( containerPath );
			
			connection.callQueued( "command.new" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.new" );
		}
		
		
		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			Assert.assertTrue( _scalerID >= 0 );
			
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetConnectionRouting( scaler.upstreamConnection.id, _midiControlInputID, "value", _scalerID, "inValue" ) );
		}		


		private var _containerID:int;
		private var _midiControlInputID:int;
		private var _midiControlInputName:String;
		
		private var _scalerID:int;
	}
}