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


package components.controlSDK.HelperClasses
{
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    
    import mx.containers.Canvas;
    import mx.controls.Label;
    import mx.controls.TextInput;
    import mx.core.ScrollPolicy;
    import mx.events.MoveEvent;
    
    import __AS3__.vec.Vector;
    
    import components.controlSDK.core.IntegraControl;
    import components.controlSDK.core.IntegraControlEvent;
    import components.utils.Utilities;
    
    import flexunit.framework.Assert;
	
    public class AttributeLabel extends Canvas
    {
        public function AttributeLabel( attributeName:String, consumeMouseDown:Boolean = false )
        {
            super();
			
            _consumeMouseDown = consumeMouseDown;
			
            horizontalScrollPolicy = ScrollPolicy.OFF;
            verticalScrollPolicy = ScrollPolicy.OFF;
			
            _attributeName = attributeName;
		
            _label = new Label;
            _label.setStyle( "color", 0xffffff );
            addChild( _label );

            _textInput = new TextInput;
            _textInput.setStyle( "borderStyle", "none" );
            _textInput.setStyle( "backgroundColor", 0x808080 );
            _textInput.setStyle( "themeColor", 0x808080 );
            _textInput.setStyle( "color", 0x000000 );
            _textInput.setStyle( "disabledColor", 0x888888 );
            _textInput.setStyle( "textAlign", "center" );
            _textInput.restrict = Utilities.printableCharacterRestrict;
            _textInput.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
            _textInput.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
            addChild( _textInput );
	
            addEventListener( Event.ADDED, onAddedToParent );
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
            addEventListener( Event.RESIZE, onResize );
            addEventListener( MoveEvent.MOVE, onMove );

            setIsEditing( false );
        }
		
        public function get isEditing():Boolean { return _isEditing; }

		
		override public function styleChanged( style:String ):void
		{
			if( style && style == "horizontalAlign" )
			{
				positionChildren();
			}
		}
		
		
        private function setIsEditing( isEditing:Boolean ):void
        {
            if( isEditing && !_writable )
            {
                return;
            }

            _isEditing = isEditing;

            _textInput.editable = isEditing; 
            _textInput.focusEnabled = isEditing;
            _textInput.enabled = isEditing;

            _textInput.setStyle( "focusAlpha", isEditing ? 0.2 : 0 );
            _textInput.setStyle( "backgroundAlpha", isEditing ? 0.2 : 0 );
			
            if( isEditing )
            {
                _textInput.setFocus();
                _textInput.drawFocus( true );
				_textInput.setSelection( 0, _textInput.length );
                _textBeforeEdit = _textInput.text;

                if( !_addedEditingEventListeners )
                {			
                    _textInput.addEventListener( KeyboardEvent.KEY_UP, onKeyUp );
				
                    systemManager.stage.addEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
                    systemManager.stage.addEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );
                    _addedEditingEventListeners = true;
                }
            }
            else
            {
                _textInput.text = _textAtLastUpdate;
                _textInput.drawFocus( false );
                _textInput.setSelection( -1, -1 );

                if( _addedEditingEventListeners )
                {				
                    _textInput.removeEventListener( KeyboardEvent.KEY_UP, onKeyUp );

                    systemManager.stage.removeEventListener( Event.MOUSE_LEAVE, onStageMouseLeave );
                    systemManager.stage.removeEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );
                    _addedEditingEventListeners = false;
                }
            }

            //dispatch event
            var isEditingMap:Object = new Object;
            isEditingMap[ _attributeName ] = isEditing;  
            dispatchEvent( new IntegraControlEvent( IntegraControlEvent.ATTRIBUTE_LABEL_EDITSTATE_CHANGED, isEditingMap ) );
        }


        private function onKeyUp( event:KeyboardEvent ):void
        {
            if( !_isEditing )
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
		
		
        private function onAddedToParent( event:Event ):void
        {
            if( !_addedControlEventListeners )
            {
				var control:IntegraControl = getParentControl();
				Assert.assertNotNull( control );	//attribute labels should always be used as children of IntegraControl classes
				
				control.addEventListener( IntegraControlEvent.HOST_TEXT_EQUIVALENTS_CHANGED, onHostTextEquivalentsChanged );
				control.addEventListener( IntegraControlEvent.HOST_ATTRIBUTE_LABELS_CHANGED, onHostAttributeLabelsChanged );
				control.addEventListener( IntegraControlEvent.HOST_WRITABLE_FLAGS_CHANGED, onHostWritableFlagsChanged );
			
                _addedControlEventListeners = true;
            }
        }
		
		
		private function onAddedToStage( event:Event ):void
		{
			positionChildren();
		}
		
		
        private function onHostTextEquivalentsChanged( event:IntegraControlEvent ):void
        {
            var changedTextEquivalents:Object = event.data;
            if( changedTextEquivalents.hasOwnProperty( _attributeName ) )
            {
                _textAtLastUpdate = changedTextEquivalents[ _attributeName ];

                if( !_isEditing )
                {
                    _textInput.text = _textAtLastUpdate;
			
                    if( !_receivedFirstText )
                    { 
                        _receivedFirstText = true;
                        positionChildren();
                    }
                }
            }
        }


        private function onHostAttributeLabelsChanged( event:IntegraControlEvent ):void
        {
            var newLabel:String = "";

            var attributeLabels:Object = event.data;
            if( attributeLabels.hasOwnProperty( _attributeName ) )
            {
                newLabel = attributeLabels[ _attributeName ];
            }

            if( newLabel != _label.text )
            {		
                _label.text = newLabel;
			
                positionChildren();
            }			
        }
		
		
        private function onHostWritableFlagsChanged( event:IntegraControlEvent ):void
        {
            var writableFlags:Object = event.data;
            Assert.assertTrue( writableFlags.hasOwnProperty( _attributeName ) );
			
            _writable = writableFlags[ _attributeName ];
			
            if( _isEditing && !_writable )
            {
                setIsEditing( false );
            } 
        }
		
		
        private function onResize( event:Event ):void
        {
            positionChildren();
        }


        private function onMove( event:Event ):void
        {
            positionChildren();
        }
		
		
        private function onDoubleClick( event:MouseEvent ):void
        {
            if( !_isEditing )
            {
                setIsEditing( true );
            }			
        }


        private function onMouseDown( event:MouseEvent ):void
        {
            if( _isEditing || _consumeMouseDown )
            {
                event.stopPropagation();
            }
        }



        private function onStageMouseLeave( event:Event ):void
        {
            if( _isEditing )
            {
                commitChanges();
            }
        }


        private function onStageMouseDown( event:MouseEvent ):void
        {
            if( _isEditing )
            {
                commitChanges();
            }
        }
		
		
        private function commitChanges():void
        {
            Assert.assertTrue( _isEditing );
			
			var changedText:Object = new Object;
			changedText[ _attributeName ] = _textInput.text;
			dispatchEvent( new IntegraControlEvent( IntegraControlEvent.CONTROL_TEXT_EQUIVALENTS_CHANGED, changedText ) );
			invalidateSize();
			
            setIsEditing( false );
			
            dispatchEvent( new Event( Event.COMPLETE ) );
        }				

				
        private function cancelChanges():void
        {
            _textInput.text = _textBeforeEdit;
			
            var changedText:Object = new Object;
            changedText[ _attributeName ] = _textBeforeEdit;
            dispatchEvent( new IntegraControlEvent( IntegraControlEvent.CONTROL_TEXT_EQUIVALENTS_CHANGED, changedText ) );

            setIsEditing( false );			
        }
		
		
        private function positionChildren():void
        {
			if( !stage || !_receivedFirstText )
			{
				return;
			}
			
            var nominalNumberOfCharacters:int = _label.text.length + 1 + nominalValueEditLength;
            Assert.assertTrue( nominalNumberOfCharacters > 0 );

            var aspectRatio:Number = nominalNumberOfCharacters * nominalCharacterAspectRatio;
            Assert.assertTrue( aspectRatio > 0 );
			
            var widthInUse:Number = Math.min( width, height * aspectRatio );
            var heightInUse:Number = Math.min( height, width / aspectRatio );

            _label.width = widthInUse * ( _label.text.length + 1 ) / nominalNumberOfCharacters ;
            _label.height = heightInUse;
            _label.y = ( height - heightInUse ) / 2;
			
            _textInput.width = widthInUse * nominalValueEditLength / nominalNumberOfCharacters;
            _textInput.height = heightInUse;
            _textInput.y = ( height - heightInUse ) / 2;

            var fontSize:Number = heightInUse * fontScale;
            _label.setStyle( "fontSize", fontSize );
            _textInput.setStyle( "fontSize", fontSize );

            //vertical centering:
            _textInput.validateNow();
            var yShift:Number = ( _textInput.height - _textInput.textHeight ) / 2; 
            _textInput.y += yShift;
            _label.y += yShift;
			
            //label width compensation
            _label.validateNow();
            var widthShift:Number = Math.max( 0, ( _label.width - _label.textWidth ) - 5 );
            _label.width -= widthShift;
            _textInput.width += widthShift;

            //horizontal alignment
            switch( getStyle( "horizontalAlign" ) )
            {
                case "left":
                    _label.x = 0;
                    _textInput.x = _label.width;
                    break;
					
                case "right":
                    _textInput.x = width - _textInput.width;
                    _label.x = _textInput.x - _label.width;
                    break;
					
                case "center":
                default:
                    _label.x = ( width - _textInput.width - _label.width ) / 2;
	                _textInput.x = _label.x + _label.width;
	                break; 
            }
    
			_textInput.setStyle( "color", 0x666666 );			
            //snap to parent bounds
            if( parent )
            {
                var minX:Number = widthInUse - width;
                var minY:Number = heightInUse - height;
                var maxX:Number = parent.width - widthInUse;
                var maxY:Number = parent.height - heightInUse;

                if( x < minX ) x = minX;
                else if( x > maxX ) x = maxX;
			
                if( y < minY ) y = minY;
                else if( y > maxY ) y = maxY;
            }

            //show/hide		
            var show:Boolean = ( fontSize >= minimumTextHeight );
							
            visible = show;
            _textInput.doubleClickEnabled = show;
			
            //dispatch event
            if( _addedControlEventListeners )
            {
                var textInputPosition:Object = new Object;
                textInputPosition[ _attributeName ] = _textInput.getRect( parentApplication.stage );  
                dispatchEvent( new IntegraControlEvent( IntegraControlEvent.ATTRIBUTE_LABEL_POSITIONED, textInputPosition ) );
            } 
	    }
		
		
		private function getParentControl():IntegraControl
		{
			for( var ancestor:DisplayObjectContainer = parent; ancestor; ancestor = ancestor.parent )
			{
				if( ancestor is IntegraControl )
				{
					return ancestor as IntegraControl;
				}
			}
			
			return null;	//this label doesn't have an IntegraControl as its parent!
		}

		
        private var _attributeName:String;
        private var _label:Label;
        private var _textInput:TextInput;

        private var _writable:Boolean = false;
        private var _isEditing:Boolean = false;
        private var _addedEditingEventListeners:Boolean = false;
        private var _addedControlEventListeners:Boolean = false;
        private var _textAtLastUpdate:String = null;
        private var _textBeforeEdit:String = null;
        private var _consumeMouseDown:Boolean = false;
        private var _receivedFirstText:Boolean = false;
        
        private static const fontScale:Number = 0.5;
        private static const minimumTextHeight:Number = 7;
        private static const nominalValueEditLength:int = 5;
        private static const nominalCharacterAspectRatio:Number = 0.35;
    }
}