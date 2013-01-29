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
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	public class StoreUserData extends ServerCommand
	{
		public function StoreUserData( objectID:int, userDataString:String = null )
		{
			super();
	
			_objectID = objectID;
			_userDataString = userDataString;
			
			isNewUndoStep = false;
		}
		
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			Assert.assertNull( _userDataString );
			
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );
			
			_userDataString = object.saveUserData( model );
			return ( _userDataString != object.userDataString );
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );

			pushInverseCommand( new StoreUserData( _objectID, object.userDataString ) );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );

			object.userDataString = _userDataString;
		}
		

		override public function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _objectID ).concat( "userData" ) );
			connection.addParam( _userDataString, XMLRPCDataTypes.STRING );
			connection.callQueued( "command.set" );	
		}


		override public function omitFromTrace():Boolean 
		{ 
			return true; 
		}

		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return ( response.response == "command.set" );
		}
		

		private var _objectID:int;
		private var _userDataString:String;		
	}
}