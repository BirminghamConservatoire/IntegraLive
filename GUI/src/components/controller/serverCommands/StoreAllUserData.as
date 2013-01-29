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


package components.controller.serverCommands
{
	import components.model.IntegraDataObject;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	
	public class StoreAllUserData extends ServerCommand
	{
		public function StoreAllUserData()
		{
			super();
	
			isNewUndoStep = false;
		}
		

		override public function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			storeUserData( model.project, controller );
		}

		
		override public function omitFromTrace():Boolean 
		{ 
			return true; 
		}
		

		private function storeUserData( object:IntegraDataObject, controller:IntegraController ):void
		{
			controller.processCommand( new StoreUserData( object.id ) );
						
			if( object is IntegraContainer )
			{
				for each( var child:IntegraDataObject in ( object as IntegraContainer ).children )
				{
					storeUserData( child, controller );
				}
			}
		}
	}
}