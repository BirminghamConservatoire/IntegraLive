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
	import flexunit.framework.Assert;
	import mx.skins.halo.ButtonSkin;

	
	public class CloseButtonSkin extends ButtonSkin
	{
		public function CloseButtonSkin()
		{
			super();
		}


     	override public function get measuredWidth():Number	{ return 12; }
     	override public function get measuredHeight():Number { return 12; }		

		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			graphics.clear();

			var glowStrength:int = 1;
			var thickness:int = 1;
			var color:uint = getStyle( "color" );
			var fillColor:uint = getStyle( "fillColor" );
			var fillAlpha:Number = getStyle( "fillAlpha" );
			if( isNaN( fillAlpha ) ) 
			{
				fillAlpha = 0;
			}
			
			var alpha:Number = 1;

			switch( name )
			{
				case "skin":
					break;
				
				case "upSkin":
					break;
					
				case "overSkin":
					thickness++;
					break;
					
				case "downSkin":
					glowStrength++;
					thickness++;
					break;
					
				case "disabledSkin":
				case "selectedDisabledSkin":
				 	color = Utilities.makeGreyscale( color );
					alpha *= 0.5;
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			var radius:Number = Math.min( width, height ) / 2;
			
			graphics.lineStyle( thickness, color, alpha );
			graphics.beginFill( fillColor, fillAlpha );
			graphics.drawCircle( width / 2, height / 2, radius );
			graphics.endFill();
			
			//draw the cross
			graphics.moveTo( radius * 0.6, radius * 0.6 );
			graphics.lineTo( radius * 1.4, radius * 1.4 ); 

			graphics.moveTo( radius * 0.6, radius * 1.4 );
			graphics.lineTo( radius * 1.4, radius * 0.6 ); 

			//update the glow
			var filterArray:Array = new Array;
			filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			filters = filterArray;
		}
	}
}