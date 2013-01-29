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
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.Command;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.StateInfo;
	
	import flash.utils.ByteArray;
	
	import flexunit.framework.Assert;

	public class SetModuleAttribute extends ServerCommand
	{
		public function SetModuleAttribute( moduleID:int, endpointName:String, value:Object = null, type:String = null )
		{
			super();
			
			_moduleID = moduleID;
			_endpointName = endpointName;
			_value = value;
			_type = type;
		}
		
		
		public function get moduleID():int { return _moduleID; }
		public function get endpointName():String { return _endpointName; }
		public function get value():Object { return _value; }
		public function get type():String { return _type; }

		public override function initialize( model:IntegraModel ):Boolean
		{
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			if( !module ) return false;
			
			var endpoint:EndpointDefinition = module.interfaceDefinition.getEndpointDefinition( endpointName );
			if( !endpoint || endpoint.type != EndpointDefinition.CONTROL ) return false;

			switch( endpoint.controlInfo.type )
			{
				case ControlInfo.STATE:
					if( type != endpoint.controlInfo.stateInfo.type ) 
					{
						return false;
					}
					
					switch( _type )
					{
						case StateInfo.FLOAT:
							var numberValue:Number = _value as Number;
							if( numberValue == module.attributes[ _endpointName ] )
							{
								return false;
							}
							
							break;
						
						case StateInfo.INTEGER:
							var integerValue:int = _value as int;
							if( integerValue == module.attributes[ _endpointName ] )
							{
								return false;
							}
							
							break;				
						
						case StateInfo.STRING:
							var stringValue:String = _value as String;
							if( stringValue == module.attributes[ _endpointName ] )
							{
								return false;
							}
							
							break;		
						
						default:
							Assert.assertTrue( false );
							return false;
					}
					
					break;
				
				case ControlInfo.BANG:
					if( _type || _value ) return false;
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}
			
			return true;
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			Assert.assertNotNull( module );
			
			if( _type )
			{
				pushInverseCommand( new SetModuleAttribute( _moduleID, _endpointName, module.attributes[ _endpointName ], _type ) );
			}
			else
			{
				Assert.assertTrue( !type );	//bang
				pushInverseCommand( new SetModuleAttribute( _moduleID, _endpointName ) );
			}
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			if( _type )
			{
				var module:ModuleInstance = model.getModuleInstance( _moduleID );
				Assert.assertNotNull( module );
			
				module.attributes[ _endpointName ] = _value;
			}
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var dataType:String = null;

			if( _type )
			{
				switch( _type )
				{
					case StateInfo.FLOAT:	dataType = XMLRPCDataTypes.DOUBLE;		break;
					case StateInfo.INTEGER:	dataType = XMLRPCDataTypes.INT;			break;
					case StateInfo.STRING:	dataType = XMLRPCDataTypes.STRING;		break;
					
					default:
						Assert.assertTrue( false );
						return;	
				}
			}
					
			connection.addArrayParam( model.getPathArrayFromID( _moduleID ).concat( _endpointName ) ); 
			if( dataType )
			{
				connection.addParam( _value, dataType );
			}
			connection.callQueued( "command.set" );				
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( _moduleID ) + "." + _endpointName );
		}		
		
		
		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetModuleAttribute = previousCommand as SetModuleAttribute;
			Assert.assertNotNull( previous );
			
			return ( _moduleID == previous._moduleID ) && ( _endpointName == previous._endpointName ) && ( _type == previous._type ); 
		}

		
		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}
		
		
		private var _moduleID:int;
		private var _endpointName:String;
		private var _value:Object;
		private var _type:String;
		
	}
}