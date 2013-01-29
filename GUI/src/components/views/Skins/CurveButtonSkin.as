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
 
 
 
package components.views.Skins
{
	import components.utils.Utilities;
	
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;
	
	import mx.skins.halo.ButtonSkin;

	public class CurveButtonSkin extends ButtonSkin
	{
		public function CurveButtonSkin()
		{
			super();
		}
		
     	override public function get measuredWidth():Number	{ return 12; }
     	override public function get measuredHeight():Number { return 12; }		
		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			graphics.clear();
			
			var isSelected:Boolean = false;
			var glow:Boolean = getStyle( glowOverrideStyleName );
			var glowStrength:int = 2;
			
			switch( name )
			{
				case "skin":
					break;
				
				case "upSkin":
					break;
				
				case "overSkin":
					glow = true;
					break;
				
				case "downSkin":
					isSelected = true;
					break;
				
				case "selectedUpSkin":
					isSelected = true;
					break;
				
				case "selectedOverSkin":
					isSelected = true;
					glow = true;
					break;
				
				case "selectedDownSkin":
					break;
				
				case "disabledSkin":
				case "selectedDisabledSkin":
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			var color:uint = getStyle( "color" );
			var fillColor:uint = getStyle( "fillColor" );
			var size:Number = Math.min( width, height );

			//draw background 
			graphics.beginFill( 0, 0 );
			graphics.drawRect( 0, 0, width, height );
			graphics.endFill();
			
			//draw the image

			var curveRect:Rectangle = new Rectangle( 0, 0, width, height );
			curveRect.inflate( -width / 6, -height / 6 );

			graphics.beginFill( fillColor );
			graphics.drawCircle( curveRect.left, curveRect.bottom, 2 );
			graphics.drawCircle( curveRect.right, curveRect.top, 2 );
			graphics.endFill();
			
			graphics.lineStyle( 1, fillColor );
			graphics.moveTo( curveRect.left, curveRect.bottom );
			graphics.curveTo( curveRect.right, curveRect.bottom, curveRect.right, curveRect.top );
			
			if( isSelected )
			{
				drawArrow( new Point( width * 0.1, height * 0.1 ), new Point( width * 0.4, height * 0.4 ) );
				drawArrow( new Point( width * 1.1, height * 1.1 ), new Point( width * 0.8, height * 0.8 ) );
			}
			
			//update the glow
			var filterArray:Array = new Array;
			if( glow )
			{
				filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			}	
			filters = filterArray;
		}

		
		private function drawArrow( from:Point, to:Point ):void
		{
			const arrowHeadProportion:Number = 0.5;
			
			graphics.moveTo( from.x, from.y );
			graphics.lineTo( to.x, to.y );

			var arrowHeadLength:Number = to.subtract( from ).length * arrowHeadProportion;
			
			var arrowHeadBack:Point = from.subtract( to );
			arrowHeadBack.normalize( arrowHeadLength );
			
			var arrowHeadSide:Point = new Point( arrowHeadBack.y, -arrowHeadBack.x );
			
			graphics.lineTo( to.x + arrowHeadBack.x + arrowHeadSide.x, to.y + arrowHeadBack.y + arrowHeadSide.y );
			graphics.moveTo( to.x, to.y );
			graphics.lineTo( to.x + arrowHeadBack.x - arrowHeadSide.x, to.y + arrowHeadBack.y - arrowHeadSide.y );
		}

		
		public static const glowOverrideStyleName:String = "glowOverride"; 
		
	}
}