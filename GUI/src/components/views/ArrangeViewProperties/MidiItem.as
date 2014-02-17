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
	import mx.core.Container;
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
	import components.controller.serverCommands.RemoveMidiControlInput;
	import components.controller.serverCommands.RemoveScript;
	import components.controller.serverCommands.RemoveTrack;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetMidiControlInputValues;
	import components.controller.serverCommands.SetMidiInputDevices;
	import components.controller.serverCommands.SetScalerInputRange;
	import components.controller.serverCommands.SetScalerOutputRange;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.serverCommands.SwitchObjectVersion;
	import components.model.Connection;
	import components.model.Envelope;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.MidiControlInput;
	import components.model.MidiRawInput;
	import components.model.Player;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.utils.lockableComboBox.LockableComboBox;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	
	import flexunit.framework.Assert;

	public class MidiItem extends IntegraView
	{
		public function MidiItem( midiControlInputID:int )
		{
			super();
			
			_midiControlInputID = midiControlInputID;
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			
			_hbox.setStyle( "horizontalAlign", "middle" );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			initialiseCombo( _sourceDeviceCombo, onChangeMidiDevice );
			initialiseCombo( _sourceChannelCombo, onChangeMidiChannel );
			initialiseCombo( _sourceMessageTypeCombo, onChangeMessageType );
			initialiseCombo( _sourceMessageValueCombo, onChangeMessageValue );

			populateStaticMidiCombos();
			
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

			addUpdateMethod( SetMidiInputDevices, onMidiInputDevicesChanged );
			addUpdateMethod( SetMidiControlInputValues, onMidiControlInputValuesChanged );
			
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
		
	
		public function get midiControlInputID():int { return _midiControlInputID; }


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
				
				_sourceDeviceCombo.height = height;
				_sourceChannelCombo.height = height;
				_sourceMessageTypeCombo.height = height;
				_sourceMessageValueCombo.height = height;
				
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

		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( event.target == _deleteButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ArrangeViewProperties/DeleteMidiButton" );
			}

			return null;
		}

		override protected function onAllDataChanged():void
		{
			updateAll();
		}


		private function get midiControlInput():MidiControlInput
		{
			var midiControlInput:MidiControlInput = model.getMidiControlInput( _midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			return midiControlInput;
		}
		
		
		private function get scaler():Scaler
		{
			return midiControlInput.scaler;
		}
		
		
		private function onMidiInputDevicesChanged( command:SetMidiInputDevices ):void
		{
			updateMidiDeviceCombo();
		}
		
		
		private function onMidiControlInputValuesChanged( command:SetMidiControlInputValues ):void
		{
			if( command.midiControlInputID != _midiControlInputID ) return;
			
			updateMidiDeviceCombo();
			updateStaticMidiCombos();
			updateMessageValueCombo();
			updateScalerInputControls();
		}

		
		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			updateAll();
		}
		
		
		private function onScalerInputRangeChanged( command:SetScalerInputRange ):void
		{
			if( command.scalerID == scaler.id )
			{
				updateScalerInputControls();
			}
		}

		
		private function onScalerOutputRangeChanged( command:SetScalerOutputRange ):void
		{
			if( command.scalerID == scaler.id )
			{
				updateScalerOutputControls();
			}
		}
		
		
		private function onObjectVersionChanged( command:SwitchObjectVersion ):void
		{
			if( command.objectID == scaler.downstreamConnection.targetObjectID )
			{
				updateScalerOutputControls();
			}
		}
		
		
		private function onAvailableObjectsChanged( command:ServerCommand ):void
		{
			updateTargetObjectCombo(); 
		}
		
		
		private function updateAll():void
		{
			updateMidiDeviceCombo();
			updateStaticMidiCombos();
			updateMessageValueCombo();
			
			updateTargetObjectCombo();
			updateTargetEndpointCombo();

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
		
		
		private function updateMidiDeviceCombo():void
		{
			var indexToSelect:int = -1;
			var devices:Array = new Array;
			
			devices.push( MidiControlInput.ANY_DEVICE );
			if( midiControlInput.device == MidiControlInput.ANY_DEVICE )
			{
				indexToSelect = 0;
			}

			for each( var device:String in model.midiSettings.activeInputDevices )
			{
				if( device == midiControlInput.device )
				{
					indexToSelect = devices.length;
				}

				devices.push( device );
			}
			
			_sourceDeviceCombo.dataProvider = devices;
			_sourceDeviceCombo.selectedIndex = indexToSelect;
			
			var hasDevices:Boolean = ( devices.length > 1 );
			var deviceSelected:Boolean = ( indexToSelect >= 0 );

			enableComponent( _sourceDeviceCombo, hasDevices );
			
			enableComponent( _sourceChannelCombo, deviceSelected );
			enableComponent( _sourceMessageTypeCombo, deviceSelected );
			enableComponent( _sourceMessageValueCombo, deviceSelected );
			enableComponent( _inScaleMinimum, deviceSelected );
			enableComponent( _inScaleMaximum, deviceSelected );
		}
		
		
		private function populateStaticMidiCombos():void
		{
			var channels:Array = new Array;

			channels.push( "any chn" );
			for( var i:int = 1; i <= 16; i++ )
			{
				channels.push( "chn" + String( i ) );
			}

			_sourceChannelCombo.dataProvider = channels;

			_sourceMessageTypeCombo.dataProvider = [ CC_LABEL, NOTE_ON_LABEL ];  
		}
		
		
		private function updateStaticMidiCombos():void
		{
			_sourceChannelCombo.selectedIndex = midiControlInput.channel;
			
			switch( midiControlInput.messageType )
			{
				case MidiControlInput.CC: 		_sourceMessageTypeCombo.selectedItem = CC_LABEL;		break;
				case MidiControlInput.NOTEON: 	_sourceMessageTypeCombo.selectedItem = NOTE_ON_LABEL;	break;
				
				default:	
					Assert.assertTrue( false );
					break;
			}
		}
		
		
		private function updateMessageValueCombo():void
		{
			var data:Array = new Array;
			
			switch( midiControlInput.messageType )
			{
				case MidiControlInput.CC:
					for( var i:int = 0; i < 128; i++ )
					{
						data.push( "cc" + String( i ) ); 
					}
					break;

				case MidiControlInput.NOTEON:
					for( i = 0; i < 128; i++ )
					{
						data.push( Utilities.midiPitchToName( i ) ); 
					}
					break;
				
				default:
					Assert.assertTrue( false );
					break;
			}
			
			_sourceMessageValueCombo.dataProvider = data;
			_sourceMessageValueCombo.selectedIndex = midiControlInput.noteOrController;
		}
		
		
		private function updateTargetObjectCombo():void
		{
			var container:IntegraContainer = model.selectedContainer;
			Assert.assertNotNull( scaler );
			
			var targetObjectComboContents:Array = new Array;

			var targetIndexToSelect:int = buildObjectComboContents( targetObjectComboContents, container, scaler.downstreamConnection.targetObjectID );

			_targetObjectCombo.dataProvider = targetObjectComboContents;

			_targetObjectCombo.selectedIndex = targetIndexToSelect;

			enableComponent( _targetObjectCombo, targetObjectComboContents.length > 0 ); 
		}
		
		
		private function buildObjectComboContents( objectComboContents:Array, container:IntegraDataObject, currentConnectedID:int, ancestorName:String = "" ):int
		{
			var indexToSelect:int = -1;
			
			var children:Object = null;
			if( container is IntegraContainer ) children = ( container as IntegraContainer ).children;
			if( container is Player ) children = ( container as Player ).scenes;
			if( !children ) return -1;
			
			for each( var child:IntegraDataObject in children )
			{
				var childName:String = ancestorName + child.name;
				
				if( shouldMakeClassAvailableForConnections( child ) )
				{
					if( currentConnectedID == child.id )
					{
						indexToSelect = objectComboContents.length;
					}

					objectComboContents.push( childName );
				}
				
				if( child is IntegraContainer || child is Player )
				{
					indexToSelect = Math.max( indexToSelect, buildObjectComboContents( objectComboContents, child, currentConnectedID, childName + "." ) );
				}				
			}
			
			return indexToSelect;
		}


		private function updateTargetEndpointCombo():void
		{
			Assert.assertNotNull( scaler );

			var downstreamConnection:Connection = scaler.downstreamConnection;

			populateEndpointCombo( _targetEndpointCombo, downstreamConnection.targetObjectID, downstreamConnection.targetAttributeName, true, scaler );
		}
		
		
		private function populateEndpointCombo( combo:LockableComboBox, objectID:int, selectedEndpointName:String, isTarget:Boolean, scaler:Scaler ):void
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
					
					var comboItem:Object = new Object;
					comboItem.label = endpoint.name;
					
					//decorate combo item
					if( isTarget )
					{
						//is target endpoint disabled?
						if( !model.canSetScaledConnection( scaler.upstreamConnection.sourceObjectID, scaler.upstreamConnection.sourceAttributeName, objectID, endpoint.name, scaler.id ) )
						{
							comboItem.disabled = true;
						}
						else
						{
							//is target endpoint locked?
							var upstreamObjects:Vector.<IntegraDataObject> = new Vector.<IntegraDataObject>; 
							if( model.isConnectionTarget( objectID, endpoint.name, upstreamObjects ) )
							{
								if( containsAnythingOtherThan( upstreamObjects, scaler ) )
								{
									comboItem.locked = true;	
								}
							}
						}
					}
					else
					{
						//is source endpoint disabled?
						if( !model.canSetScaledConnection( objectID, endpoint.name, scaler.downstreamConnection.targetObjectID, scaler.downstreamConnection.targetAttributeName, scaler.id ) )
						{
							comboItem.disabled = true;
						}
					}
					
					endpointComboContents.push( comboItem );
				} 
			}
			
			combo.dataProvider = endpointComboContents;
			combo.selectedIndexRegardlessOfLock = selectedIndex;
			enableComponent( combo, ( endpointComboContents.length > 0 ) ); 
		}
		
		
		private function containsAnythingOtherThan( objects:Vector.<IntegraDataObject>, scaler:Scaler ):Boolean
		{
			for each( var object:IntegraDataObject in objects )
			{
				if( object != scaler ) return true;
			}
			
			return false;
		}
		
		
		private function enableComponent( component:UIComponent, enabled:Boolean ):void
		{
			component.enabled = enabled;
			component.alpha = enabled ? 1 : 0.4; 
		}
		
		
		private function updateScalerInputControls():void
		{
			Assert.assertNotNull( scaler );
			
			Assert.assertNotNull( midiControlInput );
			
			var endpoint:EndpointDefinition = midiControlInput.interfaceDefinition.getEndpointDefinition( "value" );
			Assert.assertNotNull( endpoint && endpoint.isStateful );
			
			var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;
			
			_inScaleMinimum.integer = true;
			_inScaleMaximum.integer = true;
			
			var minimum:int = ( midiControlInput.messageType == MidiControlInput.NOTEON ) ? 1 : 0;
			var maximum:int = 127;
			_inScaleMinimum.setRange( minimum, maximum );
			_inScaleMaximum.setRange( minimum, maximum );
			
			_inScaleMinimum.value = scaler.inRangeMin;
			_inScaleMaximum.value = scaler.inRangeMax;
		}

		
		private function updateScalerOutputControls():void
		{
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
		
		
		private function onChangeMidiDevice( event:ListEvent ):void
		{
			midiSettingsChanged();	
		}
		
		
		private function onChangeMidiChannel( event:ListEvent ):void
		{
			midiSettingsChanged();	
		}
		
		
		private function onChangeMessageType( event:ListEvent ):void
		{
			midiSettingsChanged();
			updateMessageValueCombo();
		}
		
		
		private function onChangeMessageValue( event:ListEvent ):void
		{
			midiSettingsChanged();
		}
		
		
		private function midiSettingsChanged():void
		{
			var device:String = String( _sourceDeviceCombo.selectedItem );
			var channel:int = _sourceChannelCombo.selectedIndex;
			var messageType:String = "";
			switch( String( _sourceMessageTypeCombo.selectedItem ) )
			{
				case CC_LABEL:		messageType = MidiControlInput.CC;			break;
				case NOTE_ON_LABEL:	messageType = MidiControlInput.NOTEON;		break;
			}
				
			var messageValue:int = _sourceMessageValueCombo.selectedIndex;
			
			controller.processCommand( new SetMidiControlInputValues( midiControlInput.id, device, channel, messageType, messageValue ) );
		}

		
		private function onChangeTargetComboSelection( event:ListEvent ):void
		{
			var container:IntegraContainer = model.selectedContainer;
			
			Assert.assertNotNull( scaler );
			Assert.assertNotNull( Object );
			
			var containerPathString:String = model.getPathStringFromID( container.id );
			
			var objectID:int = -1;
			var endpointName:String = null;
			
			if( event.target == _targetObjectCombo ) 
			{
				_targetEndpointCombo.selectedIndexRegardlessOfLock = -1;
			}
			
			if( _targetObjectCombo.selectedItem )
			{
				objectID = model.getIDFromPathString( containerPathString + "." + String( _targetObjectCombo.selectedItem ) );
				Assert.assertTrue( objectID >= 0 );
				
				if( _targetEndpointCombo.selectedItem )
				{
					var object:IntegraDataObject = model.getDataObjectByID( objectID );
					Assert.assertNotNull( object );
					
					var endpoint:EndpointDefinition = object.interfaceDefinition.getEndpointDefinition( String( _targetEndpointCombo.selectedItem.label ) );
					if( endpoint )
					{		
						endpointName = endpoint.name;
					} 
				}    
			}
			
			var upstreamConnection:Connection = scaler.upstreamConnection;
			var downstreamConnection:Connection = scaler.downstreamConnection;

			if( model.canSetScaledConnection( upstreamConnection.sourceObjectID, upstreamConnection.sourceAttributeName, objectID, endpointName, scaler.id ) )
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
			Assert.assertNotNull( scaler );
			controller.processCommand( new SetScalerInputRange( scaler.id, _inScaleMinimum.value, scaler.inRangeMax ) );
		}
		
		
		private function onChangeInScaleMaximum( event:Event ):void
		{
			Assert.assertNotNull( scaler );
			controller.processCommand( new SetScalerInputRange( scaler.id, scaler.inRangeMin, _inScaleMaximum.value ) );
		}
		
		
		private function onChangeOutScaleMinimum( event:Event ):void
		{
			Assert.assertNotNull( scaler );
			controller.processCommand( new SetScalerOutputRange( scaler.id, _outScaleMinimum.value, scaler.outRangeMax ) );
		}
		
		
		private function onChangeOutScaleMaximum( event:Event ):void
		{
			Assert.assertNotNull( scaler );
			controller.processCommand( new SetScalerOutputRange( scaler.id, scaler.outRangeMin, _outScaleMaximum.value ) );
		}
		
		
		private function onDelete( event:MouseEvent ):void
		{
			controller.processCommand( new RemoveMidiControlInput( _midiControlInputID ) );
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
			var nonComboControlWidth:Number = _closeButtonWidth + _arrow.width + scaleControlWidth * 4 + horizontalGap * 6; 
			var totalComboWidth:Number = ( Math.min( width, maximumControlsWidth ) - nonComboControlWidth );
			
			var wideComboWidth:Number = totalComboWidth / 5 - horizontalGap;
			var narrowComboWidth:Number = totalComboWidth * 2/15 - horizontalGap;

			_sourceDeviceCombo.width = wideComboWidth;
			_sourceChannelCombo.width = narrowComboWidth;
			_sourceMessageTypeCombo.width = narrowComboWidth;
			_sourceMessageValueCombo.width = narrowComboWidth;
			_targetObjectCombo.width = wideComboWidth;
			_targetEndpointCombo.width = wideComboWidth;			
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
		
		
		private function shouldMakeClassAvailableForConnections( object:IntegraDataObject ):Boolean
		{
			if( object is Envelope || object is Scaler || object is MidiControlInput || object is MidiRawInput ) 
			{
				return false;
			}
			
			//only make class available if it has at least one routable endpoint
			for each( var endpoint:EndpointDefinition in object.interfaceDefinition.endpoints )
			{
				if( endpoint.canBeConnectionTarget )
				{
					return true;
				}
			}
			
			return false;
		}
		
		
		private var _midiControlInputID:int = -1;
		
		private var _hbox:HBox = new HBox;

		private var _sourceDeviceCombo:ComboBox = new ComboBox;
		private var _sourceChannelCombo:ComboBox = new ComboBox;
		private var _sourceMessageTypeCombo:ComboBox = new ComboBox;
		private var _sourceMessageValueCombo:ComboBox = new ComboBox;

		private var _inScaleMinimum:RoutingItemScalingControl = new RoutingItemScalingControl;
		private var _inScaleMaximum:RoutingItemScalingControl = new RoutingItemScalingControl;

		private var _arrow:Canvas = new Canvas;

		private var _outScaleMinimum:RoutingItemScalingControl = new RoutingItemScalingControl;
		private var _outScaleMaximum:RoutingItemScalingControl = new RoutingItemScalingControl;

		private var _targetObjectCombo:ComboBox = new ComboBox;
		private var _targetEndpointCombo:LockableComboBox = new LockableComboBox;

		private var _deleteButton:Button = new Button;
		
		private static const _closeButtonWidth:int = 40;
		
		private static const CC_LABEL:String = "cc";
		private static const NOTE_ON_LABEL:String = "note on";
	}
}