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
    import __AS3__.vec.Vector;
	
    import flash.net.FileFilter;
    import flash.geom.Rectangle;
    import mx.containers.Canvas;
	import components.controlSDK.core.*;
	import components.controls.FileLoadDialogControl;


    public class SoundFileLoadDialogControl extends FileLoadDialogControl
    {
        public function SoundFileLoadDialogControl( controlManager:ControlManager )
        {
            super( controlManager );
		
            fileFilter = new FileFilter( "Sound files", "*.wav; *.aiff; *.aif" );
            fileLoadDialogName = "Load sound file";
			
            _buttonWaveform = new Vector.< Number >();
            for( var i:int = 0; i < maximumSize.x; ++i )
            {
                _buttonWaveform.push( Math.random() );
            }
        }


        override protected function drawBackgroundPicture():void
        {
            var drawArea:Rectangle = drawArea();
            var waveformFade:int = int( drawArea.width * 0.15 ); 
            var verticalCenter:Number = ( drawArea.height / 2 ) + drawArea.y;
			
            buttonBackgroundPicture.graphics.clear();
			
            for( var i:int = 0; i < drawArea.width; ++i )
            {
                var basicLineLength:Number = ( drawArea.height * 0.6 + ( _buttonWaveform[i] * drawArea.height * 0.4 ) ) / 2;
                var lineLength:Number;
				
                if( i < waveformFade )
                {
                    lineLength = basicLineLength * ( i / waveformFade );
                }
                else if( i > ( drawArea.width - waveformFade ) )
                {
                    lineLength = basicLineLength * ( ( drawArea.width - i ) / waveformFade );
                }
                else
                {
                    lineLength = basicLineLength; 
                }
				
                buttonBackgroundPicture.graphics.lineStyle( 1, mouseOver ? foregroundColor( MEDIUM ) : foregroundColor( LOW ) );
                buttonBackgroundPicture.graphics.moveTo( i + drawArea.x, verticalCenter - lineLength );
                buttonBackgroundPicture.graphics.lineTo( i + drawArea.x, verticalCenter + lineLength );
            }
			
        }	
		
        private var _buttonWaveform:Vector.< Number >;
    }
}

