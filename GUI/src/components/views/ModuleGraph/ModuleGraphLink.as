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
	import components.utils.FontSize;
	
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	
	//import spark.components.Group;

	public class ModuleGraphLink extends Canvas
	{

		public function ModuleGraphLink( connectionID:int = -1 ):void
		{
			_connectionID = connectionID;
		}


		public function get connectionID():int 	{ return _connectionID; }
		public function get start():Point { return _start; }
		public function get end():Point { return _end; }
		
	
		public function setState( start:Point, end:Point, lineWidth:Number, lineColor:int ):void
		{
			if( _start == start && _end == end && _lineWidth == lineWidth && _lineColor == lineColor )
			{
				return;	//don't bother redrawing if nothing changed
			}			
			
			_start = start;
			_end = end;
			_lineWidth = lineWidth;
			_lineColor = lineColor;
			
			redraw();
		}
		
		
		private function redraw():void
		{
			graphics.clear();
			
			var tangentStrength:Number = _tangentScale * Point.distance( _start, _end );
			var startTangent:Point = new Point( 1, 0 );
			var endTangent:Point = new Point( -1, 0 );
			
			var controlPoint1:Point = new Point( _start.x + startTangent.x * tangentStrength, _start.y + startTangent.y * tangentStrength );
			var controlPoint2:Point = new Point( _end.x + endTangent.x * tangentStrength, _end.y + endTangent.y * tangentStrength );

			var center:Point = new Point( ( controlPoint1.x + controlPoint2.x ) / 2, ( controlPoint1.y + controlPoint2.y ) / 2 );

			graphics.lineStyle( _lineWidth, _lineColor ); 
			graphics.moveTo( _start.x, _start.y );
			graphics.curveTo( controlPoint1.x, controlPoint1.y, center.x, center.y );
			graphics.curveTo( controlPoint2.x, controlPoint2.y, _end.x, _end.y );

			var gridSize:Number = FontSize.getTextRowHeight( this );
			var arrowheadLength:Number = _arrowheadLength * gridSize;
			var arrowheadWidth:Number = _arrowheadWidth * gridSize;
			
			graphics.beginFill( _lineColor );
			graphics.moveTo( _end.x, _end.y );
			graphics.lineTo( _end.x - arrowheadLength, _end.y - arrowheadWidth );
			graphics.lineTo( _end.x - arrowheadLength, _end.y + arrowheadWidth );
			graphics.endFill();
		}


		private var _connectionID:int;

		private var _start:Point;
		private var _end:Point;
		private var _lineWidth:Number;
		private var _lineColor:int;

		private static const _tangentScale:Number = 0.3;
		private static const _arrowheadLength:Number = 0.3;
		private static const _arrowheadWidth:Number = 0.15;
	}
}
