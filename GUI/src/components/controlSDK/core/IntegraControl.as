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

package components.controlSDK.core
{
    import flexunit.framework.Assert;
	
    import __AS3__.vec.Vector;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle; 

    import mx.containers.Canvas;

    public class IntegraControl extends Canvas
    {
		public function IntegraControl( controlManager:ControlManager )
		{
		    super();
				
		    Assert.assertNotNull( controlManager );
		    _controlManager = controlManager;
		}
        
        public function get defaultSize():Point { return new Point( 120, 120 ); }
        public function get minimumSize():Point { return new Point( 16, 16 ); }
        public function get maximumSize():Point { return new Point( 400, 400 ); }
        
        public function onValueChange( changedValues:Object ):void {}
        public function onTextEquivalentChange( changedTextEquivalents:Object ):void {}
        public function onInitializationComplete():void {}
        
        public function isActiveArea( point:Point ):Boolean { return false; }
	
        public function onMouseDown( event:MouseEvent ):void { Assert.assertTrue( isActiveArea( new Point( mouseX, mouseY ) ) ); }
        public function onDrag( event:MouseEvent ):void {}
        public function onEndDrag():void {}


		protected function registerAttribute( controlAttributeName:String, type:String ):void
		{
		    _controlManager.registerAttribute( controlAttributeName, type );
		}
			
			
		protected function isAttributeWritable( controlAttributeName:String ):Boolean
		{
		    return _controlManager.isAttributeWritable( controlAttributeName );			
		}
			
			
		protected function getAllowedValues( controlAttributeName:String ):Vector.<Object>
		{
		    return _controlManager.getAllowedValues( controlAttributeName );
		}
			
			
		protected function setValues( changedValues:Object ):void
		{
		    dispatchEvent( new IntegraControlEvent( IntegraControlEvent.CONTROL_VALUES_CHANGED, changedValues ) );
		}
	
	
		protected function setTextEquivalents( changedTextEquivalents:Object ):void
		{
		    dispatchEvent( new IntegraControlEvent( IntegraControlEvent.CONTROL_TEXT_EQUIVALENTS_CHANGED, changedTextEquivalents ) );
		}
			
			
		protected function startMouseDrag():void
		{
		    dispatchEvent( new IntegraControlEvent( IntegraControlEvent.CONTROL_START_DRAG ) );
		}
	
	
        protected function drawArea():Rectangle
        {
            return new Rectangle( 0, 0, width, height );
        }

        
        protected function controlCenter():Point
        {
            var drawArea:Rectangle = drawArea();
		    return new Point( drawArea.x + drawArea.width / 2, drawArea.y + drawArea.height / 2 );
        }
	
	        
        protected function controlRadius():Number
        {
		    var drawArea:Rectangle = drawArea();
		    return Math.min( drawArea.width, drawArea.height ) * 0.4;
        }
	
	        
		protected function setGlow( glowTarget:DisplayObject, glowAmount:Number ):void
		{
		    _controlManager.setGlow( glowTarget, glowAmount );
		}
	
	  
		/*
		The brightness parameter can be any number in range 0.0-1.0
		but the use of standarized enumeration is suggested
	    The enumeration values are: FULL, HIGH, MEDIUM, LOW, NONE
		*/
		protected function foregroundColor( brightness:Number = 1.0 ):uint
		{
	            var col:Number = 0xff * brightness;
	
	            return ( col << 16 ) | ( col << 8 ) | col;
		}
		
		
		// color brightness enumeration
		public const FULL:Number = 1.0;
		public const HIGH:Number = 0.75;
		public const MEDIUM:Number = 0.5;
		public const LOW:Number = 0.25;
		public const NONE:Number = 0.0;
	
		private var _controlManager:ControlManager = null;
    }
}