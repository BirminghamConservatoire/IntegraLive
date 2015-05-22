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
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.model.Block;
	import components.model.Connection;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.Track;
	
	import flexunit.framework.Assert;

	public class SetBlockTrack extends ServerCommand
	{
		public function SetBlockTrack( blockID:int, newTrackID:int )
		{
			super();
			
		 	_blockID = blockID;
		 	_newTrackID = newTrackID;
		}

		
		public function get blockID():int { return _blockID; }
		public function get newTrackID():int { return _newTrackID; }

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var currentTrack:Track = model.getTrackFromBlock( _blockID );
			var block:Block = model.getBlock( _blockID );
			var blockConnection:Connection = model.getEnvelopeTarget( block.blockEnvelope.id );

			Assert.assertNotNull( currentTrack );
			Assert.assertNotNull( block );
			Assert.assertNotNull( blockConnection );
			
			if( _newTrackID == currentTrack.id )
			{
				return false;
			}

			_newName = getNewName( block.name, model );
			_newBlockEnvelopeName = getNewName( block.blockEnvelope.name, model );
			_newBlockConnectionName = getNewName( blockConnection.name, model );
			
			_interimName = getInterimName( block.name, _newName, model );
			_interimBlockEnvelopeName = getInterimName( block.blockEnvelope.name, _newBlockEnvelopeName, model );
			_interimBlockConnectionName = getInterimName( blockConnection.name, _newBlockConnectionName, model );
			
			_shouldMoveSelection = ( currentTrack.userData.primarySelectedChildID == _blockID );
			
			return true;
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			var currentTrack:Track = model.getTrackFromBlock( _blockID );
			Assert.assertNotNull( currentTrack );
			
			pushInverseCommand( new SetBlockTrack( _blockID, currentTrack.id ) );
		}


		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var currentTrack:Track = model.getTrackFromBlock( _blockID );
			var block:Block = model.getBlock( _blockID );
			var blockConnection:Connection = model.getEnvelopeTarget( block.blockEnvelope.id );

			Assert.assertNotNull( currentTrack );
			Assert.assertNotNull( block );
			Assert.assertNotNull( blockConnection );

			//rename everything if necessary
			if( block.name != _interimName )
			{
				controller.processCommand( new RenameObject( _blockID, _interimName ) );
			}

			if( block.blockEnvelope.name != _interimBlockEnvelopeName )
			{
				controller.processCommand( new RenameObject( block.blockEnvelope.id, _interimBlockEnvelopeName ) );
			}

			if( blockConnection.name != _interimBlockConnectionName )
			{
				controller.processCommand( new RenameObject( blockConnection.id, _interimBlockConnectionName ) );
			}
			
			//remove selection if necessary
			if( _shouldMoveSelection )
			{
				controller.processCommand( new SetPrimarySelectedChild( currentTrack.id, -1 ) );
				controller.processCommand( new SetObjectSelection( _blockID, false ) );
			} 
		}


		public override function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			var blockEnvelope:Envelope = block.blockEnvelope;
			var blockConnection:Connection = model.getEnvelopeTarget( block.blockEnvelope.id );

			Assert.assertNotNull( block );
			Assert.assertNotNull( blockEnvelope );
			Assert.assertNotNull( blockConnection );
			
			model.reparentDataObject( _blockID, _newTrackID );
			model.reparentDataObject( blockEnvelope.id, _newTrackID );
			model.reparentDataObject( blockConnection.id, _newTrackID );
		}			


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			var blockEnvelope:Envelope = block.blockEnvelope;
			var blockConnection:Connection = model.getEnvelopeTarget( block.blockEnvelope.id );

			Assert.assertNotNull( block );
			Assert.assertNotNull( blockEnvelope );
			Assert.assertNotNull( blockConnection );

			var methodCalls:Array = new Array;

			var newTrackPath:Array = model.getPathArrayFromID( _newTrackID );
			var newConnectionPath:Array = newTrackPath.concat( _newBlockConnectionName );

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.move";
			methodCalls[ 0 ].params = [ model.getPathArrayFromID( _blockID ), newTrackPath ];

			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.move";
			methodCalls[ 1 ].params = [ model.getPathArrayFromID( blockEnvelope.id ), newTrackPath ];

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.move";
			methodCalls[ 2 ].params = [ model.getPathArrayFromID( blockConnection.id ), newTrackPath ];
			
			methodCalls[ 3 ] = new Object;
			methodCalls[ 3 ].methodName = "command.set";
			methodCalls[ 3 ].params = [ newConnectionPath.concat( "sourcePath" ), _newBlockEnvelopeName + "." + "currentValue" ];
                    
			methodCalls[ 4 ] = new Object;
			methodCalls[ 4 ].methodName = "command.set";
			methodCalls[ 4 ].params = [ newConnectionPath.concat( "targetPath" ), _newName + "." + "active" ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 5 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.move" ) return false;
			if( response[ 1 ][ 0 ].response != "command.move" ) return false;
			if( response[ 2 ][ 0 ].response != "command.move" ) return false;
			if( response[ 3 ][ 0 ].response != "command.set" ) return false;
			if( response[ 4 ][ 0 ].response != "command.set" ) return false;
							
			return true;
		}	


		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlock( _blockID );
			var blockConnection:Connection = model.getEnvelopeTarget( block.blockEnvelope.id );

			Assert.assertNotNull( block );
			Assert.assertNotNull( blockConnection );

			//rename everything if necessary
			if( block.name != _newName )
			{
				controller.processCommand( new RenameObject( _blockID, _newName ) );
			}
			
			if( block.blockEnvelope.name != _newBlockEnvelopeName )
			{
				controller.processCommand( new RenameObject( block.blockEnvelope.id, _newBlockEnvelopeName ) );
			}

			if( blockConnection.name != _newBlockConnectionName )
			{
				controller.processCommand( new RenameObject( blockConnection.id, _newBlockConnectionName ) );
			}
			
			//restore selection if necessary
			if( _shouldMoveSelection )
			{
				controller.processCommand( new SetPrimarySelectedChild( _newTrackID, _blockID ) );
			}
			
			//store all user data again, since paths might have changed!
			controller.processCommand( new StoreAllUserData() );
                        
		}
		
		
		private function getNewName( originalName:String, model:IntegraModel ):String
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			if( !isNameUsedInTrack( originalName, _newTrackID, model ) )
			{
				return originalName;
			}
			
			for( var i:int = 1; ; i++ )
			{
				var candidateName:String = originalName + "_" + String( i );
				if( !isNameUsedInTrack( candidateName, _newTrackID, model ) )
				{
					return candidateName;
				}
			} 
			
			Assert.assertTrue( false );
			return null;  
		}


		private function getInterimName( originalName:String, newName:String, model:IntegraModel ):String
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			var originalTrack:Track = model.getTrackFromBlock( _blockID );
			Assert.assertNotNull( originalTrack );

			Assert.assertFalse( isNameUsedInTrack( newName, _newTrackID, model ) );

			if( newName == originalName || !isNameUsedInTrack( newName, originalTrack.id, model ) )
			{
				return newName;
			}
		
			for( var i:int = 1; ; i++ )
			{
				var candidateName:String = originalName + "_" + String( i );
				if( !isNameUsedInTrack( candidateName, originalTrack.id, model ) && !isNameUsedInTrack( candidateName, _newTrackID, model ) )
				{
					return candidateName;
				}
			} 
			
			Assert.assertTrue( false );
			return null;  
		}
		
		
		private function isNameUsedInTrack( name:String, trackID:int, model:IntegraModel ):Boolean
		{
			return ( model.getIDFromPathArray( model.getPathArrayFromID( trackID ).concat( name ) ) >= 0 );	
		}
		
		private var _blockID:int;
		private var _newTrackID:int;
		private var _shouldMoveSelection:Boolean = false;
		
		private var _interimName:String;
		private var _interimBlockEnvelopeName:String;
		private var _interimBlockConnectionName:String;

		private var _newName:String;
		private var _newBlockEnvelopeName:String;
		private var _newBlockConnectionName:String;
	}
}
