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
	import components.model.Connection;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	public class SwitchObjectVersion extends ServerCommand
	{
		public function SwitchObjectVersion( objectID:int, toGuid:String )
		{
			super();
	
			_objectID = objectID;
			_toGuid = toGuid;		
		}
		
		public function get objectID():int { return _objectID; }
		public function get toGuid():String { return _toGuid; }
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			if( !object ) return false;
			
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );
			if( !newInterface ) return false;
			
			if( object.interfaceDefinition.originGuid != newInterface.originGuid ) return false;
			
			if( object.interfaceDefinition.moduleGuid == newInterface.moduleGuid ) return false;
			
			return true;				
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );
			
			pushInverseCommand( new SwitchObjectVersion( _objectID, object.interfaceDefinition.moduleGuid ) );
		}
		
		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			removeObsoleteConnections( model, controller );
			
			correctScalerRanges( model, controller );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );

			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );
			Assert.assertNotNull( newInterface );

			object.interfaceDefinition = newInterface;
		}
		
		
		override public function executeServerCommand( model:IntegraModel ):void
		{
			var modulePath:Array = model.getPathArrayFromID( _objectID );
			Assert.assertTrue( modulePath.length > 0 );
			
			var moduleName:String = modulePath[ modulePath.length - 1 ];
			var parentPath:Array = modulePath.slice( 0, modulePath.length - 1 );
			
			var methodCalls:Array = new Array;
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.delete";
			methodCalls[ 0 ].params = [ modulePath ];
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.new";
			methodCalls[ 1 ].params = [ _toGuid, moduleName, parentPath ];
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );		
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 2 + Utilities.getNumberOfProperties( _newAttributeValues ) ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.delete" ) return false;
			if( response[ 1 ][ 0 ].response != "command.new" ) return false;
			
			return true;
		}				
			
		
		private function removeObsoleteConnections( model:IntegraModel, controller:IntegraController ):void
		{
			var oldInterface:InterfaceDefinition = model.getDataObjectByID( _objectID ).interfaceDefinition;
			Assert.assertNotNull( oldInterface );
			
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );
			Assert.assertNotNull( newInterface );
			
			for( var ancestor:IntegraContainer = model.getParent( _objectID ) as IntegraContainer; ancestor; ancestor = model.getParent( ancestor.id ) as IntegraContainer )
			{
				//first remove scaled connections
				for each( var scaler:Scaler in ancestor.scalers )
				{
					if( scaler.upstreamConnection.sourceObjectID == _objectID )
					{
						if( !isConnectionStillValid( oldInterface, newInterface, scaler.upstreamConnection.sourceAttributeName, false ) )
						{
							controller.processCommand( new RemoveScaledConnection( scaler.id ) );
							continue;
						}
					}

					if( scaler.downstreamConnection.targetObjectID == _objectID )
					{
						if( !isConnectionStillValid( oldInterface, newInterface, scaler.downstreamConnection.targetAttributeName, true ) )
						{
							controller.processCommand( new RemoveScaledConnection( scaler.id ) );
							continue;
						}
					}
				}
					
				//then remove stream connections
				for each( var connection:Connection in ancestor.connections )
				{
					if( connection.sourceObjectID == _objectID )
					{
						if( !isConnectionStillValid( oldInterface, newInterface, connection.sourceAttributeName, false ) )
						{
							controller.processCommand( new RemoveConnection( connection.id ) );
							continue;
						}
					}
					
					if( connection.targetObjectID == _objectID )
					{
						if( !isConnectionStillValid( oldInterface, newInterface, connection.targetAttributeName, true ) )
						{
							controller.processCommand( new RemoveConnection( connection.id ) );
							continue;
						}
					}
				}

			}
		}		
		
		
		private function isConnectionStillValid( oldInterface:InterfaceDefinition, newInterface:InterfaceDefinition, endpointName:String, isTarget:Boolean ):Boolean
		{
			var oldEndpointDefinition:EndpointDefinition = oldInterface.getEndpointDefinition( endpointName );
			Assert.assertNotNull( oldEndpointDefinition );

			var newEndpointDefinition:EndpointDefinition = newInterface.getEndpointDefinition( endpointName );
			if( !newEndpointDefinition ) return false;
			
			if( newEndpointDefinition.type != oldEndpointDefinition.type ) return false;

			switch( newEndpointDefinition.type )
			{
				case EndpointDefinition.CONTROL:
					if( newEndpointDefinition.controlInfo.type == ControlInfo.STATE && newEndpointDefinition.controlInfo.stateInfo.type == StateInfo.STRING )
					{
						return false;
					}
					
					if( isTarget ) 
					{
						return newEndpointDefinition.controlInfo.canBeTarget;
					}
					else
					{
						return newEndpointDefinition.controlInfo.canBeSource;
					}
					
				case EndpointDefinition.STREAM:
					if( newEndpointDefinition.streamInfo.streamType != oldEndpointDefinition.streamInfo.streamType )
					{
						return false;
					}
					
					if( isTarget )
					{
						return ( newEndpointDefinition.streamInfo.streamDirection == StreamInfo.DIRECTION_INPUT );
					}
					else
					{
						return ( newEndpointDefinition.streamInfo.streamDirection == StreamInfo.DIRECTION_OUTPUT );
					}
					
				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		
		private function correctScalerRanges( model:IntegraModel, controller:IntegraController ):void
		{
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );
			Assert.assertNotNull( newInterface );
			
			for( var ancestor:IntegraContainer = model.getParent( _objectID ) as IntegraContainer; ancestor; ancestor = model.getParent( ancestor.id ) as IntegraContainer )
			{
				for each( var scaler:Scaler in ancestor.scalers )
				{
					if( scaler.upstreamConnection.sourceObjectID == _objectID )
					{
						var upstreamEndpoint:EndpointDefinition = newInterface.getEndpointDefinition( scaler.upstreamConnection.sourceAttributeName );
						Assert.assertNotNull( upstreamEndpoint );
						Assert.assertNotNull( upstreamEndpoint.type == EndpointDefinition.CONTROL );
						
						var minimum:Number = 0;
						var maximum:Number = 0;
						if( upstreamEndpoint.isStateful )
						{
							minimum = upstreamEndpoint.controlInfo.stateInfo.constraint.minimum;
							maximum = upstreamEndpoint.controlInfo.stateInfo.constraint.maximum;
						}
						
						var inRangeMin:Number = Math.max( minimum, Math.min( maximum, scaler.inRangeMin ) );
						var inRangeMax:Number = Math.max( minimum, Math.min( maximum, scaler.inRangeMax ) );
						
						if( inRangeMin != scaler.inRangeMin || inRangeMax != scaler.inRangeMax )
						{
							controller.processCommand( new SetScalerInputRange( scaler.id, inRangeMin, inRangeMax ) );
						}
					}
					
					if( scaler.downstreamConnection.targetObjectID == _objectID )
					{
						var downstreamEndpoint:EndpointDefinition = newInterface.getEndpointDefinition( scaler.downstreamConnection.targetAttributeName );
						Assert.assertNotNull( downstreamEndpoint );
						Assert.assertNotNull( downstreamEndpoint.type == EndpointDefinition.CONTROL );
						
						minimum = 0;
						maximum = 0;
						if( downstreamEndpoint.isStateful )
						{
							minimum = downstreamEndpoint.controlInfo.stateInfo.constraint.minimum;
							maximum = downstreamEndpoint.controlInfo.stateInfo.constraint.maximum;
						}
						
						var outRangeMin:Number = Math.max( minimum, Math.min( maximum, scaler.outRangeMin ) );
						var outRangeMax:Number = Math.max( minimum, Math.min( maximum, scaler.outRangeMax ) );
						
						if( outRangeMin != scaler.outRangeMin || outRangeMax != scaler.outRangeMax )
						{
							controller.processCommand( new SetScalerOutputRange( scaler.id, outRangeMin, outRangeMax ) );
						}
					}
				}
			}			
		}
		
		
		private var _objectID:int;
		private var _toGuid:String;		
		
		private var _newAttributeValues:Object;
	}
}