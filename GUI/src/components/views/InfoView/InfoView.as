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
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.StyleSheet;
	import flash.ui.Keyboard;
	
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.styles.CSSStyleDeclaration;
	
	import spark.components.Application;
	
	import components.controller.serverCommands.SetObjectInfo;
	import components.controller.userDataCommands.SetDisplayedInfo;
	import components.controller.userDataCommands.ShowInfoView;
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	import components.views.viewContainers.IntegraViewEvent;
	
	import flexunit.framework.Assert;
		

	public class InfoView extends IntegraView
	{
		public function InfoView( defineOwnHeight:Boolean )
		{
			super();
			
			width = 200;
			minWidth = 100;
			maxWidth = 400;
			
			if( defineOwnHeight )
			{
				height = 200;
				minHeight = 100;
				maxHeight = 400;
			}
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			_htmlText.setStyle( "left", _leftMargin );
			_htmlText.setStyle( "right", _rightMargin );
			_htmlText.setStyle( "top", _topMargin );
			_htmlText.setStyle( "bottom", _bottomMargin );
			_htmlText.setStyle( "borderStyle", "none" );
			_htmlText.setStyle( "backgroundAlpha", 0 );
			_htmlText.editable = false;
			_htmlText.condenseWhite = true;
			
			loseFocus();
			
			addChild( _htmlText );
			
			_focusPrompt.setStyle( "left", 0 );
			_focusPrompt.setStyle( "right", 0 );
			_focusPrompt.setStyle( "bottom", 0 );
			_focusPrompt.setStyle( "textAlign", "center" );
			
			addChild( _focusPrompt );
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( FocusEvent.FOCUS_OUT, onFocusOut );
			addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
			
			MouseCapture.instance.addEventListener( MouseCapture.MOUSE_CAPTURE_FINISHED, onMouseCaptureFinished );
			
			addUpdateMethod( SetDisplayedInfo, onSetDisplayedInfo );
			addUpdateMethod( SetObjectInfo, onSetObjectInfo );
		}


		override public function get title():String 
		{ 
			return "Info"; 
		}
		
		
		override public function get color():uint
		{
			return 0x808080;
		}		
		
		
		override public function get isSidebarColours():Boolean { return true; } 
		override public function get titlebarView():IntegraView { return _editInfoButton; }

		
		override public function closeButtonClicked():void 
		{
			controller.processCommand( new ShowInfoView( false ) );
		}

		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "Info" );
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
						_htmlText.setStyle( "backgroundColor", 0xDFDFDF );
						_focusPrompt.setStyle( "color", 0x6D6D6D );
						_textColor ='#6D6D6D';
						_linkColor = '#0000C0';
						break;
					
					case ColorScheme.DARK:
						_htmlText.setStyle( "backgroundColor", 0x505050 );
						_focusPrompt.setStyle( "color", 0x939393 );
						_textColor = '#939393';
						_linkColor = '#4080FF';
						break;
				}
				
				updateTextCSS();
				
				invalidateDisplayList();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				_focusPrompt.setStyle( "fontSize", FontSize.NORMAL - 1 );
				
				updateTextCSS();	
			}		
		}
		
		
		override protected function onAllDataChanged():void
		{
			if( !_gotFocus ) 
			{
				if( model.currentInfo != _displayedInfo )
				{
					_displayedInfo = model.currentInfo;
					updateContent();
				}
			}
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			if( _focusPrompt.visible )
			{
				var tooltipStyle:CSSStyleDeclaration = styleManager.getStyleDeclaration( "mx.controls.ToolTip" );
				var tooltipBackgroundColor:uint = tooltipStyle.getStyle( "backgroundColor" );
				
				graphics.beginFill( tooltipBackgroundColor );
				graphics.drawRoundRectComplex( 0, height - _bottomMargin, width, _bottomMargin, 0, 0, _bottomCornerRadius, _bottomCornerRadius );
				graphics.endFill();
				
				graphics.lineStyle( 0, _focusPrompt.getStyle( "color" ) );
				graphics.moveTo( 0, height - _bottomMargin );
				graphics.lineTo( width - 1, height - _bottomMargin );
			}
		}
		
		
		private function onSetDisplayedInfo( event:SetDisplayedInfo ):void
		{
			if( !_gotFocus ) 
			{
				if( event.info != _displayedInfo )
				{
					if( MouseCapture.instance.hasCapture )
					{
						_infoChangedDuringCapture = true;
					}
					else
					{
						_displayedInfo = event.info;
						updateContent();
					}
				}
			}
		}
		
		
		private function onSetObjectInfo( command:SetObjectInfo ):void
		{
			if( _displayedInfo && _displayedInfo.ownerID == command.objectID )
			{
				updateContent();
			}
		}
		
		
		private function onMouseCaptureFinished( event:Event ):void
		{
			if( _infoChangedDuringCapture )
			{
				onAllDataChanged();
			}
		}
		
		
		private function updateContent():void
		{
			if( _displayedInfo )
			{
				_htmlText.htmlText = _displayedInfo.html;
				
				_focusPrompt.visible = !_gotFocus;
				updateFocusPrompt();
			}
			else
			{
				Assert.assertNull( _editInfoButton );
				Assert.assertFalse( _gotFocus );

				_htmlText.htmlText = "";
				_focusPrompt.visible = false;
			}
			
			invalidateDisplayList();
			
			_infoChangedDuringCapture = false;
		}
		
		
		private function onAddedToStage( event:Event ):void
		{
			if( _addedToStage )	return;
			_addedToStage = true;
			
			systemManager.stage.addEventListener( KeyboardEvent.KEY_DOWN, onStageKeyDown );  			
		}

		
		private function onStageKeyDown( event:KeyboardEvent ):void
		{
			if( !stage ) return;
			
			if( _displayedInfo )
			{
				if( Utilities.isWindows )
				{
					if( event.keyCode == Keyboard.F2 )
					{
						toggleFocus();
					}
				}
				
				if( Utilities.isMac )
				{
					if( event.keyCode == Keyboard.NUMBER_3 && event.altKey )
					{
						toggleFocus();
					}
				}
			}

		
			//easter eggs for testing
			if( Utilities.isDebugging )
			{
				if( _displayedInfo && event.keyCode == Keyboard.F3 )
				{
					Clipboard.generalClipboard.clear();
					Clipboard.generalClipboard.setData( ClipboardFormats.TEXT_FORMAT, _displayedInfo.markdown );
				}
	
				if( _displayedInfo && event.keyCode == Keyboard.F4 )
				{
					Clipboard.generalClipboard.clear();
					Clipboard.generalClipboard.setData( ClipboardFormats.TEXT_FORMAT, _displayedInfo.html );
				}
			}
		}	
		
		
		private function toggleFocus():void
		{
			if( _gotFocus )
			{
				loseFocus();
				
				if( _previousFocus && _previousFocus.stage )
				{
					stage.focus = _previousFocus;
				}
				else
				{
					stage.focus = stage;
				}
			}
			else
			{
				_previousFocus = stage.focus as UIComponent;
				setFocus();
				gainFocus();
			}			
		}
		
		
		private function updateFocusPrompt():void
		{
			var verb:String = " to lock";
			
			_htmlText.validateNow();
			if( _htmlText.textHeight > _htmlText.height )
			{
				verb += "/scroll";
			}
			
			if( _displayedInfo && _displayedInfo.canEdit )
			{
				verb += "/edit";	
			}
			
			if( Utilities.isWindows )
			{
				_focusPrompt.text = "Press F2" + verb;	
			}
			
			if( Utilities.isMac )
			{
				_focusPrompt.text = "Press Alt+3" + verb;	
			}
		}
		
		
		private function onFocusOut( event:FocusEvent ):void
		{
			var focusObject:InteractiveObject = getFocus();
			if( !focusObject ) 
			{
				return;		//app losing focus
			}
			
			if( focusObject == this || Utilities.isDescendant( focusObject, this ) )
			{					
				return;		//subcomponent of info view gaining focus
			}

			if( Utilities.getAncestorByType( focusObject, EditInfoButton ) )
			{					
				return;		//edit button click
			}

			if( Utilities.getAncestorByType( focusObject, InfoEditor ) )
			{					
				return;		//editor click
			}
			
			if( _gotFocus )
			{
				loseFocus();
			}
		}
		
		
		private function gainFocus():void
		{
			Assert.assertNotNull( _displayedInfo );
			
			_htmlText.verticalScrollPolicy = ScrollPolicy.ON;
			
			_focusPrompt.visible = false;
			
			_gotFocus = true;

			if( _displayedInfo.canEdit )
			{
				_editInfoButton = new EditInfoButton( _displayedInfo, this );
				dispatchEvent( new IntegraViewEvent( IntegraViewEvent.TITLEBAR_CHANGED ) );
			}
			
			invalidateDisplayList();
		}

		
		private function loseFocus():void
		{
			_htmlText.verticalScrollPolicy = ScrollPolicy.OFF;

			_gotFocus = false;

			if( _editInfoButton )
			{
				_editInfoButton.free();
				_editInfoButton = null;
				dispatchEvent( new IntegraViewEvent( IntegraViewEvent.TITLEBAR_CHANGED ) );
			}

			if( _displayedInfo != model.currentInfo )
			{
				_displayedInfo = model.currentInfo;
				updateContent();
			}
			else
			{
				_focusPrompt.visible = ( _displayedInfo != null );
			}

			invalidateDisplayList();
		}
		
		
		private function onDoubleClick( event:MouseEvent ):void
		{
			if( !_gotFocus || !_displayedInfo || !_displayedInfo.canEdit )
			{
				return;
			}
			
			if( !_editInfoButton )
			{
				_editInfoButton.showEditor();
			}
		}
		
		
		private function get application():Application
		{
			for( var iterator:DisplayObjectContainer = this; iterator; iterator = iterator.parent )
			{
				if( iterator is Application ) return iterator as Application;
			}
			
			Assert.assertTrue( false );
			return null;
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
			
			_htmlText.styleSheet = myStyles;

			if( _displayedInfo )
			{
				_htmlText.htmlText = _displayedInfo.html;
			}
		}
		
		
		private function setButtonTextColor( button:Button, color:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
		}
		
		
		private var _displayedInfo:Info = null;
		
		private var _htmlText:TextArea = new TextArea;
		private var _focusPrompt:Label = new Label;

		private var _addedToStage:Boolean = false;
		
		private var _gotFocus:Boolean = false;
		private var _previousFocus:UIComponent = null;
		
		private var _textColor:String;
		private var _linkColor:String;
		
		private var _infoChangedDuringCapture:Boolean;

		private var _editInfoButton:EditInfoButton = null;
		
		private static const _leftMargin:Number = 4;
		private static const _rightMargin:Number = 4;
		private static const _topMargin:Number = 4;
		private static const _bottomMargin:Number = 16;
		private static const _bottomCornerRadius:Number = 8;
	}
}