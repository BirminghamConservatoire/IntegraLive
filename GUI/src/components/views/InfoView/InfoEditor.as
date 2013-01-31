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


package components.views.InfoView
{
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.serverCommands.SetObjectInfo;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.Skins.CloseButtonSkin;
	
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	
	
	public class InfoEditor extends Canvas
	{
		public function InfoEditor( title:String, objectID:int )
		{
			super();
			
			_objectID = objectID;
			Assert.assertTrue( _objectID >= 0 );
			
			horizontalScrollPolicy = ScrollPolicy.OFF; 
			verticalScrollPolicy = ScrollPolicy.OFF;   
			
			_titleLabel.text = title;
			_titleLabel.setStyle( "verticalAlign", "center" );
			addChild( _titleLabel );
			
			_titleCloseButton.setStyle( "skin", CloseButtonSkin );
			_titleCloseButton.setStyle( "fillAlpha", 1 );
			_titleCloseButton.setStyle( "color", _borderColor );
			_titleCloseButton.addEventListener( MouseEvent.CLICK, onClickTitleCloseButton );
			addChild( _titleCloseButton );
			
			_editText.setStyle( "left", _textMargin );
			_editText.setStyle( "right", _textMargin );
			_editText.setStyle( "bottom", _textMargin );
			_editText.setStyle( "borderStyle", "none" );
			_editText.setStyle( "focusSkin", null );
			_editText.restrict = "^";	//prevent funny chars appearing on ctrl+backspace
			addChild( _editText );
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( FocusEvent.FOCUS_OUT, onFocusOut );
			_editText.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
		}
		
		
		public function set markdown( markdown:String ):void
		{
			if( markdown != _editText.text )
			{
				_editText.text = markdown;
				_anythingToCommit = false;
			}
		}
		
		
		public function onStyleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_backgroundColor = 0xffffff;
						_titleCloseButton.setStyle( "fillColor", 0x000000 );
						_titleLabel.setStyle( "color", 0x000000 );
						_editText.setStyle( "backgroundColor", 0xffffff );
						_editText.setStyle( "color", 0x6D6D6D );
						
						break;
					
					case ColorScheme.DARK:
						_backgroundColor = 0x000000;
						_titleCloseButton.setStyle( "fillColor", 0xffffff );
						_titleLabel.setStyle( "color", 0xffffff );
						_editText.setStyle( "backgroundColor", 0x000000 );
						_editText.setStyle( "color", 0x939393 );
						break;
				}
				
				invalidateDisplayList();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				Assert.assertNotNull( parentDocument );
				setStyle( FontSize.STYLENAME, parentDocument.getStyle( FontSize.STYLENAME ) );
				updateSize();
				invalidateDisplayList();
			}
		}
		
		
		private function onAddedToStage( event:Event ):void
		{
			onStyleChanged( null );
			
			setFocus();
		}
		
		
		private function onKeyDown( event:KeyboardEvent ):void
		{
			switch( event.charCode )
			{
				case Keyboard.ESCAPE:
					closeEditor();
					return;
					
				case Keyboard.ENTER:
					if( event.ctrlKey )
					{
						closeEditor();
						return;
					}
					break;
			}

			if( _commitKeys.indexOf( event.charCode ) >= 0 )
			{
				if( _anythingToCommit )
				{
					commitEditText();
				}
			}
			else
			{
				_anythingToCommit = true;
			}
		}
		
		
		private function updateSize():void
		{
			Assert.assertNotNull( parentDocument );
			
			//calculate window size
			var rowHeight:Number = FontSize.getTextRowHeight( this );
			width = Math.min( rowHeight * 20, parentDocument.width );
			height = Math.min( rowHeight * 18, parentDocument.height );
			
			//position title controls
			_titleCloseButton.width = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.height = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.x = ( titleHeight - _titleCloseButton.width ) / 2;
			_titleCloseButton.y = ( titleHeight - _titleCloseButton.width ) / 2;
			
			_titleLabel.x = titleHeight;
			_titleLabel.y = titleHeight / 6;
			_titleLabel.height = rowHeight;
			
			_editText.setStyle( "top", _textMargin + titleHeight );
		}
		
		
		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( _borderThickness, _borderColor ); 
			graphics.beginFill( _backgroundColor );
			graphics.drawRoundRect( 0, 0, width, height, _cornerRadius, _cornerRadius );
			graphics.endFill();
			
			graphics.beginFill( _borderColor );
			graphics.drawRoundRectComplex( 0, 0, width, titleHeight, _cornerRadius, _cornerRadius, 0, 0 );
			graphics.endFill();
		}
		
		
		private function onClickTitleCloseButton( event:MouseEvent ):void
		{
			closeEditor();
		}
		
		
		private function onFocusOut( event:FocusEvent ):void
		{
			var focusObject:InteractiveObject = getFocus();
			if( !focusObject ) 
			{
				return;		//app losing focus
			}
			
			if( Utilities.isDescendant( focusObject, this ) )
			{					
				return;		//subcomponent of info view gaining focus
			}

			closeEditor();
		}
		
		
		private function commitEditText():void
		{
			IntegraController.singleInstance.processCommand( new SetObjectInfo( _objectID, _editText.text ) );
			_anythingToCommit = false;
		}
		
		
		private function closeEditor():void
		{
			commitEditText();
			
			dispatchEvent( new Event( CLOSE_INFO_EDITOR ) );
		}
		
		
		private function get titleHeight():Number
		{
			return FontSize.getTextRowHeight( this );
		}
		

		private var _objectID:int;

		private var _titleLabel:Label = new Label;
		private var _titleCloseButton:Button = new Button;
		
		private var _editText:TextArea = new TextArea;
		
		private var _backgroundColor:uint = 0;
		
		private var _anythingToCommit:Boolean = false;

		private const _textMargin:Number = 5;
		private const _borderColor:uint = 0xe95d0f;
		private const _borderThickness:Number = 4;
		private const _cornerRadius:Number = 15;
		
		private static const _commitKeys:Array = [ Keyboard.SPACE, Keyboard.ENTER, Keyboard.BACKSPACE, Keyboard.DELETE ];
		
		public static const CLOSE_INFO_EDITOR:String = "CLOSE_INFO_EDITOR";
	}
}
