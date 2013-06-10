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
	import flash.text.StyleSheet;
	
	import mx.containers.Canvas;
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
			recreateTextArea();
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
						_textColor ='#6D6D6D';
						_linkColor = '#0000C0';
						break;
					
					case ColorScheme.DARK:
						_borderColor = 0x313131;
						_textColor = '#939393';
						_linkColor = '#4080FF';
						break;
				}
				
				recreateTextArea();
				
				invalidateDisplayList();
			}
			else
			{
				if( style == FontSize.STYLENAME )
				{
					recreateTextArea();
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
		
		
		private function updateTextCSS():void
		{
			Assert.assertNotNull( _textColor );
			Assert.assertNotNull( _linkColor );
			
			var fontSize:Number = getStyle( FontSize.STYLENAME );
			
			var myStyles:StyleSheet = new StyleSheet();
			
			myStyles.setStyle( "body", { fontSize:fontSize, color:_textColor } );
			myStyles.setStyle( "li", { fontSize:fontSize, color:_textColor } );
			
			myStyles.setStyle( "h1", { fontSize:fontSize + 4, fontWeight:'bold', color:_textColor } );
			myStyles.setStyle( "h2", { fontSize:fontSize + 3, fontWeight:'bold', color:_textColor, fontStyle:'italic' } );
			myStyles.setStyle( "h3", { fontSize:fontSize + 2, fontWeight:'bold', color:_textColor } );
			myStyles.setStyle( "h4", { fontSize:fontSize + 1, fontWeight:'bold', color:_textColor, fontStyle:'italic' } );
			myStyles.setStyle( "h5", { fontSize:fontSize, fontWeight:'bold', color:_textColor } );
			myStyles.setStyle( "h6", { fontSize:fontSize -1, fontWeight:'bold', color:_textColor, fontStyle:'italic' } );
			
			myStyles.setStyle( "a:link", {textDecoration:'none', color:_linkColor } );
			myStyles.setStyle( "a:hover", {textDecoration:'underline', color:_linkColor } );
			
			myStyles.setStyle( "strong", { fontWeight:'bold', display:'inline' } );
			myStyles.setStyle( "em", { fontStyle:'italic', display:'inline' } );	
			
			myStyles.setStyle( "pre", { display:'block' } );
			myStyles.setStyle( "code", { fontFamily:'courier', color:_textColor } );
			
			myStyles.setStyle( ".space", { leading:String( -fontSize / 2 ) } );
			
			if( !Utilities.isWindows )
			{
				myStyles.setStyle( ".windows-only", { display:'none' } );
			}
			
			if( !Utilities.isMac )
			{
				myStyles.setStyle( ".mac-only", { display:'none' } );
			}
			
			
			_textArea.styleSheet = myStyles;
		}
		
		
		private function recreateTextArea():void
		{
			if( _textArea )
			{
				removeChild( _textArea );
			}
			
			_textArea = new TextArea;
			_textArea.setStyle( "borderStyle", "none" );
			_textArea.setStyle( "backgroundAlpha", 0 );
			_textArea.setStyle( "left", ModuleManagerList.cornerRadius );
			_textArea.setStyle( "right", ModuleManagerList.cornerRadius );
			_textArea.setStyle( "top", ModuleManagerList.cornerRadius );
			_textArea.setStyle( "bottom", ModuleManagerList.cornerRadius );
			_textArea.editable = false;
			_textArea.condenseWhite = true;
			
			updateTextCSS();

			_textArea.htmlText = _info.html;
			
			addChild( _textArea );
		}

		private var _info:Info = new Info;

		private var _textArea:TextArea = null;
		
		private var _borderColor:uint;
		private var _textColor:String;
		private var _linkColor:String;
	
	}
}