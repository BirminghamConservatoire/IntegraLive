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
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	public class RenameObject extends ServerCommand
	{
		public function RenameObject( objectID:int, newName:String )
		{
			super();
			
			_objectID = objectID;
			_newName = newName;
		}
		
		
		public function get objectID():int { return _objectID; }
		public function get newName():String { return _newName; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			if( !object )
			{
				Assert.assertTrue( false );
				return false;
			}
			
			if( !validateName() ) 
			{
				return false;
			}
			
			var currentPath:Array = model.getPathArrayFromID( _objectID );
			Assert.assertTrue( currentPath.length >= 1 );
			currentPath[ currentPath.length - 1 ] = _newName;
			
			if( model.getIDFromPathArray( currentPath ) >= 0 )
			{
				return false;	//new name is already in use
			}
			
			return( _newName != object.name );	
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RenameObject( _objectID, model.getDataObjectByID( _objectID ).name ) );
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			object.name = _newName;	
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _objectID ) );
			connection.addParam( _newName, XMLRPCDataTypes.STRING );
			connection.callQueued( "command.rename" );
		}
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			//store all user data again, since paths might have changed!
			controller.processCommand( new StoreAllUserData() );
		}
		

		protected override function testServerResponse( response:Object ):Boolean
		{
			return (response.response == "command.rename" );
		}
		
		
		private function validateName():Boolean
		{
			//must be at least one character long
			if( _newName.length < 1 ) 
			{
				return false;
			}
			
			//must not start with a number
			var firstChar:String = _newName.charAt( 0 );
			for( var i:int = 0; i <= 9; i++ )
			{
				if( firstChar == String( i ) ) 
				{
					return false;
				}
			} 
			
			//must be alphanumeric (ie only characters in IntegraDataObject.legalObjectNameCharacterSet)
			for( i = 0; i < _newName.length; i++ )
			{
				if( IntegraDataObject.legalObjectNameCharacterSet.indexOf( _newName.charAt( i ) ) < 0 )
				{
					return false;
				}
			}

			return true;
		}

		
		private var _objectID:int;
		private var _newName:String;
	}
}