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
	import components.controller.Command;
	import components.controller.UserDataCommand;
	import components.model.IntegraModel;
	import components.model.userData.LiveViewControl;
	
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;


	public class SetLiveViewControlPosition extends UserDataCommand
	{
		public function SetLiveViewControlPosition( moduleID:int, controlInstanceName:String, newPosition:Rectangle )
		{
			super();

			_moduleID = moduleID;
			_controlInstanceName = controlInstanceName;
			_newPosition = newPosition;  		
		}


 		public function get moduleID():int { return _moduleID; }
 		public function get controlInstanceName():String { return _controlInstanceName; }
 		public function get newPosition():Rectangle { return _newPosition; } 		


		public override function initialize( model:IntegraModel ):Boolean
		{
			return( _newPosition != model.getLiveViewControl( _moduleID, _controlInstanceName ).position );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetLiveViewControlPosition( _moduleID, _controlInstanceName, model.getLiveViewControl( _moduleID, _controlInstanceName ).position ) ); 
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var control:LiveViewControl = model.getLiveViewControl( _moduleID, _controlInstanceName );
			Assert.assertNotNull( control );
			control.position = _newPosition;
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetLiveViewControlPosition = previousCommand as SetLiveViewControlPosition;
			Assert.assertNotNull( previous );
			
			return ( _moduleID == previous._moduleID ) && ( _controlInstanceName == previous._controlInstanceName ); 
		}		


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.getBlockFromModuleInstance( _moduleID ).id );	
		}


 		private var _moduleID:int;
 		private var _controlInstanceName:String;
 		private var _newPosition:Rectangle; 		
	}
}