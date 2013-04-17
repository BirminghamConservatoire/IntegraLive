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
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.model.IntegraModel;
	import components.model.Track;
	import components.model.Block;
	import components.model.Script;
	
	import flexunit.framework.Assert;

	import __AS3__.vec.Vector;


	public class RemoveTrack extends ServerCommand
	{
		public function RemoveTrack( trackID:int )
		{
			super();
			
			_trackID = trackID;
		}
		
		
		public function get trackID():int { return _trackID; } 


		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			removeConnectionsReferringTo( _trackID, model, controller );
			removeChildScalers( _trackID, model, controller );

			//removeChildConnections is only needed to fix old files in which non-scaled connections are present
			removeChildConnections( _trackID, model, controller );
			
			removeChildScripts( _trackID, model, controller );
			removeMidi( _trackID, model, controller );
			removeBlocksFromTrack( model, controller );
			deselectTrack( model, controller );

			//track color
			controller.processCommand( new SetTrackColor( _trackID, 0 ) );	
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );
			
			pushInverseCommand( new AddTrack( _trackID, track.name, track.trackUserData.color, track.zIndex ) ); 
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _trackID );
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _trackID ) );
			connection.callQueued( "command.delete" );				
		}


		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseString:String = response.response;
			
			return ( responseString == "command.delete" );
		}	
		

		private function removeBlocksFromTrack( model:IntegraModel, controller:IntegraController ):void
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );

			var blockIDs:Vector.<int> = new Vector.<int>;
			for each( var block:Block in track.blocks )
			{
				blockIDs.push( block.id );
			}

			for each( var blockID:int in blockIDs )
			{
				controller.processCommand( new RemoveBlock( blockID ) );
			}
		}
		
		
		private function deselectTrack( model:IntegraModel, controller:IntegraController ):void
		{
			if( model.getPrimarySelectedChildID( model.project.id ) == _trackID )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.project.id, -1 ) );
			}
		}	


		private var _trackID:int;		
	}
}