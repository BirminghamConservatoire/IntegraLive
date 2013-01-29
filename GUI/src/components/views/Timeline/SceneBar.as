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


package components.views.Timeline
{
	import components.model.IntegraDataObject;
	import components.model.userData.ColorScheme;
	import components.utils.CursorSetter;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	
	public class SceneBar extends Canvas
	{
		public function SceneBar( editable:Boolean = false )
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;

			_nameEdit.x = 0;
			_nameEdit.setStyle( "verticalCenter", 0 );
			_nameEdit.setStyle( "textAlign", "center" );
			_nameEdit.setStyle( "borderStyle", "none" );
			_nameEdit.setStyle( "focusAlpha", 0 );
			_nameEdit.setStyle( "backgroundAlpha", 0 );
			setNameEditable( false );
			addElement( _nameEdit );
			
			addEventListener( Event.RESIZE, onResize );

			if( editable )
			{			
				addEventListener( MouseEvent.DOUBLE_CLICK, onOpenNameEdit );
				_nameEdit.addEventListener( FocusEvent.FOCUS_OUT, onNameEditChange );
				_nameEdit.addEventListener( KeyboardEvent.KEY_UP, onNameEditKeyUp );
				_nameEdit.restrict = IntegraDataObject.legalObjectNameCharacterSet;

				_moveArea.percentHeight = 100;
				_moveArea.setStyle( "left", _resizeAreaWidth );
				_moveArea.setStyle( "right", _resizeAreaWidth );
				_moveArea.addEventListener( MouseEvent.MOUSE_OVER, onMouseOverMoveArea );
				addElement( _moveArea );
	
				_resizeStartArea.percentHeight = 100;
				_resizeStartArea.setStyle( "left", 0 );
				_resizeStartArea.width = _resizeAreaWidth;
				_resizeStartArea.addEventListener( MouseEvent.MOUSE_OVER, onMouseOverResizeArea );
				addElement( _resizeStartArea );
	
				_resizeEndArea.percentHeight = 100;
				_resizeEndArea.setStyle( "right", 0 );
				_resizeEndArea.width = _resizeAreaWidth;
				_resizeEndArea.addEventListener( MouseEvent.MOUSE_OVER, onMouseOverResizeArea );
				addElement( _resizeEndArea );
			}
		}
		
		
		public function set sceneName( name:String ):void 
		{
			_sceneName = name;
			updateNameEdit();
		}

		
		public function set isSelected( isSelected:Boolean ):void
		{
			_isSelected = isSelected;
			invalidateDisplayList();
		} 
		
		
		public function getResizeStartRect( targetCoordinateSpace:DisplayObject ):Rectangle
		{
			return _resizeStartArea.getRect( targetCoordinateSpace );
		}


		public function getResizeEndRect( targetCoordinateSpace:DisplayObject ):Rectangle
		{
			return _resizeEndArea.getRect( targetCoordinateSpace );
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
						_nameEdit.setStyle( "color", 0x000000 );
						_nameEdit.setStyle( "disabledColor", 0x000000 );
						break;
						
					case ColorScheme.DARK:
						_nameEdit.setStyle( "color", 0xffffff );
						_nameEdit.setStyle( "disabledColor", 0xffffff );
						break;
				}
			}
		} 
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			graphics.clear();
			graphics.lineStyle( _isSelected ? _selectedSceneBorderWidth : _normalSceneBorderWidth, _sceneColor, _isSelected ? _selectedSceneBorderAlpha : _normalSceneBorderAlpha );
			graphics.beginFill( _sceneColor, _isSelected ? _selectedSceneAlpha : _normalSceneAlpha );
			graphics.drawRect( 0, 0, width, height );
			graphics.endFill(); 
		}
		
		
		private function onResize( event:Event ):void
		{
			_nameEdit.width = width;	
		}
		
		
		private function onMouseOverMoveArea( event:MouseEvent ):void
		{
			CursorSetter.setCursor( CursorSetter.MOVE_EW, event.target as UIComponent );
		}
		

		private function onMouseOverResizeArea( event:MouseEvent ):void
		{
			CursorSetter.setCursor( CursorSetter.RESIZE_EW, event.target as UIComponent );
		}


		private function onOpenNameEdit( event:MouseEvent ):void
		{
			setNameEditable( true );
		}

		
		private function onNameEditChange( event:FocusEvent ):void
		{
			setNameEditable( false );
			updateNameEdit();
		}
		
		
		private function onNameEditKeyUp( event:KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case Keyboard.ENTER:
					setFocus();					//force changes to be committed
					break;

				case Keyboard.ESCAPE:
					updateNameEdit();			//reject changes
					setNameEditable( false );
					break;
					
				default:
					break;
			} 
		}		
		
		
		private function updateNameEdit():void
		{
			 _nameEdit.text = _sceneName;
		}
		
		
		private function setNameEditable( editable:Boolean ):void
		{
			_nameEdit.editable = editable;			
			_nameEdit.focusEnabled = editable;
			_nameEdit.enabled = editable;
			
			if( editable )
			{
				_nameEdit.selectionBeginIndex = 0;
				_nameEdit.selectionEndIndex = _nameEdit.text.length;
				_nameEdit.setFocus();
			}
			else
			{
				_nameEdit.selectionBeginIndex = NaN;
				_nameEdit.selectionEndIndex = NaN;
				setFocus();				
			}
		}		
		

		private var _sceneName:String = "";		

		private var _isSelected:Boolean = false; 

		private var _nameEdit:TextInput = new TextInput;

		private var _resizeStartArea:Canvas = new Canvas;
		private var _resizeEndArea:Canvas = new Canvas;
		private var _moveArea:Canvas = new Canvas;
		
		private static const _sceneColor:uint = 0x808080;
		private static const _normalSceneAlpha:Number = 0.2;
		private static const _normalSceneBorderWidth:Number = 1;
		private static const _normalSceneBorderAlpha:Number = 0.4;
		private static const _selectedSceneAlpha:Number = 0.4;
		private static const _selectedSceneBorderWidth:Number = 3;
		private static const _selectedSceneBorderAlpha:Number = 0.6;

		private static const _resizeAreaWidth:Number = 10; 
	}
}