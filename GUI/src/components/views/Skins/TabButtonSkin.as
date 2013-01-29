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
	import mx.skins.halo.ButtonSkin;

	
	public class TabButtonSkin extends ButtonSkin
	{
		public function TabButtonSkin()
		{
			super();
		}
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_normalBackgroundColor = 0xC2C2C2;
						_selectedBackgroundColor = 0xBEBEBE;
						break;
						
					case ColorScheme.DARK:
						_normalBackgroundColor = 0x3E3E3E;
						_selectedBackgroundColor = 0x424242;
						break;
				}
				
				invalidateDisplayList();
			}			
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
				
			graphics.clear();
			
			var selected:Boolean = false;
			
			switch( name )
			{
				case "selectedUpSkin":
				case "selectedOverSkin":
				case "selectedDownSkin":
				case "selectedDisabledSkin":
					selected = true;
					break;
			}			
			
			var rightHandRadius:Number = selected ? 0 : radius;
			var backgroundWidth:Number = selected ? width : width - 3;
			
			graphics.beginFill( selected ? _selectedBackgroundColor : _normalBackgroundColor );
			graphics.drawRoundRectComplex( 0, 0, backgroundWidth, height, radius, rightHandRadius, radius, rightHandRadius );
			graphics.endFill();
		}
		
		private var _normalBackgroundColor:uint;
		private var _selectedBackgroundColor:uint;
		
		private static const radius:Number = 8;
	}
}