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

package components.views.LiveView
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	import mx.events.FlexNativeMenuEvent;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddEnvelope;
	import components.controller.serverCommands.RemoveEnvelope;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetModuleAttribute;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.userDataCommands.SetLiveViewControlPosition;
	import components.controller.userDataCommands.SetLiveViewControls;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Block;
	import components.model.Info;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.LiveViewControl;
	import components.utils.ControlContainer;
	import components.utils.ControlMeasurer;
	import components.utils.CursorSetter;
	import components.utils.FontSize;
	import components.utils.RepositionType;
	import components.utils.StartControlRepositionEvent;
	import components.utils.Trace;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	
	import flexunit.framework.Assert;
	
	public class LiveViewBlock extends IntegraView
	{
		public function LiveViewBlock( blockID:int )
		{
			super();
			
			_blockID = blockID;
			
			horizontalScrollPolicy = ScrollPolicy.AUTO; 
			verticalScrollPolicy = ScrollPolicy.OFF;    
			
			addEventListener( StartControlRepositionEvent.START_CONTROL_REPOSITION, onStartControlReposition );
			
			addUpdateMethod( SetModuleAttribute, onAttributeChanged );
			addUpdateMethod( SetLiveViewControls, onLiveViewControlsChanged );
			addUpdateMethod( ToggleLiveViewControl, onLiveViewControlToggled );
			addUpdateMethod( SetLiveViewControlPosition, onLiveViewControlPositioned ); 
			addUpdateMethod( SetConnectionRouting, onPadlockStateMightHaveChanged );
			addUpdateMethod( AddEnvelope, onPadlockStateMightHaveChanged );
			addUpdateMethod( RemoveEnvelope, onPadlockStateMightHaveChanged );
			addUpdateMethod( SwitchModuleVersion, onModuleVersionSwitched ); 
			
			addChild( _snapLinesCanvas );
			
			contextMenuDataProvider = [	{ label: "Dummy Item"  } ];
		}
		
		
		public function get blockID():int { return _blockID; }

		
		override public function getInfoToDisplay( event:Event ):Info
		{
			var control:ControlContainer = Utilities.getAncestorByType( event.target, ControlContainer ) as ControlContainer;
			if( control ) 
			{
				return control.getInfoToDisplay( event );
			}
			
			return null;
		}
		

		override public function free():void
		{
			super.free();

			clear();			
		}


		protected override function onAllDataChanged():void
		{
			updateAll();
		}


		override protected function onUpdateContextMenu( event:FlexNativeMenuEvent ):void
		{
			var menu:Array = new Array; 
			
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );

			for each( var module:ModuleInstance in block.modules )
			{
				var moduleItem:NativeMenuItem = new NativeMenuItem;
				var moduleName:String = module.name;
				moduleItem.label = moduleName;
				
				var subMenu:NativeMenu = new NativeMenu;
				
				for each( var widget:WidgetDefinition in module.interfaceDefinition.widgets )
				{
					if( !ControlMeasurer.doesControlExist( widget.type ) )
					{
						continue;
					}
					
					var controlItem:NativeMenuItem = new NativeMenuItem;
					var controlInstanceName:String = widget.label;
					controlItem.label = controlInstanceName;
					controlItem.checked = ( model.getLiveViewControl( module.id, controlInstanceName ) != null );

					var control:LiveViewControl = new LiveViewControl;
					control.moduleID = module.id;
					control.controlInstanceName = controlInstanceName;
					
					var creationPoint:Point = localToContent( new Point( mouseX, mouseY ) );
					var defaultSize:Point = widget.position.size;

					control.position = new Rectangle( creationPoint.x, creationPoint.y, defaultSize.x, defaultSize.y + FontSize.getTextRowHeight( this ) );

					controlItem.data = new Object;
					controlItem.data.liveViewControl = control;
					
					controlItem.addEventListener( Event.SELECT, onToggleControl );
					
					subMenu.addItem( controlItem );
				}
				
				moduleItem.submenu = subMenu;
				
				menu.push( moduleItem );	
				
			}
			
			event.nativeMenu.items = menu;
			
			super.onUpdateContextMenu( event );
		}


		private function onAttributeChanged( command:SetModuleAttribute ):void
		{
			var mapKey:String = getMapKey( command.moduleID, command.endpointName );
			
			if( !_attributeToControlMap.hasOwnProperty( mapKey ) )
			{
				return;
			}
			
			var control:ControlContainer = _attributeToControlMap[ mapKey ] as ControlContainer;
			Assert.assertNotNull( control );

			control.updateOnModuleAttributeChanged( command.id );
		}


		private function onLiveViewControlsChanged( command:SetLiveViewControls ):void
		{
			if( _repositionWidget ) 
			{
				return;
			}
			
			if( command.blockID == _blockID )
			{
				updateAll();
			}
		}


		private function onLiveViewControlToggled( command:ToggleLiveViewControl ):void
		{
			var toggledControl:LiveViewControl = command.liveViewControl;
			if( model.getBlockFromModuleInstance( toggledControl.moduleID ).id != _blockID )
			{
				return;
			}

			//try to remove control
			var removed:Boolean = false;

			//remove live view control 
			for( var i:int = 0; i < _allWidgets.length; i++ )
			{
				var control:ControlContainer = _allWidgets[ i ];
				var widget:WidgetDefinition = control.widget;
				
				if( toggledControl.id != LiveViewControl.makeLiveViewControlID( control.module.id, widget.label ) )
				{
					continue;
				}
				
				_allWidgets.splice( i, 1 );
				removeChild( control );
				removed = true;
				
				var moduleID:int = control.module.id;

				for each( var endpointName:String in widget.attributeToEndpointMap )
				{
					delete _attributeToControlMap[ getMapKey( moduleID, endpointName ) ];
				}
				
				break;
			}
			
			if( !removed )
			{
				addLiveViewControl( toggledControl );
			}
		}		


		private function onLiveViewControlPositioned( command:SetLiveViewControlPosition ):void
		{
			for each( var control:ControlContainer in _allWidgets )
			{
				if( control.module.id == command.moduleID && control.widget.label == command.controlInstanceName )
				{
					var newPosition:Rectangle = command.newPosition;
					if( newPosition )
					{
						control.x = newPosition.left;
						control.y = newPosition.top;
						control.width = newPosition.width;
						control.height = newPosition.height;
					}
				}
			}
		}


		private function onPadlockStateMightHaveChanged( command:ServerCommand ):void
		{
			for each( var widget:ControlContainer in _allWidgets )
			{
				widget.updateWritableness();
			}
		}
		
		
		private function onModuleVersionSwitched( command:SwitchModuleVersion ):void
		{
			if( model.getBlockFromModuleInstance( command.objectID ).id == _blockID )
			{
				updateAll();
			}
		}


		private function clearSnapLines():void
		{
			_snapLinesCanvas.graphics.clear();
		}


		private function updateAll():void
		{
			clear();

			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			for each( var liveViewControl:LiveViewControl in block.blockUserData.liveViewControls )
			{
				addLiveViewControl( liveViewControl );
			}
		}
		
		
		private function clear():void
		{
			_attributeToControlMap = new Object;
			
			for each( var control:ControlContainer in _allWidgets )
			{
				removeChild( control );
			}

			_allWidgets.length = 0;
			
        	_repositionWidget = null;
        	_repositionPreviousPosition = null;        	
        	_repositionType = null;
        	_repositionOffset = null;
        	_repositionOffset = null;
		}
		
		
		private function addLiveViewControl( liveViewControl:LiveViewControl ):void
		{
			var moduleID:int = liveViewControl.moduleID;
			var module:ModuleInstance = model.getModuleInstance( moduleID );
			var widget:WidgetDefinition = module.interfaceDefinition.getWidgetDefinition( liveViewControl.controlInstanceName );
			if( !module || !widget )
			{
				Assert.assertTrue( false );
				return;
			}
			
			if( !ControlMeasurer.doesControlExist( widget.type ) )
			{
				return;
			}			
			
			var container:ControlContainer = new ControlContainer( moduleID, widget, model, controller );
			container.canReposition = true;
			container.includeInstanceNameInLabel = true;

			var position:Rectangle = liveViewControl.position;
			Assert.assertNotNull( position );

			container.x = position.x;
			container.y = position.y;
			container.width = position.width;	
			container.height = position.height;

			_allWidgets.push( container );
			addChild( container );
			
			container.addEventListener( Event.COMPLETE, onControlLoaded );
			container.addEventListener( Event.CANCEL, onControlNotLoaded );

			for each( var endpointName:String in widget.attributeToEndpointMap )
			{
				_attributeToControlMap[ getMapKey( moduleID, endpointName ) ] = container;
			}
		}

			
		private function onControlLoaded( event:Event ):void
		{
		}


		private function onControlNotLoaded( event:Event ):void
		{
			var loadedControl:ControlContainer = event.target as ControlContainer;

			var myIndex:int = _allWidgets.indexOf( loadedControl );
			if( myIndex < 0 )
			{
				return;
			}

			removeChild( loadedControl );
			_allWidgets.splice( myIndex, 1 );
		}
		
		
		private function getMapKey( moduleID:int, moduleAttributeName:String ):String
		{
			return String( moduleID ) + "." + moduleAttributeName;
		} 
		
		
        private function onStartControlReposition( event:StartControlRepositionEvent ):void
        {
			var contentMouse:Point = localToContent( new Point( mouseX, mouseY ) );
        	
       		_repositionType = event.repositionType;
        	_repositionWidget = event.control;
	
        	var cursorType:String = null;
        	switch( _repositionType )
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
        			break;
        	}

			MouseCapture.instance.setCapture( this, onRepositionControl, onEndRepositionControl, cursorType );
			_repositionOffset = new Point( contentMouse.x - _repositionWidget.x, contentMouse.y - _repositionWidget.y );
			_repositionPreviousPosition = new Rectangle( _repositionWidget.x, _repositionWidget.y, _repositionWidget.width, _repositionWidget.height );
			
			//move to front of z-order
			setChildIndex( _repositionWidget, numChildren - 1 );
        }
        
        
        private function onRepositionControl( event:MouseEvent ):void
        {
        	Assert.assertNotNull( _repositionWidget );
			Assert.assertNotNull( _repositionType );
			Assert.assertNotNull( _repositionOffset );
        	Assert.assertNotNull( _repositionPreviousPosition );
			
			var widgetType:String = _repositionWidget.widget.type;
			var minimumSize:Point = ControlMeasurer.getMinimumSize( widgetType ).add( ControlContainer.marginSizeWithoutLabel );
			var maximumSize:Point = ControlMeasurer.getMaximumSize( widgetType ).add( ControlContainer.marginSizeWithLabel );
			
			var contentMouse:Point = localToContent( new Point( mouseX, mouseY ) );
			contentMouse.x -= _repositionOffset.x;
			contentMouse.y -= _repositionOffset.y;
			var mouseDelta:Point = contentMouse.subtract( _repositionPreviousPosition.topLeft );
			
			var newPosition:Rectangle = new Rectangle( _repositionPreviousPosition.x, _repositionPreviousPosition.y, _repositionPreviousPosition.width, _repositionPreviousPosition.height );

			clearSnapLines();

			var xSnapLines:Vector.<Number> = new Vector.<Number>;
			var ySnapLines:Vector.<Number> = new Vector.<Number>;

			var previousTopRight:Point = new Point( _repositionPreviousPosition.right, _repositionPreviousPosition.top );
			var previousBottomLeft:Point = new Point( _repositionPreviousPosition.left, _repositionPreviousPosition.bottom );
			
			switch( _repositionType )
			{
				case RepositionType.MOVE:
					newPosition.x = Math.max( 0, doXMoveSnap( contentMouse.x, xSnapLines ) );
					newPosition.y = Math.max( 0, doYMoveSnap( contentMouse.y, ySnapLines ) );
					break;

        		case RepositionType.RESIZE_LEFT:		
        			newPosition.left = Math.max( Math.max( 0, newPosition.right - maximumSize.x ), Math.min( newPosition.right - minimumSize.x, doXResizeSnap( contentMouse.x, xSnapLines ) ) );
        			break;
        			 
        		case RepositionType.RESIZE_RIGHT:		
        			newPosition.right = Math.min( newPosition.left + maximumSize.x, Math.max( newPosition.left + minimumSize.x, doXResizeSnap( contentMouse.x + _repositionPreviousPosition.width, xSnapLines ) ) );
        			break;

        		case RepositionType.RESIZE_TOP:			
        			newPosition.top = Math.max( Math.max( 0, newPosition.bottom - maximumSize.y ), Math.min( newPosition.bottom - minimumSize.y, doYResizeSnap( contentMouse.y, ySnapLines ) ) );
        			break;
        			
        		case RepositionType.RESIZE_BOTTOM:		
        			newPosition.bottom = Math.min( newPosition.top + maximumSize.y, Math.max( newPosition.top + minimumSize.y, doYResizeSnap( contentMouse.y + _repositionPreviousPosition.height, ySnapLines ) ) );
        			break;

        		case RepositionType.RESIZE_TOPLEFT:
					var newTopLeft:Point = doDiagonalReposition( _repositionPreviousPosition.topLeft, _repositionPreviousPosition.bottomRight, mouseDelta, minimumSize, maximumSize, xSnapLines, ySnapLines ); 
					newPosition.left = newTopLeft.x;
					newPosition.top = newTopLeft.y;
        			break;

        		case RepositionType.RESIZE_TOPRIGHT:	
					var newTopRight:Point = doDiagonalReposition( previousTopRight, previousBottomLeft, mouseDelta, minimumSize, maximumSize, xSnapLines, ySnapLines ); 
					newPosition.right = newTopRight.x;
					newPosition.top = newTopRight.y;
        			break;

        		case RepositionType.RESIZE_BOTTOMLEFT:	
					var newBottomLeft:Point = doDiagonalReposition( previousBottomLeft, previousTopRight, mouseDelta, minimumSize, maximumSize, xSnapLines, ySnapLines ); 
					newPosition.left = newBottomLeft.x;
					newPosition.bottom = newBottomLeft.y;
        			break;

        		case RepositionType.RESIZE_BOTTOMRIGHT:	
					var newBottomRight:Point = doDiagonalReposition( _repositionPreviousPosition.bottomRight, _repositionPreviousPosition.topLeft, mouseDelta, minimumSize, maximumSize, xSnapLines, ySnapLines ); 
					newPosition.right = newBottomRight.x;
					newPosition.bottom = newBottomRight.y;
        			break;

				default:
					Assert.assertTrue( false );
					break;
			}
			

			for each( var xSnapLine:int in xSnapLines )
			{
				if( xSnapLine == newPosition.left || xSnapLine == newPosition.right )
				{ 
					drawXSnapLine( xSnapLine );
				}
			}

			for each( var ySnapLine:int in ySnapLines )
			{
				if( ySnapLine == newPosition.top || ySnapLine == newPosition.bottom )
				{ 
					drawYSnapLine( ySnapLine );
				}
			}
			 
			controller.processCommand( new SetLiveViewControlPosition( _repositionWidget.module.id, _repositionWidget.widget.label, newPosition ) );
        }		

		
		private function doDiagonalReposition( toPoint:Point, fromPoint:Point, mouseDelta:Point, minimumSize:Point, maximumSize:Point, xSnapLines:Vector.<Number>, ySnapLines:Vector.<Number> ):Point
		{
			var repositionDirection:Point = toPoint.subtract( fromPoint );
			var oldDiagonalLength:Number = repositionDirection.length;
			if( oldDiagonalLength <= 0 )
			{
				Assert.assertTrue( false );
				return toPoint;
			}
			
			repositionDirection.x /= oldDiagonalLength;
			repositionDirection.y /= oldDiagonalLength;

			if( repositionDirection.x == 0 || repositionDirection.y == 0 )
			{
				Assert.assertTrue( false );
				return toPoint;
			}
			
			//dot product
			var repositionAmount:Number = repositionDirection.x * mouseDelta.x + repositionDirection.y * mouseDelta.y + oldDiagonalLength;

			repositionAmount = doDiagonalResizeSnap( fromPoint, repositionDirection, repositionAmount, xSnapLines, ySnapLines );
			
			var maximumRepositionAmount:Number = Math.min( maximumSize.y / Math.abs( repositionDirection.y ), maximumSize.x / Math.abs( repositionDirection.x ) );
			var minimumRepositionAmount:Number = Math.max( minimumSize.y / Math.abs( repositionDirection.y ), minimumSize.x / Math.abs( repositionDirection.x ) );

			repositionAmount = Math.max( minimumRepositionAmount, Math.min( maximumRepositionAmount, repositionAmount ) );

			return new Point( fromPoint.x + repositionDirection.x * repositionAmount, fromPoint.y + repositionDirection.y * repositionAmount );
		}


        private function onEndRepositionControl():void
        {
        	_repositionWidget = null;
        	_repositionPreviousPosition = null;
        	_repositionType = null;
        	_repositionOffset = null;
        	
			clearSnapLines();
        }		


		private function doXMoveSnap( candidateX:int, snapLines:Vector.<Number> ):int
		{
			var snappedX:int = -1;
			var leftSnap:int = -1;
			var rightSnap:int = -1;

			var leftSnapThreshold:int = maximumSnapThreshold;
			var rightSnapThreshold:int = maximumSnapThreshold;
			
			var leftDifference:int; 
			var rightDifference:int;
			
			for each( var control:ControlContainer in _allWidgets )
			{
				if( control == _repositionWidget )
				{
					continue;
				}
				
				leftDifference = Math.abs( control.x - candidateX );
				if( leftDifference < leftSnapThreshold )
				{
					snappedX = control.x;
					leftSnap = snappedX;
					leftSnapThreshold = leftDifference;
				}
				
				leftDifference = Math.abs( control.x + control.width - candidateX );
				if( leftDifference < leftSnapThreshold )
				{
					snappedX = control.x + control.width;
					leftSnap = snappedX;
					leftSnapThreshold = leftDifference;
				}				

				rightDifference = Math.abs( control.x - candidateX - _repositionWidget.width );
				if( rightDifference < rightSnapThreshold )
				{
					snappedX = control.x - _repositionWidget.width;
					rightSnap = snappedX;
					rightSnapThreshold = rightDifference;
				}

				rightDifference = Math.abs( control.x + control.width - candidateX - _repositionWidget.width );
				if( rightDifference < rightSnapThreshold )
				{
					snappedX = control.x + control.width - _repositionWidget.width;
					rightSnap = snappedX;
					rightSnapThreshold = rightDifference;
				}
			}
			
			if( snappedX < 0 ) 
			{
				return candidateX;
			}

			if( snappedX == leftSnap )
			{
				snapLines.push( snappedX );
			}

			if( snappedX == rightSnap )
			{
				snapLines.push( snappedX + _repositionWidget.width );
			}
			
			return snappedX;
		}


		private function doYMoveSnap( candidateY:int, snapLines:Vector.<Number> ):int
		{
			var snappedY:int = -1;
			var topSnap:int = -1;
			var bottomSnap:int = -1;

			var topSnapThreshold:int = maximumSnapThreshold;
			var bottomSnapThreshold:int = maximumSnapThreshold;
			
			var topDifference:int; 
			var bottomDifference:int;

			for each( var control:ControlContainer in _allWidgets )
			{
				if( control == _repositionWidget )
				{
					continue;
				}
				
				topDifference = Math.abs( control.y - candidateY );
				if( topDifference < topSnapThreshold )
				{
					snappedY = control.y;
					topSnap = snappedY;
					topSnapThreshold = topDifference;
				}

				topDifference = Math.abs( control.y + control.height - candidateY );
				if( topDifference < topSnapThreshold )
				{
					snappedY = control.y + control.height;
					topSnap = snappedY;
					topSnapThreshold = topDifference;
				}

				bottomDifference = Math.abs( control.y - candidateY - _repositionWidget.height );
				if( bottomDifference < bottomSnapThreshold )
				{
					snappedY = control.y - _repositionWidget.height;
					bottomSnap = snappedY;
					bottomSnapThreshold = bottomDifference;
				}
				
				bottomDifference = Math.abs( control.y + control.height - candidateY - _repositionWidget.height );
				if( bottomDifference < bottomSnapThreshold )
				{
					snappedY = control.y + control.height - _repositionWidget.height;
					bottomSnap = snappedY;
					bottomSnapThreshold = bottomDifference;
				}
			}
			
			if( snappedY < 0 ) 
			{
				return candidateY;
			}

			if( snappedY == topSnap )
			{
				snapLines.push( snappedY );
			}

			if( snappedY == bottomSnap )
			{
				snapLines.push( snappedY + _repositionWidget.height );
			}
			
			return snappedY;
		}


		private function doXResizeSnap( candidateX:int, snapLines:Vector.<Number> ):int
		{
			var snappedX:int = -1;

			var snapThreshold:int = maximumSnapThreshold;
			var difference:int;
			
			for each( var control:ControlContainer in _allWidgets )
			{
				if( control == _repositionWidget )
				{
					continue;
				}
				
				difference = Math.abs( control.x - candidateX );
				if( difference < snapThreshold )
				{
					snappedX = control.x;
					snapThreshold = difference;
				}
		
				difference = Math.abs( control.x + control.width - candidateX );
				if( difference < snapThreshold )
				{
					snappedX = control.x + control.width;
					snapThreshold = difference;
				}				
			}
			
			if( snappedX < 0 ) 
			{
				return candidateX;
			}

			snapLines.push( snappedX );

			return snappedX;
		}


		private function doYResizeSnap( candidateY:int, snapLines:Vector.<Number> ):int
		{
			var snappedY:int = -1;

			var snapThreshold:int = maximumSnapThreshold;
			var difference:int;
			
			for each( var control:ControlContainer in _allWidgets )
			{
				if( control == _repositionWidget )
				{
					continue;
				}
				
				difference = Math.abs( control.y - candidateY );
				if( difference < snapThreshold )
				{
					snappedY = control.y;
					snapThreshold = difference;
				}
		
				difference = Math.abs( control.y + control.height - candidateY );
				if( difference < snapThreshold )
				{
					snappedY = control.y + control.height;
					snapThreshold = difference;
				}				
			}
			
			if( snappedY < 0 ) 
			{
				return candidateY;
			}

			snapLines.push( snappedY );

			return snappedY;
		}
		
		
		private function doDiagonalResizeSnap( fromPoint:Point, repositionDirection:Point, repositionAmount:Number, xSnapLines:Vector.<Number>, ySnapLines:Vector.<Number> ):Number
		{
			var snappedAmount:Number = -1;
			
			var snapThreshold:int = maximumSnapThreshold;
			var candidatePoint:Point = new Point( fromPoint.x + repositionDirection.x * repositionAmount, fromPoint.y + repositionDirection.y * repositionAmount ); 
			var difference:Number;
			
			for each( var control:ControlContainer in _allWidgets )
			{
				if( control == _repositionWidget )
				{
					continue;
				}

				//left difference
				difference = Math.abs( control.x - candidatePoint.x );
				if( difference < snapThreshold )
				{
					snappedAmount = Math.abs( ( fromPoint.x - control.x ) / repositionDirection.x );
					snapThreshold = difference;
					
					xSnapLines.length = 0;
					ySnapLines.length = 0;
					xSnapLines.push( control.x );
				}

				//top difference
				difference = Math.abs( control.y - candidatePoint.y );
				if( difference < snapThreshold )
				{
					snappedAmount = Math.abs( ( fromPoint.y - control.y ) / repositionDirection.y );
					snapThreshold = difference;
					
					xSnapLines.length = 0;
					ySnapLines.length = 0;
					ySnapLines.push( control.y );
				}
				
				//right difference
				difference = Math.abs( control.x + control.width - candidatePoint.x );
				if( difference < snapThreshold )
				{
					snappedAmount = Math.abs( ( fromPoint.x - control.x - control.width ) / repositionDirection.x );
					snapThreshold = difference;
					
					xSnapLines.length = 0;
					ySnapLines.length = 0;
					xSnapLines.push( control.x + control.width );
				}
				
				//top difference
				difference = Math.abs( control.y + control.height - candidatePoint.y );
				if( difference < snapThreshold )
				{
					snappedAmount = Math.abs( ( fromPoint.y - control.y - control.height ) / repositionDirection.y );
					snapThreshold = difference;
					
					xSnapLines.length = 0;
					ySnapLines.length = 0;
					ySnapLines.push( control.y + control.height );
				}
			}
			
			if( snappedAmount < 0 ) 
			{
				return repositionAmount;
			}
			else
			{
				return snappedAmount;
			}
		}


		private function drawXSnapLine( xCoord:int ):void
		{
			_snapLinesCanvas.graphics.lineStyle( 4, 0x808080, 0.3 );

			_snapLinesCanvas.graphics.moveTo( xCoord, 0 );
			_snapLinesCanvas.graphics.lineTo( xCoord, Math.max( height / scaleY, measuredHeight ) );
		}


		private function drawYSnapLine( yCoord:int ):void
		{
			_snapLinesCanvas.graphics.lineStyle( 4, 0x808080, 0.3 );

			_snapLinesCanvas.graphics.moveTo( 0, yCoord );
			_snapLinesCanvas.graphics.lineTo( Math.max( measuredWidth, width / scaleX ), yCoord );
		}
		
		
		private function onToggleControl( event:Event ):void
		{
			var menuItem:NativeMenuItem = event.target as NativeMenuItem;
			Assert.assertNotNull( menuItem );
			
			var liveViewControl:LiveViewControl = menuItem.data.liveViewControl as LiveViewControl;
			Assert.assertNotNull( liveViewControl );
			
			controller.processCommand( new ToggleLiveViewControl( liveViewControl ) );
		}
		
		
		private var _blockID:int;
				
		private var _allWidgets:Vector.<ControlContainer> = new Vector.<ControlContainer>;
		private var _attributeToControlMap:Object = new Object;
		
		private var _repositionWidget:ControlContainer = null;
		private var _repositionPreviousPosition:Rectangle = null;
		private var _repositionType:String = null;
		private var _repositionOffset:Point = null;

		private var _snapLinesCanvas:Canvas = new Canvas;
		
		private static const maximumSnapThreshold:int = 10;
		
	}
}