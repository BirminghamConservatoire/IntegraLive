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
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;


	public class SetObjectSelection extends UserDataCommand
	{
		public function SetObjectSelection( objectID:int, isSelected:Boolean )
		{
			super();

			_objectID = objectID;
			_isSelected = isSelected;
		}


 		public function get objectID():int { return _objectID; }
 		public function get isSelected():Boolean { return _isSelected; }


		public override function initialize( model:IntegraModel ):Boolean
		{
			//can only set selection on objects which have a container as parent
			if( !model.getParent( _objectID ) is IntegraContainer ) return false;

			return( _isSelected != model.isObjectSelected( _objectID ) );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetObjectSelection( _objectID, model.isObjectSelected( _objectID ) ) ); 
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			if( !model.doesObjectExist( _objectID ) ) return;	//special corner case for import block -> undo -> redo 
			
			
			var parent:IntegraContainer = model.getParent( _objectID ) as IntegraContainer;
			Assert.assertNotNull( parent );
			parent.userData.setChildSelected( _objectID, _isSelected );
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetObjectSelection = previousCommand as SetObjectSelection;
			Assert.assertNotNull( previous );
			
			return( _objectID == previous._objectID ); 
		}		


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.getParent( _objectID ).id );	
		}


 		private var _objectID:int;
 		private var _isSelected:Boolean;
	}
}