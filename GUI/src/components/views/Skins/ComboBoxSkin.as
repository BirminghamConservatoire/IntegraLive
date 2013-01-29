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
	import flexunit.framework.Assert;
	import mx.skins.ProgrammaticSkin;

	
	public class ComboBoxSkin extends ProgrammaticSkin
	{
		public function ComboBoxSkin()
		{
			super();
		}
		
		
		/*override public function styleChanged( style:String ):void
		{
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					setStyle( "color", 0xcfcfcf );
					setStyle( "textRollOverColor", 0xcfcfcf );
					setStyle( "textSelectedColor", 0xcfcfcf );
					
					setStyle( "rollOverColor", 0x848484 );
					setStyle( "selectionColor", 0x848484 );
					setStyle( "alternatingItemColors", [ 0x747474, 0x747474 ] ); 
					break;
				
				case ColorScheme.DARK:
					setStyle( "color", 0x313131 );
					setStyle( "textRollOverColor", 0x313131 );
					setStyle( "textSelectedColor", 0x313131 );
					
					setStyle( "rollOverColor", 0x7c7c7c );
					setStyle( "selectionColor", 0x7c7c7c );
					setStyle( "alternatingItemColors", [ 0x8c8c8c, 0x8c8c8c ] ); 
					break;
			}
		}*/
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			var fillColor:uint = 0;
			var dropdownIconColor:uint = 0;
			
			var highlight:Boolean = false;
			var disabled:Boolean = false;
			
			switch( name )
			{
				case "overSkin":
					highlight = true;
					break;
					
				case "disabledSkin":
					disabled = true;
					break;
					
				case "upSkin":
				case "downSkin":
					break;
					
				default:
					break;
			}
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					fillColor = 0x747474;
					dropdownIconColor = 0xA7A7A7;
					break;
					
				case ColorScheme.DARK:
					fillColor = 0x8c8c8c;
					dropdownIconColor = 0x595959;
					break;
			}	

			//dimensions						
			var diameter:Number = height;
			var radius:Number = height / 2;
			var dropdownIconRadius:Number = radius * _dropdownIconSizeProportion;
			var dropdownTriangleWidth:Number = radius * _dropdownTriangleWidthProportion;
			var dropdownTriangleHeight:Number = radius * _dropdownTriangleHeightProportion;

			//main background
			graphics.beginFill( fillColor );
			graphics.drawRoundRect( 0, 0, width, height, diameter, diameter );
			graphics.endFill();
			
			//dropdown icon
			graphics.beginFill( dropdownIconColor, highlight ? 0.5 : 1 );
			graphics.drawCircle( width - radius, radius, dropdownIconRadius );
			graphics.endFill();
			
			//triangle in middle of dropdown icon
			graphics.beginFill( fillColor, disabled ? 0.5 : 1 );
			graphics.moveTo( width - radius - dropdownTriangleWidth / 2, radius );
			graphics.lineTo( width - radius + dropdownTriangleWidth / 2, radius );
			graphics.lineTo( width - radius, radius + dropdownTriangleHeight );
		}
		
		private static const _dropdownIconSizeProportion:Number = 0.6;
		private static const _dropdownTriangleWidthProportion:Number = 0.6;
		private static const _dropdownTriangleHeightProportion :Number = 0.3;
	}
}