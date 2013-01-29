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
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.Block;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.Connection;
	
	import flexunit.framework.Assert;
 

	public class AddControlPoint extends ServerCommand
	{
		public function AddControlPoint( envelopeID:int, tick:int, value:Number, controlPointID:int = -1, controlPointName:String = null )
		{
			super();
			
			_envelopeID = envelopeID;
			_tick = tick;
			_value = value;
			_controlPointID = controlPointID;
			_controlPointName = controlPointName;
		}
		
		
		public function get envelopeID():int { return _envelopeID; }
		public function get tick():int { return _tick; }
		public function get value():Number { return _value; }
		public function get controlPointID():int { return _controlPointID; }
		public function get controlPointName():String { return _controlPointName; }
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var envelope:Envelope = model.getEnvelope( _envelopeID );
			if( !envelope ) 
			{
				return false;	//envelope doesn't exist
			}
			
			var block:Block = model.getBlockFromEnvelope( _envelopeID );
			Assert.assertNotNull( block );
			
			if( _tick < 0 || tick > block.length )
			{
				return false;	//control point's tick is out of range 
			}
			
			for each( var existingControlPoint:ControlPoint in envelope.controlPoints )
			{
				if( existingControlPoint.tick == _tick )
				{
					return false;	//control point's tick already in use
				}
			}
			
			var envelopeTarget:Connection = model.getEnvelopeTarget( _envelopeID );
			Assert.assertNotNull( envelopeTarget );
			
			var module:ModuleInstance = model.getModuleInstance( envelopeTarget.targetObjectID );
			Assert.assertNotNull( module );
			
			var endpoint:EndpointDefinition = module.interfaceDefinition.getEndpointDefinition( envelopeTarget.targetAttributeName );
			if( !endpoint || !endpoint.isStateful )
			{
				return false;
			}

			if( _value < endpoint.controlInfo.stateInfo.constraint.minimum || _value > endpoint.controlInfo.stateInfo.constraint.maximum )
			{
				return false;	//control point's value is out of range
			}
			
			if( _controlPointID < 0 )
			{
				_controlPointID = model.generateNewID();
			}

			if( !_controlPointName )
			{
				_controlPointName = envelope.getNewControlPointName();
			}

			return true;
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveControlPoint( _controlPointID ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var controlPoint:ControlPoint = new ControlPoint;
			controlPoint.id = _controlPointID;
			controlPoint.name = _controlPointName;
			controlPoint.tick = _tick;
			controlPoint.value = _value;

			model.addDataObject( _envelopeID, controlPoint ); 			
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var envelopePath:Array = model.getPathArrayFromID( _envelopeID );
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.new";
			methodCalls[ 0 ].params = [ model.getCoreInterfaceGuid( ControlPoint._serverInterfaceName ), _controlPointName, envelopePath ];
			
			var controlPointPath:Array = envelopePath.concat( _controlPointName );
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ controlPointPath.concat( "tick" ), _tick ];

			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ controlPointPath.concat( "value" ), _value ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 3 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.new" ) return false;
			if( response[ 1 ][ 0 ].response != "command.set" ) return false;
			if( response[ 2 ][ 0 ].response != "command.set" ) return false;
						
			return true;
		}		

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
		}


		private var _envelopeID:int;
		private var _tick:int;
		private var _value:Number;
		private var _controlPointID:int;
		private var _controlPointName:String;  
	}
}