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
	
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	public class RepositionBlock extends ServerCommand
	{
		public function RepositionBlock( blockID:int, start:int, end:int )
		{
			super();
			
		 	_blockID = blockID;
		 	_start = start;
		 	_end = end;
		}

		
		public function get blockID():int { return _blockID; }
		public function get start():int { return _start; }
		public function get end():int { return _end; }

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return( model.getBlock( _blockID ) != null ) && ( _start >= 0 ) && ( _end > _start );
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			pushInverseCommand( new RepositionBlock( _blockID, block.start, block.end ) );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			//remove control points whose time is past end of block
			var newBlockLength:int = _end - _start;
			var controlPointsToRemove:Vector.<int> = new Vector.<int>;
			for each( var envelope:Envelope in block.envelopes )
			{
				for each( var controlPoint:ControlPoint in envelope.controlPoints )
				{
					if( controlPoint.tick > newBlockLength )
					{
						controlPointsToRemove.push( controlPoint.id );
					}
				}
			}
			
			for each( var controlPointID:int in controlPointsToRemove )
			{
				controller.processCommand( new RemoveControlPoint( controlPointID ) );
			}
		}


		public override function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			block.start = _start;
			block.end = _end;
			
			for each( var envelope:Envelope in block.envelopes )
			{
				envelope.startTicks = _start;
			}
		}			


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;

			var blockPath:Array = model.getPathArrayFromID( _blockID );

			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );

			var blockEnvelope:Envelope = block.blockEnvelope;
			Assert.assertNotNull( block );
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ model.getPathArrayFromID( blockEnvelope.id ).concat( "startTick" ), start ];

			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ model.getPathArrayFromID( blockEnvelope.orderedControlPoints[ 2 ].id ).concat( "tick" ), end - start - 1 ];

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ model.getPathArrayFromID( blockEnvelope.orderedControlPoints[ 3 ].id ).concat( "tick" ), end - start ];

			//Swap order of these tick-positioning commands when block is getting longer.  
			//This will prevent active from being flicked off and on when playhead is within the block    
			if( end > block.end )
			{
				var temp:Object = methodCalls[ 2 ];
				methodCalls[ 2 ] = methodCalls[ 1 ];
				methodCalls[ 1 ] = temp;
			}
			
			for each( var envelope:Envelope in block.envelopes )
			{
				var repositionEnvelope:Object = new Object;
				repositionEnvelope.methodName = "command.set";
				repositionEnvelope.params = [ blockPath.concat( [ envelope.name, "startTick" ] ), start ];
				methodCalls.push( repositionEnvelope );
			}
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:RepositionBlock = previousCommand as RepositionBlock;
			Assert.assertNotNull( previous );
			
			return  _blockID == previous._blockID; 
		}

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new UpdateProjectLength() );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( !response is Array ) return false;
			
			var responses:Array = response as Array;
			Assert.assertNotNull( responses );
			
			for each( var individualResponse:Object in responses )
			{
				if( individualResponse[ 0 ].response != "command.set" ) 
				{
					return false;
				}
			}
			
			return true;
		}	
		
		
		private var _blockID:int;
		private var _start:int;
		private var _end:int; 
	}
}