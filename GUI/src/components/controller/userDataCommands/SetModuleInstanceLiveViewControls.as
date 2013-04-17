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


package components.controller.userDataCommands
{
	import __AS3__.vec.Vector;
	
	import components.controller.IntegraController;
	import components.controller.UserDataCommand;
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.LiveViewControl;
	import components.utils.ControlMeasurer;
	import components.utils.Utilities;
	
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;

	public class SetModuleInstanceLiveViewControls extends UserDataCommand
	{
		public function SetModuleInstanceLiveViewControls( moduleID:int, includeInLiveView:Boolean )
		{
			super();
			
			_moduleID = moduleID;
			_includeInLiveView = includeInLiveView;
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlockFromModuleInstance( _moduleID );
			Assert.assertNotNull( block );

			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			Assert.assertNotNull( module );

			var liveViewControls:Object = getCopyOfLiveViewControls( block );
			
			var orderedWidgetList:Vector.<WidgetDefinition> = module.interfaceDefinition.widgets.concat();
			orderedWidgetList.sort( compareWidgetPosition );
			
			for each( var widget:WidgetDefinition in orderedWidgetList )
			{
				var liveViewControlID:String = LiveViewControl.makeLiveViewControlID( _moduleID, widget.label );
				
				if( _includeInLiveView )
				{
					if( !liveViewControls.hasOwnProperty( liveViewControlID ) )
					{
						if( ControlMeasurer.doesControlExist( widget.type ) )
						{
							var liveViewControl:LiveViewControl = new LiveViewControl;
							liveViewControl.moduleID = _moduleID;
							liveViewControl.controlInstanceName = widget.label;
							
							liveViewControl.position = findNewLiveViewControlPosition( widget, liveViewControls ); 
							
							liveViewControls[ liveViewControlID ] = liveViewControl;
						}
					}
				}
				else
				{
					if( liveViewControls.hasOwnProperty( liveViewControlID ) )
					{
						delete liveViewControls[ liveViewControlID ];
					}
				}
			}

			if( Utilities.getNumberOfProperties( liveViewControls ) == Utilities.getNumberOfProperties( block.blockUserData.liveViewControls ) )
			{
				return;	//nothing changed
			}				
			
			controller.processCommand( new SetLiveViewControls( block.id, liveViewControls ) );
		} 
		
		
		private function getCopyOfLiveViewControls( block:Block ):Object
		{
			var copiedMap:Object = new Object;
			
			for each( var control:LiveViewControl in block.blockUserData.liveViewControls )
			{
				var copiedControl:LiveViewControl = new LiveViewControl;
				copiedControl.moduleID = control.moduleID;
				copiedControl.controlInstanceName = control.controlInstanceName;
				if( control.position )
				{
					copiedControl.position = new Rectangle( control.position.left, control.position.top, control.position.width, control.position.height );
				}
				
				copiedMap[ copiedControl.id ] = copiedControl;
			} 
			
			return copiedMap;
		}
		
		
		private function compareWidgetPosition( widget1:WidgetDefinition, widget2:WidgetDefinition ):int 
		{
			var position1:Rectangle = widget1.position;
			var position2:Rectangle = widget2.position;
			
			var xMiddle1:Number = position1.x + position1.width / 2;
			var xMiddle2:Number = position2.x + position2.width / 2;
			
			return ( xMiddle1 < xMiddle2 ) ? -1 : 1;
		}


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.getBlockFromModuleInstance( _moduleID ).id );	
		}


		private var _moduleID:int;
		private var _includeInLiveView:Boolean;
	}
}