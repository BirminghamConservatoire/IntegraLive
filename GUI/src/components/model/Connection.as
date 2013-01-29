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
	import components.utils.Trace;
	
	import flexunit.framework.Assert;
	
	public class Connection extends IntegraDataObject
	{
		public function Connection()
		{
			super();
			
			internalUserData = new UserData;
		}

		public function get sourceObjectID():int	{ return _sourceObjectID; }
		public function get sourceAttributeName():String { return _sourceAttributeName; }
		public function get targetObjectID():int { return _targetObjectID; }
		public function get targetAttributeName():String { return _targetAttributeName; }

		public function get userData():UserData { return internalUserData; }

		public function set sourceObjectID( sourceObjectID:int ):void { _sourceObjectID = sourceObjectID; }
		public function set sourceAttributeName( sourceAttributeName:String ):void { _sourceAttributeName = sourceAttributeName; }
		public function set targetObjectID( targetObjectID:int ):void { _targetObjectID = targetObjectID; }
		public function set targetAttributeName( targetAttributeName:String ):void { _targetAttributeName = targetAttributeName; }
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			var objectID:int = -1;
			var connectedAttributeName:String = null;

			var valueString:String = String( value );
			if( valueString.length > 0 && valueString != "." )
			{
				var pathArray:Array = valueString.split( "." );
				Assert.assertTrue( pathArray.length >= 2 );
				
				var relativeObjectPath:Array = pathArray.slice( 0, pathArray.length - 1 );
				Assert.assertTrue( relativeObjectPath.length >= 1 );
	
				var container:IntegraContainer = model.getContainerFromConnection( id );
				Assert.assertNotNull( container );
	
				var containerPath:Array = model.getPathArrayFromID( container.id );
				
				objectID = model.getIDFromPathArray( containerPath.concat( relativeObjectPath ) );
				if( objectID < 0 )
				{
					Trace.error( "Connection attribute", attributeName, valueString, "can't be resolved" );
					return true;
				}
	
				connectedAttributeName = pathArray[ pathArray.length - 1 ];
				if( connectedAttributeName.length == 0 )
				{
					connectedAttributeName = null;
				}
			}
			
			switch( attributeName )
			{
				case "sourcePath":
					sourceObjectID = objectID;
					sourceAttributeName = connectedAttributeName;
					return true;

				case "targetPath":
					targetObjectID = objectID;
					targetAttributeName = connectedAttributeName;
					return true;
				
				default:
					Assert.assertTrue( false );
					return false;
			}
		}

		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Connection";
	
		private var _sourceObjectID:int = -1;
		private var _sourceAttributeName:String;
		private var _targetObjectID:int = -1;
		private var _targetAttributeName:String;
	}
}
