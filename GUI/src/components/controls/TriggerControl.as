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

    import mx.controls.Label;
	import components.controlSDK.BaseClasses.BangControl;
	import components.controlSDK.core.ControlManager;
	

    public class TriggerControl extends BangControl
    {
		public function TriggerControl( controlManager:ControlManager )
		{
		    super( controlManager );
	
            button.addChild( _buttonLabel );
		}
		
	
		override protected function update():void
		{
		    var buttonCenter:Point = geometry.controlCenter;  
		    var buttonRadius:Number = geometry.controlRadius;  
	
		    var labelFontSize:Number = buttonRadius * 0.5;
				
		    _buttonLabel.setStyle( "fontSize", labelFontSize );
		    _buttonLabel.setStyle( "horizontalCenter", 0 );
		    _buttonLabel.setStyle( "verticalCenter", 2 );
            _buttonLabel.setStyle( "fontWeight", "bold" );
            if( triggered )
            {
                _buttonLabel.setStyle( "color", foregroundColor( NONE ) );
            }
            else
            {
                _buttonLabel.setStyle( "color", mouseOver ? foregroundColor( FULL ) : foregroundColor( HIGH ) );
            }
		    _buttonLabel.validateNow();
				
		    _buttonLabel.text = "BANG";
				
		    // hide the label if too tiny
		    _buttonLabel.visible = ( labelFontSize > 6 );
	
		    button.graphics.clear();
	
		    button.graphics.lineStyle( buttonRadius * 0.2, mouseOver ? foregroundColor( FULL ) : foregroundColor( MEDIUM ) );
	
		    // makes button small while clicked
		    var sizeModifier:Number = triggered ? 0.8 : 1;
	
            if( triggered )
            {
                button.graphics.beginFill( foregroundColor( MEDIUM ) );
            }
            else
            {
                button.graphics.beginFill( mouseOver ? foregroundColor( LOW ) : foregroundColor( NONE ) );
            }
		    button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius * sizeModifier );
		    button.graphics.endFill();
				
		    setGlow( button, triggered ? 1 : 0.2 );			
		}
	
        private var _buttonLabel:Label = new Label;
    }
}