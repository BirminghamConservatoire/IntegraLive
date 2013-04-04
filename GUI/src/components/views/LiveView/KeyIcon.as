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


package components.views.LiveView
{
	import components.model.userData.ColorScheme;
	
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.filters.BevelFilter;
	import flash.geom.Matrix;
	
	import mx.core.ScrollPolicy;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.Label;
	
	public class KeyIcon extends Canvas
	{
		public function KeyIcon()
		{
			super();

			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			_keyLabel.x = _keyLabelOffset;
			_keyLabel.y = _keyLabelOffset;
			addChild( _keyLabel );

			alpha = _fillerAlpha;
			
			updateBevelFilter();
			
			addEventListener( Event.RESIZE, onResize );
		}
		
		
		public static function get highlightThickness():int { return _highlightThickness; }
		
		
		public function get keyLabel():String { return _keyLabel.text; }


		public function set keyLabel( keyLabel:String ):void 
		{
			Assert.assertTrue( keyLabel.length == 1 );
			_charCodeValue = keyLabel.charCodeAt( 0 ); 
			_keyLabel.text = keyLabel; 
		}

		
		public function set sceneLabel( sceneLabel:String ):void 
		{ 
			if( sceneLabel.length > 0 )
			{
				if( !_sceneLabel )
				{
					_sceneLabel = new Label;
					_sceneLabel.setStyle( "left", 0 );
					_sceneLabel.setStyle( "right", 0 );
					_sceneLabel.setStyle( "bottom", 0 );
					
					_sceneLabel.setStyle( "textAlign", "center" );
					updateSceneLabelColor();
					updateSceneLabelSize();
					
					addChild( _sceneLabel );
				}
				
				_sceneLabel.text = sceneLabel;
				_enabled = true;
				alpha = 1;
			}
			else
			{
				if( _sceneLabel )
				{
					removeChild( _sceneLabel );
					_sceneLabel = null;
					_enabled = false;
					alpha = _unassignedAlpha; 
				}
			}
		}
		
		
		public function set highlighted( highlighted:Boolean ):void
		{
			if( highlighted != _highlighted )
			{
				_highlighted = highlighted;
				invalidateDisplayList();
			}
		} 


		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_bottomBackgroundColor = 0xefefef;
						_topBackgroundColor = 0xd8d8d8;
						_keyLabel.setStyle( "color", 0x404040 );
						
						if( _sceneLabel )
						{
							_sceneLabel.setStyle( "color", 0xc00000 );
						}
						break;
						
					case ColorScheme.DARK:
						_bottomBackgroundColor = 0x101010;
						_topBackgroundColor = 0x282828;
						_keyLabel.setStyle( "color", 0xc0c0c0 );

						if( _sceneLabel )
						{
							_sceneLabel.setStyle( "color", 0xff4040 );
						}
						break;
				}
				
				if( _sceneLabel )
				{
					updateSceneLabelColor();
				}
				
				invalidateDisplayList();
				
				updateBevelFilter();
			}			
		}


		override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );

            graphics.clear();

			var colors:Array = [ _topBackgroundColor, _bottomBackgroundColor ];
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [0x00, 0xFF];

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, Math.PI / 2 );

			if( _highlighted )
			{
				graphics.lineStyle( _highlightThickness, _highlightColor );
			}

			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
        	graphics.drawRoundRect( 0, 0, width, height, _cornerWidth, _cornerHeight );
        	graphics.endFill();
        }
		
		
		private function updateSceneLabelColor():void
		{
			Assert.assertNotNull( _sceneLabel );
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					_sceneLabel.setStyle( "color", 0xc00000 );
					break;
				
				case ColorScheme.DARK:
					_sceneLabel.setStyle( "color", 0xff4040 );
					break;
			}			
		}
        
		
		private function updateSceneLabelSize():void
		{
			Assert.assertNotNull( _sceneLabel );

			_sceneLabel.height = height / 2;
			
			var sceneLabelFontsize:int = Math.round( height / 6 );
			if( _sceneLabel.getStyle( "fontSize" ) != sceneLabelFontsize )
			{
				_sceneLabel.setStyle( "fontSize", sceneLabelFontsize );
			}
			
		}

		
        private function onResize( event:Event ):void
        {
			var keyLabelFontsize:int = Math.round( height / 3 );
			if( _keyLabel.getStyle( "fontSize" ) != keyLabelFontsize )
			{
				_keyLabel.setStyle( "fontSize", keyLabelFontsize );	
			}

			if( _sceneLabel )
			{
				updateSceneLabelSize();
			}
        }
        
        
		private function updateBevelFilter():void
		{
			var highlightColor:uint;
			var shadowColor:uint;

			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				case ColorScheme.LIGHT:
					highlightColor = 0x909090;
					shadowColor = 0xf0f0f0;
					break;
					
				case ColorScheme.DARK:
					highlightColor = 0x707070;
					shadowColor = 0x101010;
					break;
			}		
			
			var filterArray:Array = new Array;
			var filter:BevelFilter = new BevelFilter( 3, 45, highlightColor, 0.5, shadowColor, 0.5 );
			filterArray.push( filter );
			
			filters = filterArray;
		}


		private var _charCodeValue:uint = 0;
		private var _keyLabel:Label = new Label;
		private var _sceneLabel:Label = null;
		private var _enabled:Boolean = false;
		private var _highlighted:Boolean = false;

		private var _topBackgroundColor:uint = 0;
		private var _bottomBackgroundColor:uint = 0;		
		
		private static const _keyLabelOffset:Number = 2;
		private static const _cornerWidth:Number = 24;
		private static const _cornerHeight:Number = 18;
		
		private static const _highlightColor:uint = 0xff0000;
		private static const _highlightThickness:int = 3;
		
		private static const _unassignedAlpha:Number = 0.4;
		private static const _fillerAlpha:Number = 0.3;
	}
}