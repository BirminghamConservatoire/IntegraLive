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
	import mx.skins.ProgrammaticSkin;

	public class NumberEditSkin extends ProgrammaticSkin
	{
		public function NumberEditSkin()
		{
			super();
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			var fillColor:uint = 0;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					fillColor = 0x747474;
					break;
					
				case ColorScheme.DARK:
					fillColor = 0x8c8c8c;
					break;
			}	

			//dimensions						
			var diameter:Number = height;
			var radius:Number = height / 2;

			//main background
			graphics.beginFill( fillColor );
			graphics.drawRoundRect( 0, 0, width, height, diameter, diameter );
			graphics.endFill();
		}
	}
}