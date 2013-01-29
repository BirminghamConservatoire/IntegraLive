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
    import flash.geom.Rectangle;
    import flash.filters.BlurFilter;

    import mx.containers.Canvas;
	import components.controlSDK.core.*;
	import components.controlSDK.BaseClasses.BalanceControl;


    public class DryWetBalanceControl extends BalanceControl
    {
		public function DryWetBalanceControl( controlManager:ControlManager )
		{
		    super( controlManager );
	
		    leftLabelText = "DRY";
		    rightLabelText = "WET";
	
			_waveValues = new Vector.< Number >( 100, true );
			
		    for( var i:int = 0; i < _waveValues.length; ++i )
		    {
				_waveValues[ i ] = 0.4 + Math.random() * 0.4;
		    }
		    
		}
	
		
		override protected function drawBackgroundPicture():void
		{
		    var pictureArea:Rectangle = super.pictureArea;
				
		    var waveSize:Number = int( Math.min( _waveValues.length, ( pictureArea.width * 0.8 ) ) );
		    var waveFade:Number = waveSize * 0.15;
	
		    var horizontalOffset:Number = ( pictureArea.width - waveSize ) / 2;
		    var verticalOffset:Number = pictureArea.height / 2;
	
		    var blur:BlurFilter = new BlurFilter;
	
            var i:int;
            var basicHalfLineLength:Number;
            var halfLineLength:Number;
	
		    // left picture
		    leftPicture.graphics.clear();
	
		    leftPicture.graphics.lineStyle( 1, foregroundColor( MEDIUM ) );
	
		    for( i = 0; i < waveSize; ++i )
		    {
				basicHalfLineLength = _waveValues[ i ] * pictureArea.height / 2;
				halfLineLength = 0.0;
		
				if( i < waveFade )
				{
				    halfLineLength = basicHalfLineLength * ( i / waveFade );
				}
				else if( i > ( waveSize - waveFade ) )
				{
				    halfLineLength = basicHalfLineLength * ( ( waveSize - i ) / waveFade );
				}
				else
				{
				    halfLineLength = basicHalfLineLength; 
				}
					
				leftPicture.graphics.moveTo( horizontalOffset + i, verticalOffset + halfLineLength );
				leftPicture.graphics.lineTo( horizontalOffset + i, verticalOffset - halfLineLength );
		    }
	
		    // right picture
		    rightPicture.graphics.clear();
	
		    rightPicture.graphics.lineStyle( 1, foregroundColor( FULL ) );
	
		    for( i = 0; i < waveSize; ++i )
		    {
				basicHalfLineLength = _waveValues[ i ] * pictureArea.height / 2;
				halfLineLength = 0.0;
		
				if( i < waveFade )
				{
				    halfLineLength = basicHalfLineLength * ( i / waveFade );
				}
				else if( i > ( waveSize - waveFade ) )
				{
				    halfLineLength = basicHalfLineLength * ( ( waveSize - i ) / waveFade );
				}
				else
				{
				    halfLineLength = basicHalfLineLength; 
				}
					
				rightPicture.graphics.moveTo( horizontalOffset + i, verticalOffset - halfLineLength );
				rightPicture.graphics.lineTo( horizontalOffset + i, verticalOffset + halfLineLength );
		    }
	
		    rightPicture.filters = [blur];
		}	
	
		private var _waveValues:Vector.< Number >;
    }
}

