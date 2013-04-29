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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import components.controller.IntegraController;
	import components.controller.userDataCommands.SetLiveViewControlPosition;
	import components.controller.userDataCommands.SetModulePosition;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.Constraint;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.LiveViewControl;
	import components.utils.ControlContainer;
	import components.utils.ControlMeasurer;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	public class SwitchModuleVersion extends SwitchObjectVersion
	{
		public function SwitchModuleVersion( moduleID:int, toGuid:String, newAttributeValues:Object = null )
		{
			super( moduleID, toGuid );
	
			_newAttributeValues = newAttributeValues;
		}
		
		public function get newAttributeValues():Object { return _newAttributeValues; }
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			if( !super.initialize( model ) ) return false;
			
			var module:ModuleInstance = model.getModuleInstance( objectID );
			Assert.assertNotNull( module );
			
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( toGuid );
			Assert.assertNotNull( newInterface );
			
			if( !_newAttributeValues )
			{
				_newAttributeValues = generateNewAttributeValues( module.attributes, newInterface );
			}
			
			return true;				
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var module:ModuleInstance = model.getModuleInstance( objectID );
			Assert.assertNotNull( module );
			
			pushInverseCommand( new SwitchModuleVersion( objectID, module.interfaceDefinition.moduleGuid, copyAttributeValues( module.attributes ) ) );
		}
		
		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			super.preChain( model, controller );
			
			correctModulePosition( model, controller );
			
			correctLiveViewControls( model, controller );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			super.execute( model );

			var module:ModuleInstance = model.getModuleInstance( objectID );
			Assert.assertNotNull( module );

			module.attributes = _newAttributeValues;
		}
		
		
		override public function executeServerCommand( model:IntegraModel ):void
		{
			var modulePath:Array = model.getPathArrayFromID( objectID );
			Assert.assertTrue( modulePath.length > 0 );
			
			var moduleName:String = modulePath[ modulePath.length - 1 ];
			var parentPath:Array = modulePath.slice( 0, modulePath.length - 1 );
			
			var methodCalls:Array = new Array;
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.delete";
			methodCalls[ 0 ].params = [ modulePath ];
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.new";
			methodCalls[ 1 ].params = [ toGuid, moduleName, parentPath ];

			
			for( var attributeName:String in _newAttributeValues )
			{
				var setCall:Object = new Object;
				setCall.methodName = "command.set";
				setCall.params = [ modulePath.concat( attributeName ), _newAttributeValues[ attributeName ] ];

				if( attributeName == "dataDirectory" )
				{
					/*
					if there's a data directory, we need to set it first, because poorly-written modules might
					not cope with data directory being set after filenames
					*/					
					methodCalls.splice( 2, 0, setCall );
				}
				else
				{
					methodCalls.push( setCall );					
				}
			}
			
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
			
			for( var i:int = 2; i < response.length; i++ )
			{
				if( response[ i ][ 0 ].response != "command.set" ) return false;
			}
			
			return true;
		}				
			
		
		private function copyAttributeValues( attributeValues:Object ):Object
		{
			var copy:Object = new Object;
			
			for( var key:String in attributeValues )
			{
				copy[ key ] = attributeValues[ key ];
			}
			
			return copy;
		}

		
		private function generateNewAttributeValues( attributeValues:Object, newInterface:InterfaceDefinition ):Object
		{
			var newAttributeValues:Object = new Object;
			
			for each( var endpoint:EndpointDefinition in newInterface.endpoints )
			{
				if( !endpoint.isStateful ) continue;
				
				var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;
				
				if( attributeValues.hasOwnProperty( endpoint.name ) )
				{
					newAttributeValues[ endpoint.name ] = enforceConstraint( attributeValues[ endpoint.name ], stateInfo.type, stateInfo.constraint );
				}
				else
				{
					newAttributeValues[ endpoint.name ] = stateInfo.defaultValue;
				}
			}
			
			return newAttributeValues;
		}
		
		
		private function enforceConstraint( value:Object, type:String, constraint:Constraint ):Object
		{
			if( constraint.allowedValues )
			{
				var bestAllowedValue:Object = null;
				var bestDistance:Number;
				
				for each( var allowedValue:Object in constraint.allowedValues )
				{
					var distance:Number = getDistance( value, allowedValue, type );

					if( distance == 0 ) return allowedValue;	//early exit for perfect match
					
					if( !bestAllowedValue || distance < bestDistance )
					{
						bestAllowedValue = allowedValue;
						bestDistance = distance;
					}
				}
				
				Assert.assertNotNull( bestAllowedValue );
				return bestAllowedValue;
			}
			
			//if we get here, it's a range constraint
			
			switch( type )
			{
				case StateInfo.INTEGER:
					return int( Math.max( constraint.minimum, Math.min( constraint.maximum, Math.round( Number( value ) ) ) ) );
				
				case StateInfo.FLOAT:
					return Math.max( constraint.minimum, Math.min( constraint.maximum, Number( value ) ) );
					
				case StateInfo.STRING:
					var stringValue:String = String( value );
					
					//add asterixs to get to minimum length
					for( var i:int = stringValue.length; i < constraint.minimum; i++ )
					{
						stringValue += "*";
					}
					
					//truncate if above maximum length
					if( stringValue.length > constraint.maximum )
					{
						stringValue = stringValue.substr( 0, constraint.maximum ); 
					}

					return stringValue;
					
				default:
					Assert.assertTrue( false );
					return null;
			}
		}
		
		
		private function getDistance( value1:Object, value2:Object, type:String ):Number
		{
			switch( type )
			{
				case StateInfo.INTEGER:
					return Math.abs( int( value1 ) - int( value2 ) );
					
				case StateInfo.FLOAT:
					return Math.abs( Number( value1 ) - Number( value2 ) );
					
				case StateInfo.STRING:
					return levenshtein_distance( String( value1 ), String( value2 ) );
					
				default:
					Assert.assertTrue( false );
					return 0;
			}
		}
		
		
		private function levenshtein_distance( string1:String, string2:String ):int
		{
			var length1:int = string1.length;
			var length2:int = string2.length;
			
			if( length1 == 0 ) return length2;
			if( length2 == 0 ) return length1;

			var cost:int = 0;
			
			if( string1.charCodeAt( 0 ) != string2.charCodeAt( 0 ) ) 
			{
				cost = 1;
			}
			
			var string1From2ndChar:String = string1.substr( 1 );
			var string2From2ndChar:String = string2.substr( 1 );
			
			return Math.min( Math.min( 
				levenshtein_distance( string1From2ndChar, string2 ) + 1,
				levenshtein_distance( string1, string2From2ndChar ) + 1 ), 
				levenshtein_distance( string1From2ndChar, string2From2ndChar ) + cost );
		}
	
		
		private function correctModulePosition( model:IntegraModel, controller:IntegraController ):void
		{
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( toGuid );
			Assert.assertNotNull( newInterface );

			var position:Rectangle = model.getModulePosition( objectID ).clone();
			
			var newHeight:Number = ModuleInstance.getModuleHeight( newInterface );
			if( newHeight != position.height )
			{
				position.height = newHeight;
				controller.processCommand( new SetModulePosition( objectID, position ) );
			}
		}
		
		
		private function correctLiveViewControls( model:IntegraModel, controller:IntegraController ):void
		{
			var newInterface:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( toGuid );
			Assert.assertNotNull( newInterface );

			var block:Block = model.getBlockFromModuleInstance( objectID );
			Assert.assertNotNull( block );
			
			var liveViewControls:Object = block.blockUserData.liveViewControls;
			var liveViewControlsToRemove:Vector.<LiveViewControl> = new Vector.<LiveViewControl>;
			
			for each( var liveViewControl:LiveViewControl in liveViewControls )
			{
				var newWidgetDefinition:WidgetDefinition = newInterface.getWidgetDefinition( liveViewControl.controlInstanceName );
				if( newWidgetDefinition )
				{
					if( ControlMeasurer.doesControlExist( newWidgetDefinition.type ) )
					{
						var minimumSize:Point = ControlMeasurer.getMinimumSize( newWidgetDefinition.type ).add( ControlContainer.marginSizeWithoutLabel );
						var maximumSize:Point = ControlMeasurer.getMaximumSize( newWidgetDefinition.type ).add( ControlContainer.marginSizeWithoutLabel );
						
						var newPosition:Rectangle = liveViewControl.position.clone();
						newPosition.width = Math.max( minimumSize.x, Math.min( maximumSize.x, newPosition.width ) );
						newPosition.height = Math.max( minimumSize.y, Math.min( maximumSize.y, newPosition.height ) );
						
						if( !newPosition.equals( liveViewControl.position ) )
						{
							controller.processCommand( new SetLiveViewControlPosition( objectID, liveViewControl.controlInstanceName, newPosition ) );
						}
						
						continue;
					}
				}

				liveViewControlsToRemove.push( liveViewControl );
			}

			for each( liveViewControl in liveViewControlsToRemove )
			{
				controller.processCommand( new ToggleLiveViewControl( liveViewControl ) );
			}
		}
		
		
		private var _newAttributeValues:Object;
	}
}