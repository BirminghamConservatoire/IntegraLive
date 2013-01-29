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


package components.utils
{
	import components.utils.FontSize;
	
	import flexunit.framework.Assert;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	
	

	public class IntegraAlert
	{
		public function IntegraAlert()
		{
		}
		
		
		public static function show( text:String, title:String, flags:uint, parent:UIComponent, closeHandler:Function = null):void 
		{
			Assert.assertNotNull( parent );
			
 			var alert:Alert = Alert.show( text, title, flags, parent, closeHandler );
 			
 			alert.setStyle( "fontSize", 10 );
 			alert.setStyle( "color", 0xDBD3D0 ); 
 			alert.setStyle( "backgroundColor", 0x503426 );
 			alert.setStyle( "borderColor", 0xE65D0D );
			alert.setStyle( "backgroundAlpha", 1 );
			alert.setStyle( "borderAlpha", 1 );
		} 
	}
}
