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

     import mx.containers.Canvas;
	 import components.controlSDK.core.*;
	 import components.controlSDK.BaseClasses.BalanceControl;


     public class PanoramaBalanceControl extends BalanceControl
     {
	 public function  PanoramaBalanceControl( controlManager:ControlManager )
	 {
	     super( controlManager );

	     leftLabelText = "LEFT";
	     rightLabelText = "RIGHT";

	     _leftSpeaker = new Canvas;
	     leftPicture.addChild( _leftSpeaker );

	     _rightSpeaker = new Canvas;
	     rightPicture.addChild( _rightSpeaker );
	 }

	
	 override protected function drawBackgroundPicture():void
	 {
	     _leftSpeaker.graphics.clear();

	     _leftSpeaker.graphics.lineStyle( 1, foregroundColor( FULL ) );

	     _leftSpeaker.graphics.moveTo( -5, 10 );
	     _leftSpeaker.graphics.lineTo( -5, 0 );
	     _leftSpeaker.graphics.lineTo( -15, -10 );
	     _leftSpeaker.graphics.lineTo( 15, -10 );
	     _leftSpeaker.graphics.lineTo( 5, 0 );
	     _leftSpeaker.graphics.lineTo( 5, 10 );
	     _leftSpeaker.graphics.lineTo( -5, 10 );

	     _leftSpeaker.rotation = -45;
	     _leftSpeaker.x = pictureArea.width * 0.3;
	     _leftSpeaker.y = pictureArea.height * 0.6;

	    
	     _rightSpeaker.graphics.clear();

	     _rightSpeaker.graphics.lineStyle( 1, foregroundColor( FULL ) );

	     _rightSpeaker.graphics.moveTo( -5, 10 );
	     _rightSpeaker.graphics.lineTo( -5, 0 );
	     _rightSpeaker.graphics.lineTo( -15, -10 );
	     _rightSpeaker.graphics.lineTo( 15, -10 );
	     _rightSpeaker.graphics.lineTo( 5, 0 );
	     _rightSpeaker.graphics.lineTo( 5, 10 );
	     _rightSpeaker.graphics.lineTo( -5, 10 );

	     _rightSpeaker.rotation = 45;
	     _rightSpeaker.x = pictureArea.width * 0.7;
	     _rightSpeaker.y = pictureArea.height * 0.6;
	 }	

	 private var _leftSpeaker:Canvas;	
	 private var _rightSpeaker:Canvas;
     }
 }



