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
	import components.model.userData.ColorScheme;
	import flash.filters.GlowFilter;
	import flexunit.framework.Assert;
	import mx.skins.halo.ButtonSkin;

	
	public class CollapseButtonSkin extends ButtonSkin
	{
		public function CollapseButtonSkin()
		{
			super();
		}
				

		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			var color:uint;
			var arrowColor:uint;
			var collapsed:Boolean = false;
			var disabled:Boolean = false;
			var glowStrength:int = 2;

			switch( name )
			{
				case "skin":
					break;
				
				case "upSkin":
					break;
					
				case "overSkin":
					glowStrength++;
					break;
					
				case "downSkin":
					glowStrength++;
					break;
					
				case "selectedUpSkin":
					collapsed = true;
					break;

				case "selectedOverSkin":
					collapsed = true;
					glowStrength++;
					break;
					
				case "selectedDownSkin":
					collapsed = true;
					glowStrength++;
					break;
					
				case "disabledSkin":
					disabled = true;
					break;
				
				case "selectedDisabledSkin":
					disabled = true;
					collapsed = true;
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			if( disabled ) 
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						color = 0xc0c0c0;
						arrowColor = 0x808080;
						break;
					
					case ColorScheme.DARK:
						color = 0x404040;
						arrowColor = 0x000000;
						break;
				}
			}
			else
			{
				color = getStyle( "color" );
				arrowColor = 0x505050;
			}

			var radius:Number = Math.min( width, height ) / 2;

			graphics.beginFill( color );
			graphics.drawCircle( radius, radius, radius );
			graphics.endFill();
			
			//draw the arrow
			graphics.beginFill( arrowColor );
			if( collapsed )
			{
				var collapseDirection:String = getStyle( COLLAPSE_DIRECTION_STYLENAME );
				if( !collapseDirection ) collapseDirection = RIGHT;

				switch( collapseDirection )
				{
					case RIGHT:
						graphics.moveTo( radius * 0.8, radius * 0.5 );
						graphics.lineTo( radius * 0.8, radius * 1.5 );
						graphics.lineTo( radius * 1.3, radius );
						graphics.lineTo( radius * 0.8, radius * 0.5 );
						break;
					case LEFT:
						graphics.moveTo( radius * 1.2, radius * 0.5 );
						graphics.lineTo( radius * 1.2, radius * 1.5 );
						graphics.lineTo( radius * 0.7, radius );
						graphics.lineTo( radius * 1.2, radius * 0.5 );
						break;
				}
			}
			else
			{
				graphics.moveTo( radius * 0.5, radius * 0.8 );
				graphics.lineTo( radius * 1.5, radius * 0.8 );
				graphics.lineTo( radius, radius * 1.3 );
				graphics.lineTo( radius * 0.5, radius * 1.0 );
			}

			graphics.endFill();
			
			//update the glow
			var filterArray:Array = new Array;
			filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			filters = filterArray;
		}
		
		public static const COLLAPSE_DIRECTION_STYLENAME:String = "collapseDirection";
		public static const RIGHT:String = "right";
		public static const LEFT:String = "left";
		
	}
}