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
	import __AS3__.vec.Vector;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.AllDataChangedEvent;
	import components.model.Connection;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.Track;
	
	import flexunit.framework.Assert;
	

	public class RemoveTrackImport extends ServerCommand
	{
		public function RemoveTrackImport( trackID:int )
		{
			_trackID = trackID;
		}
		
		
		public function get trackID():int { return _trackID; }
		
		override public function execute( model:IntegraModel ):void
		{
			//remove connections						
			for each( var connectionID:int in _playerConnectionIDs )
			{
				model.removeDataObject( connectionID );
			}
			
			//remove child objects						
			for each( var childID:int in _childIDs )
			{
				model.removeDataObject( childID );
			}
			
			//remove track						
			model.removeDataObject( _trackID );
		}
		
		
		override public function executeServerCommand( model:IntegraModel ):void 
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );

			//collect ids of all track's child objects						
			_childIDs.length = 0;						
			for each( var child:IntegraDataObject in track.children )
			{
				getIDs( child );
			}

			//put them in a map, to quickly find the player connections which target them
			var childIDMap:Object = new Object;
			for each( var childID:int in _childIDs )
			{
				childIDMap[ childID ] = 1;
			}
			
			//collect ids of all project level connections which target the track's child objects
			_playerConnectionIDs.length = 0;
			for each( var playerConnection:Connection in model.project.connections )
			{
				if( childIDMap.hasOwnProperty( playerConnection.targetObjectID ) )
				{
					_playerConnectionIDs.push( playerConnection.id );
				}
			} 

			//construct the call to delete the connections and the track 
			var methodCalls:Array = new Array;
			
			for each( var connectionID:int in _playerConnectionIDs )
			{
				var removeConnectionCall:Object = new Object;
				removeConnectionCall.methodName = "command.delete";
				removeConnectionCall.params = [ model.getPathArrayFromID( connectionID ) ];
				methodCalls.push( removeConnectionCall );
			}

			var removeTrackCall:Object = new Object;
			removeTrackCall.methodName = "command.delete";
			removeTrackCall.params = [ model.getPathArrayFromID( _trackID ) ];
			methodCalls.push( removeTrackCall );
		
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			IntegraController.singleInstance.dispatchEvent( new AllDataChangedEvent() );

			if( response.length != _playerConnectionIDs.length + 1 ) return false;
			
			for( var i:int = 0; i < response.length; i++ )  		
			{
				if( response[ i ][ 0 ].response != "command.delete" ) return false;
			}			
			
			return true;
		}
		
		
		private function getIDs( object:IntegraDataObject ):void
		{
			if( object is IntegraContainer )
			{
				for each( var child:IntegraDataObject in ( object as IntegraContainer ).children )
				{
					getIDs( child );
				}
			}
			
			if( object is Envelope )
			{
				for each( var controlPoint:ControlPoint in ( object as Envelope ).controlPoints )
				{
					_childIDs.push( controlPoint.id );
				}
			}
			
			_childIDs.push( object.id );
		}
		

		private var _trackID:int;
		
		private var _childIDs:Vector.<int> = new Vector.<int>;
		private var _playerConnectionIDs:Vector.<int> = new Vector.<int>;
	}
}