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


package components.views.ModuleManager
{
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.text.StyleSheet;
	
	import mx.containers.Canvas;
	import mx.controls.HTML;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;
	
	public class ModuleInfo extends Canvas
	{
		public function ModuleInfo()
		{
			super();

			verticalScrollPolicy = ScrollPolicy.AUTO;

			styleChanged( null );
		}
		
		
		public function set markdown( markdown:String ):void
		{
			_info.markdown = markdown;
			recreateInfo();
		}
		

		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_borderColor = 0xcfcfcf;
						_backgroundColor ='#ffffff';
						_textColor ='#6D6D6D';
						_linkColor = '#0000C0';
						break;
					
					case ColorScheme.DARK:
						_borderColor = 0x313131;
						_backgroundColor ='#000000';
						_textColor = '#939393';
						_linkColor = '#4080FF';
						break;
				}
				
				recreateInfo();
				
				invalidateDisplayList();
			}
			else
			{
				if( style == FontSize.STYLENAME )
				{
					recreateInfo();
				}	
			}
		}		
		
		
		override protected function updateDisplayList( width:Number, height:Number):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( 2, _borderColor, 1, true );
			
			graphics.drawRoundRect( 0, 0, width, height, ModuleManagerList.cornerRadius * 2, ModuleManagerList.cornerRadius * 2 );  
		}
		
		
		private function get htmlHeader():String
		{
			Assert.assertNotNull( _textColor );
			Assert.assertNotNull( _backgroundColor );
			Assert.assertNotNull( _linkColor );
			
			var fontSize:Number = getStyle( FontSize.STYLENAME );
			
			return "<head>" +
					"<style type='text/css'>" +
						
						"body {" +
							"background-color:" + _backgroundColor + ";" + 
							"color:" + _textColor + ";" +
							"font-size:" + fontSize + ";" +
						"} " +

						"h1 {" +
							"fontSize:" + String( fontSize + 4 ) + ";" + 
						"} " +

						"p {" +
							"fontSize:" + fontSize + ";" + 
						"} " +
						
					"</style>" +
				"</head>";
		}
		
		
		private function recreateInfo():void
		{
			if( _html )
			{
				removeChild( _html );
			}
			
			_html = new HTML;
			
			_html.setStyle( "left", ModuleManagerList.cornerRadius );
			_html.setStyle( "right", ModuleManagerList.cornerRadius );
			_html.setStyle( "top", ModuleManagerList.cornerRadius );
			_html.setStyle( "bottom", ModuleManagerList.cornerRadius );
			
			var htmlText:String = _info.html;
			htmlText = "<html>" + htmlHeader + htmlText.substr( 6 );
			
			_html.htmlText = htmlText;
			
			addChild( _html );

			_html.htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		}

		
		private var _info:Info = new Info;

		private var _html:HTML = null;
		
		private var _borderColor:uint;
		private var _backgroundColor:String;
		private var _textColor:String;
		private var _linkColor:String;
	
	}
}