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
     import flash.geom.Matrix;

     import mx.containers.Canvas;
	 import components.controlSDK.core.*;
	 import components.controlSDK.BaseClasses.BalanceControl;


     public class EarlyLateBalanceControl extends  BalanceControl
     {
	 public function EarlyLateBalanceControl( controlManager:ControlManager )
	 {
	     super( controlManager );

	     leftLabelText = "EARLY";
	     rightLabelText = "LATE";

             var i:int;

	     _earlyValues = new Vector.< Number >( 10, true );
	     for( i = 0; i < _earlyValues.length; ++i )
	     {
		 _earlyValues[ i ] = 0.5 + Math.random() * 0.3;
	     }

	     _lateValues = new Vector.< Number >( 100, true );
	     for( i = 0; i < _lateValues.length; ++i )
	     {
		 _lateValues[ i ] = 0.5 + Math.random() * 0.3;
	     }
	    
	 }

	
	 override protected function drawBackgroundPicture():void
	 {
             var i:int;

	     var pictureArea:Rectangle = super.pictureArea;

	     leftPicture.graphics.clear();

	     leftPicture.graphics.lineStyle( 1, foregroundColor( FULL ) );

	     var leftPictureOffset:Number = ( pictureArea.width - ( 5 * _earlyValues.length ) ) / 2.0;
	     for( i = 0; i < _earlyValues.length; ++i )
	     {
		 leftPicture.graphics.moveTo( ( i * 5 ) + leftPictureOffset, pictureArea.height );
		 leftPicture.graphics.lineTo( ( i * 5 ) + leftPictureOffset, pictureArea.height - ( _earlyValues[ i ] * pictureArea.height ) );
	     }


	     rightPicture.graphics.clear();

	     rightPicture.graphics.lineStyle( 1, foregroundColor( FULL ) );

	     var lateSize:Number = int( Math.min( _lateValues.length, ( pictureArea.width * 0.8 ) ) );
	     var rightPictureOffset:Number = ( pictureArea.width - lateSize ) / 2.0;
	     for( i = 0; i < lateSize; ++i )
	     {
		 rightPicture.graphics.moveTo( i + rightPictureOffset, pictureArea.height );
		 rightPicture.graphics.lineTo( i + rightPictureOffset, pictureArea.height - ( _lateValues[ i ] * pictureArea.height ) );
	     }


	     // vertical axis
	     backgroundPicture.graphics.clear();

	     backgroundPicture.graphics.lineStyle( 1, foregroundColor( MEDIUM ) );
	     backgroundPicture.graphics.moveTo( 0, backgroundPictureArea.height );
	     backgroundPicture.graphics.lineTo( backgroundPictureArea.right, backgroundPictureArea.height );
	 }	

	 private var _earlyValues:Vector.< Number >;
	 private var _lateValues:Vector.< Number >;
     }
 }



