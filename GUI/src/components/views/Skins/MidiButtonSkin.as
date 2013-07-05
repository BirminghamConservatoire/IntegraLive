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



package components.views.Skins
{
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import mx.skins.halo.ButtonSkin;
	
	import components.model.userData.ColorScheme;
	
	import flexunit.framework.Assert;
	
	
	public class MidiButtonSkin extends ButtonSkin
	{
		public function MidiButtonSkin()
		{
			super();
			
			addEventListener( Event.ENTER_FRAME, onFrame );
		}
		
		
		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			graphics.clear();
			
			var nameLower:String = name.toLowerCase();
			
			var over:Boolean = ( nameLower.indexOf( "over" ) >= 0 );
			var selected:Boolean = ( nameLower.indexOf( "selected" ) >= 0 );
			var down:Boolean = ( nameLower.indexOf( "down" ) >= 0 );
			var disabled:Boolean = ( nameLower.indexOf( "disabled" ) >= 0 );
			
			var weakColor:uint;
			var strongColor:uint;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					weakColor = 0x747474;
					strongColor = 0x313131;
					break;
				
				case ColorScheme.DARK:
					weakColor = 0x8c8c8c;
					strongColor = 0xcfcfcf;
					break;
			}
			
			var color:uint = getStyle( "color" );
			if( color == 0 ) color = weakColor;
			
			var diameter:Number = Math.min( width, height );
			var radius:Number = diameter / 2;
			
			var borderColor:uint = ( over || down ) ? strongColor : weakColor;
			graphics.lineStyle( 1, borderColor, disabled ? 0.5 : 1 );
			
			var fillAlpha:Number = 0.2;
			if( selected )
			{
				fillAlpha = Math.sin( getTimer() * Math.PI * 2 / flashPeriod ) * 0.5 + 0.5;
			}
			
			graphics.beginFill( disabled ? weakColor : color, fillAlpha );
			graphics.drawCircle( radius, radius, radius );
			graphics.endFill();
			
			//draw the midi pins
			var pinHeadDistance:Number = radius * 0.55;
			var pinHeadRadius:Number = 0.6;
			var circleCenter:Point = new Point( radius, radius );
			graphics.lineStyle( 0, strongColor );
			
			for( var i:int = 0; i < 5; i++ )
			{
				var theta:Number = i * Math.PI / 4;
				var vector:Point = new Point( Math.cos( theta ), Math.sin( theta ) );
				
				var pinOffset:Point = new Point( vector.x * pinHeadDistance, vector.y * pinHeadDistance );
				var pinPosition:Point = circleCenter.add( pinOffset );
				
				graphics.beginFill( strongColor );
				graphics.drawCircle( pinPosition.x, pinPosition.y, pinHeadRadius );
			}	

			//update the glow
			var filterArray:Array = new Array;
			if( down )
			{
				filterArray.push( new GlowFilter( color, 0.6, 10, 10, 3 ) );
			}	
			filters = filterArray;
		}
		
		
		
		
		/*override protected function updateDisplayList( width:Number, height:Number ):void
		{
			graphics.clear();
			
			var edgeThickness:int = 1;
			var isLit:Boolean = false;
			var glow:Boolean = false;
			var flash:Boolean = false;
			var glowStrength:int = 2;
			
			switch( name )
			{
				case "skin":
					break;
				
				case "upSkin":
					break;
				
				case "overSkin":
					edgeThickness = 2;
					break;
				
				case "downSkin":
					isLit = true;
					glow = true;
					break;
				
				case "selectedUpSkin":
					isLit = true;
					glow = true;
					flash = true;
					break;
				
				case "selectedOverSkin":
					isLit = true;
					glow = true;
					flash = true;
					glowStrength++;
					break;
				
				case "selectedDownSkin":
					edgeThickness = 2;
					break;
				
				case "disabledSkin":
				case "selectedDisabledSkin":
				default:
					Assert.assertTrue( false );
					break;
			}			
			
			var color:uint = getStyle( "color" );
			var radius:Number = Math.min( width, height ) / 2;
			
			graphics.lineStyle( edgeThickness, borderColor );
			
			var fillAlpha:Number = 0;
			if( isLit )
			{
				if( flash )
				{
					fillAlpha = Math.sin( getTimer() * Math.PI * 2 / flashPeriod ) * 0.5 + 0.5;
				}
				else
				{
					fillAlpha = 1;
				}
			}
			graphics.beginFill( color, fillAlpha );
			graphics.drawCircle( radius, radius, radius );
			graphics.endFill();
			
			//draw the midi pins
			var pinHeadDistance:Number = radius * 0.55;
			var pinHeadRadius:Number = 0.6;
			var circleCenter:Point = new Point( radius, radius );
			graphics.lineStyle( 0, borderColor );
			
			for( var i:int = 0; i < 5; i++ )
			{
				var theta:Number = i * Math.PI / 4;
				var vector:Point = new Point( Math.cos( theta ), Math.sin( theta ) );
				
				var pinOffset:Point = new Point( vector.x * pinHeadDistance, vector.y * pinHeadDistance );
				var pinPosition:Point = circleCenter.add( pinOffset );
				
				graphics.beginFill( borderColor );
				graphics.drawCircle( pinPosition.x, pinPosition.y, pinHeadRadius );
			}	
			
			//update the glow
			var filterArray:Array = new Array;
			if( glow )
			{
				filterArray.push( new GlowFilter( color, 0.6, 10, 10, glowStrength ) );
			}	
			filters = filterArray;
		}*/

		
		private function onFrame( event:Event ):void
		{
			switch( name )
			{
				case "selectedUpSkin":
				case "selectedOverSkin":
					invalidateDisplayList();
					break;
				
				default:
					break;
			}			
		}
		
		
		private static const flashPeriod:Number = 250;
	}
}


