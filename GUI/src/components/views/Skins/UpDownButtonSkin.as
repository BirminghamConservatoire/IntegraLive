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
	
	
	import flexunit.framework.Assert;

	
	public class UpDownButtonSkin extends ButtonSkin
	{
		public function UpDownButtonSkin()
		{
			super();
		}
				

		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			var selected:Boolean = false;
			var over:Boolean = false;
			var down:Boolean = false;
			var disabled:Boolean = false;

			switch( name )
			{
				case "skin":
					break;
				
				case "upSkin":
					break;
					
				case "overSkin":
					over = true;
					break;
					
				case "downSkin":
					down = true;
					break;
					
				case "selectedUpSkin":
					selected = true;
					break;

				case "selectedOverSkin":
					selected = true;
					over = true;
					break;
					
				case "selectedDownSkin":
					selected = true;
					down = true;
					break;
					
				case "disabledSkin":
					disabled = true;
					break;
				
				case "selectedDisabledSkin":
					selected = true;
					disabled = true;
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			var arrowAlpha:Number = disabled ? 0.5 : 1;  
			var circleAlpha:Number = ( ( over || down ) && !disabled ) ? arrowAlpha / 4 : 0;  
			var color:uint = disabled ? 0x808080 : getStyle( "color" );
			var glowStrength:Number = down ? 3 : 1;
			
			var radius:Number = Math.min( width, height ) / 2;

			graphics.beginFill( color, circleAlpha );
			graphics.drawCircle( radius, radius, radius );
			
			graphics.beginFill( color, arrowAlpha );
			switch( getStyle( DIRECTION_STYLENAME ) )
			{
				default:
				case DOWN:
					
					graphics.moveTo( radius * 0.5, radius * 0.8 );
					graphics.lineTo( radius * 1.5, radius * 0.8 );
					graphics.lineTo( radius, radius * 1.3 );
					graphics.lineTo( radius * 0.5, radius * 0.8 );
					break;

				case UP:
					graphics.moveTo( radius * 0.5, radius * 1.2 );
					graphics.lineTo( radius * 1.5, radius * 1.2 );
					graphics.lineTo( radius, radius * 0.7 );
					graphics.lineTo( radius * 0.5, radius * 1.2 );
					break;
			}

			graphics.endFill();
			
			//update the glow
			var filterArray:Array = new Array;
			filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			filters = filterArray;
		}
		
		public static const DIRECTION_STYLENAME:String = "direction";
		public static const UP:String = "up";
		public static const DOWN:String = "down";
		
	}
}