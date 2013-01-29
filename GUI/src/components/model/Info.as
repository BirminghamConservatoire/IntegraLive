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
	
	public class Info
	{
		public function Info()
		{
		}

		
		public function get markdown():String {	return _markdown; }
		
		public function get title():String { return _title; }

		public function get html():String  
		{
			if( !_html ) 
			{
				regenerateHtml();
			}
			
			return _html;
		}		
		
		
		public function get ownerID():int { return _ownerID; }
		public function get canEdit():Boolean { return _canEdit; }
		
		
		public function set title( title:String ):void
		{
			_title = title;
			_html = null;
		}
		
		
		public function set markdown( markdown:String ):void
		{
			_markdown = markdown;
			_html = null;
		}
		
		
		public function set ownerID( ownerID:int ):void { _ownerID = ownerID; }
		public function set canEdit( canEdit:Boolean ):void { _canEdit = canEdit; }
		
		
		private function regenerateHtml():void
		{
			if( _title && _title.length > 0 )
			{
				_html = "<h1>" + htmlEscape( _title ) + "</h1>";
			}
			else
			{
				_html = "";
			}
			
			_html += Showdown.makeHtml( htmlEscape( _markdown ) );

			_html = addSpacingParagraphs( _html );
		}
		
		
		private function htmlEscape( string:String ):String
		{
			return XML( new XMLNode( XMLNodeType.TEXT_NODE, string ) ).toXMLString();
		}		
		
		
		private function addSpacingParagraphs( html:String ):String
		{
			//add an extra paragraph with class='space' to each paragraph and list, 
			//because as3 doesn't allow vertical paragraph margins.  This allows us to style our own
			var replaceAllCloseP:RegExp = /<\/p>/gi;
			var replaceAllCloseUL:RegExp = /<\/ul>/gi;
			var replaceAllCloseOL:RegExp = /<\/ol>/gi;
			
			html = html.replace( replaceAllCloseP, "</p><p class='space'></p>" );
			html = html.replace( replaceAllCloseUL, "</ul><p class='space'></p>" );
			html = html.replace( replaceAllCloseOL, "</ol><p class='space'></p>" );
			
			return html;
		}
		
		
		private var _title:String = "";
		private var _markdown:String = "";
		private var _html:String = null;
		
		private var _ownerID:int = -1;
		private var _canEdit:Boolean = false;
	}
}