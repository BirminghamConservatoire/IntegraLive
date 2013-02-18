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


package 
{
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.ui.KeyboardType;
	
	import mx.controls.TextArea;
	import mx.controls.textClasses.TextRange;
	
	public class TabbableTextArea extends TextArea
	{
		public function TabbableTextArea()
		{
			super();
			
			addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );

			restrict = "A-Z a-z 0-9 !\"£$%\\^&*()\\-=_+[]{};'#:@~,./<>?\\\\|";
		}
		
		
		private function onKeyDown( event:KeyboardEvent ):void
		{
			if( event.charCode == Keyboard.TAB )
			{
				var caretIndex:int = textField.caretIndex;
				if( caretIndex >= 0 )
				{
					var caretPos:TextRange = new TextRange( this, false, caretIndex, caretIndex );
					caretPos.text = _tabString;
					caretIndex += _tabString.length;
					textField.setSelection( caretIndex, caretIndex );
				}
				
				callLater( reclaimFocus );
			}
		}
			
		private function reclaimFocus():void
		{
			focusManager.setFocus( this );
		}
		
		
		private const _tabString:String = "    ";
	}
}