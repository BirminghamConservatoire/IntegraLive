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


package components.views.Timeline
{
	import flash.events.Event;
	
	import mx.containers.Canvas;
	
	public class PlayPositionMarker extends Canvas
	{
		public function PlayPositionMarker( hasTriangle:Boolean, triangleAtTop:Boolean )
		{
			super();
			
			_hasTriangle = hasTriangle;
			_triangleAtTop = triangleAtTop;
			
			addEventListener( Event.RESIZE, onResize );
		}
		
		
		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( 1,  _color, _alpha );
			
			if( _hasTriangle )
			{
				if( _triangleAtTop )
				{
					graphics.moveTo( 0, height );
					graphics.beginFill( _color, _alpha );
					graphics.lineTo( 0, _triangleHeight );
					graphics.lineTo( -_triangleWidth/2, 0 );
					graphics.lineTo( _triangleWidth/2, 0 );
					graphics.lineTo( 0, _triangleHeight );
					graphics.endFill();
				}
				else
				{
					graphics.moveTo( 0, 0 );
					graphics.beginFill( _color, _alpha );
					graphics.lineTo( 0, height - _triangleHeight );
					graphics.lineTo( -_triangleWidth/2, height );
					graphics.lineTo( _triangleWidth/2, height );
					graphics.lineTo( 0, height - _triangleHeight );
					graphics.endFill();
				}
			}
			else
			{
				graphics.moveTo( 0, height );
				graphics.lineTo( 0, 0 );
			}
		} 
		
		
		private function onResize( event:Event ):void
		{
			invalidateDisplayList();			
		}
		
			
		private var _hasTriangle:Boolean = false;
		private var _triangleAtTop:Boolean = false;

		private var _color:uint = 0x808080;
		private var _alpha:Number = 0.5;
		
		private static const _triangleHeight:Number = 8;
		private static const _triangleWidth:Number = 10;
	}
}