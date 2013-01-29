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
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;
	

	public class SetConnectionRouting extends ServerCommand
	{
		public function SetConnectionRouting( connectionID:int, sourceObjectID:int, sourceAttributeName:String, targetObjectID:int, targetAttributeName:String )
		{
			super();
			
			_connectionID = connectionID;
						
			_sourceObjectID = sourceObjectID; 
			_sourceAttributeName = sourceAttributeName;
			_targetObjectID = targetObjectID; 
			_targetAttributeName = targetAttributeName;
		}
		
		public function get connectionID():int { return _connectionID; }
		public function get sourceObjectID():int { return _sourceObjectID; }
		public function get sourceAttributeName():String { return _sourceAttributeName; }
		public function get targetObjectID():int { return _targetObjectID; }
		public function get targetAttributeName():String { return _targetAttributeName; }
	
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !sourceAttributeName )
			{
				var onlyRoutableSourceAttribute:String = getOnlyRoutableEndpoint( model, _sourceObjectID, false );
				if( onlyRoutableSourceAttribute ) 
				{
					_sourceAttributeName = onlyRoutableSourceAttribute;
				}
			}
			
			if( !targetAttributeName )
			{
				var onlyRoutableTargetAttribute:String = getOnlyRoutableEndpoint( model, _targetObjectID, true );
				if( onlyRoutableTargetAttribute ) 
				{
					_targetAttributeName = onlyRoutableTargetAttribute;
				}
			}

			if( model.isAudioLink( _sourceObjectID, _sourceAttributeName, _targetObjectID, _targetAttributeName ) )
			{
				if( !model.canSetAudioLink( _sourceObjectID, _sourceAttributeName, _targetObjectID, _targetAttributeName, _connectionID ) )
				{
					return false;
				}
			}
			else
			{
				if( model.doesObjectExist( _sourceObjectID ) )
				{
					var sourceObject:IntegraDataObject = model.getDataObjectByID( _sourceObjectID );
					if( sourceObject is Scaler )
					{
						var sourceScaler:Scaler = sourceObject as Scaler;
						if( !model.canSetScaledConnection( sourceScaler.upstreamConnection.sourceObjectID, sourceScaler.upstreamConnection.sourceAttributeName, _targetObjectID, _targetAttributeName ) )
						{
							return false;
						}
					}
				}
				
				if( model.doesObjectExist( _targetObjectID ) )
					{
						var targetObject:IntegraDataObject = model.getDataObjectByID( _targetObjectID );
						if( targetObject is Scaler )
						{
							var targetScaler:Scaler = targetObject as Scaler;
							if( !model.canSetScaledConnection( _sourceObjectID, _sourceAttributeName, targetScaler.downstreamConnection.targetObjectID, targetScaler.downstreamConnection.targetAttributeName ) )
							{
								return false;
							}
						}
					}
			}

			_previousSourceScaler = getSourceScaler( model );
			_previousTargetScaler = getTargetScaler( model );
			
			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var connection:Connection = model.getConnection( _connectionID );
			Assert.assertNotNull( connection );
			
			pushInverseCommand( new SetConnectionRouting( _connectionID, connection.sourceObjectID, connection.sourceAttributeName, connection.targetObjectID, connection.targetAttributeName ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var connection:Connection = model.getConnection( _connectionID );
			Assert.assertNotNull( connection );
			
			connection.sourceObjectID = _sourceObjectID;
			connection.sourceAttributeName = _sourceAttributeName;
			connection.targetObjectID = _targetObjectID;
			connection.targetAttributeName = _targetAttributeName;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var sourceObject:IntegraDataObject = ( _sourceObjectID >= 0 ) ? model.getDataObjectByID( _sourceObjectID ) : null;
			var targetObject:IntegraDataObject = ( _targetObjectID >= 0 ) ? model.getDataObjectByID( _targetObjectID ) : null;
			
			var methodCalls:Array = new Array;
			
			var connectionPath:Array = model.getPathArrayFromID( _connectionID );

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ connectionPath.concat( "sourcePath" ), getRelativePath( model, connectionPath, _sourceObjectID, _sourceAttributeName ) ]; 
	
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ connectionPath.concat( "targetPath" ), getRelativePath( model, connectionPath, _targetObjectID, _targetAttributeName ) ]; 
	
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			Assert.assertNotNull( responseArray );

			if( responseArray.length != 2 ) return false;

			if( responseArray[ 0 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 1 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}
		
		
		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			var sourceScaler:Scaler = getSourceScaler( model );
			if( sourceScaler )
			{
				var endpointDefinition:EndpointDefinition = model.getEndpointDefinition( _targetObjectID, _targetAttributeName );
				if( endpointDefinition && endpointDefinition.isStateful )
				{
					controller.processCommand( new SetScalerOutputRange( sourceScaler.id, endpointDefinition.controlInfo.stateInfo.constraint.minimum, endpointDefinition.controlInfo.stateInfo.constraint.maximum ) );
				}
				else
				{
					controller.processCommand( new SetScalerOutputRange( sourceScaler.id, 0, 0 ) );
				}
			}
			else
			{
				if( _previousSourceScaler )
				{
					controller.processCommand( new SetScalerOutputRange( _previousSourceScaler.id, 0, 0 ) );
				}
			}
			
			var targetScaler:Scaler = getTargetScaler( model );
			if( targetScaler )
			{
				endpointDefinition = model.getEndpointDefinition( _sourceObjectID, _sourceAttributeName );
				if( endpointDefinition && endpointDefinition.isStateful )
				{
					controller.processCommand( new SetScalerInputRange( targetScaler.id, endpointDefinition.controlInfo.stateInfo.constraint.minimum, endpointDefinition.controlInfo.stateInfo.constraint.maximum ) );
				}
				else
				{
					controller.processCommand( new SetScalerInputRange( targetScaler.id, 0, 0 ) );
				}
			}
			else
			{
				if( _previousTargetScaler )
				{
					controller.processCommand( new SetScalerInputRange( _previousTargetScaler.id, 0, 0 ) );
				}
			}
		}
		
		
		private function getRelativePath( model:IntegraModel, connectionPath:Array, objectID:int, attributeName:String ):String
		{
			var relativePath:String = "";
			
			if( objectID >= 0 )
			{
				relativePath = model.getPathArrayFromID( objectID ).slice( connectionPath.length - 1 ).join( "." );
			}
			
			relativePath += ".";
			
			if( attributeName )
			{
				relativePath += attributeName; 
			}
			
			return relativePath;			
		}
		
		
		private function getOnlyRoutableEndpoint( model:IntegraModel, objectID:int, isTarget:Boolean ):String
		{
			if( objectID < 0 ) 
			{
				return null;
			}
			
			var object:IntegraDataObject = model.getDataObjectByID( objectID );
			Assert.assertNotNull( object );
			
			var onlyRoutableAttribute:String = null;
			
			for each( var endpoint:EndpointDefinition in object.interfaceDefinition.endpoints )
			{
				var isRoutable:Boolean = isTarget ? endpoint.canBeConnectionTarget : endpoint.canBeConnectionSource;
				if( isRoutable )
				{
					if( onlyRoutableAttribute )
					{
						//found more than one Routable attribute
						return null;
					}
					
					onlyRoutableAttribute = endpoint.name;
				}
			}
			
			return onlyRoutableAttribute;		
		}
		
		
		private function getSourceScaler( model:IntegraModel ):Scaler
		{
			var connection:Connection = model.getConnection( _connectionID );
			Assert.assertNotNull( connection );
			
			if( connection.sourceObjectID < 0 )
			{
				return null;
			}
			
			var sourceObject:IntegraDataObject = model.getDataObjectByID( connection.sourceObjectID );
			if( !( sourceObject is Scaler ) )
			{
				return null;
			}
			
			var sourceScaler:Scaler = sourceObject as Scaler;
			if( sourceScaler.downstreamConnection.id != _connectionID ) 
			{
				return null;
			}
			
			return( connection.sourceAttributeName == "outValue" ) ? sourceScaler : null;
		}

		
		private function getTargetScaler( model:IntegraModel ):Scaler
		{
			var connection:Connection = model.getConnection( _connectionID );
			Assert.assertNotNull( connection );

			if( connection.targetObjectID < 0 )
			{
				return null;
			}
			
			var targetObject:IntegraDataObject = model.getDataObjectByID( connection.targetObjectID );
			if( !( targetObject is Scaler ) )
			{
				return null;
			}
			
			var targetScaler:Scaler = targetObject as Scaler;
			if( targetScaler.upstreamConnection.id != _connectionID ) 
			{
				return null;
			}
			
			return( connection.targetAttributeName == "inValue" ) ? targetScaler : null;
		}
		
		
		private var _connectionID:int;
		private var _sourceObjectID:int;
		private var _sourceAttributeName:String;
		private var _targetObjectID:int;
		private var _targetAttributeName:String;
		
		private var _previousSourceScaler:Scaler = null;
		private var _previousTargetScaler:Scaler = null;
	}
}