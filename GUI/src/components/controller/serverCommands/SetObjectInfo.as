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
	
	import components.controller.Command;
	import components.controller.ServerCommand;
	import components.model.Info;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;

	public class SetObjectInfo extends ServerCommand
	{
		public function SetObjectInfo( objectID:int, info:String )
		{
			super();
			
			_objectID = objectID;
			_info = info;
		}
		
		
		public function get objectID():int { return _objectID; }
		public function get info():String { return _info; }

		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !model.doesObjectExist( _objectID ) ) return false;
			
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			if( !object ) return false;
			
			return object.hasOwnProperty( "info" ) && object[ "info" ] is Info;
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );
			
			var info:Info = object[ "info" ];
			
			pushInverseCommand( new SetObjectInfo( _objectID, info.markdown ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var object:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( object );
			
			var info:Info = object[ "info" ];

			info.markdown = _info;
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _objectID ).concat( "info" ) ); 
			connection.addParam( _info, XMLRPCDataTypes.STRING );
			connection.callQueued( "command.set" );				
		}
		
		
		public override function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void
		{
			changedAttributes.push( model.getPathStringFromID( _objectID ) + ".info" );
		}		
		
		
		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetObjectInfo = previousCommand as SetObjectInfo;
			Assert.assertNotNull( previous );
			
			return ( _objectID == previous._objectID ); 
		}

		
		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}
		
		
		private var _objectID:int;
		private var _info:String;
	}
}