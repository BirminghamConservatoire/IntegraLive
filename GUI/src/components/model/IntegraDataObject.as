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

package components.model
{
	import components.model.userData.UserData;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	
	import flexunit.framework.Assert;
	
	public class IntegraDataObject
	{
		public function IntegraDataObject()
		{
		}


		public function get id():int { return _id; }
		public function get parentID():int { return _parentID; }
		public function get name():String { return _name; }
		public function get interfaceDefinition():InterfaceDefinition { return _interfaceDefinition; }
		public function get active():Boolean { return _active; }

		public function get userDataString():String { return _userDataString; }
		public function set active( active:Boolean ):void { _active = active; }

		public function set id( id:int ):void { _id = id; }
		public function set parentID( parentID:int ):void { _parentID = parentID; }
		public function set name( name:String ):void { _name = name; }
		public function set interfaceDefinition( interfaceDefinition:InterfaceDefinition ):void { _interfaceDefinition = interfaceDefinition; }

		public function set userDataString( userDataString:String ):void { _userDataString = userDataString; }


		public function copyDataObjectProperties( toCopy:IntegraDataObject ):void
		{
			id = toCopy.id;
			parentID = toCopy.parentID;
			name = toCopy.name;
			active = toCopy.active;
		}

		
		static public function get legalObjectNameCharacterSet():String 
		{ 
			return "0123456789_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";	
		}

		
		//this method should be overridden in concrete classes.  
		//Overrides should call the base class implementation, 
		//and should do nothing else unless the base class implementation returns false
		public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			switch( attributeName )
			{
				case "active":
					Assert.assertTrue( value is int );
					_active = Boolean( value );
					return true;
					
				default:
					return false;
			} 
		}
		
		

		public function saveUserData( model:IntegraModel ):String 
		{
			if( !_userData ) 
			{
				return null;
			}

			return _userData.save( model );
		}
		
		
		public function get serverInterfaceName():String
		{
			Assert.assertTrue( false );	//should override
			return null;
		}
			
		
		protected function get internalUserData():UserData { return _userData; }
		protected function set internalUserData( userData:UserData ):void { _userData = userData; }
		
		
		private var _id:int = -1; 
		private var _parentID:int = -1;
		private var _name:String = null;
		private var _interfaceDefinition:InterfaceDefinition = null;
		
		private var _active:Boolean = false;		
		
		private var _userDataString:String = null;
		private var _userData:UserData = null;
	}
}