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
	import components.controlSDK.BaseClasses.BangControl;
	import components.controlSDK.core.*;
	
	
    public class StopButtonControl extends BangControl
    {
		public function StopButtonControl( controlManager:ControlManager )
		{
		    super( controlManager );
		}
		
	
		override protected function update():void
		{
		    var buttonCenter:Point = geometry.controlCenter;  
		    var buttonRadius:Number = geometry.controlRadius;  
	
		    button.graphics.clear();
	
            // transparent circle to keep focus during interaction scaling!
            button.graphics.beginFill( foregroundColor( NONE ) );
            button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius );
            button.graphics.endFill();
	
		    // makes button small while clicked
		    var sizeModifier:Number = triggered ? 0.8 : 1;
	
            button.graphics.lineStyle( buttonRadius * 0.2, mouseOver ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
		    button.graphics.beginFill( mouseOver ? foregroundColor( LOW ) : foregroundColor( NONE ) );
		    button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius * sizeModifier );
            button.graphics.endFill();
	
            button.graphics.lineStyle();
            if( !triggered )
            {
                button.graphics.beginFill( mouseOver ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
            }
            else
            {
                button.graphics.beginFill( foregroundColor( NONE ) );
            }

			button.graphics.drawRect( buttonCenter.x - ( buttonRadius * 0.4 ), 
	                                      buttonCenter.y - ( buttonRadius * 0.4 ),
	                                      buttonRadius * 0.8,
	                                      buttonRadius * 0.8 );
	
		    button.graphics.endFill();
				
		    setGlow( button, triggered ? 1 : 0.2 );			
		}
    }
}