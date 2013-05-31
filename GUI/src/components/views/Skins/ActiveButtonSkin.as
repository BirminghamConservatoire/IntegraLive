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
	
	import mx.skins.halo.ButtonSkin;
	
	import components.model.userData.ColorScheme;
	
	import flexunit.framework.Assert;

	
	public class ActiveButtonSkin extends ButtonSkin
	{
		public function ActiveButtonSkin()
		{
			super();
		}
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			var edgeAlpha:Number = 0;
			var isActive:Boolean = false;
			var glow:Boolean = false;

			switch( name )
			{
				case "skin":
					break;
				
				case "upSkin":
					break;
					
				case "overSkin":
					edgeAlpha = 0.5;
					break;
					
				case "downSkin":
					edgeAlpha = 0.5;
					glow = true;
					break;
					
				case "selectedUpSkin":
					isActive = true;
					glow = true;
					break;

				case "selectedOverSkin":
					isActive = true;
					glow = true;
					edgeAlpha = 0.5;
					break;
					
				case "selectedDownSkin":
					isActive = true;
					edgeAlpha = 0.5;
					break;
					
				case "disabledSkin":
				case "selectedDisabledSkin":
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			var color:uint = getStyle( "color" );
			if( !color )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						color = 0x606060;
						break;
					
					case ColorScheme.DARK:
						color = 0xffffff;
						break;
				}
			}
			
			var radius:Number = Math.min( width, height ) / 2;

			graphics.lineStyle( 0, color, edgeAlpha );
			graphics.beginFill( color, isActive ? 0.1 : 0 );
			graphics.drawCircle( radius, radius, radius );
			graphics.endFill();
			
			//speaker icon
			var iconAlpha:Number = isActive ? 1 : 0.7;
			var iconColor:uint = isActive ? color : 0x808080;
			graphics.lineStyle( 0, iconColor, iconAlpha );
			graphics.beginFill( iconColor, iconAlpha );
			graphics.moveTo( radius * 0.5, radius * 0.8 );
			graphics.lineTo( radius * 0.9, radius * 0.8 );
			graphics.lineTo( radius * 1.3, radius * 0.4 );
			graphics.lineTo( radius * 1.3, radius * 1.6 );
			graphics.lineTo( radius * 0.9, radius * 1.2 );
			graphics.lineTo( radius * 0.5, radius * 1.2 );
			graphics.lineTo( radius * 0.5, radius * 0.8 );
			graphics.endFill();

			if( !isActive )
			{
				//inactive cross
				graphics.lineStyle( 2, color );
				graphics.moveTo( radius * 0.6, radius * 0.4 );
				graphics.lineTo( radius * 1.4, radius * 1.6 );
				
				//graphics.moveTo( radius * 0.5, radius * 1.5 );
				//graphics.lineTo( radius * 1.5, radius * 0.5 );
			}
			
			//update the glow
			var filterArray:Array = new Array;
			if( glow )
			{
				filterArray.push( new GlowFilter( color, 0.6, 10, 10, 2 ) );
			}	
			filters = filterArray;
		}
	}
}