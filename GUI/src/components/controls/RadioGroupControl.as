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
	
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
	
    import flexunit.framework.Assert;
	
    import mx.controls.Button;
	import components.controlSDK.core.*;
	

    public class RadioGroupControl extends IntegraControl
    {
        public function RadioGroupControl( controlManager:ControlManager )
        {
            super( controlManager );
			
            registerAttribute( _attributeName, ControlAttributeType.STRING );
			
            addEventListener( Event.RESIZE, onResize );
        }
		
		
        override public function get defaultSize():Point { return new Point( 120, 120 ); }
        override public function get minimumSize():Point { return new Point( 48, 48 ); }
        override public function get maximumSize():Point { return new Point( 320, 512 ); }


        override public function onValueChange( changedValues:Object ):void
        {
            Assert.assertTrue( changedValues.hasOwnProperty( _attributeName ) );
			
            _currentValue = changedValues[ _attributeName ];
			
            update();
        }


        override public function isActiveArea( point:Point ):Boolean
        {
            var globalPoint:Point = localToGlobal( point );
			
            for each( var button:Button in _radioButtons )
            {
                if( button.hitTestPoint( globalPoint.x, globalPoint.y, true ) )
                {
                    return true;
                }
            }
            
            return false;
        }


        private function update():void
        {
            var strings:Vector.<Object> = getAllowedValues( _attributeName );
            if( !strings )
            {
                //default case for no enumeration values provided
                strings = new Vector.<Object>;
            }

            var buttonIndex:int = 0;
            var buttonHeight:Number = Math.min( height / Math.max( 1, strings.length ) - _margin, _maximumButtonHeight );
            var fontSize:Number = buttonHeight * 0.6;
            var hideLabels:Boolean = ( fontSize < _minimumFontSize );
			
            for each( var string:String in strings )
            {
                if( buttonIndex >= _radioButtons.length )
                {
                    var newButton:Button = new Button();
                    newButton.setStyle( "skin", RadioButtonSkin );
                    newButton.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDownButton );
                    
                    addChild( newButton );
                    _radioButtons.push( newButton );
                }
		
                Assert.assertTrue( _radioButtons.length >= buttonIndex );
                var button:Button = _radioButtons[ buttonIndex ];
                button.id = string;
                button.label = hideLabels ? "" : string;
                button.x = _margin;
                button.y = buttonIndex * ( buttonHeight + _margin ); 
                button.width = width - ( _margin * 2 );
                button.height = buttonHeight;
                button.setStyle( "fontSize", fontSize );

                var isSelected:Boolean = ( string == _currentValue );
                var color:uint = isSelected ? 0x333333 : foregroundColor( FULL );
				
                button.setStyle( "color", color );
                button.setStyle( "textRollOverColor", color );
                button.setStyle( "textSelectedColor", color );

                button.selected = isSelected;
                setGlow( button, isSelected ? 1 : 0 );
				
                buttonIndex++;
            } 
			
            while( _radioButtons.length > buttonIndex )
            {
                removeChild( _radioButtons[ _radioButtons.length - 1 ] );
                _radioButtons.length--;
            } 
        }
		
		
        private function onMouseDownButton( event:MouseEvent ):void
        {
            var changedValues:Object = new Object;
            changedValues[ _attributeName ] = event.target.id;
            setValues( changedValues );
            startMouseDrag();	
        }	
			
		
        private function onResize( event:Event ):void
        {
            update();
        }
		

        private var _currentValue:String = null;
		
        private var _radioButtons:Vector.<Button> = new Vector.<Button>;
  		
        private static const _attributeName:String = "value";
        private static const _maximumButtonHeight:Number = 48;
        private static const _margin:Number = 4;
        private static const _minimumFontSize:Number = 7;
    }
} 