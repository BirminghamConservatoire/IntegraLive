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
	import components.controlSDK.core.*;
	import components.controls.FileLoadDialogControl;

    import mx.containers.Canvas;


    public class ExampleFileLoadDialogControl extends FileLoadDialogControl
    {
	public function ExampleFileLoadDialogControl( controlManager:ControlManager )
	{
	    super( controlManager );

	    // fileFilter specifies the name of the files group 
	    // and the extensions of the file that can be loaded
	    fileFilter = new FileFilter( "Example files", "*.txt; *.bin; *.pdf" );

	    // fileLoadDialogName is the name shown on top of open file window
	    fileLoadDialogName = "Load example file";

	    // now you can initiaze anything you need
	}
	
	override protected function drawBackgroundPicture():void
	{
	    // this gives you actual size of the button
	    // see Flex 3.5 Rectangle class reference how to use it
	    var drawArea:Rectangle = drawArea();

	    // buttonBackgroundPicture is an inherited Canvas
	    // that you do all the drawing on
	    // the first thing to do is clear it
	    buttonBackgroundPicture.graphics.clear();

	    // your drawing comes here
	    // the only color you should use is in inherited foregroundColor field
	    // use this color with different alpha values, i.e.:
	    buttonBackgroundPicture.graphics.lineStyle( 3, foregroundColor( FULL ) );
	    buttonBackgroundPicture.graphics.beginFill( foregroundColor( MEDIUM ) );
	    buttonBackgroundPicture.graphics.drawRoundRect( drawArea.x * 2, drawArea.y * 2, 
	    						    drawArea.width - ( drawArea.x * 2 ), drawArea.height - ( drawArea.y * 2 ), 
							    8, 8 );
	    buttonBackgroundPicture.graphics.endFill();

	    // this example is not too sophisticated, but prooves the concept behind it
	}	

	// put your private fields here
    }
}



