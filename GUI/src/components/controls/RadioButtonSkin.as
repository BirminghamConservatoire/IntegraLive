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


package components.controls
{
    import mx.skins.halo.ButtonSkin;
    import flash.filters.GlowFilter;
	
    import flexunit.framework.Assert;

    public class RadioButtonSkin extends ButtonSkin
    {
        public function RadioButtonSkin()
        {
            super();
        }

        override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );
			
            graphics.clear();
			
            var colorFill:uint = 0xffffff;

            switch( name )
                {
                case "upSkin":
                    // equals to foregroundColor( LOW )
                    colorFill = 0x404040; 
                    break;

                case "downSkin":
                    // equals to foregroundColor( LOW )
                    colorFill = 0x404040; 
                    break;

                case "overSkin":
                    // equals to foregroundColor( MEDIUM )
                    colorFill = 0x7f7f7f; 
                    break;

                case "selectedUpSkin":
                    // equals to foregroundColor( HIGH )
                    colorFill = 0xbfbfbf;
                    break;
					
                case "selectedDownSkin":
                    // equals to foregroundColor( HIGH )
                    colorFill = 0xbfbfbf;                    
                    break;

                case "selectedOverSkin":
                    // equals to foregroundColor( HIGH )
                    colorFill = 0xbfbfbf;                    
                    break;

                default:
                    Assert.assertTrue( false );
                    break;
                }
			
            graphics.beginFill( colorFill );
            graphics.drawRoundRect( 0, 0, width, height, height * 0.8, height * 0.8 );
            graphics.endFill(); 
        }
    }
}