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
 
 
 

package components.views.ArrangeViewProperties
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.ListEvent;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddBlock;
	import components.controller.serverCommands.AddScript;
	import components.controller.serverCommands.AddTrack;
	import components.controller.serverCommands.ImportBlock;
	import components.controller.serverCommands.RemoveBlock;
	import components.controller.serverCommands.RemoveBlockImport;
	import components.controller.serverCommands.RemoveScaledConnection;
	import components.controller.serverCommands.RemoveScript;
	import components.controller.serverCommands.RemoveTrack;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetScalerInputRange;
	import components.controller.serverCommands.SetScalerOutputRange;
	import components.controller.serverCommands.SwitchAllObjectVersions;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.serverCommands.SwitchObjectVersion;
	import components.model.Connection;
	import components.model.Envelope;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	
	import flexunit.framework.Assert;
	

	public class RoutingItem extends IntegraView
	{
		public function RoutingItem( scalerID:int )
		{
			super();
			
			_scalerID = scalerID;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			
			_hbox.setStyle( "horizontalAlign", "middle" );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			initialiseCombo( _sourceObjectCombo, onChangeSourceComboSelection );
			initialiseCombo( _sourceEndpointCombo, onChangeSourceComboSelection );

			_hbox.addChild( _inScaleMinimum );
			_hbox.addChild( _inScaleMaximum );
			
			_hbox.addChild( _arrow );

			_hbox.addChild( _outScaleMinimum );
			_hbox.addChild( _outScaleMaximum );
			
			initialiseCombo( _targetObjectCombo, onChangeTargetComboSelection );
			initialiseCombo( _targetEndpointCombo, onChangeTargetComboSelection );

			_inScaleMinimum.addEventListener( Event.CHANGE, onChangeInScaleMinimum );
			_inScaleMaximum.addEventListener( Event.CHANGE, onChangeInScaleMaximum );
			_outScaleMinimum.addEventListener( Event.CHANGE, onChangeOutScaleMinimum );
			_outScaleMaximum.addEventListener( Event.CHANGE, onChangeOutScaleMaximum );
			
			_deleteButton.setStyle( "skin", CloseButtonSkin );
			_deleteButton.setStyle( "fillAlpha", 1 );
			_deleteButton.addEventListener( MouseEvent.CLICK, onDelete );
			_hbox.addChild( _deleteButton );
			
			addChild( _hbox );
			
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( SetScalerInputRange, onScalerInputRangeChanged );
			addUpdateMethod( SetScalerOutputRange, onScalerOutputRangeChanged );
			
			addUpdateMethod( AddScript, onAvailableObjectsChanged );
			addUpdateMethod( RemoveScript, onAvailableObjectsChanged );
			addUpdateMethod( AddBlock, onAvailableObjectsChanged );
			addUpdateMethod( ImportBlock, onAvailableObjectsChanged );
			addUpdateMethod( RemoveBlock, onAvailableObjectsChanged );
			addUpdateMethod( RemoveBlockImport, onAvailableObjectsChanged );
			addUpdateMethod( AddTrack, onAvailableObjectsChanged );
			addUpdateMethod( RemoveTrack, onAvailableObjectsChanged );
			addUpdateMethod( RenameObject, onAvailableObjectsChanged );
			
			addUpdateMethod( SwitchModuleVersion, onObjectVersionChanged );
			addUpdateMethod( SwitchObjectVersion, onObjectVersionChanged );

			addEventListener( Event.RESIZE, onResize );
		}
		
	
		public function get scalerID():int { return _scalerID; }


		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_deleteButton.setStyle( "color", 0xcfcfcf );
						_deleteButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_deleteButton.setStyle( "color", 0x313131 );
						_deleteButton.setStyle( "fillColor", 0x8c8c8c );
						break;
				}

				renderArrow();						
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				height = FontSize.getTextRowHeight( this );
				
				_sourceObjectCombo.height = height;
				_sourceEndpointCombo.height = height;
				_targetObjectCombo.height = height;
				_targetEndpointCombo.height = height;

				var scaleControlWidth:Number = getScaleControlWidth();
				_inScaleMinimum.width = scaleControlWidth;
				_inScaleMaximum.width = scaleControlWidth;
				_outScaleMinimum.width = scaleControlWidth;
				_outScaleMaximum.width = scaleControlWidth;
				
				_inScaleMinimum.height = height;
				_inScaleMaximum.height = height;
				_outScaleMinimum.height = height;
				_outScaleMaximum.height = height;
				
				_arrow.width = FontSize.getButtonSize( this );
				_arrow.height = FontSize.getButtonSize( this ) / 2;
				renderArrow();

				_deleteButton.width = FontSize.getButtonSize( this );
				_deleteButton.height = FontSize.getButtonSize( this );
				
			}
		}

		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			if( event.target == _deleteButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "DeleteRoutingButton" );
			}

			return null;
		}

		override protected function onAllDataChanged():void
		{
			updateAll();
		}


		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			if( command.connectionID == scaler.upstreamConnection.id || command.connectionID == scaler.downstreamConnection.id )
			{
				updateAll();
			}
		}
		
		
		private function onScalerInputRangeChanged( command:SetScalerInputRange ):void
		{
			if( command.scalerID == _scalerID )
			{
				updateScalerInputControls();
			}
		}

		
		private function onScalerOutputRangeChanged( command:SetScalerOutputRange ):void
		{
			if( command.scalerID == _scalerID )
			{
				updateScalerOutputControls();
			}
		}
		
		
		private function onObjectVersionChanged( command:SwitchObjectVersion ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );

			if( command.objectID == scaler.upstreamConnection.sourceObjectID )
			{
				updateScalerInputControls();
			}

			if( command.objectID == scaler.downstreamConnection.targetObjectID )
			{
				updateScalerOutputControls();
			}
		}
		
		
		private function onAvailableObjectsChanged( command:ServerCommand ):void
		{
			updateObjectCombos(); 
		}
		
		
		private function updateAll():void
		{
			updateObjectCombos();
			updateEndpointCombos();

			updateScalerInputControls();
			updateScalerOutputControls();
		}
		
		
		private function getScaleControlWidth():Number
		{
			return Math.min( FontSize.getButtonSize( this ) * 3, width / 12 );
		}


		private function initialiseCombo( combo:ComboBox, eventHandler:Function ):void
		{
			combo.percentWidth = 100;
			combo.rowCount = 10;
			
			combo.addEventListener( ListEvent.CHANGE, eventHandler );
		
			_hbox.addChild( combo );	
		}	
		
		
		private function updateObjectCombos():void
		{
			var container:IntegraContainer = model.selectedContainer;
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( container );
			Assert.assertNotNull( scaler );
			
			var sourceObjectComboContents:Array = new Array;
			var targetObjectComboContents:Array = new Array;

			var sourceIndexToSelect:int = buildObjectComboContents( sourceObjectComboContents, container, scaler.upstreamConnection.sourceObjectID, false );
			var targetIndexToSelect:int = buildObjectComboContents( targetObjectComboContents, container, scaler.downstreamConnection.targetObjectID, true );

			_sourceObjectCombo.dataProvider = sourceObjectComboContents;
			_targetObjectCombo.dataProvider = targetObjectComboContents;

			_sourceObjectCombo.selectedIndex = sourceIndexToSelect;
			_targetObjectCombo.selectedIndex = targetIndexToSelect;

			enableComponent( _sourceObjectCombo, sourceObjectComboContents.length > 0 ); 
			enableComponent( _targetObjectCombo, targetObjectComboContents.length > 0 ); 
		}
		
		
		private function buildObjectComboContents( objectComboContents:Array, container:IntegraContainer, currentConnectedID:int, isTarget:Boolean, ancestorName:String = "" ):int
		{
			var indexToSelect:int = -1;
			
			for each( var child:IntegraDataObject in container.children )
			{
				var childName:String = ancestorName + child.name;
				
				if( shouldMakeClassAvailableForConnections( child, isTarget ) )
				{
					if( currentConnectedID == child.id )
					{
						indexToSelect = objectComboContents.length;
					}

					objectComboContents.push( childName );
				}
				
				if( child is IntegraContainer )
				{
					indexToSelect = Math.max( indexToSelect, buildObjectComboContents( objectComboContents, child as IntegraContainer, currentConnectedID, isTarget, childName + "." ) );
				}				
			}
			
			return indexToSelect;
		}


		private function updateEndpointCombos():void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );

			var upstreamConnection:Connection = scaler.upstreamConnection;
			var downstreamConnection:Connection = scaler.downstreamConnection;

			populateEndpointCombo( _sourceEndpointCombo, upstreamConnection.sourceObjectID, upstreamConnection.sourceAttributeName, false );
			populateEndpointCombo( _targetEndpointCombo, downstreamConnection.targetObjectID, downstreamConnection.targetAttributeName, true );
		}
		
		
		private function populateEndpointCombo( combo:ComboBox, objectID:int, selectedEndpointName:String, isTarget:Boolean ):void
		{
			var endpointComboContents:Array = new Array;
			var selectedIndex:int = -1;
			
			if( objectID >= 0 )
			{
				var object:IntegraDataObject = model.getDataObjectByID( objectID );
				Assert.assertNotNull( object );
				
				for each( var endpoint:EndpointDefinition in object.interfaceDefinition.endpoints )
				{
					var isConnectable:Boolean = isTarget ? endpoint.canBeConnectionTarget : endpoint.canBeConnectionSource;
					
					if( !isConnectable )
					{
						continue;
					}
					
					if( endpoint.name == selectedEndpointName )
					{
						selectedIndex = endpointComboContents.length; 
					}
					
					endpointComboContents.push( endpoint.name );
				} 
			}
			
			combo.dataProvider = endpointComboContents;
			combo.selectedIndex = selectedIndex;
			enableComponent( combo, ( endpointComboContents.length > 0 ) ); 
		}
		
		
		private function enableComponent( component:UIComponent, enabled:Boolean ):void
		{
			component.enabled = enabled;
			component.alpha = enabled ? 1 : 0.4; 
		}
		
		
		private function updateScalerInputControls():void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			var endpoint:EndpointDefinition = model.getEndpointDefinition( scaler.upstreamConnection.sourceObjectID, scaler.upstreamConnection.sourceAttributeName );
			if( endpoint )
			{
				if( endpoint.isStateful )
				{
					var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;
					var isInteger:Boolean = ( stateInfo.type == StateInfo.INTEGER );
					_inScaleMinimum.integer = isInteger;
					_inScaleMaximum.integer = isInteger;
	
					_inScaleMinimum.setRange( stateInfo.constraint.minimum, stateInfo.constraint.maximum );
					_inScaleMinimum.value = scaler.inRangeMin;
	
					_inScaleMaximum.setRange( stateInfo.constraint.minimum, stateInfo.constraint.maximum );
					_inScaleMaximum.value = scaler.inRangeMax;
					
					enableComponent( _inScaleMinimum, true ); 
					enableComponent( _inScaleMaximum, true ); 
				}
				else
				{
					//bang - no scaling
					_inScaleMinimum.setRange( 0, 0 );
					_inScaleMaximum.setRange( 0, 0 );
					_inScaleMinimum.value = _inScaleMaximum.value = 0;
					enableComponent( _inScaleMinimum, false ); 
					enableComponent( _inScaleMaximum, false ); 
				}
			}
			else
			{
				enableComponent( _inScaleMinimum, false ); 
				enableComponent( _inScaleMaximum, false ); 
			}
		}

		
		private function updateScalerOutputControls():void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			var endpoint:EndpointDefinition = model.getEndpointDefinition( scaler.downstreamConnection.targetObjectID, scaler.downstreamConnection.targetAttributeName );
			if( endpoint )
			{
				if( endpoint.isStateful )
				{
					var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;
					var isInteger:Boolean = ( stateInfo.type == StateInfo.INTEGER );
					_outScaleMinimum.integer = isInteger;
					_outScaleMaximum.integer = isInteger;
					
					_outScaleMinimum.setRange( stateInfo.constraint.minimum, stateInfo.constraint.maximum );
					_outScaleMinimum.value = scaler.outRangeMin;
					
					_outScaleMaximum.setRange( stateInfo.constraint.minimum, stateInfo.constraint.maximum );
					_outScaleMaximum.value = scaler.outRangeMax;
					
					enableComponent( _outScaleMinimum, true ); 
					enableComponent( _outScaleMaximum, true ); 
				}
				else
				{
					//bang - no scaling
					_outScaleMinimum.setRange( 0, 0 );
					_outScaleMaximum.setRange( 0, 0 );
					_outScaleMinimum.value = _outScaleMaximum.value = 0;
					enableComponent( _outScaleMinimum, false ); 
					enableComponent( _outScaleMaximum, false ); 
				}
			}
			else
			{
				enableComponent( _outScaleMinimum, false );
				enableComponent( _outScaleMaximum, false );
			}
		}
		
		
		private function onChangeSourceComboSelection( event:ListEvent ):void
		{
			var container:IntegraContainer = model.selectedContainer;
			var scaler:Scaler = model.getScaler( _scalerID );

			Assert.assertNotNull( scaler );
			Assert.assertNotNull( Object );
			
			var containerPathString:String = model.getPathStringFromID( container.id );
			
			var objectID:int = -1;
			var endpointName:String = null;
			
			if( _sourceObjectCombo.selectedItem )
			{
				objectID = model.getIDFromPathString( containerPathString + "." + String( _sourceObjectCombo.selectedItem ) );
				Assert.assertTrue( objectID >= 0 );
				
				if( _sourceEndpointCombo.selectedItem )
				{
					var object:IntegraDataObject = model.getDataObjectByID( objectID );
					Assert.assertNotNull( object );
					
					var endpoint:EndpointDefinition = object.interfaceDefinition.getEndpointDefinition( String( _sourceEndpointCombo.selectedItem ) );
					if( endpoint )
					{		
						endpointName = endpoint.name;
					} 
				}    
			}

			var upstreamConnection:Connection = scaler.upstreamConnection;
			var downstreamConnection:Connection = scaler.downstreamConnection;
			
			if( model.canSetScaledConnection( objectID, endpointName, downstreamConnection.targetObjectID, downstreamConnection.targetAttributeName, _scalerID ) )
			{
				controller.processCommand( new SetConnectionRouting( upstreamConnection.id, objectID, endpointName, upstreamConnection.targetObjectID, upstreamConnection.targetAttributeName ) );
			}
			else
			{
				//this connection can't be made (trying to set up an illegal connection?
				updateAll();
			}
		}

		
		private function onChangeTargetComboSelection( event:ListEvent ):void
		{
			var container:IntegraContainer = model.selectedContainer;
			var scaler:Scaler = model.getScaler( _scalerID );
			
			Assert.assertNotNull( scaler );
			Assert.assertNotNull( Object );
			
			var containerPathString:String = model.getPathStringFromID( container.id );
			
			var objectID:int = -1;
			var endpointName:String = null;
			
			if( _targetObjectCombo.selectedItem )
			{
				objectID = model.getIDFromPathString( containerPathString + "." + String( _targetObjectCombo.selectedItem ) );
				Assert.assertTrue( objectID >= 0 );
				
				if( _targetEndpointCombo.selectedItem )
				{
					var object:IntegraDataObject = model.getDataObjectByID( objectID );
					Assert.assertNotNull( object );
					
					var endpoint:EndpointDefinition = object.interfaceDefinition.getEndpointDefinition( String( _targetEndpointCombo.selectedItem ) );
					if( endpoint )
					{		
						endpointName = endpoint.name;
					} 
				}    
			}
			
			var upstreamConnection:Connection = scaler.upstreamConnection;
			var downstreamConnection:Connection = scaler.downstreamConnection;

			if( model.canSetScaledConnection( upstreamConnection.sourceObjectID, upstreamConnection.sourceAttributeName, objectID, endpointName, _scalerID ) )
			{
				controller.processCommand( new SetConnectionRouting( downstreamConnection.id, downstreamConnection.sourceObjectID, downstreamConnection.sourceAttributeName, objectID, endpointName ) );
			}
			else
			{
				//this connection can't be made (trying to set up an illegal connection?
				updateAll();
			}
		}

		
		private function onChangeInScaleMinimum( event:Event ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetScalerInputRange( _scalerID, _inScaleMinimum.value, scaler.inRangeMax ) );
		}
		
		
		private function onChangeInScaleMaximum( event:Event ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetScalerInputRange( _scalerID, scaler.inRangeMin, _inScaleMaximum.value ) );
		}
		
		
		private function onChangeOutScaleMinimum( event:Event ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetScalerOutputRange( _scalerID, _outScaleMinimum.value, scaler.outRangeMax ) );
		}
		
		
		private function onChangeOutScaleMaximum( event:Event ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			controller.processCommand( new SetScalerOutputRange( _scalerID, scaler.outRangeMin, _outScaleMaximum.value ) );
		}
		
		
		private function onDelete( event:MouseEvent ):void
		{
			controller.processCommand( new RemoveScaledConnection( _scalerID ) );
		}


		private function onResize( event:Event ):void
		{
			var maximumControlsWidth:Number = FontSize.getButtonSize( this ) * 66;
			
			var scaleControlWidth:Number = getScaleControlWidth();
			_inScaleMinimum.width = scaleControlWidth;
			_inScaleMaximum.width = scaleControlWidth;
			_outScaleMinimum.width = scaleControlWidth;
			_outScaleMaximum.width = scaleControlWidth;
			
			var horizontalGap:Number = _hbox.getStyle( "horizontalGap" );
			var nonComboControlWidth:Number = _closeButtonWidth + _arrow.width + scaleControlWidth * 4 + horizontalGap * 4; 
			var comboWidth:int = ( Math.min( width, maximumControlsWidth ) - nonComboControlWidth ) / 4 - horizontalGap;

			_sourceObjectCombo.width = comboWidth;
			_sourceEndpointCombo.width = comboWidth;
			_targetObjectCombo.width = comboWidth;
			_targetEndpointCombo.width = comboWidth;			
		}
		
		
		private function renderArrow():void
		{
			var lineColor:uint = 0;
			
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					lineColor = 0x747474;
					break;
				
				case ColorScheme.DARK:
					lineColor = 0x8c8c8c;
					break;
			}
			
			_arrow.graphics.clear();
			_arrow.graphics.lineStyle( 2, lineColor );
			
			_arrow.graphics.moveTo( 0, _arrow.height / 2 );
			_arrow.graphics.lineTo( _arrow.width, _arrow.height / 2 );
			_arrow.graphics.lineTo( _arrow.width - _arrow.height / 2, 0 );
			_arrow.graphics.moveTo( _arrow.width, _arrow.height / 2 );
			_arrow.graphics.lineTo( _arrow.width - _arrow.height / 2, _arrow.height );
		}
		
		
		private function shouldMakeClassAvailableForConnections( object:IntegraDataObject, isTarget:Boolean ):Boolean
		{
			if( object is Envelope || object is Scaler ) 
			{
				return false;
			}
			
			//only make class available if it has at least one routable endpoint
			for each( var endpoint:EndpointDefinition in object.interfaceDefinition.endpoints )
			{
				if( isTarget ? endpoint.canBeConnectionTarget : endpoint.canBeConnectionSource )
				{
					return true;
				}
			}
			
			return false;
		}
		
		
		private var _scalerID:int = -1;
		
		private var _hbox:HBox = new HBox;

		private var _sourceObjectCombo:ComboBox = new ComboBox;
		private var _sourceEndpointCombo:ComboBox = new ComboBox;

		private var _inScaleMinimum:RoutingItemScalingControl = new RoutingItemScalingControl;
		private var _inScaleMaximum:RoutingItemScalingControl = new RoutingItemScalingControl;

		private var _arrow:Canvas = new Canvas;

		private var _outScaleMinimum:RoutingItemScalingControl = new RoutingItemScalingControl;
		private var _outScaleMaximum:RoutingItemScalingControl = new RoutingItemScalingControl;

		private var _targetObjectCombo:ComboBox = new ComboBox;
		private var _targetEndpointCombo:ComboBox = new ComboBox;

		private var _deleteButton:Button = new Button;
		
		private static const _closeButtonWidth:int = 40;
	}
}