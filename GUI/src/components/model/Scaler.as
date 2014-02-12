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
	
	public class Scaler extends IntegraDataObject
	{
		public function Scaler()
		{
			super();
		}

		public function get inRangeMin():Number { return _inRangeMin; }
		public function get inRangeMax():Number { return _inRangeMax; }
		public function get inValue():Number { return _inValue; }
		public function get outRangeMin():Number { return _outRangeMin; }
		public function get outRangeMax():Number { return _outRangeMax; }
		public function get outValue():Number { return _outValue; }

		public function get upstreamConnection():Connection { return _upstreamConnection; }
		public function get downstreamConnection():Connection { return _downstreamConnection; }
		public function get midiControlInput():MidiControlInput { return _midiControlInput; }

		public function set inRangeMin( inRangeMin:Number ):void { _inRangeMin = inRangeMin; }
		public function set inRangeMax( inRangeMax:Number ):void { _inRangeMax = inRangeMax; }
		public function set inValue( inValue:Number ):void { _inValue = inValue; }
		public function set outRangeMin( outRangeMin:Number ):void { _outRangeMin = outRangeMin; }
		public function set outRangeMax( outRangeMax:Number ):void { _outRangeMax = outRangeMax; }
		public function set outValue( outValue:Number ):void { _outValue = outValue; }

		public function set upstreamConnection( upstreamConnection:Connection ):void { _upstreamConnection = upstreamConnection; }
		public function set downstreamConnection( downstreamConnection:Connection ):void { _downstreamConnection = downstreamConnection; }
		public function set midiControlInput( midiControlInput:MidiControlInput ):void { _midiControlInput = midiControlInput; }
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{         
				case "inRangeMin":
					_inRangeMin = Number( value );
					return true;
					
				case "inRangeMax":
					_inRangeMax = Number( value );
					return true;
					
				case "inValue":
					_inValue = Number( value );
					return true;

				case "outRangeMin":
					_outRangeMin = Number( value );
					return true;
					
				case "outRangeMax":
					_outRangeMax = Number( value );
					return true;
					
				case "outValue":
					_outValue = Number( value );
					return true;

				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Scaler";

		private var _inRangeMin:Number = 0;
		private var _inRangeMax:Number = 0;
		private var _inValue:Number = 0;
		private var _outRangeMin:Number = 0;
		private var _outRangeMax:Number = 0;
		private var _outValue:Number = 0;
		
		private var _upstreamConnection:Connection = null;
		private var _downstreamConnection:Connection = null;
		
		private var _midiControlInput:MidiControlInput = null;
	}
}
