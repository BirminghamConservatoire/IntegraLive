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


package components.model
{
	import com.cstrahan.Showdown;
	
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	
	import flexunit.framework.Assert;
	
	public class Info
	{
		public function Info()
		{
		}

		
		public function get markdown():String {	return _markdown; }
		
		public function get title():String { return _title; }

		public function get html():String  
		{
			if( !_generatedContent ) 
			{
				generateContent();
			}
			
			return _html;
		}		
		
		
		public function get tooltip():String
		{
			if( !_generatedContent ) 
			{
				generateContent();
			}
			
			return _tooltip;
		}		
		
		
		
		
		public function get ownerID():int { return _ownerID; }
		public function get canEdit():Boolean { return _canEdit; }
		
		
		public function set title( title:String ):void
		{
			_title = title;
			clearContent();
		}
		
		
		public function set markdown( markdown:String ):void
		{
			_markdown = markdown;
			clearContent();
			_html = null;
		}
		
		
		public function set ownerID( ownerID:int ):void { _ownerID = ownerID; }
		public function set canEdit( canEdit:Boolean ):void { _canEdit = canEdit; }
		
		
		private function clearContent():void
		{
			_html = null;
			_tooltip = null;
			_generatedContent = false;
			
		}
		

		private function generateContent():void
		{
			generateHtml();
			generateTooltip();
			
			_generatedContent = true;			
		}
		
		
		private function generateHtml( isInvalid:Boolean = false ):void
		{
			_html = "<html>";

			if( isInvalid )
			{
				_html += _invalidHtmlWarning; 
			}
			
			if( _title && _title.length > 0 )
			{
				_html += "<h1>" + htmlEscape( _title ) + "</h1>";
			}

			var preprocessedMarkdown:String = isInvalid ? htmlEscape( _markdown ) : _markdown;
			
			_html += Showdown.makeHtml( preprocessedMarkdown );

			_html = addSpacingParagraphs( _html );

			_html += "</html>";
			
			if( isInvalid )
			{
				//we expect it to always be valid when we've escaped the input
				Assert.assertTrue( validateHtml( _html ) );
			}
			else
			{
				if( !validateHtml( _html ) )
				{
					generateHtml( true );
				}
			}
		}
		
		
		private function htmlEscape( string:String ):String
		{
			return XML( new XMLNode( XMLNodeType.TEXT_NODE, string ) ).toXMLString();
		}		
		
		
		private function addSpacingParagraphs( html:String ):String
		{
			//add an extra paragraph with class='space' to each paragraph, list, and heading 
			//because as3 doesn't allow vertical paragraph margins.  This allows us to style our own
			const replaceAllCloseP:RegExp = /<\/p>/gi;
			const replaceAllCloseUL:RegExp = /<\/ul>/gi;
			const replaceAllCloseOL:RegExp = /<\/ol>/gi;
			
			const spacerParagraph:String = "<p class='space'></p>";			
			
			html = html.replace( replaceAllCloseP, "</p>" + spacerParagraph );
			html = html.replace( replaceAllCloseUL, "</ul>" + spacerParagraph );
			html = html.replace( replaceAllCloseOL, "</ol>" + spacerParagraph );

			for( var headingLevel:int = 1; headingLevel <= 6; headingLevel++ )
			{
				var closeHeadingTag:String = "</h" + String( headingLevel ) + ">";
				
				var replaceAllCloseHeading:RegExp = new RegExp( closeHeadingTag, "gi" ); 
				html = html.replace( replaceAllCloseHeading, closeHeadingTag + spacerParagraph );
			}
			
			return html;
		}

		
		private function validateHtml( html:String ):Boolean
		{
			try 
			{
				var xml:XML = XML( html );
			}
			catch (e:Error) 
			{
				return false;
			}
			
			return true;
		}
		
		
		private function generateTooltip():void
		{
			const startToken:String = "<!--";
			const endToken:String = "-->";
			
			_tooltip = null;
			
			var tooltipStart:int = 0;
			var tooltipEnd:int = 0;
			
			while( true )
			{
				tooltipStart = _markdown.indexOf( startToken, tooltipEnd );
				if( tooltipStart < 0 )
				{
					return;
				}
				
				tooltipStart += startToken.length;
				
				tooltipEnd = _markdown.indexOf( endToken, tooltipStart );
				var tooltipLength:int = tooltipEnd - tooltipStart;
				if( tooltipLength < 0 )
				{
					return;
				}
				
				var tooltipLine:String = _markdown.substr( tooltipStart, tooltipLength );

				if( _tooltip )
				{
					_tooltip += ( "\n" + tooltipLine );
				}
				else
				{
					_tooltip = tooltipLine;
				}
				
				tooltipEnd += endToken.length;
			}
		}
		
		
		private var _title:String = "";
		private var _markdown:String = "";

		private var _generatedContent:Boolean = false;
		
		private var _html:String = null;
		private var _tooltip:String = null;
		
		private var _ownerID:int = -1;
		private var _canEdit:Boolean = false;
		
		private static const _invalidHtmlWarning:String = "<p align='right'><font color='#ff4040'>Invalid HTML!</font></p>"  
	}
}