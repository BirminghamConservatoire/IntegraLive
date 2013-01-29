/* Integra Live graphical user interface
*
* Copyright (C) 2010 Birmingham City University
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


package components.controlSDK.HelperClasses
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class RoundControl 
    {
        public function RoundControl( width:Number, height:Number )
        {
            _width = width;
            _height = height;
        }


        public function isActiveArea( point:Point ):Boolean
        {
            var buttonCenter:Point = this.controlCenter;  
	    var buttonRadius:Number = this.controlRadius;  
			
	    var xDiff:Number = point.x - buttonCenter.x;
	    var yDiff:Number = point.y - buttonCenter.y;
			
	    // makes it 20% bigger then actual button to handle the stroke weight
	    return xDiff * xDiff + yDiff * yDiff <= buttonRadius * buttonRadius * 1.2;
        }


        public function get drawArea():Rectangle
        {
            return new Rectangle( 0, 0, _width, _height );
        }

        
        public function get controlCenter():Point
        {
            var drawArea:Rectangle = this.drawArea;
	    return new Point( drawArea.x + ( drawArea.width / 2 ), 
                              drawArea.y + ( drawArea.height / 2 ) );
        }

        
        public function get controlRadius():Number
        {
	    var drawArea:Rectangle = this.drawArea;
	    return Math.min( drawArea.width, drawArea.height ) * 0.4;
        }


        public function get controlStrokeWeight():Number
        {
            return this.controlRadius / 4.0;
        }


        public function set width( width:Number ):void
        {
            _width = width;
        }


        public function set height( height:Number ):void
        {
            _height = height;
        }


        private var _width:Number = 0.0;
        private var _height:Number = 0.0;
    }
}