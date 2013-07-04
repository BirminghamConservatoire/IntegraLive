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
	
	import mx.skins.halo.CheckBoxIcon;
	
	import components.utils.FontSize;
	
	
	public class CheckBoxTickIcon extends CheckBoxIcon
	{
		public function CheckBoxTickIcon()
		{
			super();
		}
		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			graphics.clear();

			var nameLower:String = name.toLowerCase();
			
			var over:Boolean = ( nameLower.indexOf( "over" ) >= 0 );
			var selected:Boolean = ( nameLower.indexOf( "selected" ) >= 0 );
			var down:Boolean = ( nameLower.indexOf( "down" ) >= 0 );
			var disabled:Boolean = ( nameLower.indexOf( "disabled" ) >= 0 );

			var color:uint = getStyle( "color" );
			var selectedColor:uint = getStyle( "textSelectedColor" );
			var backgroundColor:uint = getStyle( "backgroundColor" );
			var glowColor:uint = getStyle( GLOWCOLOR_STYLENAME );
			if( glowColor == 0 ) glowColor = color;
			
			var diameter:Number = getStyle( FontSize.STYLENAME );
			var radius:Number = diameter / 2;
			var xOffset:Number = width - diameter;

			graphics.lineStyle( 1, ( over || down ) ? selectedColor : color, disabled ? 0.5 : 1, true );

			graphics.beginFill( disabled ? color : backgroundColor, disabled ? 0.5 : 1 );
			graphics.drawCircle( xOffset + radius, radius, radius );
			graphics.endFill();
			
			//draw the tick
			if( selected )
			{
				graphics.lineStyle( 2, selectedColor );
				graphics.moveTo( xOffset + radius * 0.5, radius );
				graphics.lineTo( xOffset + radius, radius * 1.5 );
				graphics.lineTo( xOffset + radius * 1.5, radius * 0.5 );
			}

			//update the glow
			var filterArray:Array = new Array;
			if( down || selected )
			{
				var glowAlpha:Number = down ? 0.8 : 0.5;
				filterArray.push( new GlowFilter( glowColor, glowAlpha, 16, 16, 4 ) );
			}	
			filters = filterArray;
		}
		
		public static const GLOWCOLOR_STYLENAME:String = "glowColor";
	}
}