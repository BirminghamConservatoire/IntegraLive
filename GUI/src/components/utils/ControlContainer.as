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


package components.utils
{
	import __AS3__.vec.Vector;
	
	import components.controlSDK.core.ControlAttributeType;
	import components.controlSDK.core.ControlManager;
	import components.controlSDK.core.ControlNotificationSink;
	import components.controller.IntegraController;
	import components.controller.serverCommands.SetModuleAttribute;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Connection;
	import components.model.Envelope;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.Constraint;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.ColorScheme;
	import components.model.userData.LiveViewControl;
	import components.views.MouseCapture;
	import components.views.Skins.TickButtonSkin;
	
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import flexunit.framework.Assert;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	

	public class ControlContainer extends Canvas implements ControlNotificationSink
	{
		public function ControlContainer( moduleID:int, widget:WidgetDefinition, model:IntegraModel, controller:IntegraController )
		{
			super();
		
			Assert.assertNotNull( model );
			Assert.assertNotNull( controller );
			Assert.assertNotNull( widget );

			_model = model;
			_controller = controller;
			_widget = widget;

			_module = _model.getModuleInstance( moduleID );
			Assert.assertNotNull( _module );

			_color = getStyle( "color" );
		
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF; 
		
			var controlClass:Class = ControlManager.getClassReference( widget.type );
			if( !controlClass )
			{
				Assert.assertTrue( false );
				return;
			}
			
			_control = new ControlManager( controlClass, this, this );
			
			_control.leftPadding = sidePadding;
			_control.rightPadding = sidePadding;
			_control.topPadding = topPadding;
			_control.bottomPadding = bottomPadding;

			_mapWidgetAttributeToType = _control.attributes;
			
			setControlBackgroundColors();
			setControlForegroundColor();
			setControlAttributeLabels();
			
			getValuesFromModel();			
			setControlAllowedValues();
			setControlValues();
			setControlTextEquivalents();
			setControlWritableFlags();
			setControlRepositionable();
			
			updatePadlockImage();
			
			_controlLabel = new Label;
			_controlLabel.setStyle( "left", resizeAreaWidth );
			_controlLabel.setStyle( "right", resizeAreaWidth );
			_controlLabel.setStyle( "bottom", bottomPadding );
			_controlLabel.setStyle( "textAlign", "center" );
			_controlLabel.setStyle( FontSize.STYLENAME, FontSize.NORMAL );
			_controlLabel.setStyle( "color", _color );
			_controlLabel.minWidth = 0;
			addElement( _controlLabel );

			addEventListener( Event.RESIZE, onResize );
			
			updateBevelFilter();
		}

		public function get module():ModuleInstance { return _module; }
		public function get widget():WidgetDefinition { return _widget; }
		
		public static function get marginSizeWithoutLabel():Point { return new Point( sidePadding * 2, topPadding + bottomPadding ); }
		public static function get marginSizeWithLabel():Point { return marginSizeWithoutLabel.add( new Point( 0, controlLabelHeight ) ); }

		
		public function updateOnModuleAttributeChanged( controllerCommandID:int ):void
		{
			var key:String = String( controllerCommandID );
			if( _myControllerCommandIDs.hasOwnProperty( key ) )
			{
				//when the command came from this view don't update (but do remove our memory of it to prevent memory hoarding)
				delete _myControllerCommandIDs[ key ];
				
				return;					
			}			

			
			//todo - only set the values that has changed!
			getValuesFromModel();			
			setControlValues();
			setControlTextEquivalents();
		}
		
		
		public function set hasIncludeInLiveViewButton( hasButton:Boolean ):void 
		{
			if( hasButton && !_includeInLiveViewButton )
			{
				_includeInLiveViewButton = new Button;
				_includeInLiveViewButton.toggle = true;
				_includeInLiveViewButton.width = liveButtonSize;
				_includeInLiveViewButton.height = liveButtonSize;
				_includeInLiveViewButton.setStyle( "right", 1 );
				_includeInLiveViewButton.setStyle( "top", 1 );
				_includeInLiveViewButton.setStyle( "skin", TickButtonSkin );
				_includeInLiveViewButton.setStyle( "color", _color );
				_includeInLiveViewButton.addEventListener( MouseEvent.CLICK, onIncludeInLiveViewButton );
				_includeInLiveViewButton.addEventListener( MouseEvent.DOUBLE_CLICK, onIncludeInLiveViewButton );
				addElement( _includeInLiveViewButton );
			}
			
			if( !hasButton && _includeInLiveViewButton )
			{
				_includeInLiveViewButton.removeEventListener( MouseEvent.CLICK, onIncludeInLiveViewButton );
				_includeInLiveViewButton.removeEventListener( MouseEvent.DOUBLE_CLICK, onIncludeInLiveViewButton );
				removeElement( _includeInLiveViewButton );
				_includeInLiveViewButton = null;				
			}
		}
		
		
		public function set canReposition( canReposition:Boolean ):void
		{
			if( canReposition == _canReposition ) return;
			
			_canReposition = canReposition;
			
			setControlRepositionable();
			
			if( _repositionAreas )
			{
				for each( var repositionArea:Canvas in _repositionAreas )
				{
					repositionArea.removeEventListener( MouseEvent.ROLL_OVER, onRollOverRepositionArea );
					repositionArea.removeEventListener( MouseEvent.MOUSE_DOWN, onMouseDownRepositionArea );
					removeElement( repositionArea );
				}
				
				_repositionAreas = null;

				Assert.assertNotNull( _bottomMoveArea );
				_bottomMoveArea = null; 
			}
			
			if( _canReposition )
			{
				_repositionAreas = new Vector.<Canvas>;
				
				var topMoveArea:Canvas = new Canvas;
				topMoveArea.setStyle( "left", resizeAreaWidth );
				topMoveArea.setStyle( "right", resizeAreaWidth );
				topMoveArea.y = resizeAreaWidth;
				topMoveArea.height = topPadding - resizeAreaWidth;
				addRepositionArea( RepositionType.MOVE, topMoveArea );

				var leftMoveArea:Canvas = new Canvas;
				leftMoveArea.setStyle( "left", resizeAreaWidth );
				leftMoveArea.setStyle( "top", resizeAreaWidth );
				leftMoveArea.width = sidePadding - resizeAreaWidth;
				leftMoveArea.setStyle( "bottom", resizeAreaWidth );
				addRepositionArea( RepositionType.MOVE, leftMoveArea );

				var rightMoveArea:Canvas = new Canvas;
				rightMoveArea.setStyle( "right", resizeAreaWidth );
				rightMoveArea.width = sidePadding - resizeAreaWidth;
				rightMoveArea.setStyle( "top", resizeAreaWidth );
				rightMoveArea.setStyle( "bottom", resizeAreaWidth );
				addRepositionArea( RepositionType.MOVE, rightMoveArea );

				Assert.assertNull( _bottomMoveArea );
				_bottomMoveArea = new Canvas;
				_bottomMoveArea.setStyle( "left", resizeAreaWidth );
				_bottomMoveArea.setStyle( "right", resizeAreaWidth );
				_bottomMoveArea.setStyle( "bottom", resizeAreaWidth );
				_bottomMoveArea.height = bottomPadding - resizeAreaWidth;
				addRepositionArea( RepositionType.MOVE, _bottomMoveArea );
				
				var resizeTopArea:Canvas = new Canvas;
				resizeTopArea.setStyle( "left", cornerWidth );
				resizeTopArea.setStyle( "right", cornerWidth );
				resizeTopArea.setStyle( "top", 0 );
				resizeTopArea.height = resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_TOP, resizeTopArea );

				var resizeBottomArea:Canvas = new Canvas;
				resizeBottomArea.setStyle( "left", cornerWidth );
				resizeBottomArea.setStyle( "right", cornerWidth );
				resizeBottomArea.setStyle( "bottom", 0 );
				resizeBottomArea.height = resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_BOTTOM, resizeBottomArea );
				
				var resizeLeftArea:Canvas = new Canvas;
				resizeLeftArea.setStyle( "left", 0 );
				resizeLeftArea.width = resizeAreaWidth;
				resizeLeftArea.setStyle( "top", cornerHeight );
				resizeLeftArea.setStyle( "bottom", cornerHeight );
				addRepositionArea( RepositionType.RESIZE_LEFT, resizeLeftArea );

				var resizeRightArea:Canvas = new Canvas;
				resizeRightArea.setStyle( "right", 0 );
				resizeRightArea.width = resizeAreaWidth;
				resizeRightArea.setStyle( "top", cornerHeight );
				resizeRightArea.setStyle( "bottom", cornerHeight );
				addRepositionArea( RepositionType.RESIZE_RIGHT, resizeRightArea );

				var resizeTopLeftArea1:Canvas = new Canvas;
				resizeTopLeftArea1.setStyle( "left", 0 );
				resizeTopLeftArea1.setStyle( "top", 0 );
				resizeTopLeftArea1.width = cornerWidth;
				resizeTopLeftArea1.height = resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_TOPLEFT, resizeTopLeftArea1 );

				var resizeTopLeftArea2:Canvas = new Canvas;
				resizeTopLeftArea2.setStyle( "left", 0 );
				resizeTopLeftArea2.setStyle( "top", resizeAreaWidth );
				resizeTopLeftArea2.width = resizeAreaWidth;
				resizeTopLeftArea2.height = cornerHeight - resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_TOPLEFT, resizeTopLeftArea2 );

				var resizeTopRightArea1:Canvas = new Canvas;
				resizeTopRightArea1.setStyle( "right", 0 );
				resizeTopRightArea1.setStyle( "top", 0 );
				resizeTopRightArea1.width = cornerWidth;
				resizeTopRightArea1.height = resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_TOPRIGHT, resizeTopRightArea1 );

				var resizeTopRightArea2:Canvas = new Canvas;
				resizeTopRightArea2.setStyle( "right", 0 );
				resizeTopRightArea2.setStyle( "top", resizeAreaWidth );
				resizeTopRightArea2.width = resizeAreaWidth;
				resizeTopRightArea2.height = cornerHeight - resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_TOPRIGHT, resizeTopRightArea2 );

				var resizeBottomLeftArea1:Canvas = new Canvas;
				resizeBottomLeftArea1.setStyle( "left", 0 );
				resizeBottomLeftArea1.setStyle( "bottom", 0 );
				resizeBottomLeftArea1.width = cornerWidth;
				resizeBottomLeftArea1.height = resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_BOTTOMLEFT, resizeBottomLeftArea1 );

				var resizeBottomLeftArea2:Canvas = new Canvas;
				resizeBottomLeftArea2.setStyle( "left", 0 );
				resizeBottomLeftArea2.setStyle( "bottom", resizeAreaWidth );
				resizeBottomLeftArea2.width = resizeAreaWidth;
				resizeBottomLeftArea2.height = cornerHeight - resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_BOTTOMLEFT, resizeBottomLeftArea2 );

				var resizeBottomRightArea1:Canvas = new Canvas;
				resizeBottomRightArea1.setStyle( "right", 0 );
				resizeBottomRightArea1.setStyle( "bottom", 0 );
				resizeBottomRightArea1.width = cornerWidth;
				resizeBottomRightArea1.height = resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_BOTTOMRIGHT, resizeBottomRightArea1 );

				var resizeBottomRightArea2:Canvas = new Canvas;
				resizeBottomRightArea2.setStyle( "right", 0 );
				resizeBottomRightArea2.setStyle( "bottom", resizeAreaWidth );
				resizeBottomRightArea2.width = resizeAreaWidth;
				resizeBottomRightArea2.height = cornerHeight - resizeAreaWidth;
				addRepositionArea( RepositionType.RESIZE_BOTTOMRIGHT, resizeBottomRightArea2 );
			}
		}


		public function set includeInLiveView( includeInLiveView:Boolean ):void 
		{
			Assert.assertNotNull( _includeInLiveViewButton );
			
			_includeInLiveViewButton.selected = includeInLiveView;
		}
		
		
		public function set includeInstanceNameInLabel( includeInstanceNameInLabel:Boolean ):void
		{
			_includeInstanceNameInLabel = includeInstanceNameInLabel;
			
			updateControlLabel();
		}


        public function updateWritableness():void
        {
       		setControlWritableFlags();

			updatePadlockImage();
        }


        private function updatePadlockImage():void
        {
			if( shouldDisplayPadlock() )
			{
				if( !_padlockImage )
				{
					_padlockImage = new Image;
					_padlockImage.source = _padlockImageClass;
					_padlockImage.x = 2;
					_padlockImage.y = 2;
					addElement( _padlockImage );
				}

				Assert.assertNotNull( _padlockExplanation );				
				_padlockImage.toolTip = _padlockExplanation;
				_padlockImage.alpha = _padlockAlpha;
			}
			else
			{
				if( _padlockImage )
				{
					removeElement( _padlockImage );
					_padlockImage = null;
				}
			}
        }


		override public function styleChanged( style:String ):void
		{
			if( !style || style == "color" )
			{
				var newColor:uint = getStyle( "color" );
				if( newColor != _color )
				{ 
					_color = newColor; 
				
					_controlLabel.setStyle( "color", _color );
				
					if( _includeInLiveViewButton )
					{
						_includeInLiveViewButton.setStyle( "color", _color );
					}
				
					setControlForegroundColor();
				}
			}
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_bottomBackgroundColor = 0xefefef;
						_topBackgroundColor = 0xd8d8d8;
						break;
						
					case ColorScheme.DARK:
						_bottomBackgroundColor = 0x101010;
						_topBackgroundColor = 0x282828;
						break;
				}
				
				invalidateDisplayList();
				
				setControlBackgroundColors();
				
				updateBevelFilter();
			}
		}

		
		public function controlValuesChanged( changedValues:Object ):void
		{
			//todo - we need a controller command which can set multiple attributes in a single operation!

			for( var widgetAttributeName:String in changedValues )
			{ 
				var endpointDefinition:EndpointDefinition = getEndpointDefinitionFromWidgetAttribute( widgetAttributeName );
				if( !endpointDefinition )
				{
					continue;
				}
	
				var command:SetModuleAttribute = generateSetCommand( endpointDefinition, changedValues[ widgetAttributeName ], widgetAttributeName );
				
				if( command )
				{	
					_myControllerCommandIDs[ String( command.id ) ] = 1;

					_controller.processCommand( command );
				}
			}
			
			setControlTextEquivalents();
		}


		public function controlTextEquivalentsChanged( changedTextEquivalents:Object ):void
		{
			//todo - we need a controller command which can set multiple attributes in a single operation!
			
			for( var widgetAttributeName:String in changedTextEquivalents )
			{
				var text:String = changedTextEquivalents[ widgetAttributeName ];
				Assert.assertNotNull( text );

				var endpoint:EndpointDefinition = getEndpointDefinitionFromWidgetAttribute( widgetAttributeName );
				if( !endpoint || endpoint.type != EndpointDefinition.CONTROL )
				{
					Assert.assertTrue( false );
					continue;
				}
				
				switch( endpoint.controlInfo.type )
				{
					case ControlInfo.STATE:

						switch( endpoint.controlInfo.stateInfo.type )
						{
							case StateInfo.INTEGER:
							case StateInfo.FLOAT:
								var newValue:Number = Number( text );
								if( isNaN( newValue ) )
								{
									continue;
								}
								
								if( endpoint.controlInfo.stateInfo.constraint.allowedValues )
								{
									newValue = Number( quantizeToAllowedValues( newValue, endpoint.controlInfo.stateInfo.constraint.allowedValues ) );  
								}
								else
								{
									newValue = Math.max( newValue, endpoint.controlInfo.stateInfo.constraint.minimum ); 
									newValue = Math.min( newValue, endpoint.controlInfo.stateInfo.constraint.maximum );
								}
								
								switch( endpoint.controlInfo.stateInfo.type )
								{
									case StateInfo.FLOAT:
										_controller.processCommand( new SetModuleAttribute( _module.id, endpoint.name, newValue, StateInfo.FLOAT ) );
										_mapWidgetAttributeToValue[ widgetAttributeName ] = newValue;
										break;
									
									case StateInfo.INTEGER:
										var intValue:int = Math.round( newValue );
										_controller.processCommand( new SetModuleAttribute( _module.id, endpoint.name, intValue, StateInfo.INTEGER ) );
										_mapWidgetAttributeToValue[ widgetAttributeName ] = newValue;
										break;
									
									default:
										Assert.assertTrue( false );
										break;
								}
								break;
							
							case StateInfo.STRING:
								
								if( endpoint.controlInfo.stateInfo.constraint.allowedValues )
								{
									text = String( quantizeToAllowedValues( text, endpoint.controlInfo.stateInfo.constraint.allowedValues ) );  
								}
								
								_controller.processCommand( new SetModuleAttribute( _module.id, endpoint.name, text, StateInfo.STRING ) );
								_mapWidgetAttributeToValue[ widgetAttributeName ] = text;
								break;
							
							default:
								Assert.assertTrue( false );
								break;
						}
						break;;
						
					
					case ControlInfo.BANG:
						Assert.assertTrue( false );	//text-equivalent not supported for band endpoints
						break;						
						
					default:
						Assert.assertTrue( false );
						continue;
				}
			}
			
			setControlValues();			
		}
		
		
		public function startRepositionDrag():void
		{
			dispatchEvent( new StartControlRepositionEvent( this, RepositionType.MOVE ) );
		}
		

		override protected function updateDisplayList( width:Number, height:Number ):void
        {
            super.updateDisplayList( width, height );

            graphics.clear();

			var colors:Array = [ _topBackgroundColor, _bottomBackgroundColor ];
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [0x00, 0xFF];

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, Math.PI / 2 );

			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
        	graphics.drawRoundRect( 0, 0, width, height, cornerWidth, cornerHeight );
        	graphics.endFill();
        }


		private function generateSetCommand( endpoint:EndpointDefinition, newValue:Object, widgetAttributeName:String ):SetModuleAttribute
		{
			Assert.assertTrue( endpoint.type == EndpointDefinition.CONTROL );
			
			if( _mapWidgetAttributeToType[ widgetAttributeName ] == ControlAttributeType.NUMBER )
			{
				if( isNaN( Number( newValue ) ) )
				{
					Assert.assertTrue( false );
					return null;
				}
				
				if( endpoint.controlInfo.type == ControlInfo.STATE )
				{
					var constraint:Constraint = endpoint.controlInfo.stateInfo.constraint;
					var allowedValues:Vector.<Object> = constraint.allowedValues;
					if( allowedValues )
					{
						newValue = allowedValues[ Number( newValue ) * ( allowedValues.length - 1 ) ];
					}
					else
					{
						newValue = ControlScaler.controlUnitToEndpointValue( Number( newValue ), endpoint.controlInfo.stateInfo ); 
					}
				}
			}

			switch( endpoint.controlInfo.type )
			{
				case ControlInfo.STATE:
					switch( endpoint.controlInfo.stateInfo.type )
					{
						case StateInfo.FLOAT:
							var floatValue:Number = Number( newValue );
							if( isNaN( floatValue ) )
							{
								Assert.assertTrue( false );
								return null;
							}
							
							_mapWidgetAttributeToValue[ widgetAttributeName ] = floatValue;
							return new SetModuleAttribute( _module.id, endpoint.name, floatValue, StateInfo.FLOAT );
		
						case StateInfo.INTEGER:
							var intValue:int = Math.round( Number( newValue ) );					
							if( isNaN( intValue ) )
							{
								Assert.assertTrue( false );
								return null;
							}
		
							_mapWidgetAttributeToValue[ widgetAttributeName ] = intValue;
							return new SetModuleAttribute( _module.id, endpoint.name, intValue, StateInfo.INTEGER );
							
						case StateInfo.STRING:
							var stringValue:String = String( newValue ); 
							if( stringValue == null )
							{
								Assert.assertTrue( false );
								return null;
							}
							_mapWidgetAttributeToValue[ widgetAttributeName ] = stringValue;
							return new SetModuleAttribute( _module.id, endpoint.name, stringValue, StateInfo.STRING );
		
						default:
							Assert.assertTrue( false );
							return null;
					}
					break;
				
				case ControlInfo.BANG:
					setControlValues();		//special case for 'nil' modules - set control back to default state immediately
					return new SetModuleAttribute( _module.id, endpoint.name );

				default:
					Assert.assertTrue( false );
					return null;
			}
		}


        private function shouldDisplayPadlock():Boolean
        {
        	return _padlockExplanation != null;
        }
        
        
		private function getValuesFromModel():void
		{
			if( !_module )
			{
				Assert.assertTrue( false );
				return;
			}
			
			_mapWidgetAttributeToValue = new Object;

			var attributeToEndpointMap:Object = _widget.attributeToEndpointMap;
			
			for( var widgetAttributeName:String in attributeToEndpointMap )
			{
				var endpoint:EndpointDefinition = getEndpointDefinitionFromWidgetAttribute( widgetAttributeName );
				if( !endpoint )
				{
					//type mismatch or other module definition error?
					Assert.assertTrue( false );
					continue;
				}

				if( endpoint.isStateful )
				{				
					_mapWidgetAttributeToValue[ widgetAttributeName ] = _module.attributes[ endpoint.name ];
				}
			}
		}	
        
        
		private function onIncludeInLiveViewButton( event:Event ):void
		{
			var liveViewControl:LiveViewControl = new LiveViewControl;
			liveViewControl.moduleID = _module.id;
			liveViewControl.controlInstanceName = _widget.label;
			_controller.processCommand( new ToggleLiveViewControl( liveViewControl ) );
		}

		
		private function onResize( event:Event ):void
		{
			if( _control )
			{
				updateControlLabel();
			}
			
			setControlBackgroundColors();
		}	


		private function addRepositionArea( repositionType:String, area:Canvas ):void
        {
        	Assert.assertNotNull( _repositionAreas );
        	area.id = repositionType;
        	addElement( area );
        	_repositionAreas.push( area );

        	area.addEventListener( MouseEvent.ROLL_OVER, onRollOverRepositionArea );
        	area.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDownRepositionArea );
        }
        
        
        private function onMouseDownRepositionArea( event:MouseEvent ):void
        {
        	dispatchEvent( new StartControlRepositionEvent( this, event.target.id ) );
        }
        
        
        private function onRollOverRepositionArea( event:MouseEvent ):void
        {
        	Assert.assertNotNull( event.target );
        	Assert.assertTrue( event.target is Canvas );
        	
        	var cursorType:String;
			
			var id:String = ( event.target as Canvas ).id;
        	switch( id )
        	{
        		case RepositionType.MOVE:				cursorType = CursorSetter.MOVE_NSEW;	break;
        		case RepositionType.RESIZE_LEFT:		cursorType = CursorSetter.RESIZE_EW;	break;
        		case RepositionType.RESIZE_RIGHT:		cursorType = CursorSetter.RESIZE_EW;	break;
        		case RepositionType.RESIZE_TOP:			cursorType = CursorSetter.RESIZE_NS;	break;
        		case RepositionType.RESIZE_BOTTOM:		cursorType = CursorSetter.RESIZE_NS;	break;
        		case RepositionType.RESIZE_TOPLEFT:		cursorType = CursorSetter.RESIZE_NESW;	break;
        		case RepositionType.RESIZE_TOPRIGHT:	cursorType = CursorSetter.RESIZE_SENW;	break;
        		case RepositionType.RESIZE_BOTTOMLEFT:	cursorType = CursorSetter.RESIZE_SENW;	break;
        		case RepositionType.RESIZE_BOTTOMRIGHT:	cursorType = CursorSetter.RESIZE_NESW;	break;
        		
        		default:
        			Assert.assertTrue( false );
        			return;
        	}
        	
			CursorSetter.setCursor( cursorType, event.target as UIComponent );
        }
        
        
		private function updateBevelFilter():void
		{
			var highlightColor:uint;
			var shadowColor:uint;

			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				case ColorScheme.LIGHT:
					highlightColor = 0xd0d0d0;
					shadowColor = 0xb0b0b0;
					break;
					
				case ColorScheme.DARK:
					highlightColor = 0x707070;
					shadowColor = 0x101010;
					break;
			}		
			
			var filterArray:Array = new Array;
			var filter:BevelFilter = new BevelFilter( 5, 45, highlightColor, 0.5, shadowColor, 0.5 );
			filterArray.push( filter );
			
			filters = filterArray;
		}
		
		
		private function updateControlLabel():void
		{
			var controlLabelText:String = new String;
		
			switch( Utilities.getNumberOfProperties( _widget.attributeToEndpointMap ) )
			{
				case 0:	//no  attributes
					Assert.assertTrue( false );
					break;
					
				case 1:	//control has only one attribute
					if( _includeInstanceNameInLabel )
					{
						controlLabelText = _module.name + ".";
					}
	
					for each( var moduleAttributeName:String in _widget.attributeToEndpointMap )
					{
						controlLabelText += moduleAttributeName;
					}
					break;
					
				default:	//control has more than one attribute 								
			
					if( _includeInstanceNameInLabel )
					{
						controlLabelText = _module.name;
					}
					break;
			}
			
			var hasControlLabel:Boolean = ( controlLabelText.length > 0 );
			
			var canFitControlLabel:Boolean = ( width >= minimumControlLabelWidth ) && ( height >= controlLabelHeight + bottomPadding + topPadding + ControlMeasurer.getMinimumSize( _widget.type ).y ); 
			
			var shouldShowControlLabel:Boolean = hasControlLabel && canFitControlLabel;
			
			if( shouldShowControlLabel )
			{
				_controlLabel.height = controlLabelHeight;
				_controlLabel.text = controlLabelText;
				_controlLabel.visible = true;
				
				_control.bottomPadding = bottomPadding + controlLabelHeight;
				
				_controlLabel.validateNow();
				_controlLabel.validateSize();
				if( _controlLabel.textWidth > width - resizeAreaWidth * 2 )
				{
					toolTip = controlLabelText;
				}
				else
				{
					toolTip = null;
				}
			} 
			else
			{
				_controlLabel.visible = false;

				_control.bottomPadding = bottomPadding;
				toolTip = controlLabelText;
			}

			if( _bottomMoveArea ) 
			{
				_bottomMoveArea.height = _control.bottomPadding - resizeAreaWidth;
			}

			setControlBackgroundColors();
		}


		private function setControlValues():void
		{
			if( !_module )
			{
				Assert.assertTrue( false );
				return;
			}
			
			var controlValues:Object = new Object;
			
			var attributeToEndpointMap:Object = _widget.attributeToEndpointMap;
			
			for( var widgetAttributeName:String in attributeToEndpointMap )
			{
				var controlAttributeType:String = _mapWidgetAttributeToType[ widgetAttributeName ];
				var endpoint:EndpointDefinition = getEndpointDefinitionFromWidgetAttribute( widgetAttributeName );
				Assert.assertNotNull( controlAttributeType );
				Assert.assertNotNull( endpoint );
				
				if( !endpoint.isStateful )
				{
					continue;
				}
				
				var constraint:Constraint = endpoint.controlInfo.stateInfo.constraint;
				var allowedValues:Vector.<Object> = constraint.allowedValues;
				if( allowedValues && _mapWidgetAttributeToType[ widgetAttributeName ] == ControlAttributeType.NUMBER )
				{
					controlValues[ widgetAttributeName ] = getNumericControlAttributeFromAllowedValues( allowedValues, widgetAttributeName );
				}
				else
				{
					//get control attribute directly
					
					switch( endpoint.controlInfo.stateInfo.type )
					{
						case StateInfo.FLOAT:
						case StateInfo.INTEGER:
							if( allowedValues || ( _mapWidgetAttributeToAllowedValues[ widgetAttributeName ] != null && _mapWidgetAttributeToType[ widgetAttributeName ] != ControlAttributeType.NUMBER ) )
							{
								//number mapped to an enumeration control
								Assert.assertTrue( _mapWidgetAttributeToType[ widgetAttributeName ] != ControlAttributeType.NUMBER );
								controlValues[ widgetAttributeName ] = _mapWidgetAttributeToValue[ widgetAttributeName ];
							}
							else
							{
								//number used directly in a number control - use ControlScaler 
								
								Assert.assertTrue( _mapWidgetAttributeToType[ widgetAttributeName ] == ControlAttributeType.NUMBER );

								controlValues[ widgetAttributeName ] = ControlScaler.endpointValueToControlUnit( _mapWidgetAttributeToValue[ widgetAttributeName ], endpoint.controlInfo.stateInfo );
							}
							break;
							
						case StateInfo.STRING:
							controlValues[ widgetAttributeName ] = _mapWidgetAttributeToValue[ widgetAttributeName ];
							break;
	
						default:
							Assert.assertTrue( false );
							break; 
					}
					
					//convert if type is different
					if( controlAttributeType == ControlAttributeType.NUMBER && endpoint.controlInfo.stateInfo.type != StateInfo.FLOAT && endpoint.controlInfo.stateInfo.type != StateInfo.INTEGER )
					{
						controlValues[ widgetAttributeName ] = Math.max( 0, Math.min( 1, Number( controlValues[ widgetAttributeName ] ) ) );
						
						if( isNaN( controlValues[ widgetAttributeName ] ) ) 
						{
							controlValues[ widgetAttributeName ] = 0; 
						}
					}
					
					if( controlAttributeType == ControlAttributeType.STRING && endpoint.controlInfo.stateInfo.type != StateInfo.STRING )
					{
						controlValues[ widgetAttributeName ] = String( controlValues[ widgetAttributeName ] );  
					}
				}
			}
			
			//tidy up in case of missing attributes (not all mapped)
			for( widgetAttributeName in _mapWidgetAttributeToType )
			{
				if( !controlValues.hasOwnProperty( widgetAttributeName ) )		
				{
					//not all attributes of this control are in use - need to initialise to something
					
					switch( _mapWidgetAttributeToType[ widgetAttributeName ] )
					{
						case ControlAttributeType.NUMBER:
							controlValues[ widgetAttributeName ] = 0;
							break;

						case ControlAttributeType.STRING:
							controlValues[ widgetAttributeName ] = "";
							break;
							
						default:
							Assert.assertTrue( false );
							break; 					
					}
				}
			}

			_control.setControlValues( controlValues );
		}
		
		
		private function setControlTextEquivalents():void
		{
			if( !_module )
			{
				Assert.assertTrue( false );
				return;
			}
			
			var controlTextEquivalents:Object = new Object;

			var attributeToEndpointMap:Object = _widget.attributeToEndpointMap;
			
			for( var widgetAttributeName:String in attributeToEndpointMap )
			{
				var endpoint:EndpointDefinition = getEndpointDefinitionFromWidgetAttribute( widgetAttributeName );
				Assert.assertNotNull( endpoint );
				
				if( !endpoint.isStateful )
				{
					continue;
				}
				
				switch( endpoint.controlInfo.stateInfo.type )
				{
					case StateInfo.INTEGER:
						Assert.assertTrue( _mapWidgetAttributeToValue[ widgetAttributeName ] is int );
						controlTextEquivalents[ widgetAttributeName ] = String( Math.round( _mapWidgetAttributeToValue[ widgetAttributeName ] as Number ) )
						break;

					case StateInfo.FLOAT:

						const numberOfSignificantFigures:int = 3;

						Assert.assertTrue( _mapWidgetAttributeToValue[ widgetAttributeName ] is Number );
						var value:Number = _mapWidgetAttributeToValue[ widgetAttributeName ]; 
						var numberOfDigits:int = 0;
						if( value != 0 )
						{
							numberOfDigits = Math.floor( Math.log( Math.abs( value ) ) / Math.LN10 ) + 1;
						}
						
						if( numberOfDigits >= numberOfSignificantFigures )
						{
							controlTextEquivalents[ widgetAttributeName ] = String( Math.round( value ) );
						}
						else
						{
							var multiplier:int = Math.pow( 10, numberOfSignificantFigures );
							var approximation:Number = Math.round( value * multiplier ) / multiplier;
							controlTextEquivalents[ widgetAttributeName ] = String( approximation );
						}
						break;

					case StateInfo.STRING:

						Assert.assertTrue( _mapWidgetAttributeToValue[ widgetAttributeName ] is String );
						controlTextEquivalents[ widgetAttributeName ] = _mapWidgetAttributeToValue[ widgetAttributeName ];
						break;
						
					default:
						Assert.assertTrue( false );
						break; 
				}
			}

			//tidy up in case of missing attributes (not all mapped)
			for( widgetAttributeName in _mapWidgetAttributeToType )
			{
				if( !controlTextEquivalents.hasOwnProperty( widgetAttributeName ) )		
				{
					//not all attributes of this control are in use - need to initialise to blank string
					controlTextEquivalents[ widgetAttributeName ] = "";
				}
			}

			_control.setControlTextEquivalents( controlTextEquivalents );
		}
		
		
		private function getEndpointDefinitionFromWidgetAttribute( widgetAttributeName:String ):EndpointDefinition
		{
			var endpointName:String = _widget.attributeToEndpointMap[ widgetAttributeName ];
			if( !endpointName )
			{
				return null;
			}
			
			var endpointDefinition:EndpointDefinition = _module.interfaceDefinition.getEndpointDefinition( endpointName );
			if( !endpointDefinition )
			{
				Assert.assertTrue( false );		//failed to find attribute definition from name
				return null;
			}

			return endpointDefinition;
		}


		private function setControlWritableFlags():void
		{
			_mapWidgetAttributeToWritableFlag = new Object;
			_padlockExplanation = null;
			_padlockAlpha = 1; 
			var attributeToEndpointMap:Object = _widget.attributeToEndpointMap;
			
			for( var widgetAttributeName:String in _mapWidgetAttributeToType )
			{
				if( !attributeToEndpointMap.hasOwnProperty( widgetAttributeName ) )
				{
					_mapWidgetAttributeToWritableFlag[ widgetAttributeName ] = false;
					appendPadlockExplanation( "The control '" + widgetAttributeName + "' is not mapped to a module attribute" );
					continue;
				} 
				
				var moduleAttributeName:String = attributeToEndpointMap[ widgetAttributeName ];
				
				var explanation:Object = new Object;
				var writable:Boolean = isModuleAttributeWritable( moduleAttributeName, explanation );
				_mapWidgetAttributeToWritableFlag[ widgetAttributeName ] = writable;
				if( writable )
				{
					_padlockAlpha = 0.3;		//display padlocks as semitransparent when only a subset of the control's attributes are readonly
				}
				else
				{
					Assert.assertNotNull( explanation.value );
					appendPadlockExplanation( explanation.value );
				} 
			}
			
			_control.setControlWritableFlags( _mapWidgetAttributeToWritableFlag ); 
		}
		
		
		private function setControlAllowedValues():void
		{
			_mapWidgetAttributeToAllowedValues = new Object;
			var attributeToEndpointMap:Object = _widget.attributeToEndpointMap;
			
			for( var widgetAttributeName:String in _mapWidgetAttributeToType )
			{
				if( !attributeToEndpointMap.hasOwnProperty( widgetAttributeName ) )
				{
					_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = null;
					continue;
				} 
				
				var endpoint:EndpointDefinition = getEndpointDefinitionFromWidgetAttribute( widgetAttributeName);
				Assert.assertNotNull( endpoint ); 
				
				if( endpoint.controlInfo.type == ControlInfo.BANG )
				{
					_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = null;
					continue;
				}

				if( endpoint.controlInfo.stateInfo.constraint.allowedValues )
				{
					setupExplicitAllowedValues( widgetAttributeName, endpoint );
				}
				else
				{
					setupImplicitAllowedValues( widgetAttributeName, endpoint );
				}
				
				fixTypesOfAllowedValues();
			}
			
			_control.setControlAllowedValues( _mapWidgetAttributeToAllowedValues ); 
		}
		
		
		private function setControlRepositionable():void
		{
			_control.setControlRepositionable( _canReposition );
		}
		
		
		private function setControlForegroundColor():void
		{
			_control.setControlForegroundColor( _color );
		}

		
		private function setControlBackgroundColors():void
		{
			if( height > 0 )
			{
				var topBackgroundColor:uint = Utilities.interpolateColors( _topBackgroundColor, _bottomBackgroundColor, topPadding / height ); 
				var bottomBackgroundColor:uint = Utilities.interpolateColors( _topBackgroundColor, _bottomBackgroundColor, ( height - _control.bottomPadding ) / height ); 
			
				_control.setControlBackgroundColors( topBackgroundColor, bottomBackgroundColor );
			}
		}
		
		
		private function setControlAttributeLabels():void
		{
			var attributeLabels:Object = new Object;

			var attributeToEndpointMap:Object = _widget.attributeToEndpointMap;
			
			//only send attribute names for controls which have more than one attribute - otherwise attribute name is included in main control label			
			if( attributeToEndpointMap && Utilities.getNumberOfProperties( attributeToEndpointMap ) > 1 )
			{
				for( var widgetAttributeName:String in attributeToEndpointMap )
				{
					attributeLabels[ widgetAttributeName ] = attributeToEndpointMap[ widgetAttributeName ];
				}
				
				//tidy up in case of missing attributes (not all mapped)
				for( widgetAttributeName in _mapWidgetAttributeToType )
				{
					if( !attributeLabels.hasOwnProperty( widgetAttributeName ) )		
					{
						//not all attributes of this control are in use - need to initialise to blank string
						attributeLabels[ widgetAttributeName ] = "";
					}
				}
			}
			
			_control.setControlAttributeLabels( attributeLabels );
		}
		
		
		private function appendPadlockExplanation( lineOfExplanation:String ):void
		{
			if( _padlockExplanation )
			{
				_padlockExplanation += "\n";
			}
			else
			{
				_padlockExplanation = "";
			}
			
			_padlockExplanation += lineOfExplanation;
		}
		
		
		private function getNumericControlAttributeFromAllowedValues( allowedValues:Vector.<Object>, widgetAttributeName:String ):Number
		{
			if( allowedValues.length < 2 )
			{
				Assert.assertTrue( false );
				return 0;
			}
					
			var bestDifference:Number = 0;
			var bestIndex:int = -1;
			
			for( var i:int = 0; i < allowedValues.length; i++ )
			{
				var myDifference:Number = getValueDifference( _mapWidgetAttributeToValue[ widgetAttributeName ], allowedValues[ i ] );
				if( bestIndex < 0 || myDifference < bestDifference )
				{
					bestIndex = i;
					bestDifference = myDifference;
				} 
			}
			
			if( bestIndex < 0 )
			{
				Assert.assertTrue( false );
				return 0;
			} 				
			
			return bestIndex / ( allowedValues.length - 1 );
		}
		
		
		private function quantizeToAllowedValues( value:Object, allowedValues:Vector.<Object> ):Object
		{
			if( allowedValues.length < 2 )
			{
				Assert.assertTrue( false );
				return value;
			}
					
			var bestDifference:Number = 0;
			var bestValue:Object = null;
			var first:Boolean = true;
			
			for each( var allowedValue:Object in allowedValues )
			{
				var myDifference:Number = getValueDifference( value, allowedValue );
				if( first || myDifference < bestDifference )
				{
					bestValue = allowedValue;
					bestDifference = myDifference;
					first = false;
				} 
			}
			
			Assert.assertFalse( first );
			
			return bestValue;
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


		private function setupImplicitAllowedValues( widgetAttributeName:String, endpoint:EndpointDefinition ):void
		{
			Assert.assertTrue( endpoint.type == EndpointDefinition.CONTROL );
			
			switch( endpoint.controlInfo.type )
			{
				case ControlInfo.BANG:
					_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = new Vector.<Object>;
					_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( 0 );
					_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( 1 );
					break;
				
				case ControlInfo.STATE:
					switch( endpoint.controlInfo.stateInfo.type )
					{
						case StateInfo.INTEGER:
							if( _mapWidgetAttributeToType[ widgetAttributeName ] == ControlAttributeType.NUMBER )
							{
								var constraint:Constraint = endpoint.controlInfo.stateInfo.constraint;
								//if control attribute is a number, map allowed range into 0..1
								var range:Number = constraint.range.maximum - constraint.range.minimum;
								if( range <= 0 )
								{
									//no range
									Assert.assertTrue( false );
									_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = null;
								}
								else
								{
									if( range <= maximumImplicitNotches )
									{
										_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = new Vector.<Object>;
										
										for( var i:int = 0; i <= range; i++ )
										{
											_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( i / range );
										}							
									}
									else
									{
										_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = null;
									} 
								}
							}
							else
							{
								//if control attribute isn't a number, just provide all legal values
								_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = new Vector.<Object>;
								for( i = constraint.range.minimum; i <= constraint.range.maximum; i++ )
								{
									_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( i );
								}							
							}
							break;
						
						case StateInfo.FLOAT:
						case StateInfo.STRING:
							_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = null;
							break;
						
						default:
							Assert.assertTrue( false );
							break;
					}
					
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}
		}


		private function setupExplicitAllowedValues( widgetAttributeName:String, endpoint:EndpointDefinition ):void
		{
			_mapWidgetAttributeToAllowedValues[ widgetAttributeName ] = new Vector.<Object>;
				
			Assert.assertTrue( endpoint.isStateful );
			
			var allowedValues:Vector.<Object> = endpoint.controlInfo.stateInfo.constraint.allowedValues;
			
			switch( _mapWidgetAttributeToType[ widgetAttributeName ] )
			{
				case ControlAttributeType.NUMBER:
					//when control is a number, evenly space the allowed values!
					var numberOfAllowedValues:int = allowedValues.length;
					if( numberOfAllowedValues < 2 )
					{
						//special case for not enough allowed values
						_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( 0 );
						return;
					}
					
					for( var i:int = 0; i < allowedValues.length; i++ )
					{
						_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( i / ( numberOfAllowedValues - 1 ) );	
					}
					
					break;
					
				case ControlAttributeType.STRING:
					for each( var allowedValue:Object in allowedValues )
					{
						_mapWidgetAttributeToAllowedValues[ widgetAttributeName ].push( String( allowedValue ) );
					}
					
					break;
					
				default:
					Assert.assertTrue( false );		//unknown control attribute type
					break;
			}
		}
		
		
		private function fixTypesOfAllowedValues():void
		{
			for( var widgetAttributeName:String in _mapWidgetAttributeToAllowedValues )
			{
				var controlAttributeType:String = _mapWidgetAttributeToType[ widgetAttributeName ];
				
				var allowedValues:Vector.<Object> = _mapWidgetAttributeToAllowedValues[ widgetAttributeName ];
				if( !allowedValues ) 
				{
					continue;
				}
				
				for( var i:int = 0; i < allowedValues.length; i++ )
				{
					switch( controlAttributeType )
					{
						case ControlAttributeType.NUMBER:
							Assert.assertTrue( allowedValues[ i ] is Number );
							break;
							
						case ControlAttributeType.STRING:
							if( !( allowedValues[ i ] is String ) )
							{
								allowedValues[ i ] = String( allowedValues[ i ] );
							}
							break;
							
						default:
							Assert.assertTrue( false );
							break;
					} 
				}
			} 
		}
		
		
		private function isModuleAttributeWritable( moduleAttributeName:String, explanationForNonWritability:Object ):Boolean
		{
			//if the module attribute is not writable, this method sets explanationForNonWritability's <value> attribute to 
			//a string containing an explanation for why the module attribute is not writable
			Assert.assertNotNull( explanationForNonWritability );
			
			var moduleID:int = _module.id;
			
			//walk parent chain looking for connections that target this attribute
			for( var container:IntegraContainer = _model.getBlockFromModuleInstance( moduleID ); container; container = _model.getParent( container.id ) as IntegraContainer )
			{
				for each( var connection:Connection in container.connections )
				{
					if( connection.targetObjectID != moduleID || connection.targetAttributeName != moduleAttributeName )
					{
						continue;
					}
					
					if( connection.sourceObjectID < 0 || connection.sourceAttributeName == null ) 
					{
						continue;
					}
					
					explanationForNonWritability.value = moduleAttributeName + " is controlled by ";
					
					var connectionSource:IntegraDataObject = _model.getDataObjectByID( connection.sourceObjectID );
					if( connectionSource is Envelope )
					{
						explanationForNonWritability.value += "an Envelope"; 
					}
					else
					{
						if( connectionSource is Scaler )
						{
							var scaler:Scaler = connectionSource as Scaler;
							var upstreamConnection:Connection = scaler.upstreamConnection;

							if( upstreamConnection.sourceObjectID < 0 || upstreamConnection.sourceAttributeName == null )
							{
								continue;
							}
							
							explanationForNonWritability.value += ( getRelativeDescription( upstreamConnection.sourceObjectID ) + upstreamConnection.sourceAttributeName );
						}
						else
						{
							explanationForNonWritability.value += ( getRelativeDescription( connectionSource.id ) + connection.sourceAttributeName );
						}
					}

					return false;
				}
			}
			
			return true;			
		}
		
		
		private function getRelativeDescription( objectID:int ):String
		{
			var objectPath:Array = _model.getPathArrayFromID( objectID );
			var modulePath:Array = _model.getPathArrayFromID( _module.id );
			Assert.assertTrue( objectPath.length > 0 );
			Assert.assertTrue( modulePath.length > 0 );
			
			for( var i:int = 0; i < modulePath.length; i++ )
			{
				if( objectPath.length == 1 && i < modulePath.length - 1 )
				{
					break;
				}
				
				if( modulePath[ i ] == objectPath[ 0 ] )
				{
					objectPath = objectPath.slice( 1, objectPath.length );
				}
			}
			
			var relativeDescription:String = objectPath.join( "." );
			if( relativeDescription.length > 0 )  
			{
				relativeDescription += ".";
			}
				
			return relativeDescription;
		} 
		
		
		private var _module:ModuleInstance;
		private var _widget:WidgetDefinition;
		private var _model:IntegraModel;
		private var _controller:IntegraController;
		private var _color:uint = 0;
		private var _control:ControlManager;

		private var _mapWidgetAttributeToType:Object = new Object;
		private var _mapWidgetAttributeToValue:Object = new Object;
		private var _mapWidgetAttributeToWritableFlag:Object = new Object;
		private var _mapWidgetAttributeToAllowedValues:Object = new Object;
		
		private var _controlLabel:Label = null;
		private var _bottomMoveArea:Canvas = null;  
		private var _padlockImage:Image = null;
		private var _padlockExplanation:String = null; 
		private var _padlockAlpha:Number = 0;

		[Embed(source="../../../src/assets/padlock.png")]
		private var _padlockImageClass:Class;
		
		private var _myControllerCommandIDs:Object = new Object;
		
		private var _includeInLiveViewButton:Button = null;
		
		private var _canReposition:Boolean = false;
		private var _repositionAreas:Vector.<Canvas> = null;	

		private var _includeInstanceNameInLabel:Boolean = false;

		private var _bottomBackgroundColor:uint = 0;
		private var _topBackgroundColor:uint = 0;

		private static const topPadding:Number = 14;
		private static const sidePadding:Number = 8;
		private static const bottomPadding:Number = 6;
		private static const cornerWidth:Number = 18;
		private static const cornerHeight:Number = 12;
		private static const resizeAreaWidth:Number = 4;
		private static const maximumImplicitNotches:int = 32;
		private static const liveButtonSize:Number = 12;
		private static const controlLabelHeight:int = 20;
		private static const minimumControlLabelWidth:int = 48;
	}
}