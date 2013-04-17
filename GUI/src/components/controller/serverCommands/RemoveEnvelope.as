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
	import __AS3__.vec.Vector;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;


	public class RemoveEnvelope extends ServerCommand
	{
		public function RemoveEnvelope( envelopeID:int )
		{
			super();
			
			_envelopeID = envelopeID;
		}
		
		
		public function get envelopeID():int { return _envelopeID; }
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( model.getEnvelope( _envelopeID ) != null );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var envelope:Envelope = model.getEnvelope( _envelopeID );
			Assert.assertNotNull( envelope );

			//remove control points
			var controlPointsToRemove:Vector.<int> = new Vector.<int>;			
			for each( var controlPoint:ControlPoint in envelope.controlPoints )
			{
				controlPointsToRemove.push( controlPoint.id );
			}
			
			for each( var controlPointID:int in controlPointsToRemove )
			{
				controller.processCommand( new RemoveControlPoint( controlPointID ) );
			}
			
			removeConnectionsReferringTo( _envelopeID, model, controller ); 
			
			deselectEnvelope( model, controller );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var envelope:Envelope = model.getEnvelope( _envelopeID );
			var block:Block = model.getBlockFromEnvelope( _envelopeID );

			Assert.assertNotNull( envelope );
			Assert.assertNotNull( block );

			pushInverseCommand( new AddEnvelope( block.id, -1, null, 0, envelope.startTicks, envelope.id, envelope.name ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _envelopeID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _envelopeID ) );
			connection.callQueued( "command.delete" );				
		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.delete" );
		}		

		
		private function deselectEnvelope( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlockFromEnvelope( _envelopeID );
			Assert.assertNotNull( block );
			if( model.getPrimarySelectedChildID( block.id ) == _envelopeID )
			{
				controller.processCommand( new SetPrimarySelectedChild( block.id, -1 ) );
			}
		}
		
		
		private var _envelopeID:int;
	}
}