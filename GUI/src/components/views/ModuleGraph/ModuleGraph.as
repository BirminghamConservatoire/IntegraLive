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

package components.views.ModuleGraph
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.managers.DragManager;
	
	import __AS3__.vec.Vector;
	
	import components.controller.serverCommands.AddConnection;
	import components.controller.serverCommands.ImportModule;
	import components.controller.serverCommands.LoadModule;
	import components.controller.serverCommands.RemoveConnection;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.UnloadModule;
	import components.controller.userDataCommands.SetLiveViewControls;
	import components.controller.userDataCommands.SetModulePosition;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.controller.userDataCommands.SetViewMode;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Block;
	import components.model.Connection;
	import components.model.Info;
	import components.model.IntegraDataObject;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.model.userData.ColorScheme;
	import components.model.userData.LiveViewControl;
	import components.model.userData.ViewMode;
	import components.utils.DragImage;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	import components.views.ArrangeView.TrackColorPicker;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;


	public class ModuleGraph extends IntegraView
	{
		public function ModuleGraph()
		{
 			super();

			horizontalScrollPolicy = ScrollPolicy.OFF; 
			verticalScrollPolicy = ScrollPolicy.OFF;   

			_contentCanvas.percentWidth = 100;
			_contentCanvas.percentHeight = 100;
			addElement( _contentCanvas );

			_backUpButton.alpha = 0.6;
			_backUpButton.addEventListener( MouseEvent.CLICK, onClickBackUpButton );
			_backUpButton.x = 10;
			_backUpButton.y = 10;
			_backUpButton.backUpButtonLabel = "Arrange";
			addElement( _backUpButton );

			addEventListener( FlexEvent.ADD, onAdded ); 
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			addEventListener( DragEvent.DRAG_DROP, onDragDrop );
			addEventListener( DragEvent.DRAG_ENTER, onDragEnter );
			addEventListener( DragEvent.DRAG_OVER, onDragOver );
			addEventListener( DragEvent.DRAG_EXIT, onDragExit );

			addUpdateMethod( LoadModule, onModuleLoaded );
			addUpdateMethod( UnloadModule, onModuleUnloaded );
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( SetModulePosition, onModulePositioned );
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( SetObjectSelection, onObjectSelectionChanged );
			addUpdateMethod( SetLiveViewControls, onLiveViewControlsChanged );
			addUpdateMethod( ToggleLiveViewControl, onLiveViewControlToggled );
			addUpdateMethod( SetTrackColor, onTrackColorChanged );
			addUpdateMethod( RenameObject, onObjectRenamed );
			
			addVuMeterChangingCommand( SetPrimarySelectedChild );
			
			contextMenuDataProvider = contextMenuData;
			
			clear();
		}


		public function get lastModuleDirectory():String { return _lastModuleDirectory; }
		public function set lastModuleDirectory( lastModuleDirectory:String ):void { _lastModuleDirectory = lastModuleDirectory; }


		override public function get title():String { return "Module View"; }


		override public function get vuMeterContainerID():int
		{
			if( model && model.primarySelectedBlock )
			{
				return model.primarySelectedBlock.id;			
			}
			else
			{
				return -1;
			}
		}	

		
		override public function getInfoToDisplay( event:MouseEvent ):Info 
		{
			if( getLinkUnderMouse() )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleGraphLink" );
			}
			
			var connectionPin:ConnectionPin = Utilities.getAncestorByType( event.target, ConnectionPin ) as ConnectionPin;
			if( connectionPin )
			{
				if( connectionPin.isInput )
				{
					return InfoMarkupForViews.instance.getInfoForView( "ModuleInputPin" );
				}
				else
				{
					return InfoMarkupForViews.instance.getInfoForView( "ModuleOutputPin" );
				}
			}
			
			var element:ModuleGraphElement = Utilities.getAncestorByType( event.target, ModuleGraphElement ) as ModuleGraphElement;
			if( element )
			{
				return element.getInfoToDisplay( event );
			}

			if( model.primarySelectedBlock )
			{
				return model.primarySelectedBlock.info;
			}

			return null;
		}
		

		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_newLinkColor = 0x404040;
						_normalLinkColor = 0x808080;
						_selectedLinkColor = 0x404040;
						_areaSelectionColor = 0x000000;
						_areaSelectionBorderColor = 0x000000;
						break;
						
					case ColorScheme.DARK:
						_newLinkColor = 0xc0c0c0;
						_normalLinkColor = 0x808080;
						_selectedLinkColor = 0xc0c0c0;
						_areaSelectionColor = 0xffffff;
						_areaSelectionBorderColor = 0xffffff;
						break;
				}

				updateAllLinks();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				for each( var element:ModuleGraphElement in _elements )
				{
					updateModuleGraphElement( element );
				}

				updateAllLinks(); 	
				
				_backUpButton.width = 3 * FontSize.getTextRowHeight( this );
				_backUpButton.height = 3 * FontSize.getTextRowHeight( this );
			}
		} 
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		}
		
		
		private function updateAll():void
		{
			clear();

			if( !model.primarySelectedBlock ) return;
		
			updateColor();
			
			findLiveViewElements();
			
			var block:Block = model.primarySelectedBlock;
			Assert.assertNotNull( block );

			for each( var module:ModuleInstance in block.modules )
			{
				addModule( module );
			}
			
			for each( var connection:Connection in block.connections )
			{
				if( !model.isAudioLink( connection.sourceObjectID, connection.sourceAttributeName, connection.targetObjectID, connection.targetAttributeName ) ) 
				{
					continue;
				}
				
				var link:ModuleGraphLink = new ModuleGraphLink( connection.id );
				_links.push( link );
				_contentCanvas.addElement( link );
				setLinkState( link );
			}
		}
		
		
		private function addModule( module:ModuleInstance ):void
		{
			var element:ModuleGraphElement = new ModuleGraphElement( module.id, model, controller );
			_elements[ module.id ] = element;

			_contentCanvas.addElement( element );
			element.liveViewElement = _liveViewElements.hasOwnProperty( module.id );
			
			for each( var endpoint:EndpointDefinition in module.interfaceDefinition.endpoints )
			{
				if( endpoint.type != EndpointDefinition.STREAM ) continue;
				
				var streamInfo:StreamInfo = endpoint.streamInfo;
				
				if( streamInfo.streamType != StreamInfo.TYPE_AUDIO ) continue;
				
				switch( streamInfo.streamDirection )
				{
					case StreamInfo.DIRECTION_INPUT:
						var inputPin:ConnectionPin = new ConnectionPin( module.id, endpoint.name, true );
						_connectionPins.push( inputPin );
						element.addInputPin( inputPin );
						_contentCanvas.addElement( inputPin );
						break;
				
					case StreamInfo.DIRECTION_OUTPUT:
						var outputPin:ConnectionPin = new ConnectionPin( module.id, endpoint.name, false );
						_connectionPins.push( outputPin );
						element.addOutputPin( outputPin );
						_contentCanvas.addElement( outputPin );
						break;
					
					default:
						Assert.assertTrue( false );
						break;
				}
			}
			
			updateModuleGraphElement( element );
		}
		
		
		private function updateAllLinks():void
		{
			for each( var link:ModuleGraphLink in _links )
			{
				setLinkState( link );
			}
		}


		private function clear():void
		{
			for each( var element:ModuleGraphElement in _elements )
			{
				_contentCanvas.removeChild( element );
			}
			_elements = new Object;
			
			for each( var connectionPin:ConnectionPin in _connectionPins )
			{
				_contentCanvas.removeChild( connectionPin );
			}
			_connectionPins.length = 0;
			
			for each( var link:ModuleGraphLink in _links )
			{
				_contentCanvas.removeChild( link );
			}
			_links.length = 0;
			
			removeNewLink();
			endRepositioning();
			endAreaSelection();
			
			_liveViewElements.length = 0;

			endNewModuleDrag();			
		}


		private function onModuleLoaded( command:LoadModule ):void
		{
			addModule( model.getModuleInstance( command.objectID ) );
		}
		
		
		private function onModuleUnloaded( command:UnloadModule ):void
		{
			updateAll();
		}


		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			removeNewLink();
			updateAll();
		}
		
		
		private function onModulePositioned( command:SetModulePosition ):void
		{
			if( _elements.hasOwnProperty( command.instanceID ) )
			{
				var element:ModuleGraphElement = _elements[ command.instanceID ] as ModuleGraphElement;
				Assert.assertNotNull( element );
				updateModuleGraphElement( element );
			}
			
			for each( var link:ModuleGraphLink in _links )
			{
				var connection:Connection = model.getConnection( link.connectionID );
				
				if( connection.sourceObjectID == command.instanceID || connection.targetObjectID == command.instanceID )
				{
					setLinkState( link );
				}
			}
		}


		private function onObjectSelectionChanged( command:SetObjectSelection ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( command.objectID );
			
			if( object is ModuleInstance )
			{
				for each( var element:ModuleGraphElement in _elements )
				{
					updateModuleGraphElement( element );
				}
			}
			
			if( object is Connection )
			{
				updateAllLinks();
			}
		}
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( command.objectID );
			
			if( object is Track )
			{
				//primary selected block changed
				updateAll();
				return;	
			}
			
			if( object is Block )
			{
				//primary selected module changed
				for each( var element:ModuleGraphElement in _elements )
				{
					updateModuleGraphElement( element );
				}
			}
		}


		private function onLiveViewControlsChanged( command:SetLiveViewControls ):void
		{
			updateLiveViewTicks();
		}


		private function onLiveViewControlToggled( command:ToggleLiveViewControl ):void
		{
			updateLiveViewTicks();
		}


		private function onTrackColorChanged( command:SetTrackColor ):void
		{
			if( model.primarySelectedBlock ) 
			{
				updateColor();
			}
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			if( _elements.hasOwnProperty( command.objectID ) )
			{
				var element:ModuleGraphElement = _elements[ command.objectID ] as ModuleGraphElement;
				Assert.assertNotNull( element );
				updateModuleGraphElement( element );
			}
		}
		
		
		private function onClickBackUpButton( event:MouseEvent ):void
		{
 			var viewMode:ViewMode = model.project.userData.viewMode.clone();
 			viewMode.blockPropertiesOpen = false;
 			controller.processCommand( new SetViewMode( viewMode ) );				
		}

		
		private function updateLiveViewTicks():void
		{
			findLiveViewElements();
			for each( var element:ModuleGraphElement in _elements )
			{
				element.liveViewElement = _liveViewElements.hasOwnProperty( element.moduleID );
			}
		}
		
		
		private function findLiveViewElements():void
		{
			_liveViewElements = new Object;

			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				return;
			}

			for each( var liveViewControl:LiveViewControl in block.userData.liveViewControls )
			{
				_liveViewElements[ liveViewControl.moduleID ] = true;
			}
		}
		
		
		private function updateColor():void
		{
			var color:uint = model.getTrackFromBlock( model.primarySelectedBlock.id ).userData.color;
			setStyle( "color", color );
			setStyle( "disabledColor", color );
		}
		
		
		private function removeNewLink():void
		{
			if( _newLink )
			{
				_contentCanvas.removeChild( _newLink );
				_newLink = null;
				_newLinkAnchor = null;
				_newLinkDestination = null;
			}
		}

		
		private function onAdded( event:Event ):void
		{
			_contentCanvas.addElement( _snapLinesCanvas );
		}
		
		
		private function onMouseDown( event:MouseEvent ):void
		{
			if( isClickOnScrollbar() )
			{
				return;
			} 
			
			MouseCapture.instance.setCapture( this, onCapturedDrag, onCaptureFinished );
			
			var repositionElement:ModuleGraphElement = getElementToReposition();
			if( repositionElement )
			{
				_repositionModuleID = repositionElement.moduleID;

				var contentMouse:Point = _contentCanvas.localToContent( new Point( mouseX, mouseY ) );
				_repositionOffset = new Point( repositionElement.x - contentMouse.x, repositionElement.y - contentMouse.y );
				onClickModule( _repositionModuleID, event );
				return;
			}

			var clickElement:ModuleGraphElement = Utilities.getAncestorByType( event.target, ModuleGraphElement ) as ModuleGraphElement;
			if( clickElement )
			{
				return;		
			}			
			
			_newLinkAnchor = getConnectionPinUnderMouse( event );
			if( _newLinkAnchor )
			{
				_newLink = new ModuleGraphLink;
				_contentCanvas.addElement( _newLink );
				updateNewLink( event );
				return;
			}
			
			var link:ModuleGraphLink = getLinkUnderMouse();
			if( link )
			{
				onClickLink( link.connectionID, event );
				return;
			}

			onClickWhitespace( event );
		}


		private function onCaptureFinished():void
		{
			endRepositioning();
			endAreaSelection();

			if( _newLinkAnchor && _newLinkDestination )
			{
				Assert.assertTrue( _newLinkDestination.isInput != _newLinkAnchor.isInput )

				var sourceModuleID:int = _newLinkAnchor.isInput ? _newLinkDestination.moduleID : _newLinkAnchor.moduleID;
				var sourceAttributeName:String = _newLinkAnchor.isInput ? _newLinkDestination.attributeName : _newLinkAnchor.attributeName
				
				var targetModuleID:int = _newLinkAnchor.isInput ? _newLinkAnchor.moduleID : _newLinkDestination.moduleID;
				var targetAttributeName:String = _newLinkAnchor.isInput ? _newLinkAnchor.attributeName : _newLinkDestination.attributeName;

				if( model.canSetAudioLink( sourceModuleID, sourceAttributeName, targetModuleID, targetAttributeName ) )
				{
					var addConnection:AddConnection = new AddConnection( model.primarySelectedBlock.id );
					
					controller.processCommand( addConnection );					
					controller.processCommand( new SetConnectionRouting( addConnection.connectionID, sourceModuleID, sourceAttributeName, targetModuleID, targetAttributeName ) );
				}
				
				_newLinkAnchor = null;
				_newLinkDestination = null;
			}

			removeNewLink();
		}

		
		private function onCapturedDrag( event:MouseEvent ):void
		{
			if( _repositionModuleID >= 0 )
			{
				doModuleReposition();
				return;   
			}
			
			if( _areaSelectionSnapshot )
			{
				updateAreaSelection( event );
				return;
			}
			
			if( _newLink && _newLinkAnchor )
			{
				updateNewLink( event );
				return;
			}
		}
		
		
		private function onDragDrop( event:DragEvent ):void
		{
			Assert.assertTrue( event.dragSource.hasFormat( Utilities.getClassNameFromClass( InterfaceDefinition ) ) );

			var interfaceDefinition:InterfaceDefinition = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( InterfaceDefinition ) ) as InterfaceDefinition;
			Assert.assertNotNull( interfaceDefinition );
			
			Assert.assertNotNull( _elementBeingCreated );
			
			var block:Block = model.primarySelectedBlock;
			Assert.assertNotNull( block );
			
			var gridSize:Number = FontSize.getTextRowHeight( this );
			var position:Point = _contentCanvas.localToContent( new Point( _elementBeingCreated.x, _elementBeingCreated.y ) );
			Assert.assertTrue( gridSize > 0 );
			position.x /= gridSize;
			position.y /= gridSize;

			deselectEverything();

			var linkToReplaceID:int = _linkBeingCreatedOver ? _linkBeingCreatedOver.connectionID : -1;

			var newModuleCommand:LoadModule = new LoadModule( interfaceDefinition.moduleGuid, block.id, new Rectangle( position.x, position.y, ModuleInstance.getModuleWidth(), ModuleInstance.getModuleHeight( interfaceDefinition ) ) ); 
			controller.processCommand( newModuleCommand );
			
			endNewModuleDrag();
			
			if( linkToReplaceID >= 0 )
			{
				//replace link with links to/from new module
				
				var previousConnection:Connection = model.getConnection( linkToReplaceID );
				Assert.assertNotNull( previousConnection );
				
				var newModuleID:int = newModuleCommand.objectID;
				if( interfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_INPUT ) > 0 )
				{
					var newConnection1:AddConnection = new AddConnection( block.id );
					controller.processCommand( newConnection1 );

					var inputName:String = getFirstAudioEndpointNameByDirection( interfaceDefinition, StreamInfo.DIRECTION_INPUT ); 
					Assert.assertNotNull( inputName );
					controller.processCommand( new SetConnectionRouting( newConnection1.connectionID, previousConnection.sourceObjectID, previousConnection.sourceAttributeName, newModuleID, inputName ) );  
				}
				
				if( interfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_INPUT ) > 0 )
				{
					var newConnection2:AddConnection = new AddConnection( block.id );
					controller.processCommand( newConnection2 );
				
					var outputName:String = getFirstAudioEndpointNameByDirection( interfaceDefinition, StreamInfo.DIRECTION_OUTPUT );
					Assert.assertNotNull( outputName );
					controller.processCommand( new SetConnectionRouting( newConnection2.connectionID, newModuleID, outputName, previousConnection.targetObjectID, previousConnection.targetAttributeName ) );  
				}

				controller.processCommand( new RemoveConnection( linkToReplaceID ) );			
			}   
			
			applyRepositionMap();
		}


		private function onDragEnter( event:DragEvent ):void
		{
			if( !event.dragSource.hasFormat( Utilities.getClassNameFromClass( InterfaceDefinition ) ) )
			{
				return;
			}

			DragManager.acceptDragDrop( this );
						
			var interfaceDefinition:InterfaceDefinition = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( InterfaceDefinition ) ) as InterfaceDefinition;
			Assert.assertNotNull( InterfaceDefinition );
			
			Assert.assertNull( _elementBeingCreated );
		
			_elementBeingCreated = new ModuleGraphElement( -1, null, null );
			_elementBeingCreated.alpha = 0.5;

			addElement( _elementBeingCreated );
			
			for each( var endpoint:EndpointDefinition in interfaceDefinition.endpoints )
			{
				if( endpoint.type != EndpointDefinition.STREAM ) continue;
				if( endpoint.streamInfo.streamType != StreamInfo.TYPE_AUDIO ) continue;
				
				switch( endpoint.streamInfo.streamDirection )
				{
					case StreamInfo.DIRECTION_INPUT:
						var inputPin:ConnectionPin = new ConnectionPin( -1, endpoint.name, true );
						
						_connectionPinsBeingCreated.push( inputPin );
						_elementBeingCreated.addInputPin( inputPin );
						addElement( inputPin );
						break;
				
					case StreamInfo.DIRECTION_OUTPUT:
						var outputPin:ConnectionPin = new ConnectionPin( -1, endpoint.name, false );
						
						_connectionPinsBeingCreated.push( outputPin );
						_elementBeingCreated.addOutputPin( outputPin );
						addElement( outputPin );
						break;
					
					
					default:
						Assert.assertTrue( false );
						break;
				}
			}

			positionElementBeingCreated( event.localX, event.localY, interfaceDefinition );
		}
		
		
		private function onDragOver( event:DragEvent ):void
		{
			if( !event.dragSource.hasFormat( Utilities.getClassNameFromClass( InterfaceDefinition ) ) )
			{
				return;
			}

			DragImage.suppressDragImage();
			
			var interfaceDefinition:InterfaceDefinition = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( InterfaceDefinition ) ) as InterfaceDefinition;
			Assert.assertNotNull( interfaceDefinition );

			positionElementBeingCreated( event.localX, event.localY, interfaceDefinition );

			var previousLinkBeingCreatedOver:ModuleGraphLink = _linkBeingCreatedOver; 
			_linkBeingCreatedOver = getLinkUnderRect( _elementBeingCreated.getRect( _contentCanvas ) );
			
			if( previousLinkBeingCreatedOver )
			{
				previousLinkBeingCreatedOver.visible = true;
			}
			
			if( _linkBeingCreatedOver )
			{
				_linkBeingCreatedOver.visible = false;
				
				if( interfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_INPUT ) > 0 )
				{
					if( !_inputReplacementLink )
					{
						_inputReplacementLink = new ModuleGraphLink();
						addElement( _inputReplacementLink );
					}

					//budge over if necessary					
					var gridSize:Number = FontSize.getTextRowHeight( this );
					
					var previousElement:ModuleGraphElement = _elements[ model.getConnection( _linkBeingCreatedOver.connectionID ).sourceObjectID ];
					Assert.assertNotNull( previousElement );

					var elementBeingCreatedMinX:Number = _contentCanvas.contentToLocal( new Point( previousElement.x + previousElement.width, 0 ) ).x + minimumLinkMargin * gridSize;
					_elementBeingCreated.x = Math.max( elementBeingCreatedMinX, _elementBeingCreated.x );   
					_elementBeingCreated.updateIOPins();
					
					var endPoint:Point = new Point;
					var endOffset:Point = new Point;
					_elementBeingCreated.getFirstInputPoint( endPoint, endOffset );
					var trackOffset:Point = Point.interpolate( endOffset, _linkBeingCreatedOver.trackOffset, 0.5 );

					_inputReplacementLink.setState( _contentCanvas.contentToLocal( _linkBeingCreatedOver.start ), endPoint, trackOffset, normalLinkWidth, _normalLinkColor );
				}

				if( interfaceDefinition.countAudioEndpointsByDirection( StreamInfo.DIRECTION_OUTPUT ) > 0 )
				{
					if( !_outputReplacementLink )
					{
						_outputReplacementLink = new ModuleGraphLink();
						addElement( _outputReplacementLink );
					}
					
					positionElementsDownstreamOfElementBeingCreated();

					var startPoint:Point = new Point;
					var startOffset:Point = new Point;
					_elementBeingCreated.getFirstOutputPoint( startPoint, startOffset );

					var connectionBeingReplaced:Connection = model.getConnection( _linkBeingCreatedOver.connectionID );
					Assert.assertNotNull( connectionBeingReplaced );

					endPoint = new Point;
					endOffset = new Point;
					getLinkPoint( connectionBeingReplaced.targetObjectID, connectionBeingReplaced.targetAttributeName, endPoint, endOffset ); 
					trackOffset = Point.interpolate( startOffset, endOffset, 0.5 );
					
					_outputReplacementLink.setState( startPoint, _contentCanvas.contentToLocal( endPoint ), trackOffset, normalLinkWidth, _normalLinkColor );
				}
			}
			else
			{
				//not creating over a link
				if( _inputReplacementLink )
				{	
					removeChild( _inputReplacementLink );
					_inputReplacementLink = null;
				}

				if( _outputReplacementLink )
				{	
					removeChild( _outputReplacementLink );
					_outputReplacementLink = null;
				}
	
				if( _repositionMap )
				{
					_repositionMap = null;
					displayRepositionMap();
				}
				
			}
		}
		
		
		private function getFirstAudioEndpointNameByDirection( interfaceDefinition:InterfaceDefinition, direction:String ):String
		{
			for each( var endpoint:EndpointDefinition in interfaceDefinition.endpoints )
			{
				if( endpoint.type != EndpointDefinition.STREAM ) continue;
				if( endpoint.streamInfo.streamType != StreamInfo.TYPE_AUDIO ) continue;
				
				if( endpoint.streamInfo.streamDirection == direction ) 
				{
					return endpoint.name;
				}
			}
			
			return null;			
		}
		
		
		private function positionElementsDownstreamOfElementBeingCreated():void
		{
			_repositionMap = new Object;
			
			var gridSize:Number = FontSize.getTextRowHeight( this );
			var firstDownstreamModuleID:int = model.getConnection( _linkBeingCreatedOver.connectionID ).targetObjectID;
			var rightEdgeOfNewModule:Number = _contentCanvas.localToContent( new Point( _elementBeingCreated.x + _elementBeingCreated.width, 0 ) ).x / gridSize;
			
			positionDownstreamElementsRecursive( firstDownstreamModuleID, rightEdgeOfNewModule + minimumLinkMargin );
			
			displayRepositionMap();
		}


		private function positionDownstreamElementsRecursive( moduleID:int, minX:Number ):void
		{
			var block:Block = model.primarySelectedBlock;
			var position:Rectangle = model.getModulePosition( moduleID );

			Assert.assertNotNull( block );
			Assert.assertNotNull( position );
			
			if( position.x >= minX )
			{
				return;
			}
			
			var repositionedRectangle:Rectangle = new Rectangle( minX, position.y, position.width, position.height );
			_repositionMap[ moduleID ] = repositionedRectangle;

			var nextMinX:Number = minX + ModuleInstance.getModuleWidth() + minimumLinkMargin;
			
			for each( var connection:Connection in block.connections )
			{
				if( connection.sourceObjectID != moduleID ) 
				{
					continue;
				}
				
				if( !model.isAudioLink( connection.sourceObjectID, connection.sourceAttributeName, connection.targetObjectID, connection.targetAttributeName ) )
				{
					continue;
				}
				
				positionDownstreamElementsRecursive( connection.targetObjectID, nextMinX ); 
			} 
		}
		
		
		private function onDragExit( event:DragEvent ):void
		{
			endNewModuleDrag();
		}
		
		
		private function positionElementBeingCreated( x:Number, y:Number, interfaceDefinition:InterfaceDefinition ):void
		{
			var gridSize:Number = FontSize.getTextRowHeight( this );
			_elementBeingCreated.width = ModuleInstance.getModuleWidth() * gridSize;
			_elementBeingCreated.height = ModuleInstance.getModuleHeight( interfaceDefinition ) * gridSize;

			_elementBeingCreated.x = x - _elementBeingCreated.width / 2;
			_elementBeingCreated.y = y - _elementBeingCreated.height / 2;
			
			_elementBeingCreated.updateIOPins();
		}
		
		
		private function endNewModuleDrag():void
		{
			if( _linkBeingCreatedOver )
			{
				_linkBeingCreatedOver.visible = true;
				_linkBeingCreatedOver = null;
			}
			
			if( _elementBeingCreated )
			{
				removeChild( _elementBeingCreated );
				_elementBeingCreated = null;
			}
			
			for each( var connectionPinBeingCreated:ConnectionPin in _connectionPinsBeingCreated )
			{
				removeChild( connectionPinBeingCreated );
			}
			_connectionPinsBeingCreated.length = 0;
			
			if( _inputReplacementLink )
			{	
				removeChild( _inputReplacementLink );
				_inputReplacementLink = null;
			}

			if( _outputReplacementLink )
			{	
				removeChild( _outputReplacementLink );
				_outputReplacementLink = null;
			}
		}


		private function doModuleReposition():void
		{
			var contentMouse:Point = _contentCanvas.localToContent( new Point( mouseX, mouseY ) );

			var newX:int = Math.max( 0, contentMouse.x + _repositionOffset.x );
			var newY:int = Math.max( 0, contentMouse.y + _repositionOffset.y );
			
			var xSnapLines:Vector.<int> = new Vector.<int>;
			var ySnapLines:Vector.<int> = new Vector.<int>;
			
			var repositionElement:ModuleGraphElement = _elements[ _repositionModuleID ] as ModuleGraphElement;
			Assert.assertNotNull( repositionElement );
			
			var snappedX:int = doXDragSnap( newX, repositionElement.width, xSnapLines );
			var snappedY:int = doYDragSnap( newY, repositionElement.height, ySnapLines );

			if( snappedX >= 0 ) newX = snappedX;
			if( snappedY >= 0 ) newY = snappedY;

			var previousPosition:Rectangle = model.getModulePosition( _repositionModuleID );
			var gridSize:Number = FontSize.getTextRowHeight( this );
			var xMove:Number = newX - previousPosition.x * gridSize;
			var yMove:Number = newY - previousPosition.y * gridSize;  

			var block:Block = model.primarySelectedBlock;
			Assert.assertNotNull( block );
			
			for each( var module:ModuleInstance in block.modules )
			{
				if( !module.isSelected ) continue;
				
				var position:Rectangle = model.getModulePosition( module.id );
				if( xMove < -position.x * gridSize )
				{
					xMove = -position.x * gridSize;
					snappedY = -1;
				}

				if( yMove < -position.y * gridSize )
				{
					yMove = -position.y * gridSize;
					snappedY = -1;
				}
			} 

			clearSnapLines();
			drawXSnapLines( xSnapLines );
			drawYSnapLines( ySnapLines );

			_repositionMap = new Object;
			
			for each( module in block.modules )
			{
				if( !module.isSelected ) continue;
				
				position = model.getModulePosition( module.id );
				var newPosition:Rectangle = new Rectangle( position.x + xMove / gridSize, position.y + yMove / gridSize, ModuleInstance.getModuleWidth(), ModuleInstance.getModuleHeight( module.interfaceDefinition ) );

				_repositionMap[ module.id ] = newPosition;
			} 

			displayRepositionMap();			
		}		
		
		
		private function onClickModule( moduleID:int, event:MouseEvent ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				return;
			}

			_isMultiselectionClick = Utilities.hasMultiselectionModifier( event );  
			if( !_isMultiselectionClick )
			{
				if( !model.isModuleInstanceSelected( moduleID ) )
				{
					for each( var module:ModuleInstance in block.modules )
					{
						if( module.isSelected )
						{
							controller.processCommand( new SetObjectSelection( module.id, false ) );
						}
					}
				}

				for each( var connection:Connection in block.connections )
				{
					if( connection.isSelected )
					{
						controller.processCommand( new SetObjectSelection( connection.id, false ) );
					}
				}
			}
			
			controller.processCommand( new SetPrimarySelectedChild( block.id, _repositionModuleID ) );
			
			if( _isMultiselectionClick && model.isModuleInstanceSelected( moduleID ) )
			{
				controller.processCommand( new SetObjectSelection( moduleID, false ) );
				
				//don't reposition when removing from multi-selection 
				_repositionModuleID = -1;	

				//deselect module's _links, except _links whose other end is selected
				for each( connection in block.connections )
				{
					var connectionID:int = connection.id;
					if( !connection.isSelected )
					{
						continue;
					}
					
					if( !model.isAudioLink( connection.sourceObjectID, connection.sourceAttributeName, connection.targetObjectID, connection.targetAttributeName ) )
					{
						continue;
					}
					
					if( connection.sourceObjectID == moduleID && !model.isModuleInstanceSelected( connection.targetObjectID ) )
					{
						controller.processCommand( new SetObjectSelection( connectionID, false ) );
					}
					
					if( connection.targetObjectID == moduleID && !model.isModuleInstanceSelected( connection.sourceObjectID ) )
					{
						controller.processCommand( new SetObjectSelection( connectionID, false ) );
					}
				}
					
			}
			else
			{
				controller.processCommand( new SetObjectSelection( moduleID, true ) );

				//select module's links
				for each( connection in block.connections )
				{
					if( connection.sourceObjectID == moduleID || connection.targetObjectID == moduleID )
					{
						if( !connection.isSelected )
						{
							controller.processCommand( new SetObjectSelection( connection.id, true ) );
						}						
					}
				}
			}
		}


		private function onClickLink( connectionID:int, event:MouseEvent ):void
		{
			if( !Utilities.hasMultiselectionModifier( event ) )
			{
				deselectEverything();
			}
			
			var connection:Connection = model.getConnection( connectionID );
			Assert.assertNotNull( connection )

			controller.processCommand( new SetObjectSelection( connectionID, !connection.isSelected ) );
		}	
		
		
		private function onClickWhitespace( event:MouseEvent ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				return;
			}

			_contentCanvas.addElement( _areaSelectionCanvas );

			_areaSelectionStart = new Point( mouseX, mouseY );
			_areaSelectionSnapshot = new Vector.<int>;
			
			if( Utilities.hasMultiselectionModifier( event ) )
			{
				for each( var module:ModuleInstance in block.modules )
				{
					if( module.isSelected )
					{
						_areaSelectionSnapshot.push( module.id );
					}
				}

				for each( var connection:Connection in block.connections )
				{
					if( connection.isSelected )
					{
						_areaSelectionSnapshot.push( module.id );
					}
				}
			}
			else
			{
				deselectEverything();
			}
		}

		
		private function updateAreaSelection( event:MouseEvent ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				return;
			}

			var newSelection:Vector.<int> = new Vector.<int>;
			newSelection = _areaSelectionSnapshot.concat();
			
			var rectangle:Rectangle = new Rectangle( Math.min( mouseX, _areaSelectionStart.x ), Math.min( mouseY, _areaSelectionStart.y ), Math.abs( mouseX - _areaSelectionStart.x ), Math.abs( mouseY - _areaSelectionStart.y ) )
			rectangle = rectangle.intersection( getRect( this ) );
			     
			for each( var element:ModuleGraphElement in _elements )
			{
				if( !element.getBounds( this ).intersects( rectangle ) )
				{
					continue;	
				}

				var indexOfModuleID:int = newSelection.indexOf( element.moduleID );
				if( indexOfModuleID >= 0 )
				{
					if( Utilities.hasMultiselectionModifier( event ) )
					{
						newSelection.splice( indexOfModuleID, 1 );
						
						//deselect module's _links, except _links whose other end is selected
						for each( var connection:Connection in block )
						{
							var connectionID:int = connection.id;
							var indexOfConnectionID:int = newSelection.indexOf( connectionID );
							
							if( indexOfConnectionID < 0 )
							{
								continue;
							}
							
							if( connection.sourceObjectID == element.moduleID && newSelection.indexOf( connection.targetObjectID ) < 0 )
							{
								newSelection.splice( indexOfConnectionID, 1 );
							}
							
							if( connection.targetObjectID == element.moduleID && newSelection.indexOf( connection.sourceObjectID ) < 0 )
							{
								newSelection.splice( indexOfConnectionID, 1 );
							}
						}
						
					}
				}
				else
				{
					newSelection.push( element.moduleID );

					//select module's _links
					for each( connection in block.connections )
					{
						connectionID = connection.id;
						
						if( connection.sourceObjectID == element.moduleID || connection.targetObjectID == element.moduleID )
						{
							if( newSelection.indexOf( connectionID ) < 0 )
							{
								newSelection.push( connectionID );
							}						
						}
					}					
				}
			}			     
			     
			_areaSelectionCanvas.graphics.clear();
			_areaSelectionCanvas.graphics.beginFill( _areaSelectionColor, areaSelectionAlpha );
			_areaSelectionCanvas.graphics.lineStyle( areaSelectionBorderWidth, _areaSelectionBorderColor, areaSelectionBorderAlpha );
			
			var rectangleOrigin:Point = _contentCanvas.localToContent( new Point( rectangle.x, rectangle.y ) );
			_areaSelectionCanvas.graphics.drawRect( rectangleOrigin.x, rectangleOrigin.y, rectangle.width, rectangle.height );
			_areaSelectionCanvas.graphics.endFill();
			
			for each( var module:ModuleInstance in block.modules )
			{
				controller.processCommand( new SetObjectSelection( module.id, newSelection.indexOf( module.id ) >= 0 ) );
			}

			for each( connection in block.connections )
			{
				controller.processCommand( new SetObjectSelection( connection.id, newSelection.indexOf( connection.id ) >= 0 ) );
			}
		}


		private function endAreaSelection():void
		{
			if( !_areaSelectionSnapshot ) 
			{
				return;
			}
			
			_contentCanvas.removeChild( _areaSelectionCanvas );
			
			_areaSelectionCanvas.graphics.clear();
			_areaSelectionStart = null;
			_areaSelectionSnapshot = null;
		}
		
		
		private function deselectEverything():void
		{
			clearPrimarySelection();
			clearMultipleSelection();
		}


		private function clearPrimarySelection():void
		{
			var block:Block = model.primarySelectedBlock;
			Assert.assertNotNull( block );

			controller.processCommand( new SetPrimarySelectedChild( block.id, -1 ) );
		}


		private function clearMultipleSelection():void
		{
			var block:Block = model.primarySelectedBlock;
			Assert.assertNotNull( block );
			
			for each( var module:ModuleInstance in block.modules )
			{
				if( module.isSelected )
				{
					controller.processCommand( new SetObjectSelection( module.id, false ) );
				}
			}

			for each( var connection:Connection in block.connections )
			{
				if( connection.isSelected )
				{
					controller.processCommand( new SetObjectSelection( connection.id, false ) );
				}
			}
		}


		private function endRepositioning():void
		{
			if( _repositionModuleID >= 0 )
			{
				var block:Block = model.getBlockFromModuleInstance( _repositionModuleID );
				Assert.assertNotNull( block );

				if( !_isMultiselectionClick )
				{				
					for each( var module:ModuleInstance in block.modules )
					{
						if( module.id != _repositionModuleID && module.isSelected )
						{
							controller.processCommand( new SetObjectSelection( module.id, false ) );
						}
					}
				}
			}			
			
			applyRepositionMap();
			
			_repositionModuleID = -1;
			_repositionOffset = null;
			clearSnapLines();
		}

		
		private function displayRepositionMap():void
		{
			for each( var element:ModuleGraphElement in _elements )
			{
				updateModuleGraphElement( element );
			}
			
			for each( var link:ModuleGraphLink in _links )
			{
				if( link.visible )
				{
					setLinkState( link );
				}
			}
		}
		
		
		private function applyRepositionMap():void
		{
			if( !_repositionMap ) return;

			var modulesToReposition:Object = _repositionMap;
			_repositionMap = null;
			
			for( var moduleID:String in modulesToReposition )
			{
				controller.processCommand( new SetModulePosition( int( moduleID ), modulesToReposition[ moduleID ] ) );
			}
		}
			
		
		private function deleteSelection():void
		{
			var block:Block = model.primarySelectedBlock;
			Assert.assertNotNull( block );
			
			for each( var connection:Connection in block.connections )
			{
				if( !model.isAudioLink( connection.sourceObjectID, connection.sourceAttributeName, connection.targetObjectID, connection.targetAttributeName ) ) 
				{
					continue;
				}
				
				if( connection.isSelected )
				{
					controller.processCommand( new RemoveConnection( connection.id ) );
				}
			} 
			
			for each( var module:ModuleInstance in block.modules )
			{
				if( module.isSelected )
				{
					controller.processCommand( new UnloadModule( module.id ) );
				}
			}
		}
		
		
		private function getElementToReposition():ModuleGraphElement
		{
			for each( var element:ModuleGraphElement in _elements )
			{
				if( element.isMouseInRepositionArea() )
				{
					return element;
				}
			}
			
			return null;
		}


		private function getConnectionPinUnderMouse( event:MouseEvent ):ConnectionPin
		{
			return Utilities.getAncestorByType( event.target, ConnectionPin ) as ConnectionPin;
		}
		
		
		private function getLinkUnderMouse():ModuleGraphLink
		{
			var globalMouse:Point = localToGlobal( new Point( mouseX, mouseY ) );
			var proximityMargin:int = 6;
			for each( var link:ModuleGraphLink in _links )
			{
				for( var proximity:int = - proximityMargin; proximity <= proximityMargin; proximity++ )
				{ 
					if( link.hitTestPoint( globalMouse.x + proximity, globalMouse.y + proximity, true ) )
					{
						return link;
					}

					if( link.hitTestPoint( globalMouse.x + proximity, globalMouse.y - proximity, true ) )
					{
						return link;
					}
				}
			}
			
			return null;
		}


		private function getLinkUnderRect( rect:Rectangle ):ModuleGraphLink
		{
			var scrolledRect:Rectangle = rect.clone();
			scrolledRect.offset( _contentCanvas.horizontalScrollPosition, _contentCanvas.verticalScrollPosition );
			
			for each( var link:ModuleGraphLink in _links )
			{
				if( link.hitTestRectangle( scrolledRect, _contentCanvas.horizontalScrollPosition, _contentCanvas.verticalScrollPosition )  )
				{
					return link;
				}
			}
			
			return null;
		}
		
		
		private function isClickOnScrollbar():Boolean
		{
			var globalMouse:Point = localToGlobal( new Point( mouseX, mouseY ) );

			if( _contentCanvas.horizontalScrollBar && _contentCanvas.horizontalScrollBar.visible && _contentCanvas.horizontalScrollBar.hitTestPoint( globalMouse.x, globalMouse.y ) )
			{
				return true;
			} 

			if( _contentCanvas.verticalScrollBar && _contentCanvas.verticalScrollBar.visible && _contentCanvas.verticalScrollBar.hitTestPoint( globalMouse.x, globalMouse.y ) )
			{
				return true;
			}
			
			return false; 
		}


		public function updateModuleGraphElement( element:ModuleGraphElement ):void
		{
			Assert.assertNotNull( element );

			var moduleID:int = element.moduleID;			
			var position:Rectangle = null;
			
			if( _repositionMap )
			{
				if( _repositionMap.hasOwnProperty( moduleID ) )
				{
					position = _repositionMap[ moduleID ];
				}
			}
			
			if( !position )
			{
				position = model.getModulePosition( moduleID );
			}
			
			Assert.assertNotNull( position );
			
			var gridSize:Number = FontSize.getTextRowHeight( this );
			if( isNaN( gridSize ) ) 
			{
				return;
			}
			
			element.x = position.left * gridSize;
			element.y = position.top * gridSize;
			element.width = position.width * gridSize;
			element.height = position.height * gridSize;

			if( moduleID >= 0 )
			{
				if( model.isModuleInstancePrimarySelected( moduleID ) || model.isModuleInstanceSelected( moduleID ) )
				{
					element.moveElementToFront();
				}
			}
			
			element.invalidateDisplayList();
			
			element.updateNameEdit();
			element.updateIOPins();
		}

		
		private function updateNewLink( event:MouseEvent ):void
		{
			Assert.assertNotNull( _newLinkAnchor );
			
			var destinationPin:ConnectionPin = getConnectionPinUnderMouse( event );
			var destinationPinIsValid:Boolean = false;

			var destination:Point = _contentCanvas.localToContent( new Point( mouseX, mouseY ) );
			var destinationOffset:Point = new Point();
			
			if( destinationPin && destinationPin.isInput != _newLinkAnchor.isInput )
			{
				var sourceModuleID:int = _newLinkAnchor.isInput ? destinationPin.moduleID : _newLinkAnchor.moduleID;
				var sourceAttributeName:String = _newLinkAnchor.isInput ? destinationPin.attributeName : _newLinkAnchor.attributeName
					
				var targetModuleID:int = _newLinkAnchor.isInput ? _newLinkAnchor.moduleID : destinationPin.moduleID;
				var targetAttributeName:String = _newLinkAnchor.isInput ? _newLinkAnchor.attributeName : destinationPin.attributeName;
				
				if( model.canSetAudioLink( sourceModuleID, sourceAttributeName, targetModuleID, targetAttributeName ) )
				{
					getLinkPoint( destinationPin.moduleID, destinationPin.attributeName, destination, destinationOffset );
					destinationPinIsValid = true;
				}
			}
			
			_newLinkDestination = destinationPinIsValid ? destinationPin : null;
			
			var newLinkAnchorPoint:Point = new Point();
			var newLinkAnchorOffset:Point = new Point();
			getLinkPoint( _newLinkAnchor.moduleID, _newLinkAnchor.attributeName, newLinkAnchorPoint, newLinkAnchorOffset );
			var trackOffset:Point = Point.interpolate( newLinkAnchorOffset, destinationOffset, 0.5 );

			if( destinationPin == _newLinkAnchor )
			{
				var mouseOnAnchorOffset:Number = FontSize.getTextRowHeight( this ) * 0.8;
				destination.copyFrom( newLinkAnchorPoint );
				destination.x += ( _newLinkAnchor.isInput ? -mouseOnAnchorOffset : mouseOnAnchorOffset );
			}
			
			if( _newLinkAnchor.isInput )
			{
				_newLink.setState( destination, newLinkAnchorPoint, trackOffset, newLinkWidth, _newLinkColor );
			}
			else
			{
				_newLink.setState( newLinkAnchorPoint, destination, trackOffset, newLinkWidth, _newLinkColor );
			}
		}

		
		private function getLinkPoint( moduleID:int, attributeName:String, linkPoint:Point, trackOffset:Point ):void
		{
			if( _elements.hasOwnProperty( moduleID ) )
			{
				var element:ModuleGraphElement = _elements[ moduleID ] as ModuleGraphElement;
				Assert.assertNotNull( element );
				
				element.getLinkPoint( attributeName, linkPoint, trackOffset );
				return;
			}
			
			Assert.assertTrue( false );
			return;
		}
		
		
		private function setLinkState( link:ModuleGraphLink ):void
		{
			var connection:Connection = model.getConnection( link.connectionID );
			Assert.assertNotNull( connection );
					
			var start:Point = new Point;
			var end:Point = new Point;
			var startTrackOffset:Point = new Point;
			var endTrackOffset:Point = new Point;
			
			getLinkPoint( connection.sourceObjectID, connection.sourceAttributeName, start, startTrackOffset );
			getLinkPoint( connection.targetObjectID, connection.targetAttributeName, end, endTrackOffset );
			var trackOffset:Point = Point.interpolate( startTrackOffset, endTrackOffset, 0.5 );
			
			var isSelected:Boolean = model.isConnectionSelected( connection.id );
			var linkWidth:int = isSelected ? selectedLinkWidth : normalLinkWidth;
			var linkColor:int = isSelected ? _selectedLinkColor : _normalLinkColor;
			
			link.setState( start, end, trackOffset, linkWidth, linkColor );
		}


		private function doXDragSnap( candidateX:int, moduleWidth:int, xSnapLines:Vector.<int> ):int
		{
			var leftSnap:int = -1;
			var rightSnap:int = -1;
			var snapThreshold:int = maximumSnapThreshold;
			for each( var element:ModuleGraphElement in _elements )
			{
				if( element.moduleID == _repositionModuleID || model.isModuleInstanceSelected( element.moduleID ) )
				{
					continue;
				}
				
				var difference:int = Math.abs( int( element.x ) - candidateX );
				if( difference <= snapThreshold )
				{
					leftSnap = element.x;
					snapThreshold = difference;
				}

				difference = Math.abs( int( element.x + element.width ) - candidateX );
				if( difference <= snapThreshold )
				{
					leftSnap = element.x + element.width;
					snapThreshold = difference;
				}
				
				difference = Math.abs( element.x - candidateX - moduleWidth );
				if( difference <= snapThreshold )
				{
					rightSnap = element.x;
					snapThreshold = difference;
				}

				difference = Math.abs( element.x + element.width - candidateX - moduleWidth );
				if( difference <= snapThreshold )
				{
					rightSnap = element.x + element.width;
				}
			}

			if( leftSnap > 0 ) xSnapLines.push( leftSnap );
			if( rightSnap > 0 ) xSnapLines.push( rightSnap );
			
			if( leftSnap > 0 ) return leftSnap;
			if( rightSnap > 0 ) return rightSnap - moduleWidth;
			
			return -1;
		}


		private function doYDragSnap( candidateY:int, moduleHeight:int, ySnapLines:Vector.<int> ):int
		{
			var topSnap:int = -1;
			var bottomSnap:int = -1;
			var snapThreshold:int = maximumSnapThreshold;
			for each( var element:ModuleGraphElement in _elements )
			{
				if( element.moduleID == _repositionModuleID || model.isModuleInstanceSelected( element.moduleID ) )
				{
					continue;
				}
				
				var difference:int = Math.abs( int( element.y ) - candidateY );
				if( difference <= snapThreshold )
				{
					topSnap = element.y;
					snapThreshold = difference;
				}
				
				difference = Math.abs( int( element.y + element.height ) - candidateY );
				if( difference <= snapThreshold )
				{
					topSnap = element.y + element.height;
					snapThreshold = difference;
				}
				
				difference = Math.abs( element.y - candidateY - moduleHeight );
				if( difference <= snapThreshold )
				{
					bottomSnap = element.y;
					snapThreshold = difference;
				}
				
				difference = Math.abs( element.y + element.height - candidateY - moduleHeight );
				if( difference <= snapThreshold )
				{
					bottomSnap = element.y + element.height;
				}
			}
			
			if( topSnap > 0 ) ySnapLines.push( topSnap );
			if( bottomSnap > 0 ) ySnapLines.push( bottomSnap );
			
			if( topSnap > 0 ) return topSnap;
			if( bottomSnap > 0 ) return bottomSnap - moduleHeight;
			
			return -1;
		}
		
		
		private function clearSnapLines():void
		{
			_snapLinesCanvas.graphics.clear();
		}
		
		
		private function drawXSnapLines( xSnapLines:Vector.<int> ):void
		{
			for each( var xCoord:int in xSnapLines )
			{
				_snapLinesCanvas.graphics.lineStyle( 4, 0x808080, 0.3 );

				_snapLinesCanvas.graphics.moveTo( xCoord, 0 );
				_snapLinesCanvas.graphics.lineTo( xCoord, Math.max( _contentCanvas.height, _contentCanvas.measuredHeight ) );
			}
		}


		private function drawYSnapLines( ySnapLines:Vector.<int> ):void
		{
			for each( var yCoord:int in ySnapLines )
			{
				_snapLinesCanvas.graphics.lineStyle( 4, 0x808080, 0.3 );

				_snapLinesCanvas.graphics.moveTo( 0, yCoord );
				_snapLinesCanvas.graphics.lineTo( Math.max( _contentCanvas.measuredWidth, _contentCanvas.width ), yCoord );
			}
		}


 		private function get moduleDirectory():String
 		{
			if( _lastModuleDirectory )
 			{
 				var directory:File = new File( _lastModuleDirectory );
 				if( directory.exists )
 				{
	 				return _lastModuleDirectory;
 				}
 			}

			return File.documentsDirectory.nativePath;
 		}


 		private function onSelectModuleToImport( event:Event ):void
 		{
 			var file:File = event.target as File;
 			Assert.assertNotNull( file );
 			
 			_lastModuleDirectory = file.parent.nativePath;

			var gridSize:Number = FontSize.getTextRowHeight( this );
			controller.processCommand( new ImportModule( file.nativePath, model.primarySelectedBlock.id, new Point( _moduleImportPoint.x / gridSize, _moduleImportPoint.y / gridSize ) ) );
 		}


 		private function onSelectModuleToExport( event:Event ):void
 		{
 			var file:File = event.target as File;
 			Assert.assertNotNull( file );
 			
 			_lastModuleDirectory = file.parent.nativePath;

			controller.exportModule( file.nativePath ); 			
 		}
		
		
 		private function changeTrackColor():void
 		{
			Assert.assertNotNull( model.selectedTrack );
			
			new TrackColorPicker( model, controller, this );
 		}
		
		
 		private function importModule():void
 		{
			var filter:FileFilter = new FileFilter( "Integra Modules", "*" + Utilities.integraFileExtension + ";*.mixd" );
 			var file:File = new File( moduleDirectory );
 			file.browseForOpen( "Import Module", [filter] );
 			
 			file.addEventListener( Event.SELECT, onSelectModuleToImport );      			
 		}


 		private function exportModule():void
 		{
			var filter:FileFilter = new FileFilter( "Integra Modules", "*" + Utilities.integraFileExtension );
 			var file:File = new File( moduleDirectory + "/" + model.primarySelectedModule.name + Utilities.integraFileExtension );
 			file.browseForSave( "Export Module" );
 			
 			file.addEventListener( Event.SELECT, onSelectModuleToExport );      			
 		}
		

		private function onUpdateRemoveSelectionMenuItem( menuItem:Object ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				menuItem.enabled = false;
				return;
			}
			
			for each( var module:ModuleInstance in block.modules )
			{
				if( module.isSelected )
				{
					menuItem.enabled = true;
					return;
				}
			}
			
			for each( var connection:Connection in block.connections )
			{
				if( connection.isSelected )
				{
					menuItem.enabled = true;
					return;
				}
			}
			
			menuItem.enabled = false;
		}


		private function onUpdateChangeTrackColorMenuItem( menuItem:Object ):void
		{
			menuItem.enabled = ( model.selectedTrack != null );
		}
		
		
		private function onUpdateExportModuleMenuItem( menuItem:Object ):void
		{
			_moduleImportPoint = new Point( mouseX + horizontalScrollPosition, mouseY + verticalScrollPosition );
			menuItem.enabled = ( model.primarySelectedModule != null );
		}

		
		[Bindable] 
        private var contextMenuData:Array = 
        [
            { label: "Remove Selection", keyEquivalent: "backspace", keyCode: Keyboard.BACKSPACE, handler: deleteSelection, updater: onUpdateRemoveSelectionMenuItem }, 
            { type: "separator" }, 
            { label: "Import Module...", handler: importModule },
   	        { label: "Export Module...", handler: exportModule, updater: onUpdateExportModuleMenuItem },
            { type: "separator" }, 
            { label: "Change Track Color...", handler: changeTrackColor, updater: onUpdateChangeTrackColorMenuItem }
        ];


		private var _backUpButton:BackUpButton = new BackUpButton;

		private var _elements:Object = new Object;
		private var _connectionPins:Vector.<ConnectionPin> = new Vector.<ConnectionPin>;
		private var _links:Vector.<ModuleGraphLink> = new Vector.<ModuleGraphLink>;
		
		private var _liveViewElements:Object = new Object;
		
		private var _newLink:ModuleGraphLink = null;
		private var _newLinkAnchor:ConnectionPin = null;
		private var _newLinkDestination:ConnectionPin = null;
		
		
		private var _elementBeingCreated:ModuleGraphElement = null;
		private var _connectionPinsBeingCreated:Vector.<ConnectionPin> = new Vector.<ConnectionPin>;
		
		private var _linkBeingCreatedOver:ModuleGraphLink = null;
		private var _inputReplacementLink:ModuleGraphLink = null;
		private var _outputReplacementLink:ModuleGraphLink = null;
		
		private var _repositionModuleID:int = -1;
		private var _repositionOffset:Point = null;
		private var _repositionMap:Object = null;
		private var _isMultiselectionClick:Boolean = false;

		private var _areaSelectionStart:Point = null;
		private var _areaSelectionSnapshot:Vector.<int> = null;
		private var _areaSelectionCanvas:Canvas = new Canvas;

		private var _contentCanvas:Canvas = new Canvas;
		private var _snapLinesCanvas:Canvas = new Canvas;
		
		private var _newLinkColor:int;
		private var _normalLinkColor:int;
		private var _selectedLinkColor:int;
		private var _areaSelectionColor:int;
		private var _areaSelectionBorderColor:int;
		
		private var _lastModuleDirectory:String = null;
		private var _moduleImportPoint:Point = null;
		
		private static const newLinkWidth:Number = 2;
		private static const normalLinkWidth:Number = 2;
		private static const selectedLinkWidth:Number = 2;
		private static const areaSelectionAlpha:Number = 0.1;
		private static const areaSelectionBorderWidth:Number = 1;
		private static const areaSelectionBorderAlpha:Number = 0.2;
		
		private static const maximumSnapThreshold:int = 10;
		private static const minimumLinkMargin:Number = 6;
	}
}
