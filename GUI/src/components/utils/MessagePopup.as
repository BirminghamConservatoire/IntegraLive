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


package components.utils
{
	import flash.events.Event;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	
	import spark.components.Label;
	
	public class MessagePopup extends Canvas
	{
		public function MessagePopup()
		{
			super();

			height = _height;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			_label.setStyle( "left", _height );
			_label.setStyle( "right", 0 );
			_label.setStyle( "textAlign", "center" );
			_label.setStyle( "verticalCenter", 0 );
			_label.setStyle( "color", 0x212b34 );
			addChild( _label ); 
			
			addEventListener( Event.ENTER_FRAME, onFrame );
		}
		
		
		public function set message( message:String ):void
		{
			_label.text = message;
		
			_label.validateSize();
			
			width = Math.max( _label.measuredWidth + _height * 2, 300 );
			
			invalidateDisplayList();
		}
		

		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( 2, 0x10a1f0 ); 
			graphics.beginFill( 0xb5d0e1 );
			graphics.drawRoundRect( 0, 0, width, height, 10, 10 );
			graphics.endFill();
			
			drawWaitingImage();
		}
		
		
		private function drawWaitingImage():void
		{
			const numberOfSegments:int = 12;
			const segmentGap:Number = 1;
			
			var center:Point = new Point( height / 2, height / 2 );
			var innerRadius:Number = height / 6;
			var outerRadius:Number = height / 4;
			
			graphics.lineStyle();
			
			for( var i:int = 0; i < numberOfSegments; i++ )
			{
				var isDarkerSegment:Boolean = ( i == _darkSegment );
				var angle1:Number = i * Math.PI * 2 / numberOfSegments;
				var angle2:Number = ( i + 1 ) * Math.PI * 2 / numberOfSegments;
				
				var outwardVector1:Point = new Point( Math.cos( angle1 ), Math.sin( angle1 ) );
				var outwardVector1Short:Point = outwardVector1.clone();
				var outwardVector1Long:Point = outwardVector1.clone();
				outwardVector1Short.normalize( innerRadius );
				outwardVector1Long.normalize( outerRadius );
				
				var crossVector1:Point = new Point( -outwardVector1.y, outwardVector1.x );
				crossVector1.normalize( segmentGap );
				
				var outwardVector2:Point = new Point( Math.cos( angle2 ), Math.sin( angle2 ) );
				var outwardVector2Short:Point = outwardVector2.clone();
				var outwardVector2Long:Point = outwardVector2.clone();
				outwardVector2Short.normalize( innerRadius );
				outwardVector2Long.normalize( outerRadius );
				
				var crossVector2:Point = new Point( -outwardVector2.y, outwardVector2.x );
				crossVector2.normalize( segmentGap );
				
				graphics.beginFill( 0x10a1f0, isDarkerSegment ? 1 : 0.5 );
				
				var point1:Point = center.add( outwardVector1Short ).add( crossVector1 );
				var point2:Point = center.add( outwardVector1Long ).add( crossVector1 );
				var point3:Point = center.add( outwardVector2Long ).subtract( crossVector2 );
				var point4:Point = center.add( outwardVector2Short ).subtract( crossVector2 );
				
				graphics.moveTo( point1.x, point1.y );
				graphics.lineTo( point2.x, point2.y );
				graphics.lineTo( point3.x, point3.y );
				graphics.lineTo( point4.x, point4.y );
				graphics.lineTo( point1.x, point1.y );
				
				graphics.endFill();
			}
			
			_darkSegment = ( _darkSegment + 1 ) % numberOfSegments;
		}
	
		
		private function onFrame( event:Event ):void
		{
			invalidateDisplayList();
		}
		

		private var _label:Label = new Label;
		private var _darkSegment:int = 0;
		private const _height:Number = 80;
	}
}