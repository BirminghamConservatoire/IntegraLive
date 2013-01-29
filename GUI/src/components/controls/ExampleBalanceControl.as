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
	import components.controlSDK.core.*;
	import components.controlSDK.BaseClasses.BalanceControl;


    public class ExampleBalanceControl extends  BalanceControl
    {
	public function ExampleBalanceControl( controlManager:ControlManager )
	{
	    super( controlManager );

	    // here you put your left and right labels
	    leftLabelText = "MY LEFT";
	    rightLabelText = "MY RIGHT";
	    
	    // here comes your extra code
	}

	
	override protected function drawBackgroundPicture():void
	{
	    // these are the rectangles containing two different parts of the picture:
	    // 1. background - everything that won't change with value change
	    // 2. left and right pictures - both interacting with value changes
	    // Both are Rectangles - for more on that -- see Flex 4 Rectangle class reference
	    // More then that you can get the currentValue, by calling
	    // currentValue getter from the super class
	    var backgroundPictureArea:Rectangle = super.backgroundPictureArea;
	    var pictureArea:Rectangle = super.pictureArea;

	    // backgroundPicture is a rectangular canvas of the width
	    // of both left and right picture and height the same as both of them
	    // the backgroundPicture canvas doesn't fade automaticaly 
	    // when the currentValue changes
	    // everywhere in the code you should only use a foregroundColor
	    // and make it brighter/darker through the enumeration
	    // FULL, HIGH, MEDIUM, LOW, NONE
	    backgroundPicture.graphics.clear();
	    backgroundPicture.graphics.lineStyle();
	    backgroundPicture.graphics.beginFill( foregroundColor( LOW ) );
	    backgroundPicture.graphics.drawRoundRect( 0, 0, backgroundPictureArea.width, backgroundPictureArea.height, 8, 8 );
	    backgroundPicture.graphics.endFill();

	    // leftPicture is a rectangular canvas of the dimentions of
	    // pictureArea Rectangle that you can draw on your... left picture
	    // The canvas is placed in the right place on the control, 
	    // so you only have to draw within the pictureArea Rectangle
	    leftPicture.graphics.clear();

	    leftPicture.graphics.lineStyle( 1, foregroundColor( FULL ) );
	    leftPicture.graphics.drawRoundRect( 0, 0, pictureArea.width * ( 1 - currentValue ), pictureArea.height, 8, 8 );

	    // rightPicture is just the same as leftPicture canvas
	    // but it's automaticaly placed on the right side of the control
	    // like with the leftPicture canvas - the fading effect is managed by the super class
	    rightPicture.graphics.clear();
	    rightPicture.graphics.lineStyle( 1, foregroundColor( FULL ) );
	    rightPicture.graphics.drawRoundRect( pictureArea.width - ( pictureArea.width * currentValue ), 0, 
						 pictureArea.width * currentValue, pictureArea.height,
						 8, 8 );
	}	

	// your private variables go here
    }
}

