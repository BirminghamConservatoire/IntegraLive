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


package components.views.ArrangeViewProperties
{
	import components.model.userData.ColorScheme;
	import components.utils.CursorSetter;
	import components.views.MouseCapture;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.TextInput;
	
	
	public class RoutingItemScalingControl extends Canvas
	{
		public function RoutingItemScalingControl()
		{
			super();
			
			_numberEdit.setStyle( "left", 0 );
			_numberEdit.setStyle( "right", 0 );
			_numberEdit.setStyle( "verticalCenter", 0 );
			_numberEdit.setStyle( "backgroundAlpha", 0 );
			_numberEdit.setStyle( "focusAlpha", 0 );
			_numberEdit.setStyle( "borderStyle", "none" );
			_numberEdit.setStyle( "textAlign", "center" );
			
			_numberEdit.restrict = "-.0123456789";
			
			setEditing( false );
			
			addChild( _numberEdit );
			
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}


		public function get value():Number { return _value; }
		
		public function set value( value:Number ):void
		{
			if( _integer ) value = Math.round( value );
			
			value = Math.max( value, Math.min( _minimum, _maximum ) );
			value = Math.min( value, Math.max( _minimum, _maximum ) );
					
			_value = value;
			
			var stringEquivalent:String = value.toFixed( 3 );
			if( stringEquivalent.indexOf( "." ) >= 0 )
			{
				while( stringEquivalent.substr( stringEquivalent.length - 1 ) == "0" )
				{
					stringEquivalent = stringEquivalent.substr( 0, stringEquivalent.length - 1 );
				}

				if( stringEquivalent.substr( stringEquivalent.length - 1 ) == "." )
				{
					stringEquivalent = stringEquivalent.substr( 0, stringEquivalent.length - 1 );
				}
			}
			
			_numberEdit.text = stringEquivalent;
		}

		
		override public function set enabled( value:Boolean ):void
		{
			super.enabled = true;
			
			_enabled = value;
			_numberEdit.visible = value;
			mouseChildren = value;
			mouseEnabled = value;
		}
		
		
		public function setRange( minimum:Number, maximum:Number ):void
		{
			if( _integer )
			{
				_minimum = Math.round( minimum );
				_maximum = Math.round( maximum );
			}
			else
			{
				_minimum = minimum;
				_maximum = maximum;
			}

			var constrainedValue:Number = Math.max( _value, Math.min( _minimum, _maximum ) );
			constrainedValue = Math.min( constrainedValue, Math.max( _minimum, _maximum ) );
			
			if( constrainedValue != _value )
			{
				value = constrainedValue;
			}
		}
		
		
		public function set integer( integer:Boolean ):void
		{
			_integer = integer;
			
			if( _integer )
			{
				if( _value != Math.round( _value ) )
				{
					value = _value;
				}
				
				if( _minimum != Math.round( _minimum ) || _maximum != Math.round( _maximum ) )
				{
					setRange( _minimum, _maximum );
				}
			}
		}
		
		
		override public function styleChanged( style:String ):void
		{
		 	if( !style || style == ColorScheme.STYLENAME )
			{
				invalidateDisplayList();

				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_numberEdit.setStyle( "color", 0xcfcfcf );
	 					break;
					
					case ColorScheme.DARK:
						_numberEdit.setStyle( "color", 0x313131 );
						break;
				}	
			}
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			var fillColor:uint = 0;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					fillColor = 0x747474;
					break;
				
				case ColorScheme.DARK:
					fillColor = 0x8c8c8c;
					break;
			}	
			
			var diameter:Number = height;
			graphics.beginFill( fillColor );
			graphics.drawRoundRect( 0, 0, width, height, diameter, diameter );
			graphics.endFill();
		}
		
		
		private function setEditing( editing:Boolean ):void 
		{
			_editing = editing;
			
			_numberEdit.editable = editing;
			_numberEdit.focusEnabled = editing;
			_numberEdit.mouseEnabled = editing;
			_numberEdit.mouseChildren = editing;
			_numberEdit.mouseFocusEnabled = editing;
			_numberEdit.enabled = false;
			_numberEdit.enabled = true;
			
			if( editing )
			{
				_numberEdit.setFocus();
				_numberEdit.drawFocus( true );
				_numberEdit.setSelection( 0, _numberEdit.length );
				
				if( !_addedEditingEventListeners )
				{			
					_numberEdit.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
					
					systemManager.stage.addEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
					systemManager.stage.addEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );
					_addedEditingEventListeners = true;
				}
			}
			else
			{
				_numberEdit.drawFocus( false );
				_numberEdit.setSelection( -1, -1 );
				
				if( _addedEditingEventListeners )
				{				
					_numberEdit.removeEventListener( KeyboardEvent.KEY_UP, onKeyUp );
					
					systemManager.stage.removeEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
					systemManager.stage.removeEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );
					_addedEditingEventListeners = false;
				}
			}
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			if( _editing )
			{
				commitChanges();
			}
			else
			{
				_dragStartY = mouseY;
				_dragStartValue = _value;
				_isDragging = false;

				MouseCapture.instance.setCapture( this, onDrag, onDragFinished );
			}
		}
		
		
		private function onDrag( event:MouseEvent ):void
		{
			var dragTravel:Number = _dragStartY - mouseY;
			
			if( !_isDragging && Math.abs( dragTravel ) > MINIMUM_DRAG_DISTANCE )
			{
				_isDragging = true;

				CursorSetter.setDragCursor( CursorSetter.HAND );
			}
			
			if( _isDragging )
			{
				var newValue:Number = _dragStartValue + ( _dragStartY - mouseY ) * ( _maximum - _minimum ) / DRAG_RANGE_PIXELS;
				value = Math.max( _minimum, Math.min( _maximum, newValue ) );
			}
		}

		
		private function onDragFinished():void
		{
			if( _isDragging )
			{
				_isDragging = false;
	
				dispatchEvent( new Event( Event.CHANGE ) );
			}
			else
			{
				if( !_editing )
				{
					setEditing( true );
				}
			}
		}

		
		private function onKeyUp( event:KeyboardEvent ):void
		{
			if( !_editing )
			{
				return;
			}
			
			switch( event.keyCode )
			{
				case Keyboard.ESCAPE:
					cancelChanges();					
					break;
				
				case Keyboard.ENTER:
					commitChanges();
					break;
				
				default:
					break;
			} 
		}		
		
		
		private function onStageMouseLeave( event:Event ):void
		{
			if( _editing )
			{
				commitChanges();
			}
		}
		
		
		private function onStageMouseDown( event:MouseEvent ):void
		{
			if( _editing )
			{
				if( mouseX < 0 || mouseY < 0 || mouseX >= width || mouseY >= height )
				{
					commitChanges();
				}
			}
		}		
		
		
		private function commitChanges():void
		{
			setEditing( false );

			value = Math.max( _minimum, Math.min( _maximum, Number( _numberEdit.text ) ) );
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}

		
		private function cancelChanges():void
		{
			setEditing( false );
			value = _value;
		}
		

		private var _enabled:Boolean = true;
		private var _value:Number = 0;
		private var _minimum:Number = 0;
		private var _maximum:Number = 0;
		private var _integer:Boolean = false;

		private var _isDragging:Boolean = false;
		private var _dragStartY:Number = 0;
		private var _dragStartValue:Number = 0;

		private var _numberEdit:TextInput = new TextInput;
		private var _editing:Boolean = false;
		private var _addedEditingEventListeners:Boolean = false;
		
		private static const DRAG_RANGE_PIXELS:Number = 200;
		private static const MINIMUM_DRAG_DISTANCE:Number = 5;	//drags shorter than this are interpreted as 'editing' clicks
	}
}