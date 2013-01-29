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
	import components.controller.events.AllDataChangedEvent;
	import components.controller.userDataCommands.UpdateProjectLength;	
	import components.model.Track;
	import components.model.Block;
	import components.model.Connection;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;
	

	public class RemoveBlockImport extends ServerCommand
	{
		public function RemoveBlockImport( blockID:int, blockEnvelopeName:String )
		{
			_blockID = blockID;
			_blockEnvelopeName = blockEnvelopeName;
		}
		
		
		public function get blockID():int { return _blockID; }
		public function get blockEnvelopeName():String { return _blockEnvelopeName; }
		
		
		override public function execute( model:IntegraModel ):void
		{
			//remove connections						
			for each( var connectionID:int in _playerConnectionIDs )
			{
				model.removeDataObject( connectionID );
			}
			
			//remove block connection, block and block envelope
			model.removeDataObject( _blockConnectionID );

			//remove objects						
			for each( var objectID:int in _objectIDs )
			{
				model.removeDataObject( objectID );
			}
		}
		
		
		override public function executeServerCommand( model:IntegraModel ):void 
		{
			var block:Block = model.getBlock( _blockID );
			var track:Track = model.getTrackFromBlock( _blockID );
			Assert.assertNotNull( block );
			Assert.assertNotNull( track );
			
			var trackPath:Array = model.getPathArrayFromID( track.id );
			_blockEnvelopeID = model.getIDFromPathArray( trackPath.concat( _blockEnvelopeName ) );
			var blockEnvelope:Envelope = model.getEnvelope( _blockEnvelopeID );
			Assert.assertNotNull( blockEnvelope );
			
			//find the block envelope's connection
			_blockConnectionID = -1;
			for each( var candidateBlockConnection:Connection in track.connections )
			{
				if( candidateBlockConnection.sourceObjectID == _blockEnvelopeID && candidateBlockConnection.targetObjectID == _blockID )
				{
					_blockConnectionID = candidateBlockConnection.id;
					break;
				}
			} 
			
			Assert.assertTrue( _blockConnectionID >= 0 );

			//collect ids of all block's child objects						
			_objectIDs.length = 0;						
			
			getIDs( block );
			getIDs( blockEnvelope );
			
			//put them in a map, to quickly find the player connections which target them
			var objectIDMap:Object = new Object;
			for each( var objectID:int in _objectIDs )
			{
				objectIDMap[ objectID ] = 1;
			}
			
			//collect ids of all project level connections which target the track's child objects
			_playerConnectionIDs.length = 0;
			for each( var playerConnection:Connection in model.project.connections )
			{
				if( objectIDMap.hasOwnProperty( playerConnection.targetObjectID ) )
				{
					_playerConnectionIDs.push( playerConnection.id );
				}
			} 

			//construct the call to delete everything 
			var methodCalls:Array = new Array;
			
			for each( var connectionID:int in _playerConnectionIDs )
			{
				var removeConnectionCall:Object = new Object;
				removeConnectionCall.methodName = "command.delete";
				removeConnectionCall.params = [ model.getPathArrayFromID( connectionID ) ];
				methodCalls.push( removeConnectionCall );
			}

			var removeBlockConnectionCall:Object = new Object;
			removeBlockConnectionCall.methodName = "command.delete";
			removeBlockConnectionCall.params = [ model.getPathArrayFromID( _blockConnectionID ) ];
			methodCalls.push( removeBlockConnectionCall );
		
			var removeBlockEnvelopeCall:Object = new Object;
			removeBlockEnvelopeCall.methodName = "command.delete";
			removeBlockEnvelopeCall.params = [ model.getPathArrayFromID( _blockEnvelopeID ) ];
			methodCalls.push( removeBlockEnvelopeCall );

			var removeBlockCall:Object = new Object;
			removeBlockCall.methodName = "command.delete";
			removeBlockCall.params = [ model.getPathArrayFromID( _blockID ) ];
			methodCalls.push( removeBlockCall );
		
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new UpdateProjectLength() );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			IntegraController.singleInstance.dispatchEvent( new AllDataChangedEvent() );

			if( response.length != _playerConnectionIDs.length + 3 ) return false;
			
			for( var i:int = 0; i < response.length; i++ )  		
			{
				if( response[ i ][ 0 ].response != "command.delete" ) return false;
			}			
			
			return true;
		}
		
		
		private function getIDs( object:IntegraDataObject ):void
		{
			if( object is IntegraContainer )
			{
				for each( var child:IntegraDataObject in ( object as IntegraContainer ).children )
				{
					getIDs( child );
				}
			}
			
			if( object is Envelope )
			{
				for each( var controlPoint:ControlPoint in ( object as Envelope ).controlPoints )
				{
					_objectIDs.push( controlPoint.id );
				}
			}
			
			_objectIDs.push( object.id );
		}
		

		private var _blockID:int;
		private var _blockEnvelopeName:String;
		private var _blockEnvelopeID:int = -1;
		private var _blockConnectionID:int = -1;
		
		private var _objectIDs:Vector.<int> = new Vector.<int>;
		private var _playerConnectionIDs:Vector.<int> = new Vector.<int>;
	}
}