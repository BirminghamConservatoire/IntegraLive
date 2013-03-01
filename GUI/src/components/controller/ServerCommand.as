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


package components.controller
{
	import components.controller.serverCommands.AddConnection;
	import components.controller.serverCommands.RemoveScaledConnection;
	import components.controller.serverCommands.RemoveConnection;
	import components.controller.serverCommands.RemoveMidi;
	import components.controller.serverCommands.RemoveScript;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.model.Connection;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.Midi;
	import components.model.Project;
	import components.model.Scaler;
	import components.model.Script;
	import components.utils.IntegraConnection;
	import components.utils.Trace;
	import components.utils.Utilities;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flexunit.framework.Assert;
	
	import mx.controls.Alert;

	
	public class ServerCommand extends Command
	{
		public function ServerCommand()
		{
			super();
		}
		
		
		public function createConnection( serverUrl:String ):void
		{
			_connection = new IntegraConnection( serverUrl );
			_connection.addEventListener( Event.COMPLETE, onServerCommandComplete );
			_connection.addEventListener( ErrorEvent.ERROR, onServerCommandError );
		}
		
		
		protected function get connection():IntegraConnection { return _connection; }		
		
		
		/* 
		Implement executeServerCommand to send the xmlrpc command to libIntegra
		*/
		public function executeServerCommand( model:IntegraModel ):void {} 
		
		
		/* 
		Implement getAttributesChangedByThisCommand for all commands which use command.set, and populate
		changedAttributes with each changed attribute's path (dot-separated)
		*/
		public function getAttributesChangedByThisCommand( model:IntegraModel, changedAttributes:Vector.<String> ):void {}

		
		/* 
		Implement omitFromTrace for any commands which should not be written to the gui logfile
		*/
		public function omitFromTrace():Boolean { return false; }

		
		/* 
		Implement testServerResponse to check whether the libIntegra command has executed as expected.
		Return false if the command does not appear to have executed sucessfully 
		*/
		protected function testServerResponse( response:Object ):Boolean { return true; }

		
		/* 
		Helpers to remove related objects when objects are removed.  
		Implemented here to avoid code duplication.
		Should be called from preChain() methods of Remove... commands
		*/
		protected function removeConnectionsReferringTo( objectID:int, model:IntegraModel, controller:IntegraController ):void
		{
			var connectionsToRemove:Vector.<int> = new Vector.<int>;
			var connectionsToClearSource:Vector.<int> = new Vector.<int>;
			var connectionsToClearTarget:Vector.<int> = new Vector.<int>;

			for( var container:IntegraContainer = model.getParent( objectID ) as IntegraContainer; container; container = model.getParent( container.id ) as IntegraContainer ) 
			{
				for each( var connection:Connection in container.connections )
				{
					if( connection.sourceObjectID == objectID )
					{
						if( model.doesObjectExist( connection.targetObjectID ) && model.getDataObjectByID( connection.targetObjectID ) is Scaler )
						{
							connectionsToClearSource.push( connection.id );
						}
						else
						{
							connectionsToRemove.push( connection.id );
						}
					}  
					
					if( connection.targetObjectID == objectID )
					{
						if( model.doesObjectExist( connection.sourceObjectID ) && model.getDataObjectByID( connection.sourceObjectID ) is Scaler )
						{
							connectionsToClearTarget.push( connection.id );
						}
						else
						{
							connectionsToRemove.push( connection.id );
						}
					}  
				}
			}
			
			for each( var connectionID:int in connectionsToRemove )
			{
				controller.processCommand( new RemoveConnection( connectionID ) ); 
			}	

			for each( connectionID in connectionsToClearSource )
			{
				connection = model.getConnection( connectionID );
				controller.processCommand( new SetConnectionRouting( connectionID, -1, null, connection.targetObjectID, connection.targetAttributeName ) ); 
			}	

			for each( connectionID in connectionsToClearTarget )
			{
				connection = model.getConnection( connectionID );
				controller.processCommand( new SetConnectionRouting( connectionID, connection.sourceObjectID, connection.sourceAttributeName, -1, null ) ); 
			}	
		}

		
		protected function removeChildScalers( objectID:int, model:IntegraModel, controller:IntegraController ):void
		{
			var container:IntegraContainer = model.getContainer( objectID ); 
			Assert.assertNotNull( container );
			
			var scalersToRemove:Vector.<int> = new Vector.<int>;
			
			for each( var scaler:Scaler in container.scalers )
			{
				scalersToRemove.push( scaler.id );
			}
			
			for each( var scalerID:int in scalersToRemove )
			{
				controller.processCommand( new RemoveScaledConnection( scalerID ) ); 
			}	
		}
		
		
		protected function removeChildConnections( objectID:int, model:IntegraModel, controller:IntegraController ):void
		{
			var container:IntegraContainer = model.getContainer( objectID ); 
			Assert.assertNotNull( container );
			
			var connectionsToRemove:Vector.<int> = new Vector.<int>;
			
			for each( var connection:Connection in container.connections )
			{
				connectionsToRemove.push( connection.id );
			}
			
			for each( var connectionID:int in connectionsToRemove )
			{
				controller.processCommand( new RemoveConnection( connectionID ) ); 
			}	
		}		
		

		protected function removeChildScripts( objectID:int, model:IntegraModel, controller:IntegraController ):void
		{
			var container:IntegraContainer = model.getContainer( objectID ); 
			Assert.assertNotNull( container );

			var scriptsToRemove:Vector.<int> = new Vector.<int>;
			
			for each( var script:Script in container.scripts )
			{
				scriptsToRemove.push( script.id );
			}
			
			for each( var scriptID:int in scriptsToRemove )
			{
				controller.processCommand( new RemoveScript( scriptID ) ); 
			}	
		}
		
		
		protected function removeMidi( objectID:int, model:IntegraModel, controller:IntegraController ):void
		{
			var container:IntegraContainer = model.getContainer( objectID ); 
			Assert.assertNotNull( container );
			
			if( container.midi )
			{
				controller.processCommand( new RemoveMidi( container.midi.id ) );
			}
		}

		
		protected function updateProjectMidiConnection( model:IntegraModel, controller:IntegraController, midiAttributePrefix:String, targetID:int, targetAttributeName:String, newValue:int ):void
		{
			var connection:components.model.Connection;
			var project:Project = model.project;
			
			for each( connection in project.connections )
			{
				if( connection.sourceObjectID != project.midi.id || connection.sourceAttributeName.substr( 0, midiAttributePrefix.length ) != midiAttributePrefix )
				{
					continue;
				}
				
				if( connection.targetObjectID != targetID || connection.targetAttributeName != targetAttributeName )
				{
					continue;
				}
				
				//found connection - update
				
				if( newValue >= 0 )
				{
					var midiAttributeName:String = midiAttributePrefix + String( newValue );
					if( connection.sourceAttributeName != midiAttributeName )
					{
						controller.processCommand( new SetConnectionRouting( connection.id, project.midi.id, midiAttributeName, targetID, targetAttributeName ) );
					}
				}
				else
				{
					controller.processCommand( new RemoveConnection( connection.id ) );
				}
				
				return;
			}
			
			//no connection exists - create if needed
			
			if( newValue >= 0 )
			{
				var addConnectionCommand:AddConnection = new AddConnection( model.project.id );
				controller.processCommand( addConnectionCommand );
				
				controller.processCommand( new SetConnectionRouting( addConnectionCommand.connectionID, project.midi.id, midiAttributePrefix + String( newValue ), targetID, targetAttributeName ) );
			}
		}
		
		
		//private methods		
		private function onServerCommandComplete( event:Event ):void 
		{
			var connection:IntegraConnection = event.target as IntegraConnection;
			Assert.assertNotNull( connection );
			
			var responseObject:Object = connection.getResponse();
			Assert.assertNotNull( responseObject );
			
			if( !testServerResponse( responseObject ) )
			{
				Assert.assertTrue( false );
				
				//todo - handle the error!
			}	
		}
		
		
		private function onServerCommandError( event:ErrorEvent ):void
		{
			Alert.show( "xmlrpc error!\n", "Integra Live", mx.controls.Alert.OK );

			//todo - handle the error!
			
			//clearModel(); ???
			//dispatchEvent( new AllDataChangedEvent ); ???
		}
		
		
		private var _connection:IntegraConnection = null;
	}
}