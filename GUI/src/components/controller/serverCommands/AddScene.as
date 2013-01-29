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
	import components.controller.userDataCommands.SetSceneKeybinding;
	import components.controller.userDataCommands.UpdateProjectLength;
	import components.model.IntegraModel;
	import components.model.Scene;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.userData.SceneUserData;
	
	import flexunit.framework.Assert;

	public class AddScene extends ServerCommand
	{
		public function AddScene( start:int, length:int, sceneID:int = -1, name:String = null, mode:String = null, info:String = null )
		{
			super();
			
			_sceneID = sceneID;
			_name = name;

			_start = start;
			_length = length;
			_mode = mode;
			_info = info;
		}
		
		
		public function get sceneID():int { return _sceneID; }
		public function get name():String { return _name; }
		public function get start():int { return _start; }
		public function get length():int { return _length; }
		public function get mode():String { return _mode; }
		public function get info():String { return _info; }

		

		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _sceneID < 0 )
			{
				_sceneID = model.generateNewID();
			}
			
			if( !_name )
			{
				_name = model.project.player.getNewSceneName(); 				
			}			
			
			if( !_mode )
			{
				_mode = getDefaultSceneMode( model );
			}
			
			if( !_info )
			{
				_info = getDefaultInfo( model );
			}
			
			if( _start < 0 || _length <= 0 )
			{
				return false;
			}

			return true;	
		}


		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveScene( _sceneID ) )
		}		
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scene:Scene = new Scene;
			scene.id = _sceneID;
			scene.name = _name;
			scene.start = _start;
			scene.length = _length;
			scene.mode = _mode;
			scene.info.markdown = _info;
			
			model.addDataObject( model.project.player.id, scene );
		}

		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var parentPath:Array = model.getPathArrayFromID( model.project.player.id );
			
			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.new";
			methodCalls[ 0 ].params = [ model.getCoreInterfaceGuid( Scene._serverInterfaceName ), _name, parentPath ];
			
			var scenePath:Array = parentPath.concat( _name );
			
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ scenePath.concat( "start"), _start ];
			
			methodCalls[ 2 ] = new Object;
			methodCalls[ 2 ].methodName = "command.set";
			methodCalls[ 2 ].params = [ scenePath.concat( "length" ), _length ];
			
			methodCalls[ 3 ] = new Object;
			methodCalls[ 3 ].methodName = "command.set";
			methodCalls[ 3 ].params = [ scenePath.concat( "mode" ), _mode ];

			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 4 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.new" ) return false;
			if( response[ 1 ][ 0 ].response != "command.set" ) return false;
			if( response[ 2 ][ 0 ].response != "command.set" ) return false;
			if( response[ 3 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}				

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			controller.processCommand( new SelectScene( _sceneID ) );
			
			var unusedKeybinding:String = getUnusedKeybinding( model );
			if( unusedKeybinding )
			{
				controller.processCommand( new SetSceneKeybinding( _sceneID, unusedKeybinding ) );
			}
			
			controller.processCommand( new UpdateProjectLength() );
		}
		
		
		private function getUnusedKeybinding( model:IntegraModel ):String
		{
			var existingKeybindingMap:Object = new Object;
			for each( var scene:Scene in model.project.player.scenes )
			{
				var existingKeybinding:String = scene.keybinding;
				if( existingKeybinding )
				{
					existingKeybindingMap[ existingKeybinding ] = 1; 
				}
			}
			
			for( var i:int = 0; i < SceneUserData.KEYBINDINGS.length; i++ )
			{
				var candidateKeybinding:String = SceneUserData.KEYBINDINGS.substr( i, 1 );

				if( !existingKeybindingMap.hasOwnProperty( candidateKeybinding ) )
				{
					return candidateKeybinding;
				}
			} 

			return null;
		}
		
		
		private function getDefaultSceneMode( model:IntegraModel ):String
		{
			var endpointDefinition:EndpointDefinition = model.getCoreInterfaceDefinitionByName( Scene._serverInterfaceName ).getEndpointDefinition( "mode" );
			Assert.assertNotNull( endpointDefinition );
			
			return endpointDefinition.controlInfo.stateInfo.defaultValue as String;
		}

		
		private function getDefaultInfo( model:IntegraModel ):String
		{
			var endpointDefinition:EndpointDefinition = model.getCoreInterfaceDefinitionByName( Scene._serverInterfaceName ).getEndpointDefinition( "info" );
			Assert.assertNotNull( endpointDefinition );
			
			return endpointDefinition.controlInfo.stateInfo.defaultValue as String;
		}
		
		
		private var _sceneID:int;
		private var _name:String;
		private var _start:int;
		private var _length:int;
		private var _mode:String;
		private var _info:String;
	}
}