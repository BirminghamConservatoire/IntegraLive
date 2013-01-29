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


package components.controller.userDataCommands
{
	import components.controller.Command;
	import components.controller.IntegraController;
	import components.controller.UserDataCommand;
	import components.model.IntegraModel;
	import components.model.Scene;
	import components.model.userData.SceneUserData;
	
	import flexunit.framework.Assert;

	public class SetSceneKeybinding extends UserDataCommand
	{
		public function SetSceneKeybinding( sceneID:int, keybinding:String )
		{
			super();
			
			_sceneID = sceneID;
			_keybinding = keybinding;
		}
		
		
		public function get sceneID():int { return _sceneID; }
		public function get keybinding():String { return _keybinding; }
		
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var previousBinding:String = model.getScene( _sceneID ).keybinding;
			return( _keybinding != previousBinding );
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var previousBinding:String = model.getScene( _sceneID ).keybinding;

			pushInverseCommand( new SetSceneKeybinding( _sceneID, previousBinding ) );
		}
		
		
		public override function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			//remove duplicate keybindings

			for each( var scene:Scene in model.project.player.scenes )
			{
				if( scene.id == _sceneID )
				{
					continue;
				}
				
				if( _keybinding.length > 0 && scene.keybinding == _keybinding )
				{
					controller.processCommand( new SetSceneKeybinding( scene.id, SceneUserData.NO_KEYBINDING ) ); 
				}
			}
		}	
		
		
		override public function execute( model:IntegraModel ):void
		{
			var scene:Scene = model.getScene( _sceneID );
			Assert.assertNotNull( scene );
			
			scene.userData.keybinding = _keybinding;
		}


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _sceneID );	
		}

				
		private var _sceneID:int;
		private var _keybinding:String;
	}
}