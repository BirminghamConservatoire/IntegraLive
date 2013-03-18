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
	import __AS3__.vec.Vector;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddEnvelope;
	import components.controller.serverCommands.RemoveEnvelope;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetModuleAttribute;
	import components.controller.userDataCommands.SetColorScheme;
	import components.controller.userDataCommands.SetLiveViewControls;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.controller.userDataCommands.ToggleLiveViewControl;
	import components.model.Block;
	import components.model.Info;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.ColorScheme;
	import components.model.userData.LiveViewControl;
	import components.utils.ControlContainer;
	import components.utils.ControlMeasurer;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.IntegraView;
	
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
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
			addTitleInvalidatingCommand( SetPrimarySelectedChild );			
			addTitleInvalidatingCommand( RenameObject );
			addColorChangingCommand( SetColorScheme );
			
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
			switch( model.project.userData.colorScheme )
			{
				default:
				case ColorScheme.LIGHT:
					return 0x747474;
					
				case ColorScheme.DARK:
					return 0x8c8c8c;
			}
		}
		
		
		override public function getInfoToDisplay( event:MouseEvent ):Info
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
			
			var color:uint = model.selectedTrack.userData.color;			
			
			for each( var widget:WidgetDefinition in widgets )
			{
				if( !ControlMeasurer.doesControlExist( widget.type ) )
				{
					continue;
				}
				
				var container:ControlContainer = new ControlContainer( _module.id, widget, model, controller );

				container.hasIncludeInLiveViewButton = true;
				container.includeInLiveView = _liveViewControlSet.hasOwnProperty( widget.label );

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
			var track:Track = model.selectedTrack;
			if( !track ) 
			{
				Assert.assertTrue( _allControls.length == 0 );
				return;
			}
			
			var color:uint = track.userData.color;
			
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
			
			for each( var liveViewControl:LiveViewControl in block.userData.liveViewControls )
			{
				if( liveViewControl.moduleID != _module.id )
				{
					continue;
				}
				
				_liveViewControlSet[ liveViewControl.controlInstanceName ] = 1;
			}
		}			
		
		
		private function revertToDefaults():void
		{
			for each( var endpoint:EndpointDefinition in _module.interfaceDefinition.endpoints )
			{
				if( !_module.attributes.hasOwnProperty( endpoint.name ) )
				{
					continue;
				}
				
				Assert.assertTrue( endpoint.isStateful );
				var stateInfo:StateInfo = endpoint.controlInfo.stateInfo;

				controller.processCommand( new SetModuleAttribute( _module.id, endpoint.name, stateInfo.defaultValue, stateInfo.type ) );
			}			
		}
		
		
		private function onUpdateRevertToDefaultsMenuItem( menuItem:Object ):void
		{
			menuItem.label = "Revert " + _module.name + " to default settings";
			for each( var endpoint:EndpointDefinition in _module.interfaceDefinition.endpoints )
			{
				if( !_module.attributes.hasOwnProperty( endpoint.name ) )
				{
					continue;
				}
				
				Assert.assertTrue( endpoint.isStateful );

				if( _module.attributes[ endpoint.name ] != endpoint.controlInfo.stateInfo.defaultValue )
				{
					menuItem.enabled = true;
					return;
				}
			}			
			
			menuItem.enabled = false;
		}




		[Bindable] 
        private var contextMenuData:Array = 
        [
            { label: "Revert to default settings", handler: revertToDefaults, updater: onUpdateRevertToDefaultsMenuItem } 
        ];
		
		private var _module:ModuleInstance;
		private var _allControls:Vector.<ControlContainer> = new Vector.<ControlContainer>;
		private var _endpointNameToWidgetMap:Object = new Object;

		private var _liveViewControlSet:Object = new Object;

		private static const controlMargin:Number = 32;
	}
}
		
		
