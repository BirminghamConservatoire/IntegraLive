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
	import flash.display.GradientType;
	import flash.filters.BevelFilter;
	import flash.geom.Matrix;
	import mx.skins.halo.ScrollThumbSkin;

	
	public class IntegraScrollThumbSkin extends ScrollThumbSkin
	{
		public function IntegraScrollThumbSkin()
		{
			super();
			
			var filterArray:Array = new Array;
			filterArray.push( new BevelFilter( 1, 45, 0x808080, 1 ) );
			filters = filterArray;			
		}

		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			const alphas:Array = [ 1, 1 ];
			const ratios:Array = [0x00, 0xFF];

			var fillColor:uint;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					fillColor = 0xbebebe;
					break;
					
				case ColorScheme.DARK:
					fillColor = 0x424242;
					break;
			}			

			const edgeMargin:Number = 2;

			width -= ( edgeMargin * 2 );

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, 0 );

			graphics.beginFill( fillColor );
        	graphics.drawRoundRect( edgeMargin, 0, width, height, width, width );
        	graphics.endFill();			
		}
	}
}