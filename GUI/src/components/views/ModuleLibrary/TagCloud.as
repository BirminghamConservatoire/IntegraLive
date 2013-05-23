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



package components.views.ModuleLibrary
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.Skins.TextButtonSkin;
	
	public class TagCloud extends Canvas
	{
		public function TagCloud()
		{
			super();
			
			height = 60;
			
			
			addEventListener( Event.RESIZE, onResize );
		}
		
		
		public function set tags( tags:Vector.<String> ):void
		{
			var prunedSelectedTags:Object = new Object();
			
			for( var i:int = 0; i < tags.length; i++ )
			{
				var tag:String = tags[ i ];
				
				if( i >= _buttons.length )
				{
					var button:Button = new Button;
					button.toggle = true;
					button.height = buttonHeight;
					button.setStyle( "skin", TextButtonSkin );
					button.addEventListener( MouseEvent.CLICK, onClickTagButton );
					button.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClickTagButton );
					_buttons.push( button );
					
					addChild( button );
				}
				
				_buttons[ i ].label = tag;
				if( _selectedTags.hasOwnProperty( tag ) )
				{
					_buttons[ i ].selected = true;
					prunedSelectedTags[ tag ] = 1;
				}
			}
			
			if( _buttons.length > tags.length )
			{
				for( tags.length;i < _buttons.length; i++ )
				{
					removeChild( _buttons[ i ] );
				}
				
				_buttons.length = tags.length;
			}

			_selectedTags = prunedSelectedTags;
			
			positionButtons();
		}
		

		public function get selectedTags():Object 
		{ 
			return _selectedTags; 
		}
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						setStyle( "color", 0x6D6D6D );
						setStyle( "textRollOverColor", 0x6D6D6D );
						setStyle( "textSelectedColor", 0x6D6D6D );
						break;
					
					case ColorScheme.DARK:
						setStyle( "color", 0x939393 );
						setStyle( "textRollOverColor", 0x939393 );
						setStyle( "textSelectedColor", 0x939393 );
						break;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				for each( var button:Button in _buttons )
				{
					button.height = buttonHeight;
				}
				
				callLater( positionButtons );
			}
		}
		
		
		private function get buttonHeight():Number
		{
			return FontSize.getTextRowHeight( this );
		}
		
		
		private function onResize( event:Event ):void
		{
			positionButtons();
		}

	
		private function positionButtons():void
		{
			const leftMargin:Number = 2;
			const topMargin:Number = 2;
			const rightMargin:Number = 18;	//include room for vertical scroll bar
			const innerMargin:Number = 2;
			var x:Number = leftMargin;
			var y:Number = topMargin;
			
			for( var i:int = 0; i < _buttons.length; i++ )
			{
				if( x + _buttons[ i ].measuredWidth > width - rightMargin )
				{
					x = leftMargin;
					y += ( buttonHeight + innerMargin );
				}
				
				_buttons[ i ].x = x;
				_buttons[ i ].y = y;
				
				x += ( _buttons[ i ].measuredWidth + innerMargin );
			}
		}
		
		
		private function onClickTagButton( event:MouseEvent ):void
		{
			var tag:String = ( event.currentTarget as Button ).label;
			
			if( _selectedTags.hasOwnProperty( tag ) )
			{
				delete _selectedTags[ tag ];
			}
			else
			{
				_selectedTags[ tag ] = 1;
			}
			
			dispatchEvent( new Event( TAG_SELECTION_CHANGED ) );
		}
		
		
		private function onDoubleClickTagButton( event:MouseEvent ):void
		{
			//treat second half of double click like normal click
			event.target.selected = !event.target.selected;
			onClickTagButton( event );
		}

		
		private var _buttons:Vector.<Button> = new Vector.<Button>;
		private var _selectedTags:Object = new Object;
		
		
		public static const TAG_SELECTION_CHANGED:String = "tagSelectionChanged";
	}
}