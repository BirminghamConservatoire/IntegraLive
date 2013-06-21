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


package components.views.ArrangeView
{
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	
	import spark.components.Application;
	
	import __AS3__.vec.Vector;
	
	import components.controller.serverCommands.AddControlPoint;
	import components.controller.serverCommands.RemoveControlPoint;
	import components.controller.serverCommands.RepositionControlPoint;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetControlPointCurvature;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.model.Block;
	import components.model.Connection;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	
	import flexunit.framework.Assert;


	public class EnvelopeView extends IntegraView
	{
		public function EnvelopeView( envelopeID:int )
		{
			super();
			
			_envelopeID = envelopeID;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;
			
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( AddControlPoint, onControlPointAdded );
			addUpdateMethod( RemoveControlPoint, onControlPointRemoved );
			addUpdateMethod( RepositionControlPoint, onControlPointRepositioned );
			addUpdateMethod( SetControlPointCurvature, onControlPointCurvatureChanged );
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( SetTrackColor, onTrackColorChanged );
			addUpdateMethod( SetContainerActive, onContainerActiveChanged );

			_dragLabel.setStyle( "color", 0x808080 );
			_dragLabel.setStyle( "textAlign", "center" );
			_dragLabelBackground.setStyle( "backgroundAlpha", 0.6 );
			_dragLabelBackground.setStyle( "borderStyle", "solid" );
			_dragLabelBackground.setStyle( "borderColor", 0x808080 );
			_dragLabelBackground.setStyle( "cornerRadius", 4 );
			_dragLabelBackground.addChild( _dragLabel );
			
			_envelope = model.getEnvelope( _envelopeID );
			_block = model.getBlockFromEnvelope( _envelopeID );
			_track = model.getTrackFromBlock( _block.id );

			Assert.assertNotNull( _envelope );
			Assert.assertNotNull( _block );
			Assert.assertNotNull( _track );
		}

		
		public function get envelopeID():int { return _envelopeID; }
		
		public function set curvatureMode( curvatureMode:Boolean ):void { _curvatureMode = curvatureMode; }

		
		override public function get color():uint
		{
			return model.getContainerColor( _block.id );
		}
		
		
		public function getHitTestDistance( x:Number, y:Number ):int
		{
			var local:Point = globalToLocal( new Point( x, y ) );
			if( local.x < 0 || local.x >= width || local.y < 0 || local.y >= height ) 
			{
				return -1;
			}
			 
			for( var distance:int = -_proximityMargin; distance <= _proximityMargin; distance++ )
			{ 
				if( hitTestPoint( x + distance, y + distance, true ) )
				{
					return Math.abs( distance );
				}

				if( hitTestPoint( x + distance, y - distance, true ) )
				{
					return Math.abs( distance );
				}

				if( hitTestPoint( x + distance, y, true ) )
				{
					return Math.abs( distance );
				}

				if( hitTestPoint( x, y + distance, true ) )
				{
					return Math.abs( distance );
				}
			}
			
			return -1;
		}
		
		
		public function handleMouseDown( event:MouseEvent ):void
		{
			Assert.assertTrue( !_isDraggingPoint && !_isDraggingCurve );

			if( _curvatureMode )
			{
				handleDragCurveMouseDown( event );
			}
			else
			{
				handleDragPointMouseDown( event );
			}
		}
		
		
		public function handleDoubleClick( event:MouseEvent ):void
		{
			if( _isDraggingPoint || _isDraggingCurve )
			{
				Assert.assertTrue( false );
				return;
			}
			
			if( _curvatureMode )
			{
				handleCurvatureModeDoubleClick();
			}
			else
			{
				handleDragPointDoubleClick();
			}
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_dragLabelBackground.setStyle( "backgroundColor", 0xcfcfcf );
						break;
					
					case ColorScheme.DARK:
						_dragLabelBackground.setStyle( "backgroundColor", 0x303030 );
						break;
				}
			}

			if( !style || style == FontSize.STYLENAME )
			{
				var fontSize:Number = getStyle( "fontSize" );
				_dragLabel.setStyle( "fontSize", fontSize );
			}
		} 
		

		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			//super.updateDisplayList( width, height );
			
			graphics.clear();
			
			if( !model || !_endpoint ) return;
			
			var controlPoints:Vector.<ControlPoint> = _envelope.orderedControlPoints;

			var controlPointTick:int = 0; 
			var prevControlPointTick:int = 0;
			var prevControlPointCurvature:Number = 0;			

			var controlPointValue:Number = 0;
			var prevControlPointValue:Number = 0;
			
			var isFirstControlPoint:Boolean = true;
			
			for each( var controlPoint:ControlPoint in controlPoints )
			{
				var controlPointID:int = controlPoint.id;
				
				if( _isDraggingPoint && controlPointID == _dragPointID )
				{
					controlPointTick = _dragPointTick; 
					controlPointValue = _dragPointValue;
				}	
				else
				{			
					controlPointTick = controlPoint.tick; 
					controlPointValue = controlPoint.value;
					
					if( getXPixelsFromTick( controlPointTick ) > width + 1 )
					{
						//drop out of render - this should only happen when block is being resized
						break;
					}
				}

				drawControlPoint( controlPointTick, controlPointValue );	

				if( isFirstControlPoint )
				{
					isFirstControlPoint = false;
				}
				else
				{
					drawTransition( prevControlPointTick, prevControlPointValue, controlPointTick, controlPointValue, prevControlPointCurvature );
				}
				
				prevControlPointTick = controlPointTick;
				prevControlPointValue = controlPointValue;
				
				if( _isDraggingCurve && controlPointID == _dragCurveID )
				{
					prevControlPointCurvature = _dragCurvature;
				}
				else
				{
					prevControlPointCurvature = controlPoint.curvature;
				}
			}		
			
			drawTransition( prevControlPointTick, prevControlPointValue, getTickFromXPixels( width ), prevControlPointValue, 0 );
		}


		override protected function onAllDataChanged():void
		{
			_endpoint = null;
			var envelopeTarget:Connection = model.getEnvelopeTarget( _envelopeID );
			if( envelopeTarget )
			{
				var module:ModuleInstance = model.getModuleInstance( envelopeTarget.targetObjectID );
				Assert.assertNotNull( module );

				if( envelopeTarget.targetAttributeName )
				{
					_endpoint = module.interfaceDefinition.getEndpointDefinition( envelopeTarget.targetAttributeName );
					Assert.assertNotNull( _endpoint );
				}
			}
			
			updateAlpha();
			updateGlow();

			invalidateDisplayList();
		}
		
		
		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			var connection:Connection = model.getConnection( command.connectionID );
			Assert.assertNotNull( connection );
			
			if( connection.sourceObjectID != _envelopeID || connection.sourceAttributeName != "currentValue" )
			{
				return;
			}
			
			_endpoint = null;
			
			if( connection.targetObjectID >= 0 )
			{
				var module:ModuleInstance = model.getModuleInstance( connection.targetObjectID );
				Assert.assertNotNull( module );

				if( connection.targetAttributeName )
				{
					_endpoint = module.interfaceDefinition.getEndpointDefinition( connection.targetAttributeName );
					Assert.assertNotNull( _endpoint );
				}
			}

			invalidateDisplayList();
		}


		private function onControlPointAdded( command:AddControlPoint ):void
		{
			if( command.envelopeID == _envelopeID ) 
			{
				invalidateDisplayList();
			}
		}
		
		
		private function onControlPointRemoved( command:RemoveControlPoint ):void
		{
			if( command.envelopeID == _envelopeID )
			{
				invalidateDisplayList();
			}
		}
		
		
		private function onControlPointRepositioned( command:RepositionControlPoint ):void
		{
			if( model.getEnvelopeFromControlPoint( command.controlPointID ).id == _envelopeID )
			{
				invalidateDisplayList();
			}
		}
		
		
		private function onControlPointCurvatureChanged( command:SetControlPointCurvature ):void
		{
			if( model.getEnvelopeFromControlPoint( command.controlPointID ).id == _envelopeID )
			{
				invalidateDisplayList();
			}
		}
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			updateAlpha();
			invalidateDisplayList();
		}
		
		
		private function onTrackColorChanged( command:SetTrackColor ):void
		{
			if( _track.id == command.trackID )
			{
				invalidateDisplayList();
				updateGlow();
			}
		}
		
		
		private function onContainerActiveChanged( command:SetContainerActive ):void
		{
			if( model.isEqualOrAncestor( command.containerID, _block.id ) )
			{
				invalidateDisplayList();
				updateGlow();
			}
		}
		
		
		private function get isSelected():Boolean
		{
			return ( model && model.selectedEnvelope && model.selectedEnvelope.id == _envelopeID );
		}
		
		
		private function get minimumCurvature():Number
		{
			var controlPointInterface:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( "ControlPoint" );
			Assert.assertNotNull( controlPointInterface );
			
			var curvatureEndpoint:EndpointDefinition = controlPointInterface.getEndpointDefinition( "curvature" );
			Assert.assertNotNull( curvatureEndpoint );
			
			return curvatureEndpoint.controlInfo.stateInfo.constraint.minimum;
		}

		
		private function get maximumCurvature():Number
		{
			var controlPointInterface:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( "ControlPoint" );
			Assert.assertNotNull( controlPointInterface );
			
			var curvatureEndpoint:EndpointDefinition = controlPointInterface.getEndpointDefinition( "curvature" );
			Assert.assertNotNull( curvatureEndpoint );
			
			return curvatureEndpoint.controlInfo.stateInfo.constraint.maximum;
		}
		
		
		private function get application():Application
		{
			for( var iterator:DisplayObjectContainer = parent; iterator; iterator = iterator.parent )
			{
				if( iterator is Application )
				{
					return iterator as Application;
				}
			}
			
			Assert.assertTrue( false );
			return null;
		}
		
		
		private function updateAlpha():void
		{
			alpha = isSelected ? 1 : 0.4;
		}
		
		
		private function updateGlow():void
		{
			var glow:GlowFilter = new GlowFilter( color, 0.5, 10, 10, 2 );
			var filterArray:Array = new Array;
			filterArray.push( glow );
			filters = filterArray;
		}

		
		private function drawControlPoint( controlPointTick:int, controlPointValue:Number ):void
		{
			if( !isSelected ) return;
			
			var color:uint = color;
			var controlPointX:Number = getXPixelsFromTick( controlPointTick );
			var controlPointY:Number = getYPixelsFromValue( controlPointValue );

			graphics.lineStyle( _controlPointLineThickness, color );
			graphics.beginFill( 0, 0 );
			graphics.drawCircle( controlPointX, controlPointY, _controlPointRadius );
			graphics.endFill();
		}
		
		
		private function drawTransition( fromTick:int, fromValue:Number, toTick:Number, toValue:Number, curvature:Number ):void
		{
			if( fromTick == toTick && fromValue == toValue ) return;
			
			const xIncrement:Number = 1;
			
			var color:uint = color;
			var fromX:Number = getXPixelsFromTick( fromTick );
			var fromY:Number = getYPixelsFromValue( fromValue );
			var toX:Number = getXPixelsFromTick( toTick );
			var toY:Number = getYPixelsFromValue( toValue );

			graphics.lineStyle( _transitionLineThickness, color );
			graphics.moveTo( fromX, fromY );

			var yRange:Number = ( toY - fromY );
			
			if( toX > fromX && curvature != 0 && yRange != 0 )
			{
				var xRangeInverse:Number = 1 /  ( toX - fromX );
				var exponent:Number = Math.pow( 2, -curvature );
			
				for( var x:Number = fromX + xIncrement; x <= toX - xIncrement; x += xIncrement )
				{
					var interpolation:Number = ( x - fromX ) * xRangeInverse;
					
					Assert.assertTrue( interpolation > 0 && interpolation <= 1 );
					
					interpolation = Math.pow( interpolation, exponent );
					
					graphics.lineTo( x, fromY + interpolation * yRange );
				}
			}
			
			graphics.lineTo( toX, toY );

			//todo - handle integer and allowed value steps
			
			/*switch( _endpoint.controlInfo.stateInfo.type )
			{
				case StateInfo.FLOAT:
					graphics.lineTo( toX, toY );
					break; 

				case StateInfo.INTEGER:
					var numberOfSteps:int = Math.round( Math.abs( toValue - fromValue ) );
					if( numberOfSteps == 0 )
					{
						//special case for flatline
						graphics.lineTo( toX, toY );
					}
					else
					{
						var prevY:Number = fromY;
						for( var i:int = 0; i < numberOfSteps; i++ )
						{
							var interpolation:Number = ( i + 1 ) / numberOfSteps;
							var interpolationOpposite:Number = ( 1 - interpolation );
							
							var nextX:Number = interpolation * toX + interpolationOpposite * fromX;
							var nextY:Number = interpolation * toY + interpolationOpposite * fromY;
							
							graphics.lineTo( nextX, prevY );
							graphics.lineTo( nextX, nextY );
							
							prevY = nextY;
						}
					}

					break;
					
				default:
					Assert.assertTrue( false );	//unexpected attribute type
					break; 
			}*/
		}

		
		private function handleDragPointMouseDown( event:MouseEvent ):void
		{
			Assert.assertTrue( !_isDraggingPoint && !_isDraggingCurve );
			
			_dragPointID = getControlPointUnderMouse();
			
			if( _dragPointID >= 0 )
			{
				_dragPointTick = ( _envelope.controlPoints[ _dragPointID ] as ControlPoint ).tick;
				_dragPointValue = ( _envelope.controlPoints[ _dragPointID ] as ControlPoint ).value;
			}
			else
			{
				_dragPointTick = Math.max( 1, getTickFromXPixels( mouseX ) );
				_dragPointValue = getValueFromYPixels( mouseY );
			}
			
			if( !isSelected ) 
			{
				controller.processCommand( new SetPrimarySelectedChild( _block.id, _envelopeID ) );
				
				if( _dragPointID < 0 && _dragPointTick > 0 )
				{ 
					//set the capture even though we don't need it, 
					//to prevent the play position from also being updated
					MouseCapture.instance.setCapture( this );	 
					return;
				}
			}
			
			if( _dragPointID < 0 ) 
			{
				var controlPointAtTick:ControlPoint = getControlPointAtTick( _dragPointTick );
				if( controlPointAtTick )
				{
					_dragPointID = controlPointAtTick.id;
				}
			}
			
			var nextControlPoint:ControlPoint = getNextControlPoint( _dragPointTick );
			if( nextControlPoint )
			{
				_dragPointLatestTick = nextControlPoint.tick - 1;
			}
			else
			{			
				_dragPointLatestTick = _block.length;
			}
			
			var prevControlPoint:ControlPoint = getPreviousControlPoint( _dragPointTick );
			if( prevControlPoint )
			{
				_dragPointEarliestTick = prevControlPoint.tick + 1;
			}
			else
			{
				_dragPointEarliestTick = 0;
				
				//special case - when dragging first control point don't allow tick to change at all!
				_dragPointLatestTick = 0;
				
			}
			
			Assert.assertTrue( _dragPointLatestTick >= _dragPointEarliestTick );
			
			_isDraggingPoint = true;
			
			MouseCapture.instance.setCapture( this, onDragPoint, onEndDragPoint );
			
			if( _dragPointID < 0 )
			{
				_dragPointID = model.generateNewID();
				if( !controller.processCommand( new AddControlPoint( _envelopeID, _dragPointTick, _dragPointValue, _dragPointID ) ) )
				{
					Assert.assertTrue( false );		//control point creation not expected to fail!
				} 
			}
			
			onDragPoint( event );
		}
		
		
		private function onDragPoint( event:MouseEvent ):void
		{
			Assert.assertTrue( _isDraggingPoint );

			_dragPointTick = Math.max( _dragPointEarliestTick, Math.min( _dragPointLatestTick, getTickFromXPixels( mouseX ) ) );
			_dragPointValue = getValueFromYPixels( mouseY );

			invalidateDisplayList();
 			
			var application:Application = application;
			if( _dragLabelBackground.owner != application )
			{
				_dragLabel.width = _dragLabel.height = 0;
				application.addElement( _dragLabelBackground );
			}
			
			_dragLabel.text = getNumberString( _dragPointTick / model.project.player.rate ) + ", " + getNumberString( _dragPointValue );
			_dragLabel.validateNow();
			_dragLabel.width = Math.max( _dragLabel.width, _dragLabel.textWidth + 8 );
			_dragLabel.height = Math.max( _dragLabel.height, _dragLabel.textHeight + 2 );
			
			var localPosition:Point = new Point( Math.max( 0, Math.min( width, mouseX ) ) - _dragLabel.width / 2, Math.max( 0, Math.min( height, mouseY ) ) - _dragLabel.height - 5 );
			var globalPosition:Point = localToGlobal( localPosition );
			_dragLabelBackground.x = Math.max( 0, Math.min( application.width - _dragLabel.width, globalPosition.x ) );
			_dragLabelBackground.y = globalPosition.y;
		}
		
		
		private function onEndDragPoint():void
		{
			Assert.assertTrue( _isDraggingPoint );
			
			controller.processCommand( new RepositionControlPoint( _dragPointID, _dragPointTick, _dragPointValue ) );
			
			_isDraggingPoint = false;
			
			var application:Application = application;
			if( _dragLabelBackground.owner == application )
			{
				application.removeElement( _dragLabelBackground );
			}
		}
		
		
		private function handleDragPointDoubleClick():void
		{
			var controlPointID:int = getControlPointUnderMouse();
			if( controlPointID < 0 ) 
			{
				return;		//no control point under mouse
			}
			
			var orderedControlPoints:Vector.<ControlPoint> = _envelope.orderedControlPoints;
			Assert.assertTrue( orderedControlPoints.length > 0 );
			
			if( controlPointID == orderedControlPoints[ 0 ].id )
			{
				return;		//mustn't delete first control point
			}
			
			controller.processCommand( new RemoveControlPoint( controlPointID ) );			
		}
				
		
		private function handleDragCurveMouseDown( event:MouseEvent ):void
		{
			Assert.assertTrue( !_isDraggingPoint && !_isDraggingCurve );

			var tickAtMouse:int = getTickFromXPixels( mouseX );

			if( !isSelected ) 
			{
				controller.processCommand( new SetPrimarySelectedChild( _block.id, _envelopeID ) );
				
				if( tickAtMouse > 0 )
				{ 
					//set the capture even though we don't need it, 
					//to prevent the play position from also being updated
					MouseCapture.instance.setCapture( this );	 
					return;
				}
			}
			
			var previousControlPoint:ControlPoint = getPreviousControlPoint( tickAtMouse );
			if( !previousControlPoint ) 
			{
				return;
			}
			
			_dragCurveID = previousControlPoint.id;
			
			_isDraggingCurve = true;
			
			MouseCapture.instance.setCapture( this, onDragCurve, onEndDragCurve );
			
			onDragCurve( event );			
		}
		
		
		private function onDragCurve( event:MouseEvent ):void
		{
			Assert.assertTrue( _isDraggingCurve );
			
			_dragCurvature = getDragCurvatureFromMouse();
			
			invalidateDisplayList();			
		}
		
		
		private function getDragCurvatureFromMouse():Number
		{
			var prevControlPoint:ControlPoint = model.getControlPoint( _dragCurveID );
			Assert.assertNotNull( prevControlPoint );
			
			var nextControlPoint:ControlPoint = getControlPointAfter( prevControlPoint );
			if( !nextControlPoint )
			{
				return 0;
			}
			
			var prevX:Number = getXPixelsFromTick( prevControlPoint.tick );
			var prevY:Number = getYPixelsFromValue( prevControlPoint.value );
			var nextX:Number = getXPixelsFromTick( nextControlPoint.tick );
			var nextY:Number = getYPixelsFromValue( nextControlPoint.value );
			
			var xRange:Number = nextX - prevX;
			var yRange:Number = nextY - prevY;
			if( xRange == 0 || yRange == 0 )
			{
				return 0;		//special case for horizontal or vertical lines
			}

			var xProportion:Number = ( mouseX - prevX ) / xRange;
			var yProportion:Number = ( mouseY - prevY ) / yRange;
			
			if( xProportion <= 0 || yProportion >= 1 ) 
			{
				return maximumCurvature;
			}
			
			if( yProportion <= 0 || xProportion >= 1 )
			{
				return minimumCurvature;
			}

			var baseXLogOfY:Number = Math.log( yProportion ) / Math.log( xProportion );
			Assert.assertTrue( baseXLogOfY > 0 );
				
			var curvature:Number = -Math.log( baseXLogOfY ) / Math.LN2;
			
			return Math.max( minimumCurvature, Math.min( maximumCurvature, curvature ) );
		}

		
		private function onEndDragCurve():void
		{
			Assert.assertTrue( _isDraggingCurve );
			
			controller.processCommand( new SetControlPointCurvature( _dragCurveID, _dragCurvature ) );
			
			_isDraggingCurve = false;
		}
		
		
		private function handleCurvatureModeDoubleClick():void
		{
			var tickAtMouse:int = getTickFromXPixels( mouseX );
			
			var previousControlPoint:ControlPoint = getPreviousControlPoint( tickAtMouse );
			if( !previousControlPoint ) 
			{
				return;
			}
			
			controller.processCommand( new SetControlPointCurvature( previousControlPoint.id, 0 ) );
		}
		
		
		private function getControlPointAfter( controlPoint:ControlPoint ):ControlPoint
		{
			var envelope:Envelope = model.getEnvelope( _envelopeID );
			Assert.assertNotNull( envelope );
			
			var controlPoints:Vector.<ControlPoint> = envelope.orderedControlPoints;
			
			for( var i:int = 0; i < controlPoints.length - 1; i++ )
			{
				if( controlPoints[ i ] == controlPoint ) 
				{
					return controlPoints[ i + 1 ];
				}
			}
			
			return null;
		}
		
		
		private function getNumberString( number:Number ):String
		{
			var string:String = number.toPrecision( 3 );
			
			//if there's a dot, remove trailing zeros
			while( string.length > 0 && string.indexOf( "." ) >= 0 && string.substr( string.length - 1 ) == "0" )
			{
				string = string.substr( 0, string.length - 1 );
			}
			
			//if the dot is last char, remove it
			if( string.length > 0 && string.substr( string.length - 1 ) == "." )
			{
				string = string.substr( 0, string.length - 1 );
			}
			
			return string;
		}
		

		private function getXPixelsFromTick( tick:int ):Number 
		{
			return tick * model.project.projectUserData.timelineState.zoom;
		}
		
		
		private function getTickFromXPixels( xPixels:Number ):int 
		{
			xPixels = Math.max( 0, Math.min( width, xPixels ) );
			
			var zoom:Number = model.project.projectUserData.timelineState.zoom;
			if( zoom <= 0 )
			{
				Assert.assertTrue( false );
				return 0;
			}
			
			return Math.round( xPixels / model.project.projectUserData.timelineState.zoom );
		}


		private function getYPixelsFromValue( value:Number ):Number 
		{
			var minimum:Number = _endpoint.controlInfo.stateInfo.constraint.minimum;
			var maximum:Number = _endpoint.controlInfo.stateInfo.constraint.maximum;
			
			if( maximum <= minimum )
			{
				Assert.assertTrue( false );		//unexpected attribute range
				return 0;
			}
			
			var normalisedValue:Number = ( value - minimum ) / ( maximum - minimum );
			if( normalisedValue < 0 )
			{
				Assert.assertTrue( false );		//control point out of range
				normalisedValue = 0;
			}

			if( normalisedValue > 1 )
			{
				Assert.assertTrue( false );		//control point out of range
				normalisedValue = 1;
			}
			
			return ( 1 - normalisedValue ) * height; 
		}
		
		
		private function getValueFromYPixels( yPixels:Number ):Number 
		{
			var minimum:Number = _endpoint.controlInfo.stateInfo.constraint.minimum;
			var maximum:Number = _endpoint.controlInfo.stateInfo.constraint.maximum;

			yPixels = Math.max( 0, Math.min( height, yPixels ) );

			if( height == 0 )
			{
				Assert.assertTrue( false );
				return minimum;
			} 
			
			var value:Number = ( 1 - ( yPixels / height ) ) * ( maximum - minimum ) + minimum;
			
			if( _endpoint.controlInfo.stateInfo.type == StateInfo.INTEGER )
			{
				value = Math.round( value );
			} 			
			
			return value;
		}
		
		
		private function getControlPointUnderMouse():int
		{
			Assert.assertNotNull( _envelope );
			
			var bestControlPointID:int = -1;
			var bestControlPointDistance:Number;
			
			var firstControlPointID:int = _envelope.orderedControlPoints[ 0 ].id;
			
			for each ( var controlPoint:ControlPoint in _envelope.controlPoints )
			{
				var controlPointX:Number = getXPixelsFromTick( controlPoint.tick );
				var xDistance:Number = Math.abs( controlPointX - mouseX );
				
				if( xDistance > _controlPointRadius )
				{
					continue;
				}
				
				if( bestControlPointID < 0 || xDistance < bestControlPointDistance )
				{
					bestControlPointID = controlPoint.id;
					bestControlPointDistance = xDistance;
				}
			}
			
			return bestControlPointID;
		}
		
		
		private function getControlPointAtTick( tick:int):ControlPoint
		{
			for each( var controlPoint:ControlPoint in _envelope.controlPoints )
			{
				if( controlPoint.tick == tick )
				{
					return controlPoint;
				}
			}
			
			return null;
		}
		
		
		private function getNextControlPoint( tick:int ):ControlPoint
		{
			var controlPointAfterTick:ControlPoint = null;
			var orderedControlPoints:Vector.<ControlPoint> = _envelope.orderedControlPoints;
			
			for( var i:int = orderedControlPoints.length - 1; i >= 0; i-- )
			{
				var controlPoint:ControlPoint = orderedControlPoints[ i ];
				if( controlPoint.tick > tick )
				{
					controlPointAfterTick = controlPoint;
				}
				else
				{
					break;
				}
			}
			
			return controlPointAfterTick;
		}

		
		private function getPreviousControlPoint( tick:int ):ControlPoint
		{
			var controlPointBeforeTick:ControlPoint = null;
			var orderedControlPoints:Vector.<ControlPoint> = _envelope.orderedControlPoints;
			
			for each( var controlPoint:ControlPoint in orderedControlPoints )
			{
				if( controlPoint.tick < tick )
				{
					controlPointBeforeTick = controlPoint;
				}
				else
				{
					break;
				}
			}
			
			return controlPointBeforeTick;
		}
		
	
		
		private var _envelopeID:int;
		private var _envelope:Envelope;
		private var _block:Block;
		private var _track:Track;
		private var _endpoint:EndpointDefinition;
		
		private var _envelopeLock:Boolean = false;
		private var _curvatureMode:Boolean = false;
		
		//drag state
		private var _isDraggingPoint:Boolean = false;
		private var _dragPointID:int = -1;
		private var _dragPointEarliestTick:int = 0;
		private var _dragPointLatestTick:int = 0;
		private var _dragPointTick:int = -1;
		private var _dragPointValue:Number = 0;
		
		private var _isDraggingCurve:Boolean = false;
		private var _dragCurveID:int = -1;
		private var _dragCurvature:Number = 0;
		
		private var _dragLabelBackground:Canvas = new Canvas;
		private var _dragLabel:Label = new Label;
		
		private const _proximityMargin:int = 8;
		private const _controlPointRadius:Number = 4;
		private const _controlPointLineThickness:Number = 1.5;
		private const _transitionLineThickness:Number = 1.5;
		
	}
}