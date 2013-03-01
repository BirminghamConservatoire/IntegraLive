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
	import components.controller.events.ImportEvent;
	import components.controller.events.LoadCompleteEvent;
	import components.controller.events.LoadFailedEvent;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.UpdateProjectLength;	
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Utilities;
	
	import flash.events.EventDispatcher;
	
	import flexunit.framework.Assert;
	

	public class ImportBlock extends ServerCommand
	{
		public function ImportBlock( filename:String, trackID:int, start:int )
		{
			super();

			_filename = filename;
			_trackID = trackID;
			_start = start;
		}

		
		public function get filename():String { return _filename; }
		public function get trackID():int { return _trackID; }
		public function get start():int { return _start; }
		

		public override function initialize( model:IntegraModel ):Boolean
		{
			var track:Track = model.getTrack( _trackID );
			if( !track ) 
			{
				return false;
			}
			
			_blockID = model.generateNewID();
			
			var definition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Envelope._serverInterfaceName );
			_blockEnvelopeName = track.getNewChildName( "BlockEnvelope", definition.moduleGuid );

			_end = _start + Block.newBlockSeconds * model.project.player.rate;

			_loadCompleteDispatcher = new EventDispatcher;
			_modelLoader = new ModelLoader( _loadCompleteDispatcher );
			_modelLoader.serverUrl = IntegraController.singleInstance.serverUrl;
			
			_loadCompleteDispatcher.addEventListener( LoadCompleteEvent.EVENT_NAME, onLoaded );

			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveBlockImport( _blockID, _blockEnvelopeName ) );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//deselect all blocks
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					if( block.isSelected )
					{
						controller.processCommand( new SetObjectSelection( block.id, false ) );	
					}
				}
			}
		}

		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;

			var trackPath:Array = model.getPathArrayFromID( _trackID );

			//import the block
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.load";
			methodCalls[ 0 ].params = [ _filename, trackPath ];	

			//create block envelope
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.new";
			methodCalls[ 1 ].params = [ model.getCoreInterfaceGuid( Envelope._serverInterfaceName ), _blockEnvelopeName, trackPath ];

			//set block envelope attributes
			var blockEnvelopePath:Array = trackPath.concat( _blockEnvelopeName );

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ blockEnvelopePath.concat( "startTick" ), _start ];

			//create block envelope control points
			methodCalls[ 3 ] = new Object;
			methodCalls[ 3 ].methodName = "command.new";
			methodCalls[ 3 ].params = [ model.getCoreInterfaceGuid( ControlPoint._serverInterfaceName ), _controlPoint1Name, blockEnvelopePath ];

			methodCalls[ 4 ] = new Object;
			methodCalls[ 4 ].methodName = "command.new";
			methodCalls[ 4 ].params = [ model.getCoreInterfaceGuid( ControlPoint._serverInterfaceName ), _controlPoint2Name, blockEnvelopePath ];

			methodCalls[ 5 ] = new Object;
			methodCalls[ 5 ].methodName = "command.new";
			methodCalls[ 5 ].params = [ model.getCoreInterfaceGuid( ControlPoint._serverInterfaceName ), _controlPoint3Name, blockEnvelopePath ];

			methodCalls[ 6 ] = new Object;
			methodCalls[ 6 ].methodName = "command.new";
			methodCalls[ 6 ].params = [ model.getCoreInterfaceGuid( ControlPoint._serverInterfaceName ), _controlPoint4Name, blockEnvelopePath ];

			//set block envelope control point attributes
			var controlPoint1Path:Array = blockEnvelopePath.concat( _controlPoint1Name );
			methodCalls[ 7 ] = new Object;
			methodCalls[ 7 ].methodName = "command.set";
			methodCalls[ 7 ].params = [ controlPoint1Path.concat( "tick" ), -1 ];

			methodCalls[ 8 ] = new Object;
			methodCalls[ 8 ].methodName = "command.set";
			methodCalls[ 8 ].params = [ controlPoint1Path.concat( "value" ), 0 ];

			var controlPoint2Path:Array = blockEnvelopePath.concat( _controlPoint2Name );
			methodCalls[ 9 ] = new Object;
			methodCalls[ 9 ].methodName = "command.set";
			methodCalls[ 9 ].params = [ controlPoint2Path.concat( "tick" ), 0 ];

			methodCalls[ 10 ] = new Object;
			methodCalls[ 10 ].methodName = "command.set";
			methodCalls[ 10 ].params = [ controlPoint2Path.concat( "value" ), 1 ];

			var controlPoint3Path:Array = blockEnvelopePath.concat( _controlPoint3Name );
			methodCalls[ 11 ] = new Object;
			methodCalls[ 11 ].methodName = "command.set";
			methodCalls[ 11 ].params = [ controlPoint3Path.concat( "tick" ), ( _end - _start - 1 ) ];

			methodCalls[ 12 ] = new Object;
			methodCalls[ 12 ].methodName = "command.set";
			methodCalls[ 12 ].params = [ controlPoint3Path.concat( "value" ), 1 ];

			var controlPoint4Path:Array = blockEnvelopePath.concat( _controlPoint4Name );
			methodCalls[ 13 ] = new Object;
			methodCalls[ 13 ].methodName = "command.set";
			methodCalls[ 13 ].params = [ controlPoint4Path.concat( "tick" ), ( _end - _start ) ];

			methodCalls[ 14 ] = new Object;
			methodCalls[ 14 ].methodName = "command.set";
			methodCalls[ 14 ].params = [ controlPoint4Path.concat( "value" ), 0 ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );

			IntegraController.singleInstance.dispatchEvent( new ImportEvent( ImportEvent.STARTED ) );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var model:IntegraModel = IntegraModel.singleInstance;
			var controller:IntegraController = IntegraController.singleInstance;

			if( commandCompletedOK( response ) )
			{
				var trackPath:Array = model.getPathArrayFromID( _trackID );
				
				Assert.assertNotNull( _modelLoader );
				_modelLoader.loadBranchOfNodeTree( trackPath, ModelLoader.IMPORTING_BLOCK, _blockID ); 
			}
			else
			{
				controller.dispatchEvent( new LoadFailedEvent( "Cannot import \"" + Utilities.fileNameFromPath( _filename ) + "\":\n\n" + getLoadErrorText( response ) ) );
				controller.dispatchEvent( new ImportEvent( ImportEvent.FINISHED ) );
			}
			
			return true;
		}
		
		
		private function commandCompletedOK( response:Object ):Boolean
		{
			if( response.length != 15 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.load" ) return false;
			if( response[ 1 ][ 0 ].response != "command.new" ) return false;
			if( response[ 2 ][ 0 ].response != "command.set" ) return false;
			if( response[ 3 ][ 0 ].response != "command.new" ) return false;
			if( response[ 4 ][ 0 ].response != "command.new" ) return false;
			if( response[ 5 ][ 0 ].response != "command.new" ) return false;
			if( response[ 6 ][ 0 ].response != "command.new" ) return false;
			if( response[ 7 ][ 0 ].response != "command.set" ) return false;
			if( response[ 8 ][ 0 ].response != "command.set" ) return false;
			if( response[ 9 ][ 0 ].response != "command.set" ) return false;
			if( response[ 10 ][ 0 ].response != "command.set" ) return false;
			if( response[ 11 ][ 0 ].response != "command.set" ) return false;
			if( response[ 12 ][ 0 ].response != "command.set" ) return false;
			if( response[ 13 ][ 0 ].response != "command.set" ) return false;
			if( response[ 14 ][ 0 ].response != "command.set" ) return false;
						
			return true;
		}
		
		
		private function getLoadErrorText( response:Object ):String
		{
			return response[ 0 ][ 0 ].errortext;
		}		
		
		
		private function onLoaded( event:LoadCompleteEvent ):void
		{
			var model:IntegraModel = IntegraModel.singleInstance;
			var controller:IntegraController = IntegraController.singleInstance;
			
			var block:Block = model.getBlock( _blockID );
			
			var trackPath:Array = model.getPathArrayFromID( _trackID );
			var blockEnvelopeID:int = model.getIDFromPathArray( trackPath.concat( _blockEnvelopeName ) );
			var blockEnvelope:Envelope = model.getEnvelope( blockEnvelopeID );
			
			Assert.assertNotNull( block );
			Assert.assertNotNull( blockEnvelope );
			
			block.blockEnvelope = blockEnvelope;
			
			controller.activateUndoStack = false;
			{
				repositionBlock( model, controller );
				connectPlayerToBlockEnvelope( model, controller, blockEnvelopeID );
				connectBlockEnvelopeToBlock( controller, blockEnvelopeID );
				connectPlayerToEnvelopes( model, controller );
			}
			controller.activateUndoStack = true;
			controller.appendNextCommandsIntoPreviousTransaction();

			repositionSubsequentBlocks( model, controller );

			selectTrackAndBlock( model, controller );
			movePlayheadToBlock( model, controller );
			
			controller.processCommand( new UpdateProjectLength() );

			controller.dispatchEvent( new ImportEvent( ImportEvent.FINISHED ) );
		}
		
		
		private function repositionBlock( model:IntegraModel, controller:IntegraController ):void
		{
			//this method increases the length of the block if it contains envelopes which are longer than the default new block length.
			//it also causes the block's envelope's start times to be brought into line with the rest of the block
			
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			var blockLength:int = block.length;
			for each( var envelope:Envelope in block.envelopes )
			{
				var controlPoints:Vector.<ControlPoint> = envelope.orderedControlPoints;
				if( controlPoints.length > 0 )
				{
					var lastControlPoint:ControlPoint = controlPoints[ controlPoints.length - 1 ]; 
					blockLength = Math.max( blockLength, lastControlPoint.tick );
				}
			} 
			
			_end = _start + blockLength;
			controller.processCommand( new RepositionBlock( _blockID, _start, _end ) );
		}
		
		
		private function repositionSubsequentBlocks( model:IntegraModel, controller:IntegraController ):void
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );
			
			var blocks:Vector.<Block> = new Vector.<Block>;

			for each( var block:Block in track.blocks )
			{
				if( block.id != _blockID && block.end > _start )
				{
					blocks.push( block );
				}
			}
			
			function compareBlockOrder( x:Block, y:Block ):int { return ( x.start < y.start ) ? -1 : 1; };
			blocks.sort( compareBlockOrder );
			
			var earliestStart:int = _end;
			for each( block in blocks )
			{
				if( block.start >= earliestStart )
				{
					break;
				}

				var end:int = earliestStart + block.length;
				controller.processCommand( new RepositionBlock( block.id, earliestStart, end ) );
				earliestStart = end; 
			}
		}
		
		
		private function connectPlayerToBlockEnvelope( model:IntegraModel, controller:IntegraController, blockEnvelopeID:int ):void
		{
			var addConnectionCommand:AddConnection = new AddConnection( model.project.id );
			controller.processCommand( addConnectionCommand );
			controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, model.project.player.id, "tick", blockEnvelopeID, "currentTick" ) );
		}


		private function connectBlockEnvelopeToBlock( controller:IntegraController, blockEnvelopeID:int ):void
		{
			var addConnectionCommand:AddConnection = new AddConnection( _trackID );
			controller.processCommand( addConnectionCommand );
			controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, blockEnvelopeID, "currentValue", _blockID, "active" ) );
		}
		
		
		private function connectPlayerToEnvelopes( model:IntegraModel, controller:IntegraController ):void 
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			for each( var envelope:Envelope in block.envelopes )
			{
				var addConnectionCommand:AddConnection = new AddConnection( model.project.id );
				controller.processCommand( addConnectionCommand );
				controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, model.project.player.id, "tick", envelope.id, "currentTick" ) );
			}			
		}
		
		
		private function selectTrackAndBlock( model:IntegraModel, controller:IntegraController ):void
		{
			//select track
			controller.processCommand( new SetPrimarySelectedChild( model.project.id, _trackID ) );
			
			//select block
			controller.processCommand( new SetPrimarySelectedChild( _trackID, _blockID ) );
			controller.processCommand( new SetObjectSelection( _blockID, true ) );
		}
		
		
		private function movePlayheadToBlock( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			controller.processCommand( new SetPlayPosition( block.start ) );
		}
		

		
		private var _filename:String;
		private var _trackID:int;
		private var _blockID:int;
		
		private var _start:int = -1;
		private var _end:int = -1;
		
		private var _blockEnvelopeName:String = null;
		
		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;

		private static const _controlPoint1Name:String = "ControlPoint1";
		private static const _controlPoint2Name:String = "ControlPoint2";
		private static const _controlPoint3Name:String = "ControlPoint3";
		private static const _controlPoint4Name:String = "ControlPoint4";
	}
}