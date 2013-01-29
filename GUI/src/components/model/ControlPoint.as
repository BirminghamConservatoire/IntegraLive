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
	import flexunit.framework.Assert;
	
	public class ControlPoint extends IntegraDataObject
	{
		public function ControlPoint()
		{
			super();
		}

		public function get value():Number	{ return _value; }
		public function get tick():int { return _tick; }
		public function get curvature():Number { return _curvature; }

		public function set value( value:Number ):void { _value = value; }
		public function set tick( tick:int ):void { _tick = tick; }
		public function set curvature( curvature:Number ):void { _curvature = curvature; }
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{         
				case "value":
					_value = Number( value );
					return true;				
				
				case "tick":
					_tick = int( value );
					return true;
					
				case "curvature":
					_curvature = Number( value );
					return true;

				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "ControlPoint";
	
		private var _value:Number = 0;
		private var _tick:int = 0;
		private var _curvature:Number = 0;
	}
}
