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

package components.views.ModuleProperties
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import __AS3__.vec.Vector;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddConnection;
	import components.controller.serverCommands.AddEnvelope;
	import components.controller.serverCommands.AddScaledConnection;
	import components.controller.serverCommands.ReceiveMidiInput;
	import components.controller.serverCommands.RemoveEnvelope;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetModuleAttribute;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.userDataCommands.SetColorScheme;
	import components.controller.userDataCommands.SetLiveViewControls;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Block;
	import components.model.Info;
	import components.model.ModuleInstance;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.ColorScheme;
	import components.model.userData.LiveViewControl;
	import components.utils.ControlContainer;
	import components.utils.ControlMeasurer;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;


	public class ModuleProperties extends IntegraView
	{
		public function ModuleProperties()
		{
			super();
			
			minHeight = 100;
			height = 200;
			maxHeight = 400;
			
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( SetModuleAttribute, onAttributeChanged );
			addUpdateMethod( SetLiveViewControls, onLiveViewControlsChanged );
			addUpdateMethod( ToggleLiveViewControl, onLiveViewControlToggled );
			addUpdateMethod( SetConnectionRouting, onPadlockStateMightHaveChanged );
			addUpdateMethod( AddEnvelope, onPadlockStateMightHaveChanged );
			addUpdateMethod( RemoveEnvelope, onPadlockStateMightHaveChanged );
			addUpdateMethod( SetTrackColor, onTrackColorChanged );
			addUpdateMethod( SwitchModuleVersion, onModuleVersionSwitched );
			addUpdateMethod( ReceiveMidiInput, onMidiInput );
			addUpdateMethod( SetContainerActive, onContainerActiveChanged );

			addTitleInvalidatingCommand( SetPrimarySelectedChild );			
			addTitleInvalidatingCommand( RenameObject );
			addColorChangingCommand( SetColorScheme );
			
			addEventListener( MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown );
			contextMenuDataProvider = contextMenuData;
		}


		override public function get isSidebarColours():Boolean { return true; }


		override public function get isTitleEditable():Boolean 
		{ 
			return ( _module != null ); 
		}


		override public function get title():String 
		{ 
			if( _module )
			{
				return _module.name;
			}
			else
			{
				return "Module Properties";
			} 
		}


		override public function set title( title:String ):void 
		{ 
			super.title = title;

			if( !_module )
			{
				Assert.assertTrue( false );
				return;
			}

			controller.processCommand( new RenameObject( _module.id, title ) ); 
		}
		
		
		override public function get color():uint
		{
			switch( model.project.projectUserData.colorScheme )
			{
				default:
				case ColorScheme.LIGHT:
					return 0x747474;
					
				case ColorScheme.DARK:
					return 0x8c8c8c;
			}
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( !_module )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleProperties" );
			}
			
			var control:ControlContainer = Utilities.getAncestorByType( event.target, ControlContainer ) as ControlContainer;
			if( !control ) 
			{
				return _module.interfaceDefinition.interfaceInfo.info;
			}
			
			return control.getInfoToDisplay( event );
		}
	
	
		override protected function onAllDataChanged():void
		{
			updateAll();
		}


		private function clear():void
		{
			_endpointNameToWidgetMap = new Object;
		
			 // removeAllChildren(); // FL4U
			removeAllElements();
			_allControls.length = 0;
			
			_liveViewControlSet = new Object();
		}


		private function updateAll():void
		{
			clear();

			_module = model.primarySelectedModule;
			if( !_module )	 
			{
				return;	
			}

			var interfaceDefinition:InterfaceDefinition = _module.interfaceDefinition;
			var widgets:Vector.<WidgetDefinition> = interfaceDefinition.widgets;

			findLiveViewControls();
			
			var color:uint = model.getContainerColor( model.primarySelectedBlock.id );			
			
			for each( var widget:WidgetDefinition in widgets )
			{
				if( !ControlMeasurer.doesControlExist( widget.type ) )
				{
					continue;
				}
				
				var container:ControlContainer = new ControlContainer( _module.id, widget, model, controller );

				container.hasIncludeInLiveViewButton = true;
				container.includeInLiveView = _liveViewControlSet.hasOwnProperty( widget.label );
				container.hasMidiLearn = canAnyBeConnectionSource( widget.attributeToEndpointMap );

				var position:Rectangle = widget.position;
				Assert.assertNotNull( position );
				container.x = position.x; 
				container.y = position.y;
				container.width = position.width;
				container.height = position.height;

				container.setStyle( "color", color );
				
				_allControls.push( container );
				addChild( container );
				
				for each( var endpointName:String in widget.attributeToEndpointMap )
				{
					_endpointNameToWidgetMap[ endpointName ] = container;
				}
			}
		}
		
		
		private function canAnyBeConnectionSource( attributeToEndpointMap:Object ):Boolean
		{
			for each( var endpointName:String in attributeToEndpointMap )
			{
				var endpointDefinition:EndpointDefinition = _module.interfaceDefinition.getEndpointDefinition( endpointName );
				Assert.assertNotNull( endpointDefinition );
				
				if( endpointDefinition.canBeConnectionTarget ) return true;
			}
			
			return false;
		}
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			if( _module != model.primarySelectedModule )
			{
				updateAll();
			}
		};


		private function onAttributeChanged( command:SetModuleAttribute ):void
		{
			if( !_module )
			{
				return;	//don't update when no module is displayed
			}
			
			if( command.moduleID != _module.id )
			{
				return;	//don't update when a different module's attribute changes
			}
			
			var control:ControlContainer = _endpointNameToWidgetMap[ command.endpointName ] as ControlContainer;
			if( control )
			{
				control.updateOnModuleAttributeChanged( command.id );
			}
		}


		private function onLiveViewControlsChanged( command:SetLiveViewControls ):void
		{
			updateLiveViewCheckStates();
		}


		private function onLiveViewControlToggled( command:ToggleLiveViewControl ):void
		{
			updateLiveViewCheckStates();	
		}


		private function onTrackColorChanged( command:SetTrackColor ):void
		{
			updateColor();
		}
		
		
		private function onContainerActiveChanged( command:SetContainerActive ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( block && model.isEqualOrAncestor( command.containerID, block.id ) )
			{
				updateColor();
			}
		}
		
		
		private function onModuleVersionSwitched( command:SwitchModuleVersion ):void
		{
			if( _module && command.objectID == _module.id )
			{
				updateAll();
			}
		}
		
		
		private function onPadlockStateMightHaveChanged( command:ServerCommand ):void
		{
			for each( var control:ControlContainer in _allControls )
			{
				control.updateWritableness();
			}
		}


		private function updateLiveViewCheckStates():void
		{
			findLiveViewControls();
			for each( var container:ControlContainer in _allControls )
			{
				container.includeInLiveView = _liveViewControlSet.hasOwnProperty( container.widget.label );
			}
		}
		
		
		private function updateColor():void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block ) 
			{
				Assert.assertTrue( _allControls.length == 0 );
				return;
			}
			
			var color:uint = model.getContainerColor( block.id );
			
			for each( var control:ControlContainer in _allControls )
			{
				control.setStyle( "color", color );
			} 
		}


		private function findLiveViewControls():void
		{
			_liveViewControlSet = new Object;
			
			if( !_module )
			{
				 return;
			}
			
			var block:Block = model.getBlockFromModuleInstance( _module.id );
			Assert.assertNotNull( block );
			
			for each( var liveViewControl:LiveViewControl in block.blockUserData.liveViewControls )
			{
				if( liveViewControl.moduleID != _module.id )
				{
					continue;
				}
				
				_liveViewControlSet[ liveViewControl.controlInstanceName ] = 1;
			}
		}	
		
		
		private function onMidiInput( command:ReceiveMidiInput ):void
		{
			if( command.midiID != model.primarySelectedBlock.midi.id ) return;

			for each( var control:ControlContainer in _allControls )
			{
				if( control.isInMidiLearnMode )
				{
					control.endMidiLearnMode();
					doMidiLearn( command.midiEndpoint, control.midiLearnEndpoint )
				}
			}
		}
		
		
		private function doMidiLearn( midiEndpointName:String, targetEndpointName:String ):void
		{
			var block:Block = model.primarySelectedBlock;
			var blockID:int = _module.parentID;
			
			var addScaledConnection:AddScaledConnection = new AddScaledConnection( blockID );
			controller.processCommand( addScaledConnection );

			var scalerID:int = addScaledConnection.scalerID;
			var scaler:Scaler = model.getScaler( scalerID );
			Assert.assertNotNull( scaler );
			
			var upstreamConnectionID:int = scaler.upstreamConnection.id;
			var downstreamConnectionID:int = scaler.downstreamConnection.id;
			
			controller.processCommand( new SetConnectionRouting( upstreamConnectionID, block.midi.id, midiEndpointName, scalerID, "inValue" ) );
			controller.processCommand( new SetConnectionRouting( downstreamConnectionID, scalerID, "outValue", _module.id, targetEndpointName ) );
		}
		
		
		private function onRightMouseDown( event:MouseEvent ):void
		{
			_controlUnderMouse = Utilities.getAncestorByType( event.target, ControlContainer ) as ControlContainer;
		}
		
		
		private function revertAll( event:Event ):void
		{
			for each( var control:ControlContainer in _allControls )
			{
				for each( var endpoint:EndpointDefinition in control.unlockedEndpoints )
				{
					if( !endpoint.isStateful ) continue; 
					if( !endpoint.controlInfo.canBeTarget ) continue;

					var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;
					
					controller.processCommand( new SetModuleAttribute( _module.id, endpoint.name, stateInfo.defaultValue, stateInfo.type ) );
				}
			}			
		}
		
		
		private function get enableRevertAllItem():Boolean
		{
			for each( var control:ControlContainer in _allControls )
			{
				for each( var endpoint:EndpointDefinition in control.unlockedEndpoints )
				{
					if( !endpoint.isStateful ) continue;
					if( !endpoint.controlInfo.canBeTarget ) continue;
					
					if( _module.attributes[ endpoint.name ] != endpoint.controlInfo.stateInfo.defaultValue )
					{
						return true;
					}
				}			
			}
			
			return false;
		}

		
		private function revertControl( event:Event ):void
		{
			Assert.assertNotNull( _controlUnderMouse );
			
			for each( var endpointName:String in _controlUnderMouse.widget.attributeToEndpointMap )
			{
				var endpoint:EndpointDefinition = _module.interfaceDefinition.getEndpointDefinition( endpointName );
				Assert.assertTrue( endpoint );
				
				if( !endpoint.isStateful ) continue; 
				if( !endpoint.controlInfo.canBeTarget ) continue;

				var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;
				
				controller.processCommand( new SetModuleAttribute( _module.id, endpoint.name, stateInfo.defaultValue, stateInfo.type ) );
			}
		}

		
		private function updateRevertControl( menuItem:NativeMenuItem ):void
		{
			menuItem.enabled = false;
			
			if( _controlUnderMouse )
			{
				var label:String = "";
				
				for each( var endpoint:EndpointDefinition in _controlUnderMouse.unlockedEndpoints )
				{
					if( !endpoint.isStateful ) continue; 
					if( !endpoint.controlInfo.canBeTarget ) continue;
					
					if( _module.attributes[ endpoint.name ] != endpoint.controlInfo.stateInfo.defaultValue )
					{
						menuItem.enabled = true;
					}
					
					if( label.length > 0 ) label += ", ";
					label += endpoint.label;
				}
				menuItem.label = label;
			}
		}
		
		
		private function onUpdateRevert( menuItem:Object ):void
		{
			var revertSubmenu:NativeMenu = new NativeMenu;
			
			if( _controlUnderMouse )
			{
				var unlockedEndpoints:Vector.<EndpointDefinition> = _controlUnderMouse.unlockedEndpoints;
				var canEdit:Boolean = false;
				
				for each( var unlockedEndpoint:EndpointDefinition in unlockedEndpoints )
				{
					if( !unlockedEndpoint.isStateful ) continue;
					if( !unlockedEndpoint.controlInfo.canBeTarget ) continue;
					
					canEdit = true;
					break;
				}
				
				if( canEdit )
				{
					var revertControlItem:NativeMenuItem = new NativeMenuItem;
					updateRevertControl( revertControlItem );
					revertControlItem.addEventListener( Event.SELECT, revertControl ); 
					revertSubmenu.addItem( revertControlItem );
					
					revertSubmenu.addItem( new NativeMenuItem( "", true ) );	//separator
				}
			}
			
			var revertAllItem:NativeMenuItem = new NativeMenuItem;
			revertAllItem.label = "All Controls";
			revertAllItem.enabled = enableRevertAllItem;
			revertAllItem.addEventListener( Event.SELECT, revertAll ); 
				
			revertSubmenu.addItem( revertAllItem );
			
			menuItem.submenu = revertSubmenu;
		}
		
		
		[Bindable] 
        private var contextMenuData:Array = 
        [
			{ label: "Revert to default", updater: onUpdateRevert } 
        ];

		
		private var _module:ModuleInstance;
		private var _allControls:Vector.<ControlContainer> = new Vector.<ControlContainer>;
		private var _endpointNameToWidgetMap:Object = new Object;

		private var _liveViewControlSet:Object = new Object;
		
		private var _controlUnderMouse:ControlContainer = null;

		private static const controlMargin:Number = 32;
	}
}
		
		
