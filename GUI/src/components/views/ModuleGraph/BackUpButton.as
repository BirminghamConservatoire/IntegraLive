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


package components.views.ModuleGraph
{
	import components.utils.Utilities;
	import components.views.MouseCapture;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	

	public class BackUpButton extends Canvas
	{
		public function BackUpButton()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			_label.editable = false; 
			_label.focusEnabled = false;
			_label.selectable = false;
			_label.horizontalScrollPolicy = ScrollPolicy.OFF;
			_label.verticalScrollPolicy = ScrollPolicy.OFF;
			_label.percentWidth = 100;
			_label.percentHeight = 45;
			_label.setStyle( "bottom", 0 );
			_label.setStyle( "backgroundColor", null );
			_label.setStyle( "borderStyle", "none" );
			_label.setStyle( "textAlign", "left" );
			
			addChild( _label );

			updateFilter();
			
			addEventListener( Event.RESIZE, onResize );
			
			addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
			addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}
		
		
		public function set backUpButtonLabel( label:String ):void 
		{
			_label.text = label; 
		}
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == "color" )
			{
				invalidateDisplayList();
			}			
		}


		override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );

            graphics.clear();

			var color:uint = getStyle( "color" );
			var thickness:Number = _over || _pressed ? 2 : 1;
			
			graphics.lineStyle( thickness, color );
			graphics.beginFill( color, 0.5 );
			graphics.moveTo( width * 0.15, 0 );
			graphics.lineTo( width * 0.3, height * 0.15 );
			graphics.lineTo( width * 0.2, height * 0.15 );
			graphics.lineTo( width * 0.2, height * 0.3 );
			graphics.lineTo( width * 0.5, height * 0.3 );
			graphics.lineTo( width * 0.5, height * 0.4 );
			graphics.lineTo( width * 0.1, height * 0.4 );
			graphics.lineTo( width * 0.1, height * 0.15 );
			graphics.lineTo( 0, height * 0.15 );
			graphics.lineTo( width * 0.15, 0 );
			graphics.endFill();	
        }
        
        
        private function onResize( event:Event ):void
        {
        	invalidateDisplayList();
        }
        
        
        private function onMouseDown( event:MouseEvent ):void
        {
        	event.stopPropagation();
        	
       		MouseCapture.instance.setCapture( this, onCapturedDrag, onCaptureFinished );
       		_pressed = true;
       		updateFilter();
       		invalidateDisplayList();
        }
        
        
        private function onMouseOver( event:MouseEvent ):void
        {
        	_over = true;
       		invalidateDisplayList();
        }


        private function onMouseOut( event:MouseEvent ):void
        {
        	_over = false;
       		invalidateDisplayList();
        }


		private function onCapturedDrag( event:MouseEvent ):void
		{
			var pressed:Boolean = Utilities.pointIsInRectangle( getRect( this ), mouseX, mouseY );
			
			if( pressed != _pressed )
			{
				_pressed = pressed;
				updateFilter();
	       		invalidateDisplayList();
			} 
		}


		private function onCaptureFinished():void
		{
			if( _pressed )
			{
				_pressed = false;
				updateFilter();
	       		invalidateDisplayList();
			}			
		}


		private function updateFilter():void
		{
			var filterArray:Array = new Array;
			filterArray.push( new GlowFilter( getStyle( "color" ), 0.6, 10, 10, _pressed ? 2 : 1 ) );
			filters = filterArray;
		}
		
		private var _pressed:Boolean = false;
		private var _over:Boolean = false;

		private var _label:TextArea = new TextArea;
	}
}
