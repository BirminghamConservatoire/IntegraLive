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


package components.model.userData
{
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	
	public class UserData
	{
		public function UserData()
		{
			clear();
		}
		
		public function get isSelected():Boolean { return _isSelected; }
		public function get primarySelectedChildID():int { return _primarySelectedChildID; }

		public function set isSelected( isSelected:Boolean ):void { _isSelected = isSelected; }
		public function set primarySelectedChildID( primarySelectedChildID:int ):void { _primarySelectedChildID = primarySelectedChildID; }
		
		public function save( model:IntegraModel ):String
		{
			XML.ignoreWhitespace = true;
			var xml:XML = new XML( "<userdata></userdata>" );
			
			writeToXML( xml, model );

			var xmlString:String = xml.toString();
			
			//put it all on one line for increased readability when embedded into ixd
			xmlString = xmlString.split( "\r" ).join( "" );
			xmlString = xmlString.split( "\n" ).join( "" );
			
			return xmlString;
		}


		public function load( xmlAsString:String, model:IntegraModel, myID:int ):void
		{
			clear();
			
			XML.ignoreWhitespace = true;
			var xml:XML = new XML( xmlAsString );

			readFromXML( xml, model, myID );			
		}


		protected function writeToXML( xml:XML, model:IntegraModel ):void
		{
			//is selected?
			if( _isSelected )
			{
				 xml.appendChild( <isSelected>{_isSelected}</isSelected> );
			}

			//primary selected child			
			if( _primarySelectedChildID >= 0 ) 
			{
				 xml.appendChild( <primarySelectedChild>{getSelectedChildNameFromID( _primarySelectedChildID, model )}</primarySelectedChild> );
			}
		}


		protected function readFromXML( xml:XML, model:IntegraModel, myID:int ):void
		{
			//is selected? 
			if( xml.hasOwnProperty( "isSelected" ) )
			{
				_isSelected = xml.isSelected;
			}

			//primary selected child			
			if( xml.hasOwnProperty( "primarySelectedChild" ) ) 
			{
				_primarySelectedChildID = getSelectedChildIDFromName( xml.primarySelectedChild, myID, model );
			}
		}
		
		protected function clear():void
		{
			_isSelected = false;
			_primarySelectedChildID = -1;
		}
		
		
		//this method can be overridden to allow customised selection of objects which are not IntegraDataObjects 
		protected function getSelectedChildNameFromID( selectedChildID:int, model:IntegraModel ):String
		{
			return model.getDataObjectByID( selectedChildID ).name;
		} 
		
		
		//this method can be overridden to allow customised selection of objects which are not IntegraDataObjects 
		protected function getSelectedChildIDFromName( selectedChildName:String, myID:int, model:IntegraModel ):int
		{
			var myPath:Array = model.getPathArrayFromID( myID );
			return model.getIDFromPathArray( myPath.concat( selectedChildName ) );
		} 
		
		
		private var _isSelected:Boolean;
		private var _primarySelectedChildID:int;
	}
}
