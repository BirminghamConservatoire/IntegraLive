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
	
	import mx.controls.Button;
	import mx.skins.halo.ButtonSkin;

	public class TextButtonSkin extends ButtonSkin
	{
		public function TextButtonSkin()
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
						_normalBackgroundColor = 0xD2D2D2;
						_selectedBackgroundColor = 0xB0B0B0;
						break;
						
					case ColorScheme.DARK:
						_normalBackgroundColor = 0x2E2E2E;
						_selectedBackgroundColor = 0x505050;
						break;
				}
				
				invalidateDisplayList();
			}			
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
				
			graphics.clear();
			
			var over:Boolean = false;
			var down:Boolean = false;
			
			switch( name )
			{
				case "skin":
				case "upSkin":
					break;
				
				case "overSkin":
					over = true;
					break;
				
				case "downSkin":
					down = true;
					break;
				
				case "selectedUpSkin":
					down = true;
					break;

				case "selectedOverSkin":
					over = true;
					down = true;
					break;

				case "selectedDownSkin":
					down = true;
					break;
				
				default:
					Assert.assertTrue( false );
					break;				
			}			
			
			graphics.beginFill( over || down ? _selectedBackgroundColor : _normalBackgroundColor );
			graphics.drawRoundRectComplex( 0, 0, width, height, radius, radius, radius, radius );
			graphics.endFill();
			
			//update the glow
			var filterArray:Array = new Array;
			
			if( down )
			{
				filterArray.push( new GlowFilter( _selectedBackgroundColor, 0.6, 10, 10, 2 ) );
			}
			
			filters = filterArray;			
		}
		
		private var _normalBackgroundColor:uint;
		private var _selectedBackgroundColor:uint;
		
		private static const radius:Number = 8;
	}
}