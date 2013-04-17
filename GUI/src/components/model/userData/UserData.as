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
		
		public function get primarySelectedChildID():int { return _primarySelectedChildID; }
		public function set primarySelectedChildID( primarySelectedChildID:int ):void { _primarySelectedChildID = primarySelectedChildID; }

		public function isChildSelected( childID:int ):Boolean 
		{
			return _selectedChildIDs.hasOwnProperty( childID );
		}
		
		public function setChildSelected( childID:int, selected:Boolean ):void
		{
			if( selected )
			{
				_selectedChildIDs[ childID ] = 1;
			}
			else
			{
				delete _selectedChildIDs[ childID ];
			}
		}
		
		
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
			//primary selected child			
			if( _primarySelectedChildID >= 0 ) 
			{
				 xml.appendChild( <primarySelectedChild>{getChildNameFromID( _primarySelectedChildID, model )}</primarySelectedChild> );
			}
			
			//selected children
			for( var idString:String in _selectedChildIDs )
			{
				xml.appendChild( <selectedChild>{getChildNameFromID( int( idString ), model )}</selectedChild> );
			}
		}


		protected function readFromXML( xml:XML, model:IntegraModel, myID:int ):void
		{
			//primary selected child			
			if( xml.hasOwnProperty( "primarySelectedChild" ) ) 
			{
				_primarySelectedChildID = getChildIDFromName( xml.primarySelectedChild, myID, model );
			}
			
			if( xml.hasOwnProperty( "selectedChild" ) )
			{
				for each( var selectedChildName:String in xml.selectedChild )
				{
					setChildSelected( getChildIDFromName( selectedChildName, myID, model ), true );
				}
			}
		}
		
		protected function clear():void
		{
			_selectedChildIDs = new Object;
			_primarySelectedChildID = -1;
		}
		
		
 		private function getChildNameFromID( selectedChildID:int, model:IntegraModel ):String
		{
			return model.getDataObjectByID( selectedChildID ).name;
		} 
		
		
		private function getChildIDFromName( selectedChildName:String, myID:int, model:IntegraModel ):int
		{
			var myPath:Array = model.getPathArrayFromID( myID );
			return model.getIDFromPathArray( myPath.concat( selectedChildName ) );
		} 
		
		
		private var _primarySelectedChildID:int;
		
		private var _selectedChildIDs:Object = new Object;
	}
}
