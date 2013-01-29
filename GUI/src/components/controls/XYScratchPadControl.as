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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import components.controlSDK.core.*;
	import components.controlSDK.HelperClasses.AttributeLabel;
	

	public class XYScratchPadControl extends IntegraControl
	{
		public function XYScratchPadControl( controlManager:ControlManager )
		{
			super( controlManager );
			
			registerAttribute( _xAttributeName, ControlAttributeType.NUMBER );
			registerAttribute( _yAttributeName, ControlAttributeType.NUMBER );

			_xAttributeLabel = new AttributeLabel( _xAttributeName, true );
			_xAttributeLabel.setStyle( "left", _axisMargin );
			_xAttributeLabel.setStyle( "right", 0 );
			_xAttributeLabel.setStyle( "bottom", 0 );
			_xAttributeLabel.height = _labelHeight;
			_xAttributeLabel.setStyle( "horizontalAlign", "right" );

			_yAttributeLabel = new AttributeLabel( _yAttributeName, true );
			_yAttributeLabel.setStyle( "left", _axisMargin );
			_yAttributeLabel.setStyle( "right", _axisMargin );
			_yAttributeLabel.setStyle( "top", 0 );
			_yAttributeLabel.height = _labelHeight;
			_yAttributeLabel.setStyle( "horizontalAlign", "left" );

			addChild( _xAttributeLabel );
			addChild( _yAttributeLabel );
			
			addEventListener( Event.RESIZE, onResize );

			_display = new Canvas();
			
			addChild( _display );
		}


		override public function get defaultSize():Point { return new Point( 240, 240 ); }
		override public function get minimumSize():Point { return new Point( 160, 160 ); }
		override public function get maximumSize():Point { return new Point( 1000, 1000 ); }


		override public function onValueChange( changedValues:Object ):void
		{
			if( changedValues.hasOwnProperty( _xAttributeName ) )
			{
				_x = changedValues[ _xAttributeName ];
			}
			
			if( changedValues.hasOwnProperty( _yAttributeName ) )
			{
				_y = changedValues[ _yAttributeName ];
			}
			
			update();
		}


		override public function isActiveArea( point:Point ):Boolean
		{
			return graphArea.containsPoint( point );
		}


		override public function onMouseDown( event:MouseEvent ):void
		{
			_xAtClick = _x;
			_yAtClick = _y;
				
			startMouseDrag();
			onDrag( event );
		}


		override public function onDrag( event:MouseEvent ):void
		{
			var graphArea:Rectangle = this.graphArea;
			if( Math.min( graphArea.width, graphArea.height ) <= 0 )
			{
				Assert.assertTrue( false );
				return;
			} 

			var newX:Number = ( mouseX - graphArea.left ) / graphArea.width;
			var newY:Number = ( graphArea.bottom - mouseY ) / graphArea.height;

			newX = Math.max( 0, Math.min( 1, newX ) );     
			newY = Math.max( 0, Math.min( 1, newY ) );     

			var anythingChanged:Boolean = false;			
			var changedValues:Object = new Object;
			if( newX != _x && isAttributeWritable( _xAttributeName ) )
			{	
				changedValues[ _xAttributeName ] = newX;
				anythingChanged = true;	
			} 

			if( newY != _y && isAttributeWritable( _yAttributeName ) )
			{			
				changedValues[ _yAttributeName ] = newY;		
				anythingChanged = true;	
			}

			if( anythingChanged )
			{	
				setValues( changedValues );
			}
		}


		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			graphics.clear();
			
			//dimensions			
			var graphArea:Rectangle = this.graphArea;

			/*the following commented code draws extra grids onto the graph area.  I removed it because it 
			clashes with the 'allowed values' grid when allowed values are present.  Another option would be 
			to only draw these extra grids when no allowed values are present  - Leighton Hargreaves 27-07-11*/
			
			/*var boxWidth:Number = graphArea.width / 4.0;
			var boxHeight:Number = graphArea.height / 4.0;
						
			graphics.lineStyle( 1, foregroundColor( 0.05 ) );
			for( var x:int = 0; x < 4; ++x )
			{
				for( var y:int = 0; y < 4; ++y )
				{
					graphics.drawRect( x * boxWidth + _axisMargin, y * boxHeight + _axisMargin, boxWidth, boxHeight );
				}
			}
			
			graphics.lineStyle( 1, foregroundColor( 0.1 ) );
			
			graphics.moveTo( graphArea.x + _axisMargin, graphArea.y + _axisMargin );
			graphics.lineTo( graphArea.width, graphArea.height );
			
			graphics.moveTo( graphArea.x + _axisMargin, graphArea.height );
			graphics.lineTo( graphArea.width, graphArea.y + _axisMargin );*/
			
			//axes			
			graphics.lineStyle( 3, foregroundColor( LOW ) );
			graphics.moveTo( graphArea.left, graphArea.bottom );
			graphics.lineTo( graphArea.left, graphArea.top );
			graphics.lineTo( graphArea.left + _arrowSize, graphArea.top + _arrowSize );
			graphics.moveTo( graphArea.left, graphArea.top );
			graphics.lineTo( graphArea.left - _arrowSize, graphArea.top + _arrowSize );

			graphics.moveTo( graphArea.left, graphArea.bottom );
			graphics.lineTo( graphArea.right, graphArea.bottom);
			graphics.lineTo( graphArea.right - _arrowSize, graphArea.bottom + _arrowSize );
			graphics.moveTo( graphArea.right, graphArea.bottom );
			graphics.lineTo( graphArea.right - _arrowSize, graphArea.bottom - _arrowSize );
			
			//allowed values grid
			var allowedXValues:Vector.<Object> = getAllowedValues( _xAttributeName );
			if( allowedXValues )
			{
				graphics.lineStyle( 1, foregroundColor( 0.1 ) );
				for each( var xAllowedValue:Number in allowedXValues )
				{
					if( xAllowedValue == 0 ) 
					{
						continue;	
					}
					
					var xPixels:Number = graphArea.left + xAllowedValue * graphArea.width;
					
					graphics.moveTo( xPixels, graphArea.bottom - 1 );
					graphics.lineTo( xPixels, graphArea.top );
				}
			}

			var allowedYValues:Vector.<Object> = getAllowedValues( _yAttributeName );
			if( allowedYValues )
			{
				graphics.lineStyle( 1, foregroundColor( 0.1 ) );
				for each( var yAllowedValue:Number in allowedYValues )
				{
					if( yAllowedValue == 0 ) 
					{
						continue;	
					}
					
					var yPixels:Number = graphArea.bottom - yAllowedValue * graphArea.height;
					
					graphics.moveTo( graphArea.left + 1, yPixels );
					graphics.lineTo( graphArea.right, yPixels );
				}
			}
		}


		private function update():void
		{
			invalidateDisplayList();

			var graphArea:Rectangle = this.graphArea;

			//dial

			var currentX:Number = graphArea.left + _x * graphArea.width;			
			var currentY:Number = graphArea.bottom - _y * graphArea.height;
			
			_display.graphics.clear();
			_display.graphics.lineStyle( 1, foregroundColor( MEDIUM ) );
			_display.graphics.moveTo( graphArea.left, currentY ); 
			_display.graphics.lineTo( currentX, currentY );
			_display.graphics.lineTo( currentX, graphArea.bottom );

			_display.graphics.lineStyle( 3, foregroundColor( FULL ) );
			_display.graphics.moveTo( currentX - _displayCrossSize, currentY - _displayCrossSize );
			_display.graphics.lineTo( currentX + _displayCrossSize, currentY + _displayCrossSize );
			_display.graphics.moveTo( currentX - _displayCrossSize, currentY + _displayCrossSize );
			_display.graphics.lineTo( currentX + _displayCrossSize, currentY - _displayCrossSize );
			
			setGlow( _display, Math.sqrt( _x * _x + _y * _y ) * Math.SQRT1_2 );
		}


		private function get graphArea():Rectangle
		{
			return new Rectangle( _axisMargin, _axisMargin, width - _axisMargin * 2, height - _axisMargin * 2 );
		}


		private function onResize( event:Event ):void
		{
			update();
		}


		private var _x:Number = 0;
		private var _y:Number = 0;
		private var _xAtClick:Number = 0;
		private var _yAtClick:Number = 0;
		
		private var _xAttributeLabel:AttributeLabel;
		private var _yAttributeLabel:AttributeLabel;
		
		private var _display:Canvas;  

		private static const _xAttributeName:String = "x";
		private static const _yAttributeName:String = "y";

		private static const _labelHeight:Number = 24;
		private static const _axisMargin:Number = 24;
		private static const _arrowSize:Number = 4;
		private static const _displayCrossSize:Number = 10;
	}
}
