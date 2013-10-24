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
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import mx.containers.Canvas;
	import mx.controls.HTML;
	import mx.core.ScrollPolicy;
	
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	
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
						_backgroundColor = 0xffffff;
						_cssBackgroundColor ='#ffffff';
						_cssTextColor ='#6D6D6D';
						break;
					
					case ColorScheme.DARK:
						_backgroundColor = 0x000000;
						_cssBackgroundColor ='#000000';
						_cssTextColor = '#939393';
						break;
				}
				
				recreateInfo();
			}
			else
			{
				if( style == FontSize.STYLENAME )
				{
					recreateInfo();
				}	
			}
		}		
		
		
		private function get htmlHeader():String
		{
			Assert.assertNotNull( _cssTextColor );
			Assert.assertNotNull( _cssBackgroundColor );
			
			var fontSize:Number = getStyle( FontSize.STYLENAME );
			
			return "<head>" +
					"<style type='text/css'>" +
						
						"body {" +
							"background-color:" + _cssBackgroundColor + ";" + 
							"color:" + _cssTextColor + ";" +
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
			_html.paintsDefaultBackground = true;
			
			_html.setStyle( "left", ModuleManagerList.cornerRadius );
			_html.setStyle( "right", ModuleManagerList.cornerRadius );
			_html.setStyle( "top", ModuleManagerList.cornerRadius );
			_html.setStyle( "bottom", ModuleManagerList.cornerRadius );
			_html.setStyle( "borderStyle", "none" );
			_html.setStyle( "backgroundColor", _backgroundColor );
			
			var htmlText:String = _info.html;
			htmlText = "<html>" + htmlHeader + htmlText.substr( 6 );
			
			_html.addEventListener( Event.COMPLETE, onComplete );
			
			_html.htmlText = htmlText;
			
			addChild( _html );

			_html.htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		}
		
		
		private function onComplete( event:Event ):void
		{
			//always open links in a browser, not within the HTML control 
			
			var html:HTML = event.currentTarget as HTML;
			var document:Object = html.htmlLoader.window.document;
			var links:Object = document.getElementsByTagName( "a" );
			
			for( var i:int = 0; i < links.length; i++ ) 
			{
				var link:Object = links[ i ];
				
				link.onclick = function( linkEvent:Object ):void
				{
					linkEvent.preventDefault();
					navigateToURL( new URLRequest( linkEvent.srcElement ), "_blank" );
				}
			}			
		}

		
		private var _info:Info = new Info;

		private var _html:HTML = null;
		
		private var _backgroundColor:uint;
		private var _cssBackgroundColor:String;
		private var _cssTextColor:String;
	}
}