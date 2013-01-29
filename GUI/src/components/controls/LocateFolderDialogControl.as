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


    public class LocateFolderDialogControl extends IntegraControl
    {
		public function LocateFolderDialogControl( controlManager:ControlManager )
		{
		    super( controlManager );
	
		    registerAttribute( _attributeName, ControlAttributeType.STRING );
	
		    _button = new Canvas();
		    _button.horizontalScrollPolicy = ScrollPolicy.OFF;
		    _button.verticalScrollPolicy = ScrollPolicy.OFF;
		    _button.percentWidth = 100;
		    _button.percentHeight = 100;
		    addChild( _button );
	
		    _buttonBackgroundPicture = new Canvas();
		    _button.addChild( _buttonBackgroundPicture );
	
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
				
			_folderPath = changedValues[ _attributeName ];
			var splitPath:Array = _folderPath.split( File.separator );
	
			_folderName = splitPath[ splitPath.length - 1 ];
	
			update();
		}		
	
	
		protected function update():void
		{
		    var drawArea:Rectangle = drawArea();
	
			if( _folderName == "" )
			{
				_buttonLabel.text = "CHOOSE FOLDER";
			}
			else
			{
				_buttonLabel.text = _folderName;
			}
			
		    var labelFontSize:Number = Math.min( drawArea.height * 0.6, drawArea.width * 0.1 ); 
		    var labelGlow:Number = 0.4;
	
		    _button.graphics.clear();
				
		    drawBackgroundPicture();
	
		    // button label
		    _buttonLabel.setStyle( "fontSize", labelFontSize );
		    _buttonLabel.setStyle( "color", _mouseOver ? 0x000000 : foregroundColor( FULL ) );
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
	
		
		private function drawBackgroundPicture():void
		{
			var flapHeight:Number = height / 8;
			var flapWidth:Number = width / 4;
			var cornerSize:Number = flapHeight * 3 / 2;
			
			_buttonBackgroundPicture.graphics.clear();
			_buttonBackgroundPicture.graphics.lineStyle( 3, foregroundColor( MEDIUM ) );
			_buttonBackgroundPicture.graphics.beginFill( foregroundColor( LOW ) );
			_buttonBackgroundPicture.graphics.drawRoundRect( 0, flapHeight, width, height - flapHeight, cornerSize, cornerSize );
			_buttonBackgroundPicture.graphics.endFill();			

			_buttonBackgroundPicture.graphics.beginFill( foregroundColor( LOW / 2 ) );
			_buttonBackgroundPicture.graphics.drawRoundRectComplex( 0, 0, flapWidth, flapHeight * 2, cornerSize, cornerSize, 0, 0 );
			_buttonBackgroundPicture.graphics.endFill();			
		}	
	
		
		override public function isActiveArea( point:Point ):Boolean
		{
		    return drawArea().containsPoint( point );
		}
	
			
		private function onMouseOver( event:MouseEvent ):void
		{
		    if( !event.buttonDown )
		    {
				_mouseOver = true;
				update();
		    }
		}
			
	
		private function onMouseOut( event:MouseEvent ):void
		{
		    _mouseOver = false;
		    update();
		}
	
	
		override public function onMouseDown( event:MouseEvent ):void
		{
			_file = new File();
			_file.addEventListener( Event.SELECT, onFileSelected );
			_file.browseForDirectory( "Locate Folder..." );
		}
	
	
		private function onFileSelected( event:Event ):void
		{
		    var changedValues:Object = new Object;
		    changedValues[ _attributeName ] = event.target.nativePath;
		    setValues( changedValues );
		}
			
			
		private function onResize( event:Event ):void
		{
		    update();
		}
		
			
		override protected function  drawArea():Rectangle
		{
		    return new Rectangle( 0, 0, width, height );
		}
		    

		private var _folderPath:String = "";
		private var _folderName:String = "";
		
		private var _file:File = null;

		private var _button:Canvas;
		private var _buttonLabel:Label;
		private var _buttonBackgroundPicture:Canvas;
			
		private var _mouseOver:Boolean = false;
		
		private static var _attributeName:String = "value"; 			
    }
}

