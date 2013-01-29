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
	import components.controlSDK.BaseClasses.ToggleControl;
	import components.controlSDK.core.*;
	
	
    public class CheckboxControl extends ToggleControl
    {
		public function CheckboxControl( controlManager:ControlManager )
		{
		    super( controlManager );
			
			_label.setStyle( "horizontalCenter", 0 );
			_label.setStyle( "verticalCenter", 0 );
			addChild( _label );
		}
		
		
		override protected function update():void
		{
		   	var buttonCenter:Point = geometry.controlCenter;  
		    var buttonRadius:Number = geometry.controlRadius;
			
			_label.setStyle( "color", foregroundColor( selected ? LOW : HIGH ) );
			_label.setStyle( "fontSize", buttonRadius * 0.8 );
			_label.text = selected ? "On" : "Off";
			
			button.graphics.clear();

			//button circle background
			button.graphics.beginFill( foregroundColor( selected ? HIGH : LOW ) );
			button.graphics.drawCircle( buttonCenter.x, buttonCenter.y, buttonRadius );
			button.graphics.endFill();

		    setGlow( button, selected ? 1.0 : 0.2 );	
		}
		
		
		private var _label:Label = new Label;
    }
}