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
	
	import components.controller.UserDataCommand;
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.LiveViewControl;
	
	import flexunit.framework.Assert;
	

	public class ToggleLiveViewControl extends UserDataCommand
	{
		public function ToggleLiveViewControl( liveViewControl:LiveViewControl )
		{
			super();
			
			_liveViewControl = liveViewControl; 
		}
		
		
		public function get liveViewControl():LiveViewControl { return _liveViewControl; }
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var existingControl:LiveViewControl = model.getBlockFromModuleInstance( _liveViewControl.moduleID ).userData.liveViewControls[ _liveViewControl.id ] as LiveViewControl;
			pushInverseCommand( new ToggleLiveViewControl( existingControl ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlockFromModuleInstance( _liveViewControl.moduleID );
			Assert.assertNotNull( block );
			
			var liveViewControls:Object = block.userData.liveViewControls;

			var controlID:String = _liveViewControl.id;
			
			if( liveViewControls.hasOwnProperty( controlID ) )
			{
				delete liveViewControls[ controlID ];
			}
			else
			{
				if( _liveViewControl.position == null )
				{
					var widget:WidgetDefinition = model.getModuleInstance( _liveViewControl.moduleID ).interfaceDefinition.getWidgetDefinition( _liveViewControl.controlInstanceName );
					Assert.assertNotNull( widget );
					_liveViewControl.position = findNewLiveViewControlPosition( widget, liveViewControls );
				}
				
				liveViewControls[ controlID ] = _liveViewControl;
			}
		}
		

		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.getBlockFromModuleInstance( _liveViewControl.moduleID ).id );	
		}		

		
		private var _liveViewControl:LiveViewControl; 
	}
}