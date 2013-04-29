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
	import components.utils.Trace;
	
	
	public class Envelope extends IntegraDataObject
	{
		public function Envelope()
		{
			super();
		}

		public function get startTicks():int { return _startTicks; }
		public function get currentTick():int { return _currentTick; }
		public function get currentValue():Number { return _currentValue; }
		public function get interpolationType():String { return _interpolationType; }
		public function get controlPoints():Object { return _controlPoints; }

		public function set startTicks( startTicks:int ):void { _startTicks = startTicks; }
		public function set currentTick( currentTick:int ):void { _currentTick = currentTick; }
		public function set currentValue( currentValue:Number ):void { _currentValue = currentValue; }
		public function set interpolationType( interpolationType:String ):void { _interpolationType = interpolationType; }
		public function set controlPoints( controlPoints:Object ):void { _controlPoints = controlPoints; }

		public function get orderedControlPoints():Vector.<ControlPoint>
		{
			var orderedControlPoints:Vector.<ControlPoint> = new Vector.<ControlPoint>;
			for each( var controlPoint:ControlPoint in _controlPoints )
			{
				orderedControlPoints.push( controlPoint );
			}
			
			function compareControlPointOrder( controlPoint1:ControlPoint, controlPoint2:ControlPoint ):int
			{
				if( controlPoint1.tick < controlPoint2.tick ) return -1;
				if( controlPoint1.tick > controlPoint2.tick ) return 1;

				Trace.error( "Control points have identical ticks!  names:", controlPoint1.name, controlPoint2.name, "ticks:", controlPoint1.tick, controlPoint2.tick, "values:", controlPoint1.value, controlPoint2.value );
				return 0;
			}
			
			orderedControlPoints.sort( compareControlPointOrder );

			return orderedControlPoints;			
		}

		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{        
				case "startTick":
					_startTicks = int( value );
					return true;

				case "currentTick":
					_currentTick = int( value );
					return true;
					
				case "interpolationType":
					_interpolationType = String( value );
					return true;

				case "currentValue":
					_currentValue = Number( value );
					return true;
					
				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		
		public function getNewControlPointName():String
		{
			var existingNameMap:Object = new Object;
			
			for each( var controlPoint:ControlPoint in _controlPoints )
			{
				existingNameMap[ controlPoint.name ] = 1;
			}
			 			
			for( var number:int = 1; ; number++ )
			{
				var candidateName:String = "ControlPoint" + String( number );
				if( existingNameMap.hasOwnProperty( candidateName ) )
				{
					continue;
				}
				
				return candidateName;
			}
			
			Assert.assertTrue( false );
			return null;  
		}
		

		override public function getAllModuleGuidsInTree( results:Object ):void
		{
			super.getAllModuleGuidsInTree( results );
			
			for each( var descendant:ControlPoint in _controlPoints )
			{
				descendant.getAllModuleGuidsInTree( results );
			}
		}		
		

		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Envelope";
	
		private var _startTicks:int = -1;
		private var _currentTick:int = -1;
		private var _currentValue:Number = 0;
		private var _interpolationType:String = null;
		private var _controlPoints:Object = new Object;
	}
}
