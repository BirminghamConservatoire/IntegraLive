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


package components.views.RibbonBar
{
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.MouseCapture;
	
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	
	import spark.components.Label;
	

	public class RibbonButton extends Canvas
	{
		public function RibbonButton()
		{
			super();
			
			_label.setStyle( "horizontalCenter", 0 );
			_label.setStyle( "verticalCenter", 0 );
			addElement( _label );
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;

			updateFilters();
			
			addEventListener( Event.RESIZE, onResize );
			
			addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
			addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}
		
		
		public function set ribbonButtonLabel( label:String ):void 
		{
			_label.text = label; 
		}
		
		
		public function set ribbonButtonIcon( icon:String ):void
		{
			_icon = icon;
			invalidateDisplayList();	
		}
		
		
		public function set selected( selected:Boolean ):void 
		{ 
			_selected = selected;
			updateIconColor();
			updateFilters();
			invalidateDisplayList(); 
		}


		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				updateIconColor();
				invalidateDisplayList(); 
				updateFilters();
			}			

			if( !style || style == FontSize.STYLENAME )
			{
				height = FontSize.getTextRowHeight( this );

				_label.setStyle( FontSize.STYLENAME, getStyle( FontSize.STYLENAME ) );
				
				//trick the label into remeasuring its length
				var prevLabel:String = _label.text;
				_label.text = null;
				_label.validateNow();
				_label.text = prevLabel;
				_label.validateNow();
				
				//width = height + _label.textWidth;  // FL4U
				width = height + _label.text.length * 8;
			}			
		}


		override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );

            graphics.clear();

			var rimBackgroundColor:uint;
			var middleBackgroundColor:uint;

			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					rimBackgroundColor = _selected ? 0x959595 : 0xCECECE;
					middleBackgroundColor = _selected ? 0xC8C8C8 : 0xEDEDED;
					break;
					
				case ColorScheme.DARK:
					rimBackgroundColor = _selected ? 0x6B6B6B : 0x313131;
					middleBackgroundColor = _selected ? 0x383838 : 0x121212;
					break;
			}
			
			var colors:Array = [ rimBackgroundColor, middleBackgroundColor, rimBackgroundColor ];
			var alphas:Array = [ 1, 1, 1 ];
			var ratios:Array = [0x00, 0x80, 0xFF];

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, Math.PI / 2 );

			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
			graphics.drawRoundRect( 0, 0, width, height, height / 4, height / 4 );
			graphics.endFill();
			
			switch( _icon )
			{
				case RIBBONICON_PLAY:
					drawPlayIcon( width, height );
					break;
					
				case RIBBONICON_PAUSE:
					drawPauseIcon( width, height );
					break;
					
				case RIBBONICON_LIGHT:
					drawLightIcon( width, height );
					break;
					
				case RIBBONICON_NONE:
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}	
        }


		private function drawPlayIcon( width:Number, height:Number ):void
		{
			graphics.beginFill( _iconColor );
			graphics.moveTo( width/3, height/3 );			
			graphics.lineTo( width*2/3, height/2 );
			graphics.lineTo( width/3, height*2/3 );
			graphics.lineTo( width/3, height/3 );
			graphics.endFill();			
		}


		private function drawPauseIcon( width:Number, height:Number ):void
		{
			graphics.beginFill( _iconColor );
			graphics.drawRect( width/3, height/3, width/9, height/3 );
			graphics.endFill();

			graphics.beginFill( _iconColor );
			graphics.drawRect( width*5/9, height/3, width/9, height/3 );
			graphics.endFill();
		}


		private function drawLightIcon( width:Number, height:Number ):void
		{
			var lightColor:uint;

			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					lightColor = 0xFFFFFF;
					break;
					
				case ColorScheme.DARK:
					lightColor = 0xC0C0C0;
					break;
			}

			graphics.lineStyle( 2, lightColor );
			graphics.drawRect( width * 0.4, height * 0.7, width * 0.2, height * 0.1 );
			graphics.drawCircle( width * 0.5, height * 0.5, height * 0.2 );
			
			graphics.lineStyle( 1, lightColor );
			graphics.moveTo( width * 0.5, height * 0.7 );
			graphics.curveTo( width * 0.35, height * 0.35, width * 0.45, height * 0.5 );
		
			graphics.moveTo( width * 0.5, height * 0.7 );
			graphics.curveTo( width * 0.65, height * 0.3, width * 0.55, height * 0.5 );
			graphics.curveTo( width * 0.5, height * 0.6, width * 0.45, height * 0.5 );
		}
       
        
        private function updateIconColor():void
        {
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					_iconColor = _selected ? 0x000000 : 0x808080;
					break;
					
				case ColorScheme.DARK:
					_iconColor = _selected ? 0xffffff : 0x808080;
					break;
			}
			
			_label.setStyle( "color", _iconColor );
        }
        
        
        private function onResize( event:Event ):void
        {
        	invalidateDisplayList();
        }
        
        
        private function onMouseDown( event:MouseEvent ):void
        {
       		MouseCapture.instance.setCapture( this, onCapturedDrag, onCaptureFinished );
       		_pressed = true;
       		updateFilters();
        }
        
        
        private function onMouseOver( event:MouseEvent ):void
        {
        	_over = true;
       		updateFilters();
        }


        private function onMouseOut( event:MouseEvent ):void
        {
        	_over = false;
       		updateFilters();
        }


		private function onCapturedDrag( event:MouseEvent ):void
		{
			var pressed:Boolean = Utilities.pointIsInRectangle( getRect( this ), mouseX, mouseY );
			
			if( pressed != _pressed )
			{
				_pressed = pressed;
				updateFilters();
			} 
		}


		private function onCaptureFinished():void
		{
			if( _pressed )
			{
				_pressed = false;
				updateFilters();
			}			
		}


		private function updateFilters():void
		{
			var highlightColor:uint;
			var shadowColor:uint;

			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					highlightColor = 0x909090;
					shadowColor = 0xf0f0f0;
					break;
					
				case ColorScheme.DARK:
					highlightColor = 0x707070;
					shadowColor = 0x101010;
					break;
			}		
			
			var down:Boolean = _pressed || _selected;
			
			var filterArray:Array = new Array;

			var bevel:BevelFilter = new BevelFilter( _pressed ? 1 : 2, 45, highlightColor, 0.5, shadowColor, 0.5 );
			filterArray.push( bevel );
			
			if( _over || _selected )
			{
				var glow:GlowFilter = new GlowFilter( 0x808080, 0.6, 10, 10, 1.5 );
				filterArray.push( glow );
			}
			
			filters = filterArray;
		}
		
		private var _pressed:Boolean = false;
		private var _selected:Boolean = false;
		private var _over:Boolean = false;

		private var _label:Label = new Label;
		private var _icon:String = RIBBONICON_NONE;

		private var _iconColor:uint = 0;

		public static const RIBBONICON_PLAY:String = "play";
		public static const RIBBONICON_PAUSE:String = "pause";
		public static const RIBBONICON_LIGHT:String = "light";
		public static const RIBBONICON_NONE:String = "none";
	}
}