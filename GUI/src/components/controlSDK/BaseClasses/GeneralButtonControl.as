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

package components.controlSDK.BaseClasses
{
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
	
    import flexunit.framework.Assert;
	
    import mx.containers.Canvas;
	import components.controlSDK.core.*;
	import components.controlSDK.HelperClasses.RoundControl;

	
    // ABSTRACT CLASS - NOT TO BE INSTANTIATED DIRECTLY
    public class GeneralButtonControl extends IntegraControl
    {
		public function GeneralButtonControl( controlManager:ControlManager )
		{
		    super( controlManager );
				
		    registerAttribute( attributeName, ControlAttributeType.NUMBER );
				
		    button.percentWidth = 100;
		    button.percentHeight = 100;
		    addChild( button );
            
	    	addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
            addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
	    	addEventListener( Event.RESIZE, onResize );

            geometry = new RoundControl( width, height );
		}
		

        // ABSTRACT METHOD
		override public function onValueChange( changedValues:Object ):void
		{
            throw new Error( "Abstract method to be overriden in the subclasses" ); 
		}		


        // ABSTRACT METHODS
		override public function onMouseDown( event:MouseEvent ):void
		{
            throw new Error( "Abstract method to be overriden in the subclasses" ); 
		}


        // ABSTRACT METHOD
		protected function update():void
		{
            throw new Error( "Abstract method to be overriden in the subclasses" ); 
        }


		override public function get defaultSize():Point { return new Point( 64, 64 ); }
		override public function get minimumSize():Point { return new Point( 16, 16 ); }
		override public function get maximumSize():Point { return new Point( 320, 320 ); }
	

		override public function isActiveArea( point:Point ):Boolean
		{
            return geometry.isActiveArea( point );
		}

		
		protected function onMouseOver( event:MouseEvent ):void
		{
		    if( this.isActiveArea( new Point( mouseX, mouseY ) ) && !event.buttonDown )
		    {
				mouseOver = true;
				update();
		    }
		    else
		    {
				mouseOver = false;
				update();
		    }
		}


        protected function onMouseOut( event:MouseEvent ):void
        {
            mouseOver = false;
            update();
        }
						
		
		protected function onResize( event:Event ):void
		{
            geometry.width = width;
            geometry.height = height;

		    update();
		}

		
		
		protected var mouseOver:Boolean = false;

		protected var button:Canvas = new Canvas;
        protected var geometry:RoundControl;
	
		protected static const attributeName:String = "value";
    }
}