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

package components.controls
{
    import __AS3__.vec.Vector;
    
    import components.controlSDK.core.*;

	import flash.ui.Keyboard;
	import flash.events.Event;
    import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
    
    import flexunit.framework.Assert;
    
    import mx.controls.TextInput;
	

    public class NumberBoxControl extends IntegraControl
    {
        public function NumberBoxControl( controlManager:ControlManager )
        {
            super( controlManager );
			
            registerAttribute( _attributeName, ControlAttributeType.NUMBER );
			
			_input.setStyle( "borderStyle", "none" );
			_input.setStyle( "backgroundColor", 0x808080 );
			_input.setStyle( "themeColor", 0x808080 );
			_input.setStyle( "color", 0x666666 );
			_input.setStyle( "disabledColor", 0x888888 );
			_input.setStyle( "textAlign", "center" );
			
			_input.setStyle( "horizontalCenter", "0" );
			_input.setStyle( "verticalCenter", "0" );
            addChild( _input );

			_input.addEventListener( MouseEvent.MOUSE_DOWN, onInputMouseDown );
			_input.addEventListener( KeyboardEvent.KEY_UP, onInputKeyUp );
			
            addEventListener( Event.RESIZE, onResize );
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			
			setEditing( false );
		}
		
		
        override public function get defaultSize():Point { return new Point( 120, 80 ); }
        override public function get minimumSize():Point { return new Point( 32, 32 ); }
        override public function get maximumSize():Point { return new Point( 320, 320 ); }

                
        override public function onTextEquivalentChange( changedTextEquivalents:Object ):void
        {
			Assert.assertTrue( changedTextEquivalents.hasOwnProperty( _attributeName ) );
			_currentText = changedTextEquivalents[ _attributeName ];

			if( !_editing )
			{
				update();
			}
		}
		

        override public function isActiveArea( point:Point ):Boolean
        {
			return _input.getRect( this ).containsPoint( point );
        }
		
		
		private function onAddedToStage( event:Event ):void
		{
			systemManager.stage.addEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
			systemManager.stage.addEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );
		}
		
		
		private function onInputMouseDown( event:MouseEvent ):void
		{
			if( !isAttributeWritable( _attributeName ) )
			{
				return;
			}

			event.stopPropagation();

			if( !_editing )
			{
				setEditing( true );
			}
		}

		
		private function onStageMouseDown( event:MouseEvent ):void
		{
			setEditing( false );
			update();
		}

		
		private function onStageMouseLeave( event:Event ):void
		{
			setEditing( false );
			update();
		}
		
		
		private function onInputKeyUp( event:KeyboardEvent ):void
		{
			if( !_editing )
			{
				return;
			}
			
			switch( event.keyCode )
			{
				case Keyboard.ESCAPE:
					storeValue( _previousText );
					setEditing( false );
					update();
					break;
				
				case Keyboard.ENTER:
					setEditing( false );
					update();
					break;
				
				default:
					storeValue( _input.text );
					break;
			} 
		}
		
		
		private function storeValue( value:String ):void
		{
			var changedText:Object = new Object;
			changedText[ _attributeName ] = value;
			dispatchEvent( new IntegraControlEvent( IntegraControlEvent.CONTROL_TEXT_EQUIVALENTS_CHANGED, changedText ) );
		}
		
		
		private function update():void
		{
			_input.text = _currentText;
		}
		
		
		private function setEditing( editing:Boolean ):void
		{
			Assert.assertFalse( editing && !isAttributeWritable( _attributeName ) );

			_editing = editing;
			
			_input.editable = editing; 
			_input.focusEnabled = editing;
			_input.enabled = editing;

			_input.setStyle( "focusAlpha", editing ? 0.2 : 0 );
			_input.setStyle( "backgroundAlpha", editing ? 0.2 : 0 );
			
			if( editing )
			{
				_previousText = _currentText;

				_input.setFocus();
				_input.drawFocus( true );
				
				_input.setSelection( 0, _input.text.length );
			}
			else
			{
				_input.drawFocus( false );
				_input.setSelection( -1, -1 );
			}
		}
		
		
		private function onResize( event:Event ):void
		{
			_input.setStyle( "fontSize", Math.min( height * 0.75, width * 0.2 ) );
			
			_input.width = Math.min( width, height * _aspectRatio );
			_input.height = Math.min( height, width / _aspectRatio );
		}
		

		private var _previousText:String = "";
		private var _currentText:String = "";
		private var _editing:Boolean = false;

        private var _input:TextInput = new TextInput;
	
        private static const _attributeName:String = "value";
		
		private static const _aspectRatio:Number = 3;
    }
}