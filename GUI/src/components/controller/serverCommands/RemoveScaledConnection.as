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
	import components.model.Connection;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.Scaler;
	
	import flexunit.framework.Assert;

	public class RemoveScaledConnection extends ServerCommand
	{
		public function RemoveScaledConnection( scalerID:int )
		{
			super();

			_scalerID = scalerID; 
		}

		public function get scalerID():int { return _scalerID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			if( !scaler )
			{
				return false;
			}
			
			_upstreamConnectionID = scaler.upstreamConnection.id;
			_downstreamConnectionID = scaler.downstreamConnection.id;
			
			return true;
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetConnectionRouting( scaler.upstreamConnection.id, -1, null, -1, null ) );
			controller.processCommand( new SetConnectionRouting( scaler.downstreamConnection.id, -1, null, -1, null ) );
		}
		

		public override function generateInverse( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			var container:IntegraContainer = model.getContainerFromScaler( _scalerID );
			Assert.assertNotNull( scaler );
			Assert.assertNotNull( container );
			
			pushInverseCommand( new AddScaledConnection( container.id, _scalerID, scaler.name, scaler.upstreamConnection.name, scaler.downstreamConnection.name ) );	
		}

		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _scalerID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _scalerID ) );
			connection.callQueued( "command.delete" );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.delete" );
		}

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			Assert.assertTrue( _upstreamConnectionID >= 0 && _downstreamConnectionID >= 0 );
			
			controller.processCommand( new RemoveConnection( _upstreamConnectionID ) );
			controller.processCommand( new RemoveConnection( _downstreamConnectionID ) );
		}
		

		private var _scalerID:int;
		private var _upstreamConnectionID:int = -1;
		private var _downstreamConnectionID:int = -1;
	}
}