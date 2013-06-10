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
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.utils.CursorSetter;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.MouseCapture;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	import components.views.Skins.TextButtonSkin;
	
	public class TagCloud extends Canvas
	{
		public function TagCloud()
		{
			super();
			
			height = 60;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			_label.setStyle( "color", '#808080' );
			_label.alpha = 0.5;
			_label.x = _labelMargin;
			_label.y = _labelMargin;
			_label.text = "Tags...";
			addChild( _label );

			_clearButton.visible = false;
			_clearButton.setStyle( "skin", CloseButtonSkin );
			_clearButton.setStyle( "color", 0x808080 );
			_clearButton.addEventListener( MouseEvent.CLICK, onClear );
			addChild( _clearButton );
			
			_buttonCanvas.horizontalScrollPolicy = ScrollPolicy.OFF;
			addChild( _buttonCanvas );
			
			addEventListener( Event.RESIZE, onResize );
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		}
		
		
		public function getInfoToDisplay( mouseObject:Object ):Info
		{
			if( mouseObject == _clearButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleTagsClearButton" );
			}
			else
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleTags" );
			}
		}		
		
		
		public function set tags( tags:Vector.<String> ):void
		{
			var prunedSelectedTags:Object = new Object();
			
			for( var i:int = 0; i < tags.length; i++ )
			{
				var tag:String = tags[ i ];
				
				if( i >= _tagButtons.length )
				{
					var button:Button = new Button;
					button.toggle = true;
					button.height = buttonHeight;
					button.setStyle( "skin", TextButtonSkin );
					button.addEventListener( MouseEvent.CLICK, onClickTagButton );
					button.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClickTagButton );
					_tagButtons.push( button );
					
					_buttonCanvas.addChild( button );
				}
				
				_tagButtons[ i ].label = tag;
				if( _selectedTags.hasOwnProperty( tag ) )
				{
					_tagButtons[ i ].selected = true;
					prunedSelectedTags[ tag ] = 1;
				}
				
				_tagButtons[ i ].validateNow();
			}
			
			if( _tagButtons.length > tags.length )
			{
				for( tags.length;i < _tagButtons.length; i++ )
				{
					_buttonCanvas.removeChild( _tagButtons[ i ] );
				}
				
				_tagButtons.length = tags.length;
			}

			_selectedTags = prunedSelectedTags;
			
			positionTagButtons();
		}
		
		
		public function get selectedTags():Object 
		{ 
			return _selectedTags; 
		}

		
		public function deselectAll():void
		{
			_selectedTags = new Object;
			for each( var button:Button in _tagButtons )
			{
				button.selected = false;
			}
			
			_clearButton.visible = false;
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
				for each( var button:Button in _tagButtons )
				{
					button.height = buttonHeight;
				}

				positionClearButton();
				
				callLater( positionTagButtons );
			}
		}
		
		
		private function get buttonHeight():Number
		{
			return FontSize.getTextRowHeight( this );
		}
		
		
		private function onResize( event:Event ):void
		{
			positionClearButton();
			positionTagButtons();
		}
		
		
		private function positionClearButton():void
		{
			_clearButton.width = _clearButton.height = buttonHeight * 0.5;
			_clearButton.setStyle( "right", buttonHeight * 0.25 );
			_clearButton.setStyle( "top", buttonHeight * 0.25 );
		}

	
		private function positionTagButtons():void
		{
			const edgeMargin:Number = 2;
			const innerMargin:Number = 2;
			
			_buttonCanvas.x = 0;
			_buttonCanvas.y = buttonHeight;
			_buttonCanvas.width = width;
			_buttonCanvas.height = height - buttonHeight;

			var x:Number = edgeMargin;
			var y:Number = edgeMargin;
			
			_buttonCanvasHeight = 0;
				
			for( var i:int = 0; i < _tagButtons.length; i++ )
			{
				if( x + _tagButtons[ i ].measuredWidth > width - edgeMargin - _scrollBarWidth )
				{
					x = edgeMargin;
					y += ( buttonHeight + innerMargin );
				}
				
				_tagButtons[ i ].x = x;
				_tagButtons[ i ].y = y;
				
				x += ( _tagButtons[ i ].measuredWidth + innerMargin );
				
				_buttonCanvasHeight = y + buttonHeight;
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
			
			_clearButton.visible = !Utilities.isObjectEmpty( _selectedTags );

			dispatchEvent( new Event( TAG_SELECTION_CHANGED ) );
		}

		
		private function onClear( event:MouseEvent ):void
		{
			deselectAll();
			dispatchEvent( new Event( TAG_SELECTION_CHANGED ) );
		}
		
		
		private function onDoubleClickTagButton( event:MouseEvent ):void
		{
			//treat second half of double click like normal click
			event.target.selected = !event.target.selected;
			onClickTagButton( event );
		}
		
		
		private function get mouseIsInResizeArea():Boolean
		{
			if( mouseY >= buttonHeight )
			{
				return false;
			}
			
			if( _clearButton.visible && _clearButton.getRect( this ).contains( mouseX, mouseY ) )
			{
				return false;
			}
				
			return true;
		}

		
		private function onMouseMove( event:MouseEvent ):void
		{
			if( mouseIsInResizeArea )
			{
				CursorSetter.setCursor( CursorSetter.RESIZE_NS, this );
			}
			else
			{
				CursorSetter.setCursor( CursorSetter.ARROW, this );
			}
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			if( mouseIsInResizeArea )
			{
				_heightDragOffset = stage.mouseY + height;
				MouseCapture.instance.setCapture( this, onDragResize, null, CursorSetter.RESIZE_NS );
			}
		}
		
		
		private function onDragResize( event:MouseEvent ):void
		{
			var min:Number = buttonHeight;
			var max:Number = Math.min( maxHeight, buttonHeight + _buttonCanvasHeight );
			
			height = Math.max( min, Math.min( max, _heightDragOffset - stage.mouseY ) );
		}

		
		private var _label:Label = new Label;
		private var _clearButton:Button = new Button;

		private var _buttonCanvas:Canvas = new Canvas;
		private var _tagButtons:Vector.<Button> = new Vector.<Button>;
		private var _selectedTags:Object = new Object;
		
		private var _buttonCanvasHeight:Number = 0;
		
		private var _heightDragOffset:Number = 0;
		
		private static const _labelMargin:Number = 3;
		private static const _scrollBarWidth:Number = 16;
		
		public static const TAG_SELECTION_CHANGED:String = "tagSelectionChanged";
	}
}