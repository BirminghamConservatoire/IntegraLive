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



package components.views.ArrangeView
{
	import components.controller.IntegraController;
	import components.controller.userDataCommands.SetTrackColor;
	import components.model.IntegraModel;
	import components.model.userData.ColorScheme;
	import components.views.MouseCapture;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.managers.PopUpManager;
	
	//import spark.components.Group;
	

	public class TrackColorPicker extends Canvas
	{
		public function TrackColorPicker( model:IntegraModel, controller:IntegraController, parent:DisplayObject )
		{
			super();
			
			Assert.assertNotNull( model );
			Assert.assertNotNull( controller );
			Assert.assertNotNull( parent );
			
			_model = model;
			_controller = controller;
			
			if( !model.selectedTrack )
			{
				Assert.assertTrue( false );
				return;
			} 

			if( !_bitmapData )
			{			
				createBitmapData();
			}
			
			findCurrentPosition();
			
			var position:Point = parent.localToGlobal( new Point( parent.mouseX, parent.mouseY ) );
			x = position.x;
			y = position.y;
			width = diameter;
			height = diameter;
			
			mx.managers.PopUpManager.addPopUp( this, parent, true );
			mx.managers.PopUpManager.bringToFront( this );

			systemManager.stage.addEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.beginBitmapFill( _bitmapData );
			graphics.drawRect( 0, 0, diameter, diameter );
			graphics.endFill();
			
			graphics.lineStyle( borderWidth, borderColor );
			graphics.drawCircle( radius, radius, radius );

			//draw a crosshair			
			graphics.lineStyle( crossHairThickness, 0x000000, 0.2 );

			graphics.moveTo( _currentPosition.x - crossHairGap, _currentPosition.y - crossHairGap );  
			graphics.lineTo( _currentPosition.x - crossHairGap, _currentPosition.y - crossHairLength );  

			graphics.moveTo( _currentPosition.x - crossHairGap, _currentPosition.y - crossHairGap );  
			graphics.lineTo( _currentPosition.x - crossHairLength, _currentPosition.y - crossHairGap );  

			graphics.moveTo( _currentPosition.x + crossHairGap, _currentPosition.y - crossHairGap );  
			graphics.lineTo( _currentPosition.x + crossHairGap, _currentPosition.y - crossHairLength );  

			graphics.moveTo( _currentPosition.x + crossHairGap, _currentPosition.y - crossHairGap );  
			graphics.lineTo( _currentPosition.x + crossHairLength, _currentPosition.y - crossHairGap );  

			graphics.moveTo( _currentPosition.x - crossHairGap, _currentPosition.y + crossHairGap );  
			graphics.lineTo( _currentPosition.x - crossHairGap, _currentPosition.y + crossHairLength );  

			graphics.moveTo( _currentPosition.x - crossHairGap, _currentPosition.y + crossHairGap );  
			graphics.lineTo( _currentPosition.x - crossHairLength, _currentPosition.y + crossHairGap );  

			graphics.moveTo( _currentPosition.x + crossHairGap, _currentPosition.y + crossHairGap );  
			graphics.lineTo( _currentPosition.x + crossHairGap, _currentPosition.y + crossHairLength );  

			graphics.moveTo( _currentPosition.x + crossHairGap, _currentPosition.y + crossHairGap );  
			graphics.lineTo( _currentPosition.x + crossHairLength, _currentPosition.y + crossHairGap );  
		} 
		
		
		private function createBitmapData():void
		{
			const greyBrightness:Number = 0.5;
			const overallBrightness:Number = 0.5;
			
			_bitmapData = new BitmapData( diameter, diameter, true, 0x00FFFFFF );
			
			Assert.assertTrue( radius > 0 );
			var radiusInverse:Number = 1 / ( radius - borderWidth ); 
			
			for( var x:int = 0; x < diameter; x++ )
			{
				for( var y:int = 0; y < diameter; y++ )
				{
					var centeredX:int = x - radius;
					var centeredY:int = y - radius;
					
					var myRadius:Number = Math.sqrt( centeredX * centeredX + centeredY * centeredY );
					
					if( myRadius > radius )
					{
						continue;
					}   
					
					var bearing:Number = Math.atan2( centeredY, centeredX );
					var red:Number = Math.cos( bearing ) * 0.5 + 0.5;
					var green:Number = Math.cos( bearing + Math.PI * 2 / 3 ) * 0.5 + 0.5;
					var blue:Number = Math.cos( bearing + Math.PI * 4 / 3 ) * 0.5 + 0.5;
					
					var saturation:Number = myRadius * radiusInverse;
					var saturationOpposite:Number = 1 - saturation;
					
					red = red * saturation + greyBrightness * saturationOpposite;
					green = green * saturation + greyBrightness * saturationOpposite;
					blue = blue * saturation + greyBrightness * saturationOpposite;
					
					if( overallBrightness > 0.5 )
					{
						var lightening:Number = 2 - ( overallBrightness * 2 ); 
						red = 1 - lightening * ( 1 - red );
						green = 1 - lightening * ( 1 - green );
						blue = 1 - lightening * ( 1 - blue );
					}
					else
					{
						var darkening:Number = overallBrightness * 2;
						red *= darkening;
						green *= darkening;
						blue *= darkening;
					}
					
					
					red = Math.max( 0, Math.min( 1, red ) );
					green = Math.max( 0, Math.min( 1, green ) );
					blue = Math.max( 0, Math.min( 1, blue ) );
					
					var color:uint = ( 0xff << 24 ) + 
										( uint( red * 255 ) << 16 ) + 
										( uint( green * 255 ) << 8 ) + 
										uint( blue * 255 );
				
					_bitmapData.setPixel32( x, y, color );  
				}
			}
		}
		
		
		private function findCurrentPosition():void
		{
			var color:uint = _model.selectedTrack.userData.color;
			
			var smallestDifference:uint = 0xffffff;

			for( var x:int = 0; x < diameter; x++ )
			{
				for( var y:int = 0; y < diameter; y++ )
				{
					var pixelColor:uint = _bitmapData.getPixel32( x, y );
					var pixelAlpha:uint = ( ( pixelColor & 0xff000000 ) >> 24 );
					pixelColor = ( pixelColor & 0xffffff );
					
					if( pixelAlpha <= 0 )
					{
						continue;
					}
					
					var difference:uint = getColorDifference( color, pixelColor );
					if( difference < smallestDifference )
					{
						smallestDifference = difference;
						_currentPosition.x = x;
						_currentPosition.y = y;
					}
				}
			}
		}
		
		
		private function getColorDifference( color1:uint, color2:uint ):uint
		{
			var red1:uint = ( ( color1 & 0xff0000 ) >> 16 );
			var red2:uint = ( ( color2 & 0xff0000 ) >> 16 );
			
			var green1:uint = ( ( color1 & 0x00ff00 ) >> 8 );
			var green2:uint = ( ( color2 & 0x00ff00 ) >> 8 );

			var blue1:uint = ( color1 & 0x0000ff );
			var blue2:uint = ( color2 & 0x0000ff );

			return Math.abs( red1 - red2 ) + Math.abs( green1 - green2 ) + Math.abs( blue1 - blue2 );  			
		}
		
		
		private function onDrag( event:MouseEvent ):void
		{
			if( setColorFromMouse() )
			{
				return
			}
			else
			{
				setColorFromOutOfBoundsMouse();
			}
		}


		private function onDragFinished():void
		{
			close();
		}


		private function onStageMouseDown( event:MouseEvent ):void
		{
			if( setColorFromMouse() )
			{
				MouseCapture.instance.setCapture( this, onDrag, onDragFinished );
			}
			else
			{  
				close();
			}			
		}
		
		
		private function setColorFromMouse():Boolean
		{
			if( mouseX < 0 || mouseX >= diameter || mouseY < 0 || mouseY >= diameter )
			{
				return false;
			}

			var color:uint = _bitmapData.getPixel32( mouseX, mouseY );
			var alpha:uint = ( color & 0xff000000 ) >> 24;
			color = color & 0xffffff;
			
			if( alpha <= 0 )
			{
				return false;
			}

			Assert.assertNotNull( _model.selectedTrack );
			_controller.processCommand( new SetTrackColor( _model.selectedTrack.id, color ) );

			_currentPosition.x = mouseX;
			_currentPosition.y = mouseY;
			
			invalidateDisplayList();
			
			return true;
		}
		
		
		private function setColorFromOutOfBoundsMouse():void
		{
			var xVector:Number = mouseX - radius;
			var yVector:Number = mouseY - radius;
			var vectorLength:Number = Math.sqrt( xVector * xVector + yVector * yVector );
			Assert.assertTrue( vectorLength > 0 );
			xVector /= vectorLength;
			yVector /= vectorLength;
			
			var point:Point = new Point( radius, radius );
			
			var color:uint = 0;
			
			while( true )
			{
				point.x += xVector;
				point.y += yVector;

				if( point.x < 0 || point.y < 0 || point.x >= diameter || point.y >= diameter )
				{
					break;
				}
				
				var newColor:uint = _bitmapData.getPixel32( int( point.x ), int( point.y ) );
				var alpha:uint = ( newColor & 0xff000000 ) >> 24;
				newColor = newColor & 0xffffff;
			
				if( alpha > 0 && newColor != borderColor )
				{
					color = newColor;
				}
				else
				{
					break;
				}
			}    
			
			Assert.assertNotNull( _model.selectedTrack );
			_controller.processCommand( new SetTrackColor( _model.selectedTrack.id, color ) );

			_currentPosition.x = point.x - xVector;
			_currentPosition.y = point.y - yVector;
			
			invalidateDisplayList();
		}
		
		
		private function close():void
		{
			systemManager.stage.removeEventListener( MouseEvent.MOUSE_DOWN, onStageMouseDown );

			mx.managers.PopUpManager.removePopUp( this );
		}


		private var _model:IntegraModel;
		private var _controller:IntegraController;
		
		private var _currentPosition:Point = new Point();

		private static var _bitmapData:BitmapData = null;
		
		private static const diameter:int = 128;
		private static const crossHairThickness:Number = 2;
		private static const crossHairGap:Number = 2;
		private static const crossHairLength:Number = 12;
		
		private static const radius:Number = diameter / 2;

		private static const borderWidth:Number = 3;
		private static const borderColor:uint = 0x808080;
	}
}