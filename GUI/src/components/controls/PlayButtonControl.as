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
    import flash.geom.Point;
	import components.controlSDK.core.*;
	import components.controlSDK.BaseClasses.ToggleControl;

    
    public class PlayButtonControl extends ToggleControl
    {
        public function PlayButtonControl( controlManager:ControlManager )
        {
            super( controlManager );
        }
	
	
        override protected function update():void
        {
            var buttonCenter:Point = geometry.controlCenter;  
            var buttonRadius:Number = geometry.controlRadius;  
            var sizeModifier:Number = selected ? 0.9 : 1;
            
            button.graphics.clear();
            
            button.graphics.lineStyle( buttonRadius * 0.2, mouseOver || selected ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
            button.graphics.beginFill( mouseOver ? foregroundColor( LOW ) : foregroundColor( NONE ) );
            button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius * sizeModifier );
            button.graphics.endFill();
            
            var playPauseOffset:Number = buttonRadius * 0.1;
            
            if( selected )
            {   // pause button double line
                button.graphics.lineStyle( buttonRadius * 0.15, foregroundColor( FULL ) );
		
                button.graphics.moveTo( buttonCenter.x - ( buttonRadius * 0.3 ) + playPauseOffset,
                                        buttonCenter.y - ( buttonRadius * 0.3 ) );
                button.graphics.lineTo( buttonCenter.x - ( buttonRadius * 0.3 ) + playPauseOffset,
                                        buttonCenter.y + ( buttonRadius * 0.3 ) );
                button.graphics.moveTo( buttonCenter.x + ( buttonRadius * 0.3 ) - playPauseOffset,
                                        buttonCenter.y - ( buttonRadius * 0.3 ) );
                button.graphics.lineTo( buttonCenter.x + ( buttonRadius * 0.3 ) - playPauseOffset, 
                                        buttonCenter.y + ( buttonRadius * 0.3 ) );
            }
            else
            {   // play button triangle
                button.graphics.lineStyle(); 
                button.graphics.beginFill( mouseOver ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );

                button.graphics.moveTo( buttonCenter.x - ( buttonRadius * 0.4 ) + ( playPauseOffset * 1.5 ),
                                        buttonCenter.y - ( buttonRadius * 0.4 ) );
                button.graphics.lineTo( buttonCenter.x + ( buttonRadius * 0.4 ) - ( playPauseOffset * 0.5 ),
                                        buttonCenter.y );
                button.graphics.lineTo( buttonCenter.x - ( buttonRadius * 0.4 ) + ( playPauseOffset * 1.5 ), 
                                        buttonCenter.y + ( buttonRadius * 0.4 ) );

                button.graphics.endFill();
            }

            setGlow( button, selected ? 0.6 : 0.2 );			
        }
    }
}
