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


package components.model
{
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.model.userData.UserData;
	
	import flash.utils.ByteArray;
	
	import flexunit.framework.Assert;
	
	
	public class ModuleInstance extends IntegraDataObject
	{
		public function ModuleInstance()
		{
			super();

			internalUserData = new UserData;
		}

		public static function getModuleWidth():Number 
		{ 
			return _standardModuleWidth; 
		}		
		
		public static function getModuleHeight( interfaceDefinition:InterfaceDefinition ):Number 
		{ 
			Assert.assertNotNull( interfaceDefinition );
			
			var numberOfInputPins:uint = interfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_INPUT );
			var numberOfOutputPins:uint = interfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_OUTPUT );
			
			var heightNeededForPins:Number = Math.max( numberOfInputPins, numberOfOutputPins ) * _minimumHeightPerPin;
			
			return Math.max( _minimumModuleHeight, heightNeededForPins ); 
		}		
		
		
		public function get attributes():Object { return _attributes; }
		
		public function get userData():UserData { return internalUserData; }

		public function set attributes( attributes:Object ):void { _attributes = attributes; }

		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			var endpoint:EndpointDefinition = interfaceDefinition.getEndpointDefinition( attributeName );
			Assert.assertNotNull( endpoint );
			Assert.assertTrue( endpoint.isStateful );
			
			switch( endpoint.controlInfo.stateInfo.type )
			{
				case StateInfo.INTEGER:
					if( !value is int )
					{
						Assert.assertTrue( false );
						return false;
					} 
					break;

				case StateInfo.FLOAT:
					if( !value is Number )
					{
						Assert.assertTrue( false );
						return false;
					} 
					break;

				case StateInfo.STRING:
					if( !value is String )
					{
						Assert.assertTrue( false );
						return false;
					} 
					break;
			}

			attributes[ attributeName ] = value;
			return true;
		}
		

		private static const _standardModuleWidth:Number = 7;		
		private static const _minimumModuleHeight:Number = 3;
		private static const _minimumHeightPerPin:Number = 1;

		private var _attributes:Object;
	}
}
