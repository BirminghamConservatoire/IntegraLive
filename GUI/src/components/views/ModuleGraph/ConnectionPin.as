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
	import components.model.ModuleInstance;
	import components.model.userData.ColorScheme;
	
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	
	import spark.components.Label;

	public class ConnectionPin extends Canvas
	{
		public function ConnectionPin( moduleID:int, attributeName:String, isInput:Boolean )
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			_moduleID = moduleID, 
			_attributeName = attributeName;
			
			_isInput = isInput;
			
			_nameLabel = new Label;
			_nameLabel.text = attributeName;
			_nameLabel.setStyle( "textAlign", "center" );
			_nameLabel.setStyle( "verticalCenter", 0 );
			_nameLabel.x = 0;
			_nameLabel.percentWidth = 100;
			
			addEventListener( Event.ADDED, onAdded );
		}


		public function get moduleID():int
		{
			return _moduleID;
		}

		
		public function get attributeName():String
		{
			return _attributeName;
		}


		public function get isInput():Boolean 
		{ 
			return _isInput;
		}

		
		public function get linkPoint():Point
		{
			if( _isInput )
			{
				return new Point( x, y + height / 2 );
			}
			else 
			{
				return new Point( x + width, y + height / 2 );
			}
		}

		
		public function redraw():void
		{
			var leftRadius:Number = _isInput ? cornerRadius: 0;
			var rightRadius:Number = _isInput ? 0 : cornerRadius;

			var colors:Array = [ topBackgroundColor, bottomBackgroundColor ];
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [0x00, 0xFF];

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, Math.PI / 2 );

			graphics.clear();
			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
			graphics.drawRoundRectComplex( 0, 0, width, height, leftRadius, rightRadius, leftRadius, rightRadius );
			graphics.endFill();
		}


		override public function styleChanged( style:String ):void
		{
			if( !style || style == "color" )
			{
				invalidateDisplayList();
			}

			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						borderColor = 0x808080;
						topBackgroundColor = 0xcfcfcf;
						bottomBackgroundColor = 0xe4e4e4;
						break;
						
					case ColorScheme.DARK:
						borderColor = 0x808080;
						topBackgroundColor = 0x313131;
						bottomBackgroundColor = 0x1c1c1c;
						break;
				}
				
				redraw();
			}
		}
		
		
		private function onAdded( event:Event ):void
		{
			if( !_nameLabel.parent )
			{
				addChild( _nameLabel );
			}
		}

		private var _moduleID:int;		
		private var _attributeName:String;		
		private var _isInput:Boolean = false;
		private var _nameLabel:Label;

		private var borderColor:uint = 0x808080;
		private var topBackgroundColor:uint = 0x313131;
		private var bottomBackgroundColor:uint = 0x1c1c1c;

		private static const borderThickness:Number = 0;
		private static const cornerRadius:int = 10;
	}
}