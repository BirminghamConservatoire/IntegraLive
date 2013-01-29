/* Integra Live graphical user interface
 *
 * Copyright (C) 2010 Birmingham City University
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

package components.controlSDK.BaseClasses
{
    import __AS3__.vec.Vector;
    
    import components.controlSDK.HelperClasses.AttributeLabel;
    import components.controlSDK.core.*;
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import flexunit.framework.Assert;
    
    import mx.containers.Canvas;
    import mx.controls.Label;
    

    public class BalanceControl extends IntegraControl
    {
		public function BalanceControl( controlManager:ControlManager )
		{
		    super( controlManager );
	
		    registerAttribute( _attributeName, ControlAttributeType.NUMBER );
	
		    _attributeLabel = new AttributeLabel( _attributeName );
		    _attributeLabel.setStyle( "horizontalAlign", "center" );
		    _attributeLabel.setStyle( "horizontalCenter", 0 );
		    _attributeLabel.setStyle( "bottom", 0 );
		    _attributeLabel.height = 25;
	
		    addChild( _attributeLabel );
	
		    addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
	            addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );	    
		    addEventListener( Event.RESIZE, onResize );
		    
		    _balance = new Canvas();
		    addChild( _balance );
	
		    _leftLabel = new Label;
		    _leftLabel.setStyle( "fontSize", 12 );
		    _leftLabel.setStyle( "textAlign", "left" );
		    addChild( _leftLabel );
	
		    _rightLabel = new Label;
		    _rightLabel.setStyle( "fontSize", 12 );
		    _rightLabel.setStyle( "textAlign", "right" );
		    addChild( _rightLabel );
	
		    _balanceData = new Vector.< Number >( 16, true );
		    _balanceCommands = new Vector.< int >( 4, true );
		    _balanceCommands[ 0 ] = 1;
		    _balanceCommands[ 1 ] = 2;	
		    _balanceCommands[ 2 ] = 2; 
		    _balanceCommands[ 3 ] = 2;   
	
		    backgroundPicture = new Canvas;
		    
		    leftPicture = new Canvas;
		    backgroundPicture.addChild( leftPicture );
		    
		    rightPicture = new Canvas;
		    backgroundPicture.addChild( rightPicture );
	
		    addChild( backgroundPicture );
		}
	
		override public function get defaultSize():Point { return new Point( 240, 180 ); }
		override public function get minimumSize():Point { return new Point( 92, 64 ); }
		override public function get maximumSize():Point { return new Point( 1024, 1024 ); }
	
	
		override public function onValueChange( changedValues:Object ):void
		{
		    Assert.assertTrue( changedValues.hasOwnProperty( _attributeName ) );
	
		    _currentValue = changedValues[ _attributeName ];
	
		    update();
		}
	
		
		override public function isActiveArea( point:Point ):Boolean
		{
		    var activeArea:Rectangle = new Rectangle( graphArea.x, graphArea.bottom - ( graphArea.height * 0.7 ), graphArea.width, ( graphArea.height * 0.7 ) + ( _handleRadius * 2 ) );
	
		    return activeArea.containsPoint( point );
		}
	
	
		override public function onMouseDown( event:MouseEvent ):void
		{
			setValueFromMouse();
		    startMouseDrag();
		}
	        
	
		protected function onMouseOver( event:MouseEvent ):void
		{
		    if( isActiveArea( new Point( mouseX, mouseY ) ) && !event.buttonDown )
		    {
				_mouseOver = true;
				update();
		    }
		    else
		    {
				_mouseOver = false;
				update();
		    }
		}


        protected function onMouseOut( event:MouseEvent ):void
        {
            _mouseOver = false;
            update();
        }
        

		override public function onDrag( event:MouseEvent ):void
		{
			setValueFromMouse();
		}
	
	
		private function setValueFromMouse():void
		{
	   	    var newValue:Number = ( mouseX - graphArea.x ) / graphArea.width;
	
			var changedValues:Object = new Object;
		    changedValues[ _attributeName ] = Math.max( 0, Math.min( 1, newValue ) );
		    setValues( changedValues );
		}
	
	
		override protected function updateDisplayList( width:Number, height:Number ):void
		{
		    super.updateDisplayList( width, height );
	
		    _leftLabel.setStyle( "color", foregroundColor( FULL ) );
		    _rightLabel.setStyle( "color", foregroundColor( FULL ) );           
	
		    var drawArea:Rectangle = drawArea();
		    var margin:Number = drawArea.height * 0.1;
		    var graphArea:Rectangle = this.graphArea;
		    var maxGraphHeight:Number = graphArea.height * 0.7;
	
		    graphics.clear();
		    
		    // background rectangle
		    graphics.lineStyle();
		    graphics.beginFill( foregroundColor( LOW ) );
		    graphics.drawRoundRect( drawArea.x, drawArea.y, drawArea.width, drawArea.height, margin, margin );
		    graphics.endFill();
	
		    // horizontal axis
		    graphics.lineStyle( 1, foregroundColor( MEDIUM ) );
		    graphics.moveTo( graphArea.x, graphArea.bottom );
		    graphics.lineTo( graphArea.right, graphArea.bottom );
		    
		    // left axis indicator
		    graphics.moveTo( graphArea.x, graphArea.bottom );
		    graphics.lineTo( graphArea.x, graphArea.bottom + 5 );
		    // central axis indicator
		    graphics.moveTo( graphArea.x + ( graphArea.width / 2 ), graphArea.bottom );
		    graphics.lineTo( graphArea.x + ( graphArea.width / 2 ), graphArea.bottom + 3 );
		    // right axis indicator
		    graphics.moveTo( graphArea.right, graphArea.bottom );
		    graphics.lineTo( graphArea.right, graphArea.bottom + 5 );
	
		    // positioning the labels
		    _leftLabel.width = graphArea.width;
		    _leftLabel.x = graphArea.x + 1; // + 1 to make the label not too close to the axis
		    _leftLabel.y = graphArea.bottom;
	
		    _rightLabel.width = graphArea.width;
		    _rightLabel.x = graphArea.x - 1; // - 1 to make the label not too close to the axis
		    _rightLabel.y = graphArea.bottom;
	
		    _balance.graphics.lineStyle( 0.5, foregroundColor( MEDIUM ) );
		    // small vertical indicators on the top
		    _balance.graphics.moveTo( graphArea.x, graphArea.bottom - maxGraphHeight );
		    _balance.graphics.lineTo( graphArea.x - 5, graphArea.bottom - maxGraphHeight );
		    _balance.graphics.moveTo( graphArea.right, graphArea.bottom - maxGraphHeight );
		    _balance.graphics.lineTo( graphArea.right + 5, graphArea.bottom - maxGraphHeight );
		    // small vertical indicators in the middle
		    _balance.graphics.moveTo( graphArea.x, graphArea.bottom - ( maxGraphHeight * 0.5 ) );
		    _balance.graphics.lineTo( graphArea.x - 5, graphArea.bottom - ( maxGraphHeight * 0.5 ) );
		    _balance.graphics.moveTo( graphArea.right, graphArea.bottom - ( maxGraphHeight * 0.5 ) );
		    _balance.graphics.lineTo( graphArea.right + 5, graphArea.bottom - ( maxGraphHeight * 0.5 ) );
		    // thin vertical axes on sides
		    _balance.graphics.moveTo( graphArea.x, graphArea.bottom );
		    _balance.graphics.lineTo( graphArea.x, graphArea.bottom - ( maxGraphHeight ) );
		    _balance.graphics.moveTo( graphArea.right, graphArea.bottom );
		    _balance.graphics.lineTo( graphArea.right, graphArea.bottom - ( maxGraphHeight ) );
	
	
		    // things to be reimplemented in the subclasses goes here
		    _leftLabel.text = leftLabelText;
		    _rightLabel.text = rightLabelText;
	
		    leftPicture.x = leftPicturePosition.x;
		    leftPicture.y = leftPicturePosition.y;
	
		    rightPicture.x = rightPicturePosition.x;
		    rightPicture.y = rightPicturePosition.y;
	
		    backgroundPicture.x = backgroundPicturePosition.x;
		    backgroundPicture.y = backgroundPicturePosition.y;
	 	}
	
	
		private function update():void
		{
		    invalidateDisplayList();
		    
		    var graphArea:Rectangle = this.graphArea;
		    var margin:Number = this.margin;
		    var maxGraphHeight:Number = graphArea.height * 0.7;
	
		    // reassigning the balance graph verticies
		    _balanceData[ 0 ] = graphArea.x;
		    _balanceData[ 1 ] = graphArea.bottom;
		    _balanceData[ 2 ] = graphArea.x;
		    _balanceData[ 3 ] = graphArea.bottom - ( maxGraphHeight * ( 1 - _currentValue ) );
		    _balanceData[ 4 ] = graphArea.right;
		    _balanceData[ 5 ] = graphArea.bottom - ( maxGraphHeight * _currentValue );;
		    _balanceData[ 6 ] = graphArea.right;
		    _balanceData[ 7 ] = graphArea.bottom;
	
		    _balance.graphics.clear();
	
		    // balance shape
		    _balance.graphics.lineStyle( 1, foregroundColor( FULL ) );
		    _balance.graphics.beginFill( foregroundColor( MEDIUM ) );
		    _balance.graphics.drawPath( _balanceCommands, _balanceData );
		    _balance.graphics.endFill();
	
		    // balance line
		    _balance.graphics.lineStyle( 2, foregroundColor( FULL ) );
		    _balance.graphics.moveTo( _balanceData[ 2 ], _balanceData[ 3 ] );
		    _balance.graphics.lineTo( _balanceData[ 4 ], _balanceData[ 5 ] );
	
	            // vertical indication on current value
	            _balance.graphics.lineStyle( 2, foregroundColor( FULL ) );
		    _balance.graphics.moveTo( _balanceData[ 0 ], _balanceData[ 1 ] );
		    _balance.graphics.lineTo( _balanceData[ 2 ], _balanceData[ 3 ] );
		    _balance.graphics.moveTo( _balanceData[ 4 ], _balanceData[ 5 ] );
		    _balance.graphics.lineTo( _balanceData[ 6 ], _balanceData[ 7 ] );
	            
		    // value ball - handle
		    _balance.graphics.lineStyle( 2, foregroundColor( FULL ) );
		    _balance.graphics.beginFill( foregroundColor( MEDIUM ) ); 
		    _balance.graphics.drawCircle( graphArea.x + ( graphArea.width * _currentValue ), graphArea.bottom, _mouseOver ? _handleRadius * 1.3 : _handleRadius );
		    _balance.graphics.endFill();
	
		    // corner balls 
		    _balance.graphics.lineStyle();
		    _balance.graphics.beginFill( foregroundColor( MEDIUM ) );
		    _balance.graphics.drawCircle( _balanceData[ 2 ], _balanceData[ 3 ], 3 );
		    _balance.graphics.drawCircle( _balanceData[ 4 ], _balanceData[ 5 ], 3 );
		    _balance.graphics.endFill();
		    
		    drawBackgroundPicture();
	
		    leftPicture.alpha = 1 - _currentValue;
		    rightPicture.alpha = _currentValue;
	
		    _leftLabel.alpha = 1 - _currentValue;
		    _rightLabel.alpha = _currentValue;
		}
	
	
		private function get graphArea():Rectangle
		{
	            var drawArea:Rectangle = drawArea();
	
		    return new Rectangle( drawArea.x + margin, drawArea.y + margin, 
					  drawArea.width - ( 2 * margin ), drawArea.height - Math.max( 3 * margin, minimumLabelHeight ) );
		}
	
	
		private function get backgroundPicturePosition():Point
		{
		    return new Point( graphArea.x + graphArea.width * 0.125, graphArea.y );
		}
	
	
		private function get leftPicturePosition():Point
		{
		    return new Point( backgroundPictureArea.x, backgroundPictureArea.y );
		} 
	
	
		private function get rightPicturePosition():Point
		{
		    return new Point( backgroundPictureArea.x + ( backgroundPictureArea.width / 2 ), backgroundPictureArea.y );
		} 
		
	
		private function get margin():Number
		{
		    return drawArea().height * 0.1;
		}
	
	
		private function onResize( event:Event ):void 
		{
		    update();
		}
	
	
		// subclasses interface starts here
		protected function drawBackgroundPicture():void
		{
		    // empty in the plain control
		    // to be implemented in the subclasses
		}
	
	
		protected function get currentValue():Number
		{
		    return _currentValue;
		}
	
	
		protected function get backgroundPictureArea():Rectangle
		{
		    var graphArea:Rectangle = this.graphArea;
	
		    return new Rectangle( 0, 0, graphArea.width * 0.75, graphArea.height * 0.3 );
		}
	
	
		protected function get pictureArea():Rectangle
		{
		    return new Rectangle( 0, 0, backgroundPictureArea.width / 2, backgroundPictureArea.height );
		} 
	
	
		// protected fields
		protected var backgroundPicture:Canvas;
		protected var leftPicture:Canvas;
		protected var rightPicture:Canvas;
	
		protected var leftLabelText:String = "LEFT";
		protected var rightLabelText:String = "RIGHT";
		
		// private fields
		private var _attributeName:String = "value";
		private var _attributeLabel:AttributeLabel;
	
		private var _currentValue:Number = 0.5;
	
		private var _leftLabel:Label;
		private var _rightLabel:Label;
	
		private var _balanceData:Vector.< Number >;
		private var _balanceCommands:Vector.< int >;
	
		private var _balance:Canvas;
		private var _handleRadius:int = 4;

        private var _mouseOver:Boolean = false;
		
		private const minimumLabelHeight:Number = 12;		
    }
}
