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


package components.controller.moduleManagement
{
	import flash.events.EventDispatcher;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.InstallEvent;
	import components.controller.events.LoadCompleteEvent;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Trace;
	

	public class InstallEmbeddedModules extends ServerCommand
	{
		public function InstallEmbeddedModules( embeddedModulesGuidsToInstall:Vector.<String> )
		{
			super();
			
			_embeddedModulesGuidsToInstall = embeddedModulesGuidsToInstall;  

			_loadCompleteDispatcher = new EventDispatcher;
			_modelLoader = new ModelLoader( _loadCompleteDispatcher );
			_modelLoader.serverUrl = IntegraController.singleInstance.serverUrl;
		}
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return ( _embeddedModulesGuidsToInstall.length > 0 );
		}
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			const maximumDescriptionItems:int = 3;
			
			var methodCalls:Array = new Array;
			
			var description:String = "Installing...  ";
			var count:int = 0;
			
			for each( var moduleID:String in _embeddedModulesGuidsToInstall )
			{
				if( count < maximumDescriptionItems )
				{
					var title:String = model.getInterfaceDefinitionByModuleGuid( moduleID ).interfaceInfo.label;
					if( count > 0 ) description += ", ";
					description += title;
					count++;
					if( count == maximumDescriptionItems )
					{
						description += ( " <more modules>" );
					}
				}
				
				var methodCall:Object = new Object;
				
				methodCall.methodName = "module.installembeddedmodule";
				methodCall.params = [ moduleID ];
				
				methodCalls.push( methodCall );
			}
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
			
			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.STARTED, description ) );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			var previouslyEmbeddedModuleGuids:Array = [];
			
			for( var i:int = 0; i < response.length; i++ )
			{
				var responseNode:Object = response[ i ][ 0 ];
				var moduleID:String = _embeddedModulesGuidsToInstall[ i ];
				
				switch( responseNode.response )
				{
					case "module.installembeddedmodule":
						previouslyEmbeddedModuleGuids.push( moduleID );
						break;
					
					case "error":
						Trace.error( responseNode.errortext );
						break;

					case "default":
						Trace.error( "unexpected response", responseNode.response );
						break;
				}
			}
			
			IntegraModel.singleInstance.handleModuleSourcesChanged( previouslyEmbeddedModuleGuids, InterfaceDefinition.MODULE_EMBEDDED, InterfaceDefinition.MODULE_THIRD_PARTY );

			IntegraController.singleInstance.dispatchEvent( new InstallEvent( InstallEvent.FINISHED ) );
			
			return true;
		}
		
		
		private var _embeddedModulesGuidsToInstall:Vector.<String>; 

		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;
	}
}