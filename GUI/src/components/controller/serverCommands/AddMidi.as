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
	import components.controller.userDataCommands.SetObjectSelection;
	import components.model.Midi;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;
	

	public class AddMidi extends ServerCommand
	{
		public function AddMidi( containerID:int, midiID:int = -1, midiName:String = null )
		{
			super();

			_containerID = containerID;			
			_midiID = midiID;
			_midiName = midiName;
		}
		
		public function get containerID():int { return _containerID; }
		public function get midiID():int { return _midiID; }
		public function get midiNameID():String { return _midiName; }
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _midiID < 0 )
			{
				_midiID = model.generateNewID();
			} 
			
			if( !_midiName )
			{
				var container:IntegraContainer = model.getContainer( _containerID );
				Assert.assertNotNull( container );
				
				var definition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Midi._serverInterfaceName );
				_midiName = container.getNewChildName( Midi._serverInterfaceName, definition.guid ); 				
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveMidi( _midiID ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var midi:Midi = new Midi();
			
			midi.id = _midiID;
			midi.name = _midiName;

			model.addDataObject( _containerID, midi ); 						
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var containerPath:Array = model.getPathArrayFromID( _containerID );
			
			connection.addParam( model.getCoreInterfaceGuid( Midi._serverInterfaceName ), XMLRPCDataTypes.STRING );
			connection.addParam( _midiName, XMLRPCDataTypes.STRING );
			connection.addArrayParam( containerPath );
			
			connection.callQueued( "command.new" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.new" );
		}
		
		
		private var _containerID:int;
		private var _midiID:int;
		private var _midiName:String;
	}
}