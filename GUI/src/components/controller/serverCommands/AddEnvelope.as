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
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	
	import flexunit.framework.Assert;
 

	public class AddEnvelope extends ServerCommand
	{
		public function AddEnvelope( blockID:int, targetModuleID:int, targetAttribute:String, startValue:Number, startTicks:int = -1, envelopeID:int = -1, envelopeName:String = null )
		{
			super();
			
			_blockID = blockID;
			_targetModuleID = targetModuleID;
			_startTicks = startTicks;
			_startValue = startValue; 
			_targetAttribute = targetAttribute;
			_envelopeID = envelopeID;
			_envelopeName = envelopeName;  
		}
		
		
		public function get blockID():int { return _blockID; }
		public function get targetModuleID():int { return _targetModuleID; }
		public function get targetAttribute():String { return _targetAttribute; }
		public function get startTicks():int { return _startTicks; }
		public function get startValue():Number { return _startValue; }
		public function get envelopeID():int { return _envelopeID; }
		public function get envelopeName():String { return _envelopeName; }
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var block:Block = model.getBlock( _blockID );
			if( !block ) 
			{
				return false;	//block doesn't exist
			}
			
			if( block.getEnvelope( _targetModuleID, _targetAttribute ) != null )
			{
				return false;	//target already controlled by an envelope
			}
			
			var module:ModuleInstance = model.getModuleInstance( _targetModuleID );
			if( !module )
			{
				return false;
			}

			var endpointDefinition:EndpointDefinition = module.interfaceDefinition.getEndpointDefinition( _targetAttribute );
			if( !endpointDefinition || !endpointDefinition.isStateful || endpointDefinition.controlInfo.stateInfo.type == StateInfo.STRING )
			{
				return false;	
			}
			
			if( _startValue < endpointDefinition.controlInfo.stateInfo.constraint.minimum || _startValue > endpointDefinition.controlInfo.stateInfo.constraint.maximum )
			{
				return false;	//start value out of range
			}
			
			if( _startTicks < 0 )
			{
				_startTicks = block.start;
			}
			
			if( _startTicks != block.start )
			{
				return false;	//envelope start times should always match their owning block! 
			}
			
			if( _envelopeID < 0 )
			{
				_envelopeID = model.generateNewID();
			}

			if( !_envelopeName )
			{
				var envelopeInterface:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Envelope._serverInterfaceName );
				_envelopeName = block.getNewChildName( Envelope._serverInterfaceName, envelopeInterface.moduleGuid );
			}

			return true;
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveEnvelope( _envelopeID ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var envelope:Envelope = new Envelope;
			envelope.id = _envelopeID;
			envelope.name = _envelopeName;
			envelope.startTicks = _startTicks;

			model.addDataObject( _blockID, envelope );
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var blockPath:Array = model.getPathArrayFromID( _blockID );
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.new";
			methodCalls[ 0 ].params = [ model.getCoreInterfaceGuid( Envelope._serverInterfaceName ), _envelopeName, blockPath ];
			
			var envelopePath:Array = blockPath.concat( _envelopeName );
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ envelopePath.concat( "startTick" ), _startTicks ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 2 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.new" ) return false;
			if( response[ 1 ][ 0 ].response != "command.set" ) return false;
						
			return true;
		}		

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			//connections
			connectPlayerToEnvelope( model, controller );
			connectEnvelopeToModule( model, controller );

			//add initial control point
			controller.processCommand( new AddControlPoint( _envelopeID, 0, _startValue ) );
			
			//select the envelope
			controller.processCommand( new SetPrimarySelectedChild( _blockID, _envelopeID ) );
		}
		
		
		private function connectPlayerToEnvelope( model:IntegraModel, controller:IntegraController ):void
		{
			var addConnectionCommand:AddConnection = new AddConnection( model.project.id );
			controller.processCommand( addConnectionCommand );
			
			controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, model.project.player.id, "tick", _envelopeID, "currentTick" ) );	
		}


		private function connectEnvelopeToModule( model:IntegraModel, controller:IntegraController ):void
		{
			Assert.assertTrue( _targetModuleID >= 0 && targetAttribute != null );
			 
			var addConnectionCommand:AddConnection = new AddConnection( _blockID );
			controller.processCommand( addConnectionCommand );
			
			controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, _envelopeID, "currentValue", _targetModuleID, _targetAttribute ) );	
		}
		

		private var _blockID:int;
		private var _targetModuleID:int;
		private var _targetAttribute:String;
		private var _startTicks:int;
		private var _startValue:Number;
		private var _envelopeID:int;
		private var _envelopeName:String;  
	}
}