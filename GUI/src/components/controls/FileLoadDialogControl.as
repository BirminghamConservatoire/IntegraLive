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
	
    import flexunit.framework.Assert;    

    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.net.FileFilter;
	
    import mx.containers.Canvas;
    import mx.controls.Label;
    import mx.core.ScrollPolicy;	
	import components.controlSDK.core.*;


    public class FileLoadDialogControl extends IntegraControl
    {
		public function FileLoadDialogControl( controlManager:ControlManager )
		{
		    super( controlManager );
	
		    registerAttribute( _attributeName, ControlAttributeType.STRING );
	
		    _button = new Canvas();
		    _button.horizontalScrollPolicy = ScrollPolicy.OFF;
		    _button.verticalScrollPolicy = ScrollPolicy.OFF;
		    _button.percentWidth = 100;
		    _button.percentHeight = 100;
		    addChild( _button );
	
		    buttonBackgroundPicture = new Canvas();
		    _button.addChild( buttonBackgroundPicture );
	
		    _buttonLabel = new Label();
		    _button.addChild( _buttonLabel );
	
		    addEventListener( Event.RESIZE, onResize );
		    addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
		    addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
		}
		
		
		override public function get defaultSize():Point { return new Point( 150, 60 ); }
		override public function get minimumSize():Point { return new Point( 72, 24 ); }
		override public function get maximumSize():Point { return new Point( 1024, 1024 ); }
	
	        
		override public function onValueChange( changedValues:Object ):void
		{
			Assert.assertTrue( changedValues.hasOwnProperty( _attributeName ) );
				
			_filePath = changedValues[ _attributeName ];
			var splitFilePath:Array = _filePath.split( File.separator );
	
			_fileName = splitFilePath[ splitFilePath.length - 1 ];
	
			update();
		}		
	
	
		public function setControlValues( values:Object ):void
		{
		    Assert.assertTrue( values.hasOwnProperty( _attributeName ) );
	
		    if( values[ _attributeName ] != _filePath )
		    {
			var changedValues:Object;
			changedValues[ _attributeName ] = values[ _attributeName ];
	
			onValueChange( changedValues );
		    }
		} 
	
	
		protected function update():void
		{
		    var drawArea:Rectangle = drawArea();
	
			if( _fileName == "" )
			{
				_buttonLabel.text = buttonLabelText;
			}
			else
			{
				_buttonLabel.text = _fileName;
			}
			
		    var labelFontSize:Number = Math.min( drawArea.height * 0.7, drawArea.width * 0.12 ); 
		    var labelGlow:Number = 0.4;
	
		    _button.graphics.clear();
				
		    // function to be overwritten that draws on the buttonBackgroundPicture canvas
		    drawBackgroundPicture();
	
		    // button label
		    _buttonLabel.setStyle( "fontSize", labelFontSize );
		    _buttonLabel.setStyle( "color", mouseOver ? 0x000000 : foregroundColor( FULL ) );
		    _buttonLabel.setStyle( "textAlign", "center" );
	        _buttonLabel.setStyle( "verticalCenter", 0 );
		    _buttonLabel.width = drawArea.width;
		    _buttonLabel.truncateToFit = true;
		    _buttonLabel.validateNow();
	
		    _buttonLabel.y = drawArea.y;
		    _buttonLabel.x = drawArea.x; 
	
		    _buttonLabel.setVisible( labelFontSize > 6 );
		    setGlow( _buttonLabel, labelGlow );
		}
	
		protected function drawBackgroundPicture():void
		{
		    // to be implemented in the subclasses

			// plain file loader draws a default rectangular background
			buttonBackgroundPicture.graphics.clear();
			buttonBackgroundPicture.graphics.beginFill( foregroundColor( LOW ) );
			buttonBackgroundPicture.graphics.drawRect( 0, 0, width, height );
			buttonBackgroundPicture.graphics.endFill();			
		}	
	
		override public function isActiveArea( point:Point ):Boolean
		{
		    return drawArea().containsPoint( point );
		}
	
			
		private function onMouseOver( event:MouseEvent ):void
		{
		    if( !event.buttonDown )
		    {
			mouseOver = true;
			update();
		    }
		}
			
	
		private function onMouseOut( event:MouseEvent ):void
		{
		    mouseOver = false;
		    update();
		}
	
	
		override public function onMouseDown( event:MouseEvent ):void
		{
		    _fileReference = new File();
		    _fileReference.addEventListener( Event.SELECT, onFileSelected );
	
	 	    _fileReference.browseForOpen( fileLoadDialogName, [ fileFilter ] );
		}
	
	
		protected function onFileSelected( event:Event ):void
		{
		    _fileName = event.target.name;
		    _filePath = event.target.nativePath; 
	
		    var changedValues:Object = new Object;
		    changedValues[ _attributeName ] = _filePath;
		    setValues( changedValues );
	
		    update();
		}
			
			
		private function onResize( event:Event ):void
		{
		    update();
		}
		
			
		override protected function  drawArea():Rectangle
		{
		    return new Rectangle( 0, 0, width, height );
		}
		    
			
		private var _fileName:String = "";
		private var _filePath:String;
		private var _fileReference:File;
		protected var fileFilter:FileFilter = new FileFilter( "Files", "*" );
		protected var fileLoadDialogName:String = "Open file...";	
		protected var buttonLabelText:String = "LOAD FILE"
			
		private var _button:Canvas;
		private var _buttonLabel:Label;
		protected var buttonBackgroundPicture:Canvas;
			
		protected var mouseOver:Boolean = false;
		
		private static var _attributeName:String = "value"; 			
    }
}

