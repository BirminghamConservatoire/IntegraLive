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
	import components.controller.userDataCommands.SetModuleInstanceLiveViewControls;
	import components.controller.userDataCommands.SetModulePosition;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Block;
	import components.model.Connection;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	
	import flexunit.framework.Assert;

	public class UnloadModule extends ServerCommand
	{
		public function UnloadModule( moduleID:int )
		{
			super();
			
			_moduleID = moduleID;
		}
		
		
		public function get moduleID():int { return _moduleID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{		
			return( model.getModuleInstance( _moduleID ) != null );
		}


		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new SetModuleInstanceLiveViewControls( _moduleID, false ) );
			controller.processCommand( new SetModulePosition( _moduleID, null ) );

			removeEnvelopes( model, controller );
			removeConnectionsReferringTo( _moduleID, model, controller );
			
			deselectModule( model, controller );
		} 
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			Assert.assertNotNull( module );
			
			pushInstanceAttributeInverses( module );
			
			pushInverseCommand( new LoadModule( module.interfaceDefinition.moduleGuid, model.getBlockFromModuleInstance( _moduleID ).id, model.getModulePosition( _moduleID ), _moduleID, module.name ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _moduleID );
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _moduleID ) );
			connection.callQueued( "command.delete" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.delete" );
		}		
		

		private function pushInstanceAttributeInverses( module:ModuleInstance ):void
		{
			var attributes:Object = module.attributes;
			
			for each( var endpoint:EndpointDefinition in module.interfaceDefinition.endpoints )
			{
				if( !endpoint.isStateful )
				{
					continue;
				}
				
				var endpointName:String = endpoint.name;
				var endpointType:String = endpoint.controlInfo.stateInfo.type;

				if( endpointName == "userData" )
				{
					continue;
				}

				pushInverseCommand( new SetModuleAttribute( module.id, endpointName, attributes[ endpointName ], endpointType ) );
			}
		}


		private function removeEnvelopes( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlockFromModuleInstance( _moduleID );
			Assert.assertNotNull( block );

			var envelopesToRemove:Vector.<int> = new Vector.<int>;
			
			for each( var connection:Connection in block.connections )
			{
				if( connection.targetObjectID == _moduleID )
				{
					if( block.envelopes.hasOwnProperty( connection.sourceObjectID ) )
					{
						envelopesToRemove.push( connection.sourceObjectID );
					} 
				}
			}
			
			for each( var envelopeID:int in envelopesToRemove )
			{
				controller.processCommand( new RemoveEnvelope( envelopeID ) );
			}
		}


		private function deselectModule( model:IntegraModel, controller:IntegraController ):void
		{
			var block:Block = model.getBlockFromModuleInstance( _moduleID );
			Assert.assertNotNull( block );
			
			if( block.primarySelectedChildID == _moduleID )
			{
				controller.processCommand( new SetPrimarySelectedChild( block.id, -1 ) );
			}
		}
	
		
		private var _moduleID:int; 
	}
}