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
	import flash.filters.GlowFilter;
	import flexunit.framework.Assert;
	import mx.skins.halo.ButtonSkin;

	
	public class TickButtonSkin extends ButtonSkin
	{
		public function TickButtonSkin()
		{
			super();
		}
		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			graphics.clear();

			var edgeThickness:int = 1;
			var isLit:Boolean = false;
			var glow:Boolean = false;
			var glowStrength:int = 2;

			//treat icons names as skin names in order to reuse skin for both icons and button skins
			var name:String = this.name.replace( /\Icon/g, "Skin" );
			
			switch( name )
			{
				case "skin":
				case "icon":
					break;
				
				case "upSkin":
					break;
					
				case "overSkin":
					edgeThickness = 2;
					break;
					
				case "downSkin":
					isLit = true;
					glow = true;
					break;
					
				case "selectedUpSkin":
					isLit = true;
					glow = true;
					break;

				case "selectedOverSkin":
					isLit = true;
					glow = true;
					glowStrength++;
					break;
					
				case "selectedDownSkin":
					edgeThickness = 2;
					break;
					
				case "disabledSkin":
				case "selectedDisabledSkin":
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			var color:uint = getStyle( "color" );
			var radius:Number = Math.min( width, height ) / 2;

			graphics.lineStyle( edgeThickness, isLit ? color : borderColor );

			graphics.beginFill( color, isLit ? 1 : 0 );
			graphics.drawCircle( radius, radius, radius );
			graphics.endFill();
			
			//draw the tick
			graphics.lineStyle( 2, borderColor );
			graphics.moveTo( radius * 0.5, radius );
			graphics.lineTo( radius, radius * 1.5 );
			graphics.lineTo( radius * 1.5, radius * 0.5 );

			//update the glow
			var filterArray:Array = new Array;
			if( glow )
			{
				filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			}	
			filters = filterArray;
		}

		private static const borderColor:uint = 0x505050;
	}
}