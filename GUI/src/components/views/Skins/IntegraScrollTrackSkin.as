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
	import components.model.userData.ColorScheme;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flexunit.framework.Assert;
	import mx.core.Container;
	import mx.core.IChildList;
	import mx.skins.halo.ScrollTrackSkin;

	
	public class IntegraScrollTrackSkin extends ScrollTrackSkin
	{
		public function IntegraScrollTrackSkin()
		{
			super();
		}
		
		
		override public function styleChanged( styleProp:String ):void
		{
			if( !styleProp || styleProp == ColorScheme.STYLENAME )
			{
				invalidateDisplayList();
			}	
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );

			graphics.clear();
			var hasBothSliders:Boolean = decorateWhiteBox();
	
			var fillColor:uint;
			var backgroundColor:uint;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					fillColor = 0xf8f8f8;
					backgroundColor = 0xffffff;
					break;
					
				case ColorScheme.DARK:
					fillColor = 0x080808;
					backgroundColor = 0x000000;
					break;
			}	

			graphics.beginFill( backgroundColor );
			graphics.drawRect( 0, 0, width, height );
			graphics.endFill();			
						
			var cornerRadius:Number = width / 2;
			graphics.beginFill( fillColor );
			graphics.drawRoundRectComplex( 0, 0, width, height, 0, cornerRadius, 0, hasBothSliders ? 0 : cornerRadius );
			graphics.endFill();			
		}
		
		
		private function decorateWhiteBox():Boolean
		{
			for( var ancestor:DisplayObject = parent; ancestor; ancestor = ancestor.parent )
			{
				var container:Container = ancestor as Container;
				if( !container )
				{
					continue;
				}

				var rawChildren:IChildList = container.rawChildren;
				var whiteBox:DisplayObject = rawChildren.getChildByName( "whiteBox" );
				if( !whiteBox )
				{
					return false;
				}

				var whiteBoxShape:Shape = ( whiteBox as Shape );
				Assert.assertNotNull( whiteBoxShape );
				var whiteBoxWidth:Number = whiteBoxShape.width;
				var whiteBoxHeight:Number = whiteBoxShape.height;

				var backgroundColor:uint;
				var curveColor:uint;
			
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						backgroundColor = 0xf8f8f8;
						curveColor = 0xf0f0f0;
						break;
						
					case ColorScheme.DARK:
						backgroundColor = 0x080808;
						curveColor = 0x101010;
						break;
				}	

				whiteBoxShape.graphics.clear();
				whiteBoxShape.graphics.beginFill( backgroundColor );
				whiteBoxShape.graphics.drawRect( 0, 0, whiteBoxWidth, whiteBoxHeight );
				whiteBoxShape.graphics.endFill();
						
				whiteBoxShape.graphics.beginFill( curveColor );
				whiteBoxShape.graphics.drawRoundRectComplex( 0, 0, whiteBoxWidth, whiteBoxHeight, 0, 0, 0, Math.min( whiteBoxWidth, whiteBoxHeight ) );
				whiteBoxShape.graphics.endFill();

				return true;
			}
			
			return false; 	
		}
	}
}