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
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;

	public class AddBlock extends ServerCommand
	{
		public function AddBlock( trackID:int, start:int, end:int, blockID:int = -1, blockEnvelopeID:int = -1, controlPoint1ID:int = -1, controlPoint2ID:int = -1, controlPoint3ID:int = -1, controlPoint4ID:int = -1, blockName:String = null, blockEnvelopeName:String = null )
		{
			super();

			_blockID = blockID;
			_blockEnvelopeID = blockEnvelopeID;
			
			_controlPoint1ID = controlPoint1ID;
			_controlPoint2ID = controlPoint2ID;
			_controlPoint3ID = controlPoint3ID;
			_controlPoint4ID = controlPoint4ID;
			
			_blockName = blockName;
			_blockEnvelopeName = blockEnvelopeName;
			_trackID = trackID;
			_start = start;
			_end = end;
		}


		public function get blockID():int { return _blockID; }
		public function get blockName():String { return _blockName; }
		public function get trackID():int { return _trackID; }
		public function get start():int { return _start; }
		public function get end():int { return _end; }


		public override function initialize( model:IntegraModel ):Boolean
		{
			var track:Track = model.getTrack( _trackID );
			if( !track )
			{
				Assert.assertTrue( false );	//track doesn't exist
				return false;
			}

			if( _blockID < 0 )			_blockID = model.generateNewID();
			if( _blockEnvelopeID < 0 )	_blockEnvelopeID = model.generateNewID();
			if( _controlPoint1ID < 0 )	_controlPoint1ID = model.generateNewID();
			if( _controlPoint2ID < 0 )	_controlPoint2ID = model.generateNewID();
			if( _controlPoint3ID < 0 )	_controlPoint3ID = model.generateNewID();
			if( _controlPoint4ID < 0 )	_controlPoint4ID = model.generateNewID();
			
			if( !_blockName )			
			{
				var blockDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( IntegraContainer._serverInterfaceName );
				_blockName = track.getNewChildName( "Block", blockDefinition.moduleGuid );
			}

			if( !_blockEnvelopeName )	
			{
				var envelopeDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Envelope._serverInterfaceName );
				_blockEnvelopeName = track.getNewChildName( "BlockEnvelope", envelopeDefinition.moduleGuid );
			}

			return true;
		} 
		

		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveBlock( _blockID ) );			
		}	
		
		
		public override function execute( model:IntegraModel ):void
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );

			var block:Block = new Block;
			block.id = _blockID;
			block.name = _blockName;

			var blockEnvelope:Envelope = new Envelope;
			blockEnvelope.id = _blockEnvelopeID;
			blockEnvelope.name = _blockEnvelopeName;
			blockEnvelope.startTicks = start;
			
			var controlPoint1:ControlPoint = new ControlPoint;
			controlPoint1.id = _controlPoint1ID;
			controlPoint1.name = _controlPoint1Name;
			controlPoint1.tick = -1;
			controlPoint1.value = 0;
			
			var controlPoint2:ControlPoint = new ControlPoint;
			controlPoint2.id = _controlPoint2ID;
			controlPoint2.name = _controlPoint2Name;
			controlPoint2.tick = 0;
			controlPoint2.value = 1;

			var controlPoint3:ControlPoint = new ControlPoint;
			controlPoint3.id = _controlPoint3ID;
			controlPoint3.name = _controlPoint3Name;
			controlPoint3.tick = ( _end - _start - 1 );
			controlPoint3.value = 1;

			var controlPoint4:ControlPoint = new ControlPoint;
			controlPoint4.id = _controlPoint4ID;
			controlPoint4.name = _controlPoint4Name;
			controlPoint4.tick = ( _end - _start );
			controlPoint4.value = 0;
			
			block.blockEnvelope = blockEnvelope;
			
			model.addDataObject( _trackID, block );
			model.addDataObject( _trackID, blockEnvelope );
			model.addDataObject( blockEnvelope.id, controlPoint1 );
			model.addDataObject( blockEnvelope.id, controlPoint2 );
			model.addDataObject( blockEnvelope.id, controlPoint3 );
			model.addDataObject( blockEnvelope.id, controlPoint4 );
		}
			
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;

			//create block
			var trackPath:Array = model.getPathArrayFromID( _trackID );
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.new";
			methodCalls[ 0 ].params = [ model.getCoreInterfaceGuid( IntegraContainer._serverInterfaceName ), _blockName, trackPath ];

			//create block envelope
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.new";
			methodCalls[ 1 ].params = [ model.getCoreInterfaceGuid( Envelope._serverInterfaceName ), _blockEnvelopeName, trackPath ];

			//set block envelope attributes
			var blockEnvelopePath:Array = trackPath.concat( _blockEnvelopeName );

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ blockEnvelopePath.concat( "startTick" ), start ];

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
			methodCalls[ 11 ].params = [ controlPoint3Path.concat( "tick" ), ( end - start - 1 ) ];

			methodCalls[ 12 ] = new Object;
			methodCalls[ 12 ].methodName = "command.set";
			methodCalls[ 12 ].params = [ controlPoint3Path.concat( "value" ), 1 ];

			var controlPoint4Path:Array = blockEnvelopePath.concat( _controlPoint4Name );
			methodCalls[ 13 ] = new Object;
			methodCalls[ 13 ].methodName = "command.set";
			methodCalls[ 13 ].params = [ controlPoint4Path.concat( "tick" ), ( end - start ) ];

			methodCalls[ 14 ] = new Object;
			methodCalls[ 14 ].methodName = "command.set";
			methodCalls[ 14 ].params = [ controlPoint4Path.concat( "value" ), 0 ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 15 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.new" ) return false;
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


		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new SetPrimarySelectedChild( model.project.id, _trackID ) );
			controller.processCommand( new SetPrimarySelectedChild( _trackID, _blockID ) );
			controller.processCommand( new SetObjectSelection( _blockID, true ) );
			
			//connections
			connectPlayerToBlockEnvelope( model, controller );
			connectBlockEnvelopeToActive( model, controller );
			
			//default new block contents
			createDefaultBlockContents( model, controller );

			//info (use view-specific value, because we want different default for project/track/block)
			controller.processCommand( new SetObjectInfo( _blockID, InfoMarkupForViews.instance.getInfoForView( "BlockView" ).markdown ) );
			
			//update project length
			controller.processCommand( new UpdateProjectLength() );
		}


		private function connectPlayerToBlockEnvelope( model:IntegraModel, controller:IntegraController ):void
		{
			var addConnectionCommand:AddConnection = new AddConnection( model.project.id );
			controller.processCommand( addConnectionCommand );
			
			controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, model.project.player.id, "tick", _blockEnvelopeID, "currentTick" ) );	
		}


		private function connectBlockEnvelopeToActive( model:IntegraModel, controller:IntegraController ):void
		{
			var addConnectionCommand:AddConnection = new AddConnection( _trackID );
			controller.processCommand( addConnectionCommand );
			
			controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, _blockEnvelopeID, "currentValue", _blockID, "active" ) );	
		}
		
		
		private function createDefaultBlockContents( model:IntegraModel, controller:IntegraController ):void
		{
			const inputInterfaceName:String = "AudioIn";
			const outputInterfaceName:String = "StereoAudioOut";
			const midiInterfaceName:String = "MIDI";
	
			var inputInterfaceDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( inputInterfaceName );   
			var outputInterfaceDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( outputInterfaceName );
			var midiInterfaceDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( midiInterfaceName );
			Assert.assertNotNull( inputInterfaceDefinition );
			Assert.assertNotNull( outputInterfaceDefinition );
			Assert.assertNotNull( midiInterfaceDefinition );
			Assert.assertTrue( inputInterfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_OUTPUT ) > 0 );
			Assert.assertTrue( outputInterfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_INPUT ) > 0 );

			var moduleWidth:Number = ModuleInstance.getModuleWidth();
			var inputModuleHeight:Number = ModuleInstance.getModuleHeight( inputInterfaceDefinition );
			var outputModuleHeight:Number = ModuleInstance.getModuleHeight( outputInterfaceDefinition );
			var midiModuleHeight:Number = ModuleInstance.getModuleHeight( midiInterfaceDefinition );
			var horizontalMargin:Number = moduleWidth / 8;
			var verticalMargin:Number = moduleWidth * 3 / 4;
			var inputPosition:Rectangle = new Rectangle( horizontalMargin, verticalMargin, moduleWidth, inputModuleHeight );  
			var outputPosition:Rectangle = new Rectangle( moduleWidth * 4 + horizontalMargin, verticalMargin, moduleWidth, inputModuleHeight );
			
			var addInput:LoadModule = new LoadModule( inputInterfaceDefinition.moduleGuid, _blockID, inputPosition );
			var addOutput:LoadModule = new LoadModule( outputInterfaceDefinition.moduleGuid, _blockID, outputPosition );
			var addMIDI:AddMidi = new AddMidi( _blockID );
			
			controller.processCommand( addMIDI );
			controller.processCommand( addOutput );
			controller.processCommand( addInput ); 
		}
		

		private var _blockID:int;
		private var _blockEnvelopeID:int;
		private var _blockName:String;
		private var _blockEnvelopeName:String;
		private var _controlPoint1ID:int;
		private var _controlPoint2ID:int;
		private var _controlPoint3ID:int;
		private var _controlPoint4ID:int;
		private var _trackID:int;
		private var _start:int;
		private var _end:int;
		
		private static const _controlPoint1Name:String = "ControlPoint1";
		private static const _controlPoint2Name:String = "ControlPoint2";
		private static const _controlPoint3Name:String = "ControlPoint3";
		private static const _controlPoint4Name:String = "ControlPoint4";
	}
}
