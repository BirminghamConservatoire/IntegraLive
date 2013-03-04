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

package components.views.ModuleGraph
{
	import flash.display.BitmapData;
	import flash.display.IGraphicsData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.utils.ObjectUtil;
	
	import components.utils.FontSize;
	
	import flexunit.framework.Assert;
	
	public class ModuleGraphLink extends Canvas
	{

		public function ModuleGraphLink( connectionID:int = -1 ):void
		{
			_connectionID = connectionID;
		}


		public function get connectionID():int 	{ return _connectionID; }
		
		public function get start():Point { return _start; }
		public function get end():Point { return _end; }

		public function get trackOffset():Point { return _trackOffset; }

		public function setState( start:Point, end:Point, trackOffset:Point, lineWidth:Number, lineColor:int ):void
		{
			if( ObjectUtil.compare( _start, start ) == 0 && 
				ObjectUtil.compare( _end, end ) == 0 &&
				ObjectUtil.compare( _trackOffset, trackOffset ) == 0 &&
				_lineWidth == lineWidth && _lineColor == lineColor )
			{
				return;	//don't bother redrawing if nothing changed
			}			
			
			_start = start;
			_end = end;
			_trackOffset = trackOffset;
			_lineWidth = lineWidth;
			_lineColor = lineColor;
			
			redraw();
			
			_bitmapData = null;
			_bounds = null;
		}
		
		
		public function hitTestRectangle( rectangle:Rectangle, horizontalScroll:Number, verticalScroll:Number ):Boolean
		{
			if( !_bounds ) 
			{
				_bounds = getBounds( parent );
				_bounds.offset( horizontalScroll, verticalScroll );
			}
			
			if( !_bounds.intersects( rectangle ) ) 
			{
				return false;
			}
			
			if( !_bitmapData )
			{
				_bitmapData = new BitmapData( _bounds.width, _bounds.height, true, 0 );
				var translate:Matrix = new Matrix( 1, 0, 0, 1, -_bounds.x, -_bounds.y );
				_bitmapData.draw( this, translate );
			}
			
			return _bitmapData.hitTest( _bounds.topLeft, 1, rectangle );
		}
		
		
		private function redraw():void
		{
			graphics.clear();
			
			var gridSize:Number = FontSize.getTextRowHeight( this );
			var arrowheadLength:Number = _arrowheadLength * gridSize;
			var arrowheadWidth:Number = _arrowheadWidth * gridSize;

			var start:Point = _start.clone();
			start.x += _margin;
			
			var end:Point = _end.clone();
			end.x -= ( arrowheadLength + _margin );
			
			var startTangent:Point = new Point( 1, 0 );
			var endTangent:Point = new Point( -1, 0 );
			
			var trackStart:Point = _start.add( _trackOffset );
			var trackEnd:Point = _end.add( _trackOffset );
			var center:Point = Point.interpolate( trackStart, trackEnd, 0.5 );
			
			var track:Point = trackEnd.subtract( trackStart );
			var centerTangentAngle:Number = Math.atan2( track.y, track.x );
			centerTangentAngle *= _curvatureScale;
			centerTangentAngle = Math.max( -_maxTangentAngle, Math.min( _maxTangentAngle, centerTangentAngle ) );  
			
			var centerTangent:Point = Point.polar( 1, centerTangentAngle );
			var centerTangentBackwards:Point = new Point( -centerTangent.x, -centerTangent.y );
			
			var centerNormal:Point = perpendicular( centerTangent );
			var centerOffset:Point = new Point( dotProduct( _trackOffset, centerTangent ), dotProduct( _trackOffset, centerNormal ) ); 
				
			center = center.add( centerOffset ); 
			
			//curvy line
			graphics.lineStyle( _lineWidth, _lineColor ); 
			drawCurve( start, center, startTangent, centerTangentBackwards );
			drawCurve( center, end, centerTangent, endTangent );

			//draw arrowhead
			
			graphics.beginFill( _lineColor );
			graphics.moveTo( end.x + arrowheadLength, end.y );
			graphics.lineTo( end.x, end.y - arrowheadWidth );
			graphics.lineTo( end.x, end.y + arrowheadWidth );
			graphics.endFill();
		}

		
		private function dotProduct( point1:Point, point2:Point ):Number
		{
			return ( point1.x * point2.x + point1.y * point2.y );	
		}
		
		
		private function drawCurve( point1:Point, point2:Point, tangent1:Point, tangent2:Point ):void
		{
			Assert.assertTrue( Math.abs( tangent1.length - 1 ) < 0.0001 );	//approximately normalized
			Assert.assertTrue( Math.abs( tangent2.length - 1 ) < 0.0001 );	//approximately normalized

			var dot1:Number = dotProduct( point2.subtract( point1 ), tangent1 );	//distance to 2 from 1, along 1's tangent	
			var dot2:Number = dotProduct( point1.subtract( point2 ), tangent2 );	//distance to 1 from 2, along 2's tangent
			
			if( Math.max( dot1, dot2 ) < 0 )
			{
				//both ends point away from other end
				
				//this is an unexpected and unhandled case
				return;
			}

			if( dot2 < dot1 )
			{
				//draw it the other way round to eliminate code duplication
				drawCurve( point2, point1, tangent2, tangent1 );
				return;
			}

			var intersection:Point = getLineIntersection( point1, point1.add( tangent1 ), point2, point2.add( tangent2 ) );
			if( !intersection )
			{
				//special case - lines are parallel
				if( Math.abs( dotProduct( point2.subtract( point1 ), perpendicular( tangent1 ) ) ) < 1 )
				{
					//lines are co-incident - just connect with straight line
					graphics.moveTo( point1.x, point1.y );
					graphics.lineTo( point2.x, point2.y );
				}
				else
				{
					drawTwoCurves( point1, point2, tangent1, tangent2 );
				}
				return;
			}

			if( dotProduct( intersection.subtract( point1 ), tangent1 ) <= 0 || dotProduct( intersection.subtract( point2 ), tangent2 ) <= 0 ) 
			{
				//special case - tangents don't point towards intersection.  connect with 2 lines
				drawTwoCurves( point1, point2, tangent1, tangent2 );
				return;		
			}
			
			
			var distanceToIntersection:Number = intersection.subtract( point1 ).length;
			var arcEnd:Point = intersection.clone();
			arcEnd.x -= tangent2.x * distanceToIntersection;
			arcEnd.y -= tangent2.y * distanceToIntersection;
			
			var normal1:Point = perpendicular( tangent1 );
			var normal2:Point = perpendicular( tangent2 );

			var arcCenter:Point = getLineIntersection( point1, point1.add( normal1 ), arcEnd, arcEnd.add( normal2 ) );

			graphics.moveTo( arcEnd.x, arcEnd.y );
			graphics.lineTo( point2.x, point2.y );

			var arcStart:Point = point1.subtract( arcCenter );
			arcEnd = arcEnd.subtract( arcCenter );
			var angleStart:Number = Math.atan2( arcStart.y, arcStart.x ); 
			var angleEnd:Number = Math.atan2( arcEnd.y, arcEnd.x );
			var radius:Number = arcStart.length;
			drawArc( arcCenter, radius, angleStart, angleEnd );
		}

		
		private function drawTwoCurves( point1:Point, point2:Point, tangent1:Point, tangent2:Point ):void
		{
			const controlPointStrength:Number = 0.1;
			
			var center:Point = Point.interpolate( point1, point2, 0.5 );
			var length:Number = point2.subtract( point1 ).length;
			if( length < 1 ) return;
			
			length *= controlPointStrength;
			var controlPoint1:Point = point1.add( new Point( tangent1.x * length, tangent1.y * length ) );
			var controlPoint2:Point = point2.add( new Point( tangent2.x * length, tangent2.y * length ) );

			var centerTangent:Point = controlPoint1.subtract( controlPoint2 );
			centerTangent.normalize( 1 );
			var centerTangentOpposite:Point = new Point( -centerTangent.x, -centerTangent.y );
			
			drawCurve( point1, center, tangent1, centerTangent );
			drawCurve( center, point2, centerTangentOpposite, tangent2 );			
		}
		
		
		private function getLineIntersection( point1:Point, point2:Point, point3:Point, point4:Point ):Point
		{
			var denominator:Number = ( point1.x - point2.x ) * ( point3.y - point4.y ) - ( point1.y - point2.y ) * ( point3.x - point4.x );
			if( denominator == 0 ) return null;  //lines are parallel
			
			var intersectionX:Number = ( ( point1.x * point2.y - point1.y * point2.x ) * (point3.x - point4.x ) - ( point1.x - point2.x ) * ( point3.x * point4.y - point3.y * point4.x ) ) / denominator;
			var intersectionY:Number = ( ( point1.x * point2.y - point1.y * point2.x ) * (point3.y - point4.y ) - ( point1.y - point2.y ) * ( point3.x * point4.y - point3.y * point4.x ) ) / denominator;

			return new Point( intersectionX, intersectionY );			
		}
		
		
		private function perpendicular( vector:Point ):Point
		{
			return new Point( vector.y, -vector.x );
		}
		
		
		private function drawArc( center:Point, radius:Number, angle1:Number, angle2:Number ):void
		{
			const pixelsPerSegment:Number = 3;
			
			var radians:Number = ( angle2 - angle1 );
			while( radians > Math.PI ) radians -= Math.PI * 2;
			while( radians < -Math.PI ) radians += Math.PI * 2;

			var radianMagnitude:Number = Math.abs( radians );
			var arcLength:Number = radianMagnitude * radius;
			var steps:int = Math.ceil( arcLength / pixelsPerSegment );
			
			graphics.moveTo( center.x + Math.cos( angle1 ) * radius, center.y + Math.sin( angle1 ) * radius );
				
			for( var i:int = 1; i <= steps; i++ )
			{
				var angle:Number = angle1 + i * radians / steps;
				
				graphics.lineTo( center.x + Math.cos( angle ) * radius, center.y + Math.sin( angle ) * radius );
			}
		}
		

		private var _connectionID:int;

		private var _start:Point;
		private var _end:Point;
		private var _trackOffset:Point;
		private var _lineWidth:Number;
		private var _lineColor:int;
		
		private var _bitmapData:BitmapData = null;
		private var _bounds:Rectangle = null;

		private static const _curvatureScale:Number = 2;
		private static const _maxTangentAngle:Number = Math.PI * 0.99;
		
		private static const _margin:Number = 2;
		private static const _arrowheadLength:Number = 0.3;
		private static const _arrowheadWidth:Number = 0.15;
	}
}
