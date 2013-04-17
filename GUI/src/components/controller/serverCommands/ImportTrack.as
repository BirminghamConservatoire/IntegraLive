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
	
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.LoadCompleteEvent;
	import components.controller.events.ImportEvent;
	import components.controller.events.LoadFailedEvent;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Block;
	import components.model.Envelope;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.Track;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Utilities;
	
	import flash.events.EventDispatcher;
	
	import flexunit.framework.Assert;
	

	public class ImportTrack extends ServerCommand
	{
		public function ImportTrack( filename:String )
		{
			super();

			_filename = filename;
		}
		
		
		public function get filename():String { return _filename; }
		

		public override function initialize( model:IntegraModel ):Boolean
		{
			_trackID = model.generateNewID();

			_loadCompleteDispatcher = new EventDispatcher;
			_modelLoader = new ModelLoader( _loadCompleteDispatcher );
			_modelLoader.serverUrl = IntegraController.singleInstance.serverUrl;
			
			_loadCompleteDispatcher.addEventListener( LoadCompleteEvent.EVENT_NAME, onLoaded );

			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveTrackImport( _trackID ) );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//deselect all blocks
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					if( model.isObjectSelected( block.id ) )
					{
						controller.processCommand( new SetObjectSelection( block.id, false ) );	
					}
				}
			}
		}

		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addParam( _filename, XMLRPCDataTypes.STRING );
			connection.addArrayParam( model.getPathArrayFromID( model.project.id ) );	
			connection.callQueued( "command.load" );

			IntegraController.singleInstance.dispatchEvent( new ImportEvent( ImportEvent.STARTED ) );
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var model:IntegraModel = IntegraModel.singleInstance;
			var controller:IntegraController = IntegraController.singleInstance;

			if( response.response == "command.load" )
			{
				var projectPath:Array = model.getPathArrayFromID( model.project.id );
				var newEmbeddedModuleGuids:Array = response.embeddedmodules;
				
				_modelLoader.loadBranchOfNodeTree( projectPath, ModelLoader.IMPORTING_TRACK, _trackID, newEmbeddedModuleGuids ); 
			}
			else
			{
				controller.dispatchEvent( new LoadFailedEvent( "Cannot import \"" + Utilities.fileNameFromPath( _filename ) + "\":\n\n" + response.errortext ) );
				controller.dispatchEvent( new ImportEvent( ImportEvent.FINISHED ) );
			}
			
			return true;
		}
		
		
		private function onLoaded( event:LoadCompleteEvent ):void
		{
			var model:IntegraModel = IntegraModel.singleInstance;
			var controller:IntegraController = IntegraController.singleInstance;
			
			controller.activateUndoStack = false;
			{
				connectPlayerToEnvelopes( model.getTrack( _trackID ), model, controller );
	
				controller.dispatchEvent( new ImportEvent( ImportEvent.FINISHED ) );
	
				normalizeTrackOrder( model, controller );
			}
			controller.activateUndoStack = true;
			
			controller.appendNextCommandsIntoPreviousTransaction();

			selectTrack( model, controller );
		}
		
		
		private function normalizeTrackOrder( model:IntegraModel, controller:IntegraController ):void
		{
			var trackOrder:Vector.<int> = new Vector.<int>;
			
			for each( var track:Track in model.project.orderedTracks )
			{
				if( track.id != _trackID ) 
				{
					trackOrder.push( track.id );
				}
			} 			
			
			trackOrder.push( _trackID );
			
			controller.processCommand( new SetTrackOrder( trackOrder ) );
		}
		
		
		private function connectPlayerToEnvelopes( container:IntegraContainer, model:IntegraModel, controller:IntegraController ):void 
		{
			var track:Track = model.getTrack( _trackID );
			Assert.assertNotNull( track );
			
			for each( var blockEnvelope:Envelope in track.blockEnvelopes )
			{
				var addConnectionCommand:AddConnection = new AddConnection( model.project.id );
				controller.processCommand( addConnectionCommand );
				controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, model.project.player.id, "tick", blockEnvelope.id, "currentTick" ) );
			}

			for each( var block:Block in track.blocks )
			{
				for each( var envelope:Envelope in block.envelopes )
				{
					addConnectionCommand = new AddConnection( model.project.id );
					controller.processCommand( addConnectionCommand );
					controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, model.project.player.id, "tick", envelope.id, "currentTick" ) );
				}
			}			
		}

		
		private function selectTrack( model:IntegraModel, controller:IntegraController ):void
		{
			//select track
			controller.processCommand( new SetPrimarySelectedChild( model.project.id, _trackID ) );
		}
		

		private var _filename:String;
		private var _trackID:int;
		
		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;
	}
}