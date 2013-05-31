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


package components.controlSDK.core
{
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.GradientType;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.StatusEvent;
    import flash.filters.ColorMatrixFilter;
    import flash.filters.GlowFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.getDefinitionByName;
    
    import mx.containers.Canvas;
    import mx.core.ScrollPolicy;
    
    import __AS3__.vec.Vector;
    
    import components.controls.AllControlsToInclude;
    import components.utils.CursorSetter;
    import components.utils.Trace;
    import components.utils.Utilities;
    import components.views.MouseCapture;
    
    import flexunit.framework.Assert;
	
	AllControlsToInclude;	//forces compilation of all the control classes listed in AllControlsToInclude.as 
	
	
    public class ControlManager
    {
		public function ControlManager( controlClass:Class, parent:DisplayObjectContainer, notificationSink:ControlNotificationSink )
		{
		    Assert.assertNotNull( controlClass );
				
		    _parent = parent;
			_notificationSink = notificationSink;
	
		    //create control
		    _control = new controlClass( this );
			if( !_parent ) return;
			
		    _control.horizontalScrollPolicy = ScrollPolicy.OFF;
		    _control.verticalScrollPolicy = ScrollPolicy.OFF;
		    _control.percentWidth = 100;
		    _control.percentHeight = 100;			
	
		    _control.addEventListener( IntegraControlEvent.CONTROL_START_DRAG, onStartDrag );
		    _control.addEventListener( IntegraControlEvent.CONTROL_VALUES_CHANGED, onValuesChanged );
		    _control.addEventListener( IntegraControlEvent.CONTROL_TEXT_EQUIVALENTS_CHANGED, onTextEquivalentsChanged );
		    _control.addEventListener( IntegraControlEvent.ATTRIBUTE_LABEL_POSITIONED, onAttributeLabelPositioned );
		    _control.addEventListener( IntegraControlEvent.ATTRIBUTE_LABEL_EDITSTATE_CHANGED, onAttributeLabelEditstateChanged );
	
		    _control.addEventListener( MouseEvent.MOUSE_MOVE, onControlMouseMove );
		    _control.addEventListener( MouseEvent.MOUSE_DOWN, onControlMouseDown );
		    _control.addEventListener( MouseEvent.ROLL_OUT, onControlMouseOut );
	
			//create filter canvas
			_filterCanvas = new Canvas;
			_filterCanvas.horizontalScrollPolicy = ScrollPolicy.OFF;
			_filterCanvas.verticalScrollPolicy = ScrollPolicy.OFF;
			_filterCanvas.percentWidth = 100;
			_filterCanvas.percentHeight = 100;			
			_parent.addChild( _filterCanvas );
			
		    _filterCanvas.addChild( _control );
		}
		
		
		public static function getClassReference( controlName:String ):Class
		{
			var packageName:String = "components.controls." + controlName + "Control";
			var classReference:Class = null;
	
			try
			{
				classReference = getDefinitionByName( packageName ) as Class;
			}
			catch( error:Error )
			{
				Trace.error( "failed to get class reference for control " + packageName );	
			}
			
			return classReference;
		}
		
		
		public function get attributes():Object { return _attributes; }

		public function get defaultSize():Point { return _control.defaultSize; }
		public function get maximumSize():Point { return _control.maximumSize; }
		public function get minimumSize():Point { return _control.minimumSize; }
		
		public function get leftPadding():Number { return _filterCanvas.getStyle( "left" ); }
		public function get rightPadding():Number { return _filterCanvas.getStyle( "right" ); }
		public function get topPadding():Number { return _filterCanvas.getStyle( "top" ); }
		public function get bottomPadding():Number { return _filterCanvas.getStyle( "bottom" ); }

		public function set leftPadding( padding:Number ):void { _filterCanvas.setStyle( "left", padding ); }
		public function set rightPadding( padding:Number ):void { _filterCanvas.setStyle( "right", padding ); }
		public function set topPadding( padding:Number ):void { _filterCanvas.setStyle( "top", padding ); }
		public function set bottomPadding( padding:Number ):void { _filterCanvas.setStyle( "bottom", padding ); }
		
	
		public function registerAttribute( controlAttributeName:String, type:String ):void
		{
		    Assert.assertFalse( _attributes.hasOwnProperty( controlAttributeName ) );
				
		    _attributes[ controlAttributeName ] = type;
		}
			
			
		public function setControlValues( values:Object ):void
		{
			Assert.assertFalse( Utilities.isObjectEmpty( values ) );
			
			_values = new Object;
			for( var key:String in values )
			{
				_values[ key ] = values[ key ];
			}
			
			_control.onValueChange( values );
		}
	
	
		public function setControlTextEquivalents( textEquivalents:Object ):void
		{
		    var changedTextEquivalents:Object = new Object;
		    var anythingChanged:Boolean = false;
	
		    for( var attributeName:String in textEquivalents )
		    {
				var textEquivalent:String = textEquivalents[ attributeName ];
						
				if( !_textEquivalents.hasOwnProperty( attributeName ) || _textEquivalents[ attributeName ] != textEquivalent )
				{
				    _textEquivalents[ attributeName ] = textEquivalent;
				    changedTextEquivalents[ attributeName ] = textEquivalent;
				    anythingChanged = true;
				} 
		    }
	
		    if( anythingChanged )
		    {			
				_control.onTextEquivalentChange( changedTextEquivalents );
				_control.dispatchEvent( new IntegraControlEvent( IntegraControlEvent.HOST_TEXT_EQUIVALENTS_CHANGED, changedTextEquivalents ) );
		    }			
		}
			
			
		public function setControlWritableFlags( writableFlags:Object ):void
		{
		    var anythingChanged:Boolean = false;
				
		    for( var attributeName:String in _attributes )
		    {
				var flag:Boolean = false;
				if( writableFlags.hasOwnProperty( attributeName ) )
				{
				    flag = writableFlags[ attributeName ];
				}
				else
				{
				    Assert.assertTrue( false );		//flag not provided for one of control's attributes
				}
						
				if( !writableFlags.hasOwnProperty( attributeName ) || _writableFlags[ attributeName ] != flag )
				{
				    anythingChanged = true;
				    _writableFlags[ attributeName ] = flag;	
				} 
		    }
				
		    if( anythingChanged )
		    {
				_control.dispatchEvent( new IntegraControlEvent( IntegraControlEvent.HOST_WRITABLE_FLAGS_CHANGED, _writableFlags ) );
		    }
		}
			
			
		public function setControlAllowedValues( allowedValues:Object ):void
		{
		    _allowedValues = allowedValues;
		}
			
			
		public function setControlBackgroundColors( topBackgroundColor:uint, bottomBackgroundColor:uint ):void
		{
		    _topBackgroundColor = topBackgroundColor;
		    _bottomBackgroundColor = bottomBackgroundColor;
	
		    if( !_backgroundCanvas )
		    {
				_backgroundCanvas = new Canvas;
				_backgroundCanvas.percentWidth = 100;
				_backgroundCanvas.percentHeight = 100;
				_backgroundCanvas.addEventListener( Event.RESIZE, onResizeBackground );
		
				_parent.addChildAt( _backgroundCanvas, 0 );
		    }
	
            updateFilter();			
		    renderBackgroundCanvas();
		}  

		
        private function updateFilter():void
        {
            var desaturationMatrix:ColorMatrixFilter = new ColorMatrixFilter( [ 0.333, 0.333, 0.333, 0, 0,
                                                                                0.333, 0.333, 0.333, 0, 0,
                                                                                0.333, 0.333, 0.333, 0, 0,
                                                                                0, 0, 0, 1, 0 ] );
            // extract the RGB components from the current background color
            var backgroundRedComponent:uint = ( _topBackgroundColor >> 16 ) & 0xff;
            var backgroundGreenComponent:uint = ( _topBackgroundColor >> 8 ) & 0xff;
            var backgroundBlueComponent:uint = _topBackgroundColor & 0xff;
            
            // extract the RGB components from the track foreground color
            var foregroundRedComponent:uint = ( _foregroundColor >> 16 ) & 0xff;
            var foregroundGreenComponent:uint = ( _foregroundColor >> 8 ) & 0xff;
            var foregroundBlueComponent:uint = _foregroundColor & 0xff;            

            // transformation values
            var redTransformation:Number = ( foregroundRedComponent - backgroundRedComponent ) / 0xff;
            var greenTransformation:Number = ( foregroundGreenComponent - backgroundGreenComponent ) / 0xff;
            var blueTransformation:Number = ( foregroundBlueComponent - backgroundBlueComponent ) / 0xff;

            var resaturationMatrix:ColorMatrixFilter = new ColorMatrixFilter( [ redTransformation, 0, 0, 0, backgroundRedComponent,
                                                                                0, greenTransformation, 0, 0, backgroundGreenComponent,
                                                                                0, 0, blueTransformation, 0, backgroundBlueComponent,
                                                                                0, 0, 0, 1, 0 ] );

            _filterCanvas.filters = [ desaturationMatrix, resaturationMatrix ];
        }

			
		public function setControlForegroundColor( color:uint ):void
		{
		    _foregroundColor = color;			
	
            updateFilter();
		    renderBackgroundCanvas();
		}
	
		
		public function setControlRepositionable( repositionable:Boolean ):void
		{
		    _repositionable = repositionable;
		}
			
			
		public function setControlAttributeLabels( attributeLabels:Object ):void
		{
			_control.dispatchEvent( new IntegraControlEvent( IntegraControlEvent.HOST_ATTRIBUTE_LABELS_CHANGED, attributeLabels ) );
		}
	
			
		public function setGlow( glowTarget:DisplayObject, glowAmount:Number ):void
		{
		    const glowCoefficient:Number = 3;
	
		    glowAmount = Math.max( 0, Math.min( 1, glowAmount ) );
				
		    Assert.assertNotNull( glowTarget );
				
		    var glow:GlowFilter = new GlowFilter( _foregroundColor, 0.6, 10, 10, glowAmount * glowCoefficient );
		    var filterArray:Array = new Array;
		    filterArray.push( glow );
		    glowTarget.filters = filterArray;
		}
			
			
		public function isAttributeWritable( controlAttributeName:String ):Boolean
		{
		    if( !_writableFlags.hasOwnProperty( controlAttributeName ) )
		    {
				Assert.assertTrue( false );
				return false;
		    }
				
		    return ( _writableFlags[ controlAttributeName ] == true );
		} 
			
			
		public function getAllowedValues( controlAttributeName:String ):Vector.<Object>
		{
		    if( _allowedValues.hasOwnProperty( controlAttributeName ) )
		    {
				return _allowedValues[ controlAttributeName ];
		    }
				
		    return null;
		} 
	
	
	    // function is not used at the moment
		private function interpolateColors( color1:uint, color2:uint, interpolation:Number ):uint
		{
		    var redComponent1:Number = ( color1 >> 16 ) & 0xff;
		    var greenComponent1:Number = ( color1 >> 8 ) & 0xff;  
		    var blueComponent1:Number = color1 & 0xff;
		    
		    var redComponent2:Number = ( color2 >> 16 ) & 0xff;
		    var greenComponent2:Number = ( color2 >> 8 ) & 0xff;  
		    var blueComponent2:Number = color2 & 0xff;
		    
		    var interpolation2:Number = Math.max( 0, Math.min( 1, interpolation ) );
		    var interpolation1:Number = 1 - interpolation2;
		    
		    var redResult:int = redComponent1 * interpolation1 + redComponent2 * interpolation2;
		    var greenResult:int = greenComponent1 * interpolation1 + greenComponent2 * interpolation2;
		    var blueResult:int = blueComponent1 * interpolation1 + blueComponent2 * interpolation2; 			
		    
		    redResult = Math.max( 0, Math.min( 255, redResult ) );
		    greenResult = Math.max( 0, Math.min( 255, greenResult ) );
		    blueResult = Math.max( 0, Math.min( 255, blueResult ) );
		    
		    return ( redResult << 16 ) | ( greenResult << 8 ) | blueResult;
		}
	
	
		private function onValuesChanged( event:IntegraControlEvent ):void
		{
		    var data:Object = event.data;
		    var changedValues:Object = new Object;
		    var anythingChanged:Boolean = false;
				
		    for( var attributeName:String in data )
		    {
				if( !isAttributeWritable( attributeName ) )
				{
				    Assert.assertTrue( false );		//attempt to modify readonly attribute
				    continue; 
				}
						
				var newValue:Object = getQuantisedValue( attributeName, data[ attributeName ] );
						
				if( !_values.hasOwnProperty( attributeName ) || _values[ attributeName ] != newValue )
				{
				    _values[ attributeName ] = newValue;
				    changedValues[ attributeName ] = newValue;
				    anythingChanged = true;
				}  
		    }
				
		    if( anythingChanged )
		    {
				_control.onValueChange( changedValues );
				if( _notificationSink )
				{
					_notificationSink.controlValuesChanged( changedValues );
				}
		    }			
		}
			
			
		private function onTextEquivalentsChanged( event:IntegraControlEvent ):void
		{
		    var changedTextEquivalents:Object = event.data;
		    for( var attributeName:String in changedTextEquivalents )
		    {	
				if( !isAttributeWritable( attributeName ) )
				{
				    Assert.assertTrue( false );		//attempt to modify readonly attribute
				    return; 
				}
		    }
				
			if( _notificationSink )
			{
				_notificationSink.controlTextEquivalentsChanged( changedTextEquivalents );
			}
		}
			
			
		private function getQuantisedValue( attributeName:String, rawValue:Object ):Object
		{
		    var allowedValues:Vector.<Object> = _allowedValues[ attributeName ]; 
		    if( !allowedValues ) 
		    {
				return rawValue;	
		    }
				
		    var bestDifference:Number = 0;
		    var bestValue:Object = null;
		    var first:Boolean = true;
				
		    for each( var allowedValue:Object in allowedValues )
		    {
				var myDifference:Number = getValueDifference( rawValue, allowedValue );
				if( first || myDifference < bestDifference )
				{
				    bestValue = allowedValue;
				    bestDifference = myDifference;
				    first = false;
				} 
		    }
				
		    if( !first )
		    {
				return bestValue;
		    }
				
		    Assert.assertTrue( false );
		    return rawValue;
		}
			
			
		//generic object for comparing values - allows numbers and strings to be intermingled, while
		//allowing avoidance of == with numbers, in case of fp rounding errors 
		private function getValueDifference( value1:Object, value2:Object ):Number
		{
		    if( value1 is Number && value2 is Number ) 
		    {
				return Math.abs( Number( value1 ) - Number( value2 ) );
		    }
				
		    if( value1 is String && value2 is String ) 
		    {
				return ( value1 == value2 ) ? 0 : 1;
		    }
				
		    if( value1 is ByteArray && value2 is ByteArray )
		    {
				return ( value1 == value2 ) ? 0 : 1;
		    }
				
		    Assert.assertTrue( false );		//values are of mismatching type
		    return 1;
		}
					
			
		private function onAttributeLabelPositioned( event:IntegraControlEvent ):void
		{
		    for( var attributeLabel:String in event.data )
		    {
				_attributeLabelPositions[ attributeLabel ] = event.data[ attributeLabel ];
		    } 
		}
			
			
		private function onAttributeLabelEditstateChanged( event:IntegraControlEvent ):void
		{
		    for( var attributeLabel:String in event.data )
		    {
				var isEditing:Boolean = event.data[ attributeLabel ];
				_attributeLabelEditStates[ attributeLabel ] = isEditing;
						
				if( isEditing )
				{
				    updateIsInActiveArea();
				}
		    } 
		}
	
	
		private function onControlMouseMove( event:MouseEvent ):void
		{
		    updateIsInActiveArea();
		    _mouseInControl = true;
		}
	
	
		private function onControlMouseOut( event:MouseEvent ):void
		{
		    _mouseInActiveArea = false;
		    _mouseInControl = false;
		}
			
			
		private function onControlMouseDown( event:MouseEvent ):void
		{
		    if( _mouseInActiveArea && _control.isActiveArea( new Point( _control.mouseX, _control.mouseY ) ) )
		    {
				_control.onMouseDown( event );
		    }			
		    else
		    {
				if( _repositionable )
				{
					if( _notificationSink )
					{
						_notificationSink.startRepositionDrag();
					}
				}
		    }
		}
			
			
		private function updateIsInActiveArea():void
		{
		    if( isMouseInEditingLabel() )
		    {
				_mouseInActiveArea = true;
				CursorSetter.setCursor( CursorSetter.ARROW, _control );
				return;				
		    }
	
		    var mouseInActiveArea:Boolean = isMouseInActiveArea();
		    if( mouseInActiveArea != _mouseInActiveArea )
		    {
				_mouseInActiveArea = mouseInActiveArea;

				if( _mouseInActiveArea )
				{
					CursorSetter.setCursor( CursorSetter.HAND, _control );
				}
				else
				{
					if( _repositionable )
					{
						CursorSetter.setCursor( CursorSetter.MOVE_NSEW, _control );
					}
					else
					{
						CursorSetter.setCursor( CursorSetter.ARROW, _control );
					}
				}
		    }
		}
			
			
		private function isMouseInActiveArea():Boolean
		{
		    //check whether control has any writable attributes (early exit if no)
		    var foundWritableAttribute:Boolean = false;
		    for each( var flag:Boolean in _writableFlags )
		    {
				if( flag )
				{
				    foundWritableAttribute = true;
				    break;
				}
		    }
				
		    if( !foundWritableAttribute )
		    {
				return false;
		    }
				
		    //check whether mouse is over a writable attribute label
		    for( var attributeName:String in _attributeLabelPositions )
		    {
				Assert.assertTrue( _writableFlags.hasOwnProperty( attributeName ) );
				if( !_writableFlags[ attributeName ] )
				{
				    continue;	//skip attribute labels which are not writable
				}
						
				var labelPosition:Rectangle = _attributeLabelPositions[ attributeName ] as Rectangle;
				Assert.assertNotNull( labelPosition );
						
				if( labelPosition.contains( _control.stage.mouseX, _control.stage.mouseY ) ) 
				{
				    return true;	
				} 
		    } 
				
		    return _control.isActiveArea( new Point( _control.mouseX, _control.mouseY ) );
		}
			
			
		private function isMouseInEditingLabel():Boolean
		{
		    for( var attributeName:String in _attributeLabelEditStates )
		    {
				if( _attributeLabelEditStates[ attributeName ] != true )
				{
				    continue;		//only interested in labels which are being editted
				}
						
				var labelPosition:Rectangle = _attributeLabelPositions[ attributeName ] as Rectangle;
				Assert.assertNotNull( labelPosition );
						
				if( labelPosition.contains( _control.stage.mouseX, _control.stage.mouseY ) ) 
				{
				    return true;	
				} 
		    }
				
		    return false;
		}
			
	
		private function onStartDrag( event:IntegraControlEvent ):void
		{
			MouseCapture.instance.setCapture( this, onDrag, onEndDrag, CursorSetter.HIDDEN ); 
		}

		
		private function onDrag( event:MouseEvent ):void
		{
		    _control.onDrag( event );	
		}

		
		private function onEndDrag():void
		{
			if( _mouseInControl )
			{
				updateIsInActiveArea();
			}
			
			_control.onEndDrag();
		}
		
			
		private function onResizeBackground( event:Event ):void
		{
		    renderBackgroundCanvas();
		}
			
			
		private function renderBackgroundCanvas():void
		{
			if( !_backgroundCanvas ) 
			{
				return;
			}
				
		    var colors:Array = [ _topBackgroundColor, _bottomBackgroundColor ];
		    var alphas:Array = [ 1, 1 ];
		    var ratios:Array = [0x00, 0xFF];
	
		    var matrix:Matrix = new Matrix();
		    matrix.createGradientBox( _backgroundCanvas.width, _backgroundCanvas.height, Math.PI / 2 );
	
		    _backgroundCanvas.graphics.clear();
	
		    _backgroundCanvas.graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
		    _backgroundCanvas.graphics.drawRect( 0, 0, _backgroundCanvas.width, _backgroundCanvas.height );
		    _backgroundCanvas.graphics.endFill();
		}
		
		
		private var _control:IntegraControl = null; 
		private var _parent:DisplayObjectContainer = null;
		private var _notificationSink:ControlNotificationSink = null;
			
		private var _attributes:Object = new Object; 
	
		private var _values:Object = new Object;
		private var _textEquivalents:Object = new Object;
		private var _writableFlags:Object = new Object;
		private var _allowedValues:Object = new Object;
		private var _repositionable:Boolean = false;
	
		private var _mouseInActiveArea:Boolean = false;
		private var _mouseInControl:Boolean = false;
	
		private var _attributeLabelPositions:Object = new Object;
		private var _attributeLabelEditStates:Object = new Object;
			
		private var _backgroundCanvas:Canvas = null;
		private var _topBackgroundColor:uint = 0;
		private var _bottomBackgroundColor:uint = 0;
		private var _foregroundColor:uint = 0;
			
		private var _filterCanvas:Canvas = null;
    }
}