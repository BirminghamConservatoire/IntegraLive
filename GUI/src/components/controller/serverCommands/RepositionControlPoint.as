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
	
	import components.controller.ServerCommand;
	import components.model.Block;
	import components.model.Connection;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	
	import flexunit.framework.Assert;

	public class RepositionControlPoint extends ServerCommand
	{
		public function RepositionControlPoint( controlPointID:int, tick:int, value:Number )
		{
			super();
			
		 	_controlPointID = controlPointID;
		 	_tick = tick;
		 	_value = value;
		}

		
		public function get controlPointID():int { return _controlPointID; }
		public function get tick():int { return _tick; }
		public function get value():Number { return _value; }

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var envelope:Envelope = model.getEnvelopeFromControlPoint( _controlPointID );
			if( !envelope ) return false;
			
			var block:Block = model.getBlockFromEnvelope( envelope.id );
			if( !block ) return false;
			
			var envelopeTarget:Connection = model.getEnvelopeTarget( envelope.id );
			if( !envelopeTarget ) return false;

			var module:ModuleInstance = model.getModuleInstance( envelopeTarget.targetObjectID );
			if( !module ) return false;

			var endpointDefinition:EndpointDefinition = module.interfaceDefinition.getEndpointDefinition( envelopeTarget.targetAttributeName );
			if( !endpointDefinition ) return false;
			
			//check tick is in range
			if( _tick < 0 || _tick > block.length ) return false;
			
			//check not changing tick of first control point
			var controlPoints:Vector.<ControlPoint> = envelope.orderedControlPoints; 
			if( controlPoints.length > 0 && controlPoints[ 0 ].id == _controlPointID && _tick != 0 )
			{
				return false;
			} 		
			
			//check value is in range
			if( _value < endpointDefinition.controlInfo.stateInfo.constraint.minimum || _value > endpointDefinition.controlInfo.stateInfo.constraint.maximum ) return false;
			
			for each( var otherControlPoint:ControlPoint in envelope.controlPoints )
			{
				if( otherControlPoint.id != _controlPointID )
				{
					if( otherControlPoint.tick == _tick )
					{
						return false;	//disallow setting control point to same tick as a sibling
					}
				}
			}  
			
			return true;
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			var controlPoint:ControlPoint = model.getControlPoint( _controlPointID );
			Assert.assertNotNull( controlPoint );

			pushInverseCommand( new RepositionControlPoint( _controlPointID, controlPoint.tick, controlPoint.value ) )
		}


		public override function execute( model:IntegraModel ):void
		{
			var controlPoint:ControlPoint = model.getControlPoint( _controlPointID );
			Assert.assertNotNull( controlPoint );
			
			controlPoint.tick = _tick;
			controlPoint.value = _value;
		}			


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;

			var controlPointPath:Array = model.getPathArrayFromID( _controlPointID );

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ controlPointPath.concat( "tick" ), _tick ];

			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ controlPointPath.concat( "value" ), _value ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			if( !response is Array ) return false;
			
			var responses:Array = response as Array;
			Assert.assertNotNull( responses );
		
			if( responses.length != 2 ) return false;
			
			if( responses[ 0 ][ 0 ].response != "command.set" ) return false;
			if( responses[ 1 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}	
		

		private var _controlPointID:int;
		private var _tick:int;
		private var _value:Number; 
	}
}