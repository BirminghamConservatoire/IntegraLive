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
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	
	import spark.components.Label;
	
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.MouseCapture;
	
	import flexunit.framework.Assert;
	

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
		
		
		public function get selected():Boolean { return _selected; } 
		
		
		public function set selected( selected:Boolean ):void 
		{ 
			_selected = selected;
			updateEverything();
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
		
		
		public function set receivesPulses( receivesPulses:Boolean ):void
		{
			_receivesPulses = receivesPulses; 
			updateIconColor();
			updateFilters();
			invalidateDisplayList(); 
		}

		
		public function pulse():void
		{
			Assert.assertTrue( _receivesPulses );

			if( !_inPulse )
			{
				_inPulse = true;
				addEventListener( Event.ENTER_FRAME, onPulseFrame )
			}

			_pulseStartTicks = getTimer();
			_pulseIntensity = 1;
			updateEverything();
			
		}
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				updateEverything();
			}			

			if( !style || style == FontSize.STYLENAME )
			{
				height = FontSize.getTextRowHeight( this );

				width = height + _label.text.length * 8;
			}			
		}


		override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );

            graphics.clear();

			var strongRimColor:uint, normalRimColor:uint, strongMiddleColor:uint, normalMiddleColor:uint; 
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					strongRimColor = 0x959595;
					normalRimColor = 0xCECECE;
					strongMiddleColor = 0xC8C8C8;
					normalMiddleColor = 0xEDEDED;
					break;
				
				case ColorScheme.DARK:
					strongRimColor = 0x6B6B6B;
					normalRimColor = 0x313131;
					strongMiddleColor = 0x383838;
					normalMiddleColor = 0x121212;
					break;
			}
			
			var rimColor:uint;
			var middleColor:uint;
			
			if( _receivesPulses )
			{
				rimColor = Utilities.interpolateColors( normalRimColor, strongRimColor, _pulseIntensity );
				middleColor = Utilities.interpolateColors( normalMiddleColor, strongMiddleColor, _pulseIntensity );
			}
			else
			{
				rimColor = _selected ? strongRimColor : normalRimColor;
				middleColor = _selected ? strongMiddleColor : normalMiddleColor;
			}

			var colors:Array = [ rimColor, middleColor, rimColor ];
			var alphas:Array = [ 1, 1, 1 ];
			var ratios:Array = [0x00, 0x80, 0xFF];

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, Math.PI / 2 );

			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
			graphics.drawRoundRect( 0, 0, width, height, height / 4, height / 4 );
			graphics.endFill();
			
			switch( _icon )
			{
				case RIBBONICON_HOME:
					drawHomeIcon( width, height );
					break;

				case RIBBONICON_PLAY:
					drawPlayIcon( width, height );
					break;
					
				case RIBBONICON_PAUSE:
					drawPauseIcon( width, height );
					break;
					
				case RIBBONICON_LIGHT:
					drawLightIcon( width, height );
					break;
				
				case RIBBONICON_MIDI:
					drawMidiIcon( width, height );
					break;
					
				case RIBBONICON_NONE:
					break;
					
				default:
					Assert.assertTrue( false );
					break;
			}	
        }
		
		
		private function drawHomeIcon( width:Number, height:Number ):void
		{
			graphics.lineStyle( 1, _iconColor );
			graphics.moveTo( width/3, height/3 );
			graphics.lineTo( width/3, height*2/3 );
			
			graphics.lineStyle( 0, 0, 0 );
			graphics.beginFill( _iconColor );
			graphics.moveTo( width*2/3, height/3 );			
			graphics.lineTo( width/3, height/2 );
			graphics.lineTo( width*2/3, height*2/3 );
			graphics.lineTo( width*2/3, height/3 );
			graphics.endFill();			
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

		
		private function drawMidiIcon( width:Number, height:Number ):void
		{
			var circleRadius:Number = Math.min( width, height ) * 0.3;
			var circleCenter:Point = new Point( width * 0.5, height * 0.5 );
			
			graphics.lineStyle( 1, _iconColor );
			graphics.drawCircle( circleCenter.x, circleCenter.y, circleRadius );
			
			var pinHeadDistance:Number = circleRadius * 0.55;
			var pinHeadRadius:Number = 0.5;
			
			graphics.lineStyle( 0, _iconColor );
			
			for( var i:int = 0; i < 5; i++ )
			{
				var theta:Number = i * Math.PI / 4;
				var vector:Point = new Point( Math.cos( theta ), Math.sin( theta ) );
				
				var pinOffset:Point = new Point( vector.x * pinHeadDistance, vector.y * pinHeadDistance );
				var pinPosition:Point = circleCenter.add( pinOffset );
				
				graphics.beginFill( _iconColor );
				graphics.drawCircle( pinPosition.x, pinPosition.y, pinHeadRadius );
			}
		}

		
		private function updateEverything():void
		{
			updateIconColor();
			invalidateDisplayList(); 
			updateFilters();
		}
		
        
        private function updateIconColor():void
        {
			var strongColor:uint;
			var normalColor:uint;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					strongColor = 0x000000;
					normalColor = 0x808080;
					break;
					
				case ColorScheme.DARK:
					strongColor = 0xffffff;
					normalColor = 0x808080;
					break;
			}
			
			if( _receivesPulses )
			{
				_iconColor = Utilities.interpolateColors( normalColor, strongColor, _pulseIntensity );			
			}
			else
			{
				_iconColor = _selected ? strongColor : normalColor;
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
			
			var glowProportion:Number = 0;
			var glowDistance:Number = 10;
			
			if( _receivesPulses )
			{
				glowProportion = _over ? 1 : _pulseIntensity;
				glowDistance = Math.max( glowDistance, _pulseIntensity * 20 );
			}
			else
			{
				glowProportion = ( _over || _selected ) ? 1 : 0;
			}

			if( glowProportion > 0 )
			{
				var glow:GlowFilter = new GlowFilter( 0x808080, 0.6 * glowProportion, glowDistance, glowDistance, 1.5 );
				filterArray.push( glow );
			}
			
			filters = filterArray;
		}
		
		
		private function onPulseFrame( event:Event ):void
		{
			_pulseIntensity = Math.max( 0, 1 - ( getTimer() - _pulseStartTicks ) / _pulseMilliseconds );
			
			_pulseIntensity = 1 - Math.cos( _pulseIntensity * Math.PI / 2 );	//curve	
			
			updateEverything();
			
			if( _pulseIntensity == 0 )
			{
				_inPulse = false;
				removeEventListener( Event.ENTER_FRAME, onPulseFrame );
			}
		}
		
		
		private var _pressed:Boolean = false;
		private var _selected:Boolean = false;
		private var _over:Boolean = false;

		private var _label:Label = new Label;
		private var _icon:String = RIBBONICON_NONE;

		private var _receivesPulses:Boolean = false;
		
		private var _inPulse:Boolean = false;
		private var _pulseIntensity:Number = 0;
		private var _pulseStartTicks:Number = 0;

		private var _iconColor:uint = 0;
		
		private static const _pulseMilliseconds:Number = 1000;

		public static const RIBBONICON_HOME:String = "home";
		public static const RIBBONICON_PLAY:String = "play";
		public static const RIBBONICON_PAUSE:String = "pause";
		public static const RIBBONICON_LIGHT:String = "light";
		public static const RIBBONICON_MIDI:String = "midi";
		public static const RIBBONICON_NONE:String = "none";
	}
}