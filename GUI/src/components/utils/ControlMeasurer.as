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
	import components.controlSDK.core.ControlManager;
	import components.controlSDK.core.IntegraControl;
	
	import flash.geom.Point;
	
	import flexunit.framework.Assert;
	
		
	public class ControlMeasurer 
	{
		public static function doesControlExist( controlName:String ):Boolean
		{
			return ( ControlManager.getClassReference( controlName ) != null );
		}	
				

		public static function getDefaultSize( controlName:String ):Point
		{
			if( _mapControlNameToDefaultSize.hasOwnProperty( controlName ) && _mapControlNameToDefaultSize[ controlName ] is Point )
			{
				return _mapControlNameToDefaultSize[ controlName ] as Point;
			}
				
			var classReference:Class = ControlManager.getClassReference( controlName );
			if( !classReference ) return null;
			
			var control:ControlManager = new ControlManager( classReference, null, null ); 
			
			var defaultSize:Point = control.defaultSize;
			var minimumSize:Point = getMinimumSize( controlName );
			var maximumSize:Point = getMaximumSize( controlName );

			Assert.assertNotNull( defaultSize );
			Assert.assertNotNull( minimumSize );
			Assert.assertNotNull( maximumSize );

			//ensure default is not smaller than minimum or larger than maximum
			defaultSize.x = Math.max( defaultSize.x, minimumSize.x );
			defaultSize.y = Math.max( defaultSize.y, minimumSize.y );
			
			defaultSize.x = Math.min( defaultSize.x, maximumSize.x );
			defaultSize.y = Math.min( defaultSize.y, maximumSize.y );

			_mapControlNameToDefaultSize[ controlName ] = defaultSize;
			
			return defaultSize;		
		}	


		public static function getMaximumSize( controlName:String ):Point
		{
			if( _mapControlNameToMaximumSize.hasOwnProperty( controlName ) && _mapControlNameToMaximumSize[ controlName ] is Point )
			{
				return _mapControlNameToMaximumSize[ controlName ] as Point;
			}
			
			var classReference:Class = ControlManager.getClassReference( controlName );
			if( !classReference ) return null;
			
			var control:ControlManager = new ControlManager( classReference, null, null ); 
			
			var maximumSize:Point = control.maximumSize;
			Assert.assertNotNull( maximumSize );
			
			//ensure maximum is not larger than allowed range
			maximumSize.x = Math.min( maximumSize.x, largestAllowedMaximumSize.x );
			maximumSize.y = Math.min( maximumSize.y, largestAllowedMaximumSize.y );
			
			//ensure maximum is not smaller than minimum
			var minimumSize:Point = getMinimumSize( controlName );
			Assert.assertNotNull( minimumSize );

			maximumSize.x = Math.max( minimumSize.x, maximumSize.x );
			maximumSize.y = Math.max( minimumSize.y, maximumSize.y );
			
			_mapControlNameToMaximumSize[ controlName ] = maximumSize;
			
			return maximumSize;
		}	


		public static function getMinimumSize( controlName:String ):Point
		{
			if( _mapControlNameToMinimumSize.hasOwnProperty( controlName ) && _mapControlNameToMinimumSize[ controlName ] is Point )
			{
				return _mapControlNameToMinimumSize[ controlName ] as Point;
			}
			
			var classReference:Class = ControlManager.getClassReference( controlName );
			if( !classReference ) 
			{
				return smallestAllowedMinimumSize;	//failsafe
			}

			var control:ControlManager = new ControlManager( classReference, null, null ); 
			
			var minimumSize:Point = control.minimumSize;
			Assert.assertNotNull( minimumSize );
			
			//ensure minimum is within the smallest/largest allowed ranges
			minimumSize.x = Math.max( minimumSize.x, smallestAllowedMinimumSize.x );
			minimumSize.y = Math.max( minimumSize.y, smallestAllowedMinimumSize.y );
			
			minimumSize.x = Math.min( minimumSize.x, largestAllowedMaximumSize.x );
			minimumSize.y = Math.min( minimumSize.y, largestAllowedMaximumSize.y );
			
			_mapControlNameToMinimumSize[ controlName ] = minimumSize;
			
			return minimumSize;
		}
		
		
		private static var _mapControlNameToDefaultSize:Object = new Object;		
		private static var _mapControlNameToMaximumSize:Object = new Object;
		private static var _mapControlNameToMinimumSize:Object = new Object;
		
		private static const smallestAllowedMinimumSize:Point = new Point( 16, 16 ); 
		private static const largestAllowedMaximumSize:Point = new Point( 1000, 1000 );
		private static const failsafeDefaultSize:Point = new Point( 100, 100 );
	}
}