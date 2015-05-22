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


package components.utils
{
	import components.model.interfaceDefinitions.Constraint;
	import components.model.interfaceDefinitions.ControlScale;
	import components.model.interfaceDefinitions.StateInfo;
	
	import flexunit.framework.Assert;

	
	public class ControlScaler
	{
		public static function endpointValueToControlUnit( endpointValue:Number, stateInfo:StateInfo ):Number
		{
			const tinyErrorMargin:Number = 0.000001;
			
			var constraint:Constraint = stateInfo.constraint;
			Assert.assertNotNull( constraint.range );
			
			var minimum:Number = constraint.minimum;
			var maximum:Number = constraint.maximum;
			
			Assert.assertTrue( endpointValue >= minimum - tinyErrorMargin && endpointValue <= maximum + tinyErrorMargin );
			
			endpointValue = Math.max( minimum, Math.min( maximum, endpointValue ) );

			var unitValue:Number = 0;
				
			switch( stateInfo.scale.type )
			{
				case ControlScale.LINEAR:		
					unitValue = endpointValueToLinearUnit( endpointValue, minimum, maximum );
					break;
				
				case ControlScale.EXPONENTIAL:	
					unitValue = endpointValueToExponentialUnit( endpointValue, minimum, maximum );
					break;
				
				case ControlScale.DECIBEL:		
					unitValue = endpointValueToDecibelUnit( endpointValue, minimum, maximum );
					break;
					
				default:
					Assert.assertTrue( false );
					return 0;
			}
			
			unitValue = Math.max( 0, Math.min( 1, unitValue ) );
			return unitValue;
		}
		
		
		public static function controlUnitToEndpointValue( controlUnit:Number, stateInfo:StateInfo ):Number
		{
			Assert.assertTrue( controlUnit >= 0 && controlUnit <= 1 );

			var constraint:Constraint = stateInfo.constraint;
			Assert.assertNotNull( constraint.range );
			
			var minimum:Number = constraint.minimum;
			var maximum:Number = constraint.maximum;
		
			var endpointValue:Number = 0;
			
			switch( stateInfo.scale.type )
			{
				case ControlScale.LINEAR:		
					endpointValue = linearUnitToEndpointValue( controlUnit, minimum, maximum );
					break;

				case ControlScale.EXPONENTIAL:	
					endpointValue = exponentialUnitToEndpointValue( controlUnit, minimum, maximum );
					break;

				case ControlScale.DECIBEL:
					endpointValue = decibelUnitToEndpointValue( controlUnit, minimum, maximum );
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}
			
			//clamp to min/max to fix rounding errors
			if( endpointValue < minimum ) endpointValue = minimum;
			if( endpointValue > maximum ) endpointValue = maximum;
			
			return endpointValue;
		}
		
		
		private static function endpointValueToLinearUnit( endpointValue:Number, minimum:Number, maximum:Number ):Number
		{
			var range:Number = maximum - minimum;
			
			if( range > 0 )
			{
				return ( endpointValue - minimum ) / range;
			}
			else
			{
				return 0;
			}
		}

		
		private static function linearUnitToEndpointValue( controlUnit:Number, minimum:Number, maximum:Number ):Number
		{
			var range:Number = maximum - minimum;
			
			return controlUnit * range + minimum;
		}

		
		
		private static function endpointValueToExponentialUnit( endpointValue:Number, minimum:Number, maximum:Number ):Number
		{
			const exponentRoot:Number = 2;	//it doesn't matter what exponent root we use
			const logBase:Number = Math.log( exponentRoot );
			const logBaseInverse:Number = 1 / logBase;

			Assert.assertTrue( minimum > 0 );
			Assert.assertTrue( maximum > minimum );
			
			var logMin:Number = Math.log( minimum ) * logBaseInverse;
			var logMax:Number = Math.log( maximum ) * logBaseInverse;
			
			Assert.assertTrue( logMax > logMin );
			
			return ( Math.log( endpointValue ) * logBaseInverse - logMin ) / ( logMax - logMin );
		}

	
		private static function exponentialUnitToEndpointValue( controlUnit:Number, minimum:Number, maximum:Number ):Number
		{
			const exponentRoot:Number = 2;	//it doesn't matter what exponent root we use

			const logBase:Number = Math.log( exponentRoot );
			const logBaseInverse:Number = 1 / logBase;
			
			Assert.assertTrue( minimum > 0 );
			Assert.assertTrue( maximum > minimum );
			
			var logMin:Number = Math.log( minimum ) * logBaseInverse;
			var logMax:Number = Math.log( maximum ) * logBaseInverse;

			Assert.assertTrue( logMax > logMin );
			
			return Math.pow( exponentRoot, controlUnit * ( logMax - logMin ) + logMin );
		}

		
		private static function endpointValueToDecibelUnit( endpointValue:Number, minimum:Number, maximum:Number ):Number
		{
			minimum = decibelToAmplitude( minimum );
			maximum = decibelToAmplitude( maximum );
			
			Assert.assertTrue( maximum > minimum );
			
			return ( decibelToAmplitude( endpointValue ) - minimum ) / ( maximum - minimum ); 
		}
		

		private static function decibelUnitToEndpointValue( controlUnit:Number, minimum:Number, maximum:Number ):Number
		{
			minimum = decibelToAmplitude( minimum );
			maximum = decibelToAmplitude( maximum );

			return amplitudeToDecibel( controlUnit * ( maximum - minimum ) + minimum );
		}

		
		private static function decibelToAmplitude( decibel:Number ):Number
		{
			return Math.pow( 10, decibel * 0.1 );
		}

	
		private static function amplitudeToDecibel( amplitude:Number ):Number
		{
			return 10 * Math.log( amplitude ) / Math.LN10;
		}
	}
}