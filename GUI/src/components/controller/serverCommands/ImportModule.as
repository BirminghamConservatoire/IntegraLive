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
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.events.ImportEvent;
	import components.controller.events.LoadCompleteEvent;
	import components.controller.events.LoadFailedEvent;
	import components.controller.userDataCommands.SetModulePosition;
	import components.controller.userDataCommands.SetObjectSelection;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.modelLoader.ModelLoader;
	import components.utils.Utilities;
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;
	

	public class ImportModule extends ServerCommand
	{
		public function ImportModule( filename:String, blockID:int, importPoint:Point )
		{
			super();

			_filename = filename;
			_blockID = blockID;
			_importPoint = importPoint;
		}
		
		
		public function get filename():String { return _filename; }
		public function get blockID():int { return _blockID; }
		public function get importPoint():Point { return _importPoint; }
		

		public override function initialize( model:IntegraModel ):Boolean
		{
			var block:Block = model.getBlock( _blockID );
			if( !block ) 
			{
				return false;
			}
			
			_moduleID = model.generateNewID();

			_loadCompleteDispatcher = new EventDispatcher;
			_modelLoader = new ModelLoader( _loadCompleteDispatcher );
			_modelLoader.serverUrl = IntegraController.singleInstance.serverUrl;
			
			_loadCompleteDispatcher.addEventListener( LoadCompleteEvent.EVENT_NAME, onLoaded );

			return true;
		}
	
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new UnloadModule( _moduleID ) );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//deselect all modules
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			for each( var module:ModuleInstance in block.modules )
			{
				if( model.isObjectSelected( module.id ) )
				{
					controller.processCommand( new SetObjectSelection( module.id, false ) );	
				}
			}
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addParam( _filename, XMLRPCDataTypes.STRING );
			connection.addArrayParam( model.getPathArrayFromID( _blockID ) );	
			connection.callQueued( "command.load" );

			IntegraController.singleInstance.dispatchEvent( new ImportEvent( ImportEvent.STARTED ) );
		}


		override protected function testServerResponse( response:Object ):Boolean
		{
			var model:IntegraModel = IntegraModel.singleInstance;
			var controller:IntegraController = IntegraController.singleInstance;

			if( response.response == "command.load" )
			{
				var blockPath:Array = model.getPathArrayFromID( _blockID );
				var newEmbeddedModuleGuids:Array = response.embeddedmodules;
				
				_modelLoader.loadBranchOfNodeTree( blockPath, ModelLoader.IMPORTING_MODULE, _moduleID, newEmbeddedModuleGuids ); 
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
			
			controller.appendNextCommandsIntoPreviousTransaction();
			
			var module:ModuleInstance = model.getModuleInstance( _moduleID );
			Assert.assertNotNull( module );
			var position:Rectangle = new Rectangle( _importPoint.x, _importPoint.y, ModuleInstance.getModuleWidth(), ModuleInstance.getModuleHeight( module.interfaceDefinition ) );
			
			controller.processCommand( new SetModulePosition( _moduleID, position ) );			
			
			controller.processCommand( new SetPrimarySelectedChild( _blockID, _moduleID ) );
			controller.processCommand( new SetObjectSelection( _moduleID, true ) );
			
			controller.dispatchEvent( new ImportEvent( ImportEvent.FINISHED ) );
		}
		
		
		private var _filename:String;
		private var _blockID:int;
		private var _importPoint:Point;
		
		private var _moduleID:int;
		
		private var _modelLoader:ModelLoader = null;
		private var _loadCompleteDispatcher:EventDispatcher = null;
	}
}