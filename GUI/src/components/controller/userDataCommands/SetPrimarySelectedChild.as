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
	import components.controller.IntegraController;
	import components.controller.UserDataCommand;
	import components.controller.serverCommands.SelectScene;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.Scene;
	
	import flexunit.framework.Assert;


	public class SetPrimarySelectedChild extends UserDataCommand
	{
		public function SetPrimarySelectedChild( objectID:int, primarySelectedChildID:int )
		{
			super();

			_objectID = objectID;
			_primarySelectedChildID = primarySelectedChildID;
		}


 		public function get objectID():int { return _objectID; }
 		public function get primarySelectedChildID():int { return _primarySelectedChildID; }


		public override function initialize( model:IntegraModel ):Boolean
		{
			return( _primarySelectedChildID != model.getDataObjectByID( _objectID ).primarySelectedChildID );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetPrimarySelectedChild( _objectID, model.getDataObjectByID( _objectID ).primarySelectedChildID ) ); 
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );
			object.primarySelectedChildID = _primarySelectedChildID;
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetPrimarySelectedChild = previousCommand as SetPrimarySelectedChild;
			Assert.assertNotNull( previous );
			
			return( _objectID == previous._objectID ); 
		}		


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _objectID );	
		}

		
 		private var _objectID:int;
 		private var _primarySelectedChildID:int;
	}
}
