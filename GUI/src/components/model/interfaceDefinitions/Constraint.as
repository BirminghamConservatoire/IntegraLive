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


package components.model.interfaceDefinitions
{
	import flexunit.framework.Assert;
	

	public class Constraint
	{
		public function Constraint()
		{
		}

		
		public function get range():ValueRange 					{ return _range; }
		public function get allowedValues():Vector.<Object> 	{ return _allowedValues; }

		public function set range( range:ValueRange ):void
		{
			Assert.assertNull( _allowedValues );
			_range = range;
		}
		
		public function set allowedValues( allowedValues:Vector.<Object> ):void
		{
			Assert.assertNull( _range );
			_allowedValues = allowedValues;
		}

		
		public function get minimum():Number
		{
			//retrieve a minimum from range or allowed values, whichever is present
			if( _range ) 
			{
				return _range.minimum;
			}
			else
			{
				Assert.assertNotNull( _allowedValues );
				
				var minimum:Number = 0;
				var first:Boolean = true;
				
				for each( var allowedValue:Object in _allowedValues )
				{
					if( first || Number( allowedValue ) < minimum )
					{
						first = false;
						minimum = Number( allowedValue );
					}
				}
				return minimum;
			}
		}

		public function get maximum():Number
		{
			//retrieve a minimum from range or allowed values, whichever is present
			if( _range ) 
			{
				return _range.maximum;
			}
			else
			{
				Assert.assertNotNull( _allowedValues );
				
				var maximum:Number = 0;
				var first:Boolean = true;
				
				for each( var allowedValue:Object in _allowedValues )
				{
					if( first || Number( allowedValue ) > maximum )
					{
						first = false;
						maximum = Number( allowedValue );
					}
				}
				
				return maximum;
			}
		}
		
		
		
	
		private var _range:ValueRange = null;
		private var _allowedValues:Vector.<Object> = null;
	
	}
}
