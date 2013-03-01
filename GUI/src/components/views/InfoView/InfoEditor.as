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
	import components.utils.LazyChangeReporter;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.Skins.CloseButtonSkin;
	
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
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
			
			_editText.setStyle( "top", _textMargin );
			_editText.setStyle( "left", _textMargin );
			_editText.setStyle( "right", _textMargin );
			_editText.setStyle( "bottom", _textMargin );
			_editText.setStyle( "borderStyle", "none" );
			_editText.setStyle( "focusSkin", null );
			_editText.restrict = "A-Z a-z 0-9 !\"£$%\\^&*()\\-=_+[]{};'#:@~,./<>?\\\\|";
			addChild( _editText );
			
			_lazyChangeReporter = new LazyChangeReporter( _editText, commitEditText );
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( FocusEvent.FOCUS_OUT, onFocusOut );
			_editText.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
		}
		
		
		public function set markdown( markdown:String ):void
		{
			if( markdown != _editText.text )
			{
				_lazyChangeReporter.reset();
				_editText.text = markdown;
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
						_borderColor = 0xBEBEBE;
						_backgroundColor = 0xdfdfdf;
						_editText.setStyle( "color", 0x6D6D6D );
						
						break;
					
					case ColorScheme.DARK:
						_borderColor = 0x424242;
						_backgroundColor = 0x202020;
						_editText.setStyle( "color", 0x939393 );
						break;
				}

				_editText.setStyle( "backgroundColor", _backgroundColor );
				invalidateDisplayList();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				Assert.assertNotNull( parentDocument );
				setStyle( FontSize.STYLENAME, parentDocument.getStyle( FontSize.STYLENAME ) );
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
		}
		
	
		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( _borderThickness, _borderColor ); 
			graphics.beginFill( _backgroundColor );
			graphics.drawRoundRect( 0, 0, width, height, _cornerRadius, _cornerRadius );
			graphics.endFill();
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

			if( Utilities.getAncestorByType( focusObject, EditInfoButton ) )
			{					
				return;		
			}
			
			closeEditor();
		}
		
		
		private function commitEditText():void
		{
			IntegraController.singleInstance.processCommand( new SetObjectInfo( _objectID, _editText.text ) );
		}
		
		
		private function closeEditor():void
		{
			_lazyChangeReporter.close();
			
			dispatchEvent( new Event( CLOSE_INFO_EDITOR ) );
		}
		
		
		private var _objectID:int;

		private var _editText:TabbableTextArea = new TabbableTextArea;
		private var _lazyChangeReporter:LazyChangeReporter = null;
		
		private var _backgroundColor:uint = 0;
		private var _borderColor:uint = 0;
		
		private const _textMargin:Number = 5;
		private const _borderThickness:Number = 4;
		private const _cornerRadius:Number = 15;

		
		public static const CLOSE_INFO_EDITOR:String = "CLOSE_INFO_EDITOR";
	}
}
