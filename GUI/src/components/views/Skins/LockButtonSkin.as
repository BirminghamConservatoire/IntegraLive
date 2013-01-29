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
	
	import flexunit.framework.Assert;
	
	import mx.skins.halo.ButtonSkin;

	public class LockButtonSkin extends ButtonSkin
	{
		public function LockButtonSkin()
		{
			super();
		}
		
     	override public function get measuredWidth():Number	{ return 12; }
     	override public function get measuredHeight():Number { return 12; }		
		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			graphics.clear();
			
			var isLocked:Boolean = false;
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
					isLocked = true;
					break;
				
				case "selectedUpSkin":
					isLocked = true;
					break;
				
				case "selectedOverSkin":
					isLocked = true;
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
			
			//draw the padlock
			
			const lockWidth:Number = 0.55;
			const lockTopHeight:Number = 0.1;
			const baseStartHeight:Number = 0.5;
			const openRotation:Number = 45;
			
			graphics.beginFill( fillColor );
			graphics.drawRect( 0, size * baseStartHeight, size, size * ( 1 - baseStartHeight ) );
			graphics.endFill();
			
			var curvePoints:Vector.<Point> = new Vector.<Point>;
			
			curvePoints.push( new Point( size * ( 1 - lockWidth ) / 2, size * baseStartHeight ) );
			curvePoints.push( new Point( size * ( 1 - lockWidth ) / 2, size * lockTopHeight ) );
			curvePoints.push( new Point( size /2, size * lockTopHeight ) );
			curvePoints.push( new Point( size * ( 1 + lockWidth ) / 2, size * baseStartHeight ) );
			curvePoints.push( new Point( size * ( 1 + lockWidth ) / 2, size * lockTopHeight ) );
			curvePoints.push( new Point( size / 2, size * lockTopHeight ) );
			
			if( !isLocked )
			{
				var matrix:Matrix = new Matrix;
				matrix.identity();
				matrix.translate( -size * ( 1 + lockWidth ) / 2, -size * baseStartHeight );
				matrix.rotate( openRotation * Math.PI / 180 );
				matrix.translate( size * ( 1 + lockWidth ) / 2, size * baseStartHeight );
				
				for( var i:int = 0; i < curvePoints.length; i++ )
				{
					curvePoints[ i ] = matrix.transformPoint( curvePoints[ i ] );
				}
			}
			
			graphics.lineStyle( 3, fillColor );
			
			drawCurve( curvePoints.slice( 0, 3 ) );
			drawCurve( curvePoints.slice( 3, 6 ) );
			
			//update the glow
			var filterArray:Array = new Array;
			if( glow )
			{
				filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			}	
			filters = filterArray;
		}

		
		private function drawCurve( curve:Vector.<Point> ):void
		{
			Assert.assertTrue( curve.length == 3 );
			
			graphics.moveTo( curve[ 0 ].x, curve[ 0 ].y );
			graphics.curveTo( curve[ 1 ].x, curve[ 1 ].y, curve[ 2 ].x, curve[ 2 ].y );
		}
		
		
		public static const glowOverrideStyleName:String = "glowOverride"; 
	}
}