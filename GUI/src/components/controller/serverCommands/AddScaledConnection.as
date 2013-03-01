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
	import components.controller.serverCommands.AddConnection;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;
	

	public class AddScaledConnection extends ServerCommand
	{
		public function AddScaledConnection( containerID:int, scalerID:int = -1, scalerName:String = null, upstreamConnectionName:String = null, downstreamConnectionName:String = null )
		{
			super();

			_containerID = containerID;			
			_scalerID = scalerID;
			_scalerName = scalerName;
			
			_upstreamConnectionName = upstreamConnectionName;
			_downstreamConnectionName = downstreamConnectionName;
		}
		
		public function get containerID():int { return _containerID; }
		public function get scalerID():int { return _scalerID; }
		public function get scalerName():String { return _scalerName; }
	
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _scalerID < 0 )
			{
				_scalerID = model.generateNewID();
			} 
			
			if( !_scalerName )
			{
				var container:IntegraContainer = model.getContainer( _containerID );
				Assert.assertNotNull( container );
				
				var scalerInterface:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Scaler._serverInterfaceName );
				Assert.assertNotNull( scalerInterface );
				_scalerName = container.getNewChildName( Scaler._serverInterfaceName, scalerInterface.guid ); 				
			}
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveScaledConnection( _scalerID ) );
		}

		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			Assert.assertTrue( _upstreamConnectionID < 0 && _downstreamConnectionID < 0 );
			
			var addUpstreamConnection:AddConnection = new AddConnection( _containerID );
			controller.processCommand( addUpstreamConnection );
			_upstreamConnectionID = addUpstreamConnection.connectionID;

			var addDownstreamConnection:AddConnection = new AddConnection( _containerID );
			controller.processCommand( addDownstreamConnection );
			_downstreamConnectionID = addDownstreamConnection.connectionID;
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scaler:Scaler = new Scaler();
			
			scaler.id = _scalerID;
			scaler.name = _scalerName;

			model.addDataObject( _containerID, scaler );

			var containerPath:Array = model.getPathArrayFromID( _containerID );
			if( _upstreamConnectionID < 0 )
			{
				Assert.assertNotNull( _upstreamConnectionName );
				_upstreamConnectionID = model.getIDFromPathArray( containerPath.concat( _upstreamConnectionName ) );
			}

			if( _downstreamConnectionID < 0 )
			{
				Assert.assertNotNull( _downstreamConnectionName );
				_downstreamConnectionID = model.getIDFromPathArray( containerPath.concat( _downstreamConnectionName ) );
			}
			
			Assert.assertTrue( _upstreamConnectionID >= 0 && _downstreamConnectionID >= 0 );

			scaler.upstreamConnection = model.getConnection( _upstreamConnectionID );
			scaler.downstreamConnection = model.getConnection( _downstreamConnectionID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var containerPath:Array = model.getPathArrayFromID( _containerID );
			
			connection.addParam( model.getCoreInterfaceGuid( Scaler._serverInterfaceName ), XMLRPCDataTypes.STRING );
			connection.addParam( _scalerName, XMLRPCDataTypes.STRING );
			connection.addArrayParam( containerPath );
			
			connection.callQueued( "command.new" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.new" );
		}
		
		
		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new SetConnectionRouting( _upstreamConnectionID, -1, null, _scalerID, "inValue" ) );
			controller.processCommand( new SetConnectionRouting( _downstreamConnectionID, _scalerID, "outValue", -1, null ) );
		}		


		private var _containerID:int;
		private var _scalerID:int;
		private var _scalerName:String;
		
		private var _upstreamConnectionName:String;
		private var _downstreamConnectionName:String;		

		private var _upstreamConnectionID:int = -1;
		private var _downstreamConnectionID:int = -1;		
	}
}