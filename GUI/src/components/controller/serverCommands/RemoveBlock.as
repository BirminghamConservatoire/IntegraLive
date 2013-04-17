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
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.Script;
	import components.model.Track;
	
	import flexunit.framework.Assert;


	public class RemoveBlock extends ServerCommand
	{
		public function RemoveBlock( blockID:int )
		{
			super();
			
			_blockID = blockID;
		}
		
		
		public function get blockID():int { return _blockID; }
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( model.getBlock( _blockID ) != null );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );

			removeConnectionsReferringTo( _blockID, model, controller );
			removeConnectionsReferringTo( block.blockEnvelope.id, model, controller );
			removeChildScalers( _blockID, model, controller );
			
			//removeChildConnections is only needed to fix old files in which non-scaled connections are present
			removeChildConnections( _blockID, model, controller );
			
			removeChildScripts( _blockID, model, controller );
			removeMidi( _blockID, model, controller );

			//remove envelopes
			var envelopesToRemove:Vector.<int> = new Vector.<int>;			
			for each( var envelope:Envelope in block.envelopes )
			{
				envelopesToRemove.push( envelope.id );
			}
			
			for each( var envelopeID:int in envelopesToRemove )
			{
				controller.processCommand( new RemoveEnvelope( envelopeID ) );
			}

			//remove modules
			var modulesToRemove:Vector.<int> = new Vector.<int>;			
			for each( var module:ModuleInstance in block.modules )
			{
				modulesToRemove.push( module.id );
			}
			
			for each( var moduleID:int in modulesToRemove )
			{
				controller.processCommand( new UnloadModule( moduleID ) );
			}
			
			deselectBlock( model, controller );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var track:Track = model.getTrackFromBlock( _blockID );
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( track );
			Assert.assertNotNull( block );

			var blockEnvelope:Envelope = block.blockEnvelope;
			Assert.assertNotNull( blockEnvelope );
				
			var controlPoints:Vector.<ControlPoint> = blockEnvelope.orderedControlPoints;
			Assert.assertTrue( controlPoints.length == 4 );  

			pushInverseCommand( new AddBlock( track.id, block.start, block.end, _blockID, blockEnvelope.id, controlPoints[ 0 ].id, controlPoints[ 1 ].id, controlPoints[ 2 ].id, controlPoints[ 3 ].id, block.name, block.blockEnvelope.name ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertTrue( block );
			
			var blockEnvelope:Envelope = block.blockEnvelope;
			Assert.assertNotNull( blockEnvelope );
				
			var controlPoints:Vector.<ControlPoint> = blockEnvelope.orderedControlPoints;
			Assert.assertTrue( controlPoints.length == 4 );  
			
			for each( var controlPoint:ControlPoint in controlPoints )
			{
				model.removeDataObject( controlPoint.id );
			}
			
			model.removeDataObject( blockEnvelope.id );
			model.removeDataObject( block.id );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertTrue( block );
			
			var blockEnvelope:Envelope = block.blockEnvelope;
			Assert.assertNotNull( blockEnvelope );
				
			var controlPoints:Vector.<ControlPoint> = blockEnvelope.orderedControlPoints;
			Assert.assertTrue( controlPoints.length == 4 );  

			var methodCalls:Array = new Array;
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.delete";
			methodCalls[ 0 ].params = [ model.getPathArrayFromID( controlPoints[ 0 ].id ) ];

			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.delete";
			methodCalls[ 1 ].params = [ model.getPathArrayFromID( controlPoints[ 1 ].id ) ];

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.delete";
			methodCalls[ 2 ].params = [ model.getPathArrayFromID( controlPoints[ 2 ].id ) ];

			methodCalls[ 3 ] = new Object;
			methodCalls[ 3 ].methodName = "command.delete";
			methodCalls[ 3 ].params = [ model.getPathArrayFromID( controlPoints[ 3 ].id ) ];

			methodCalls[ 4 ] = new Object;
			methodCalls[ 4 ].methodName = "command.delete";
			methodCalls[ 4 ].params = [ model.getPathArrayFromID( blockEnvelope.id ) ];

			methodCalls[ 5 ] = new Object;
			methodCalls[ 5 ].methodName = "command.delete";
			methodCalls[ 5 ].params = [ model.getPathArrayFromID( _blockID ) ];
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 6 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 1 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 2 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 3 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 4 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 5 ][ 0 ].response != "command.delete" ) return false;
						
			return true;
		}		

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new UpdateProjectLength() );
		}
		
		
		private function deselectBlock( model:IntegraModel, controller:IntegraController ):void
		{
			if( model.isObjectSelected( _blockID ) )
			{
				controller.processCommand( new SetObjectSelection( _blockID, false ) );
			}
			
			var track:Track = model.getTrackFromBlock( _blockID );
			Assert.assertNotNull( track );
			if( model.getPrimarySelectedChildID( track.id ) == _blockID )
			{
				controller.processCommand( new SetPrimarySelectedChild( track.id, -1 ) );
			}
		}

		
		private var _blockID:int;
	}
}