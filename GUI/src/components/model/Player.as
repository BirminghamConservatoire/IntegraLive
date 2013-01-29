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


package components.model
{
	import flexunit.framework.Assert;
	
	public class Player extends IntegraDataObject
	{
		public function Player()
		{
			super();
		}

		public function get playing():Boolean { return _playing; }
		public function get playPosition():int { return _playPosition; }
		public function get rate():int { return _rate; }
		public function get selectedSceneID():int { return _selectedSceneID; }
		public function get scenes():Object { return _scenes; }
		
		public function set playing( playing:Boolean ):void { _playing = playing; }
		public function set playPosition( playPosition:int ):void { _playPosition = playPosition; }
		public function set rate( rate:int ):void { _rate = rate; }
		public function set selectedSceneID( selectedSceneID:int ):void { _selectedSceneID = selectedSceneID; }
		public function set scenes( scenes:Object ):void { _scenes = scenes; }

		
		public function get orderedScenes():Vector.<Scene>
		{
			var orderedScenes:Vector.<Scene> = new Vector.<Scene>;
			for each( var scene:Scene in _scenes )
			{
				orderedScenes.push( scene );
			}
			
			function compareSceneOrder( scene1:Scene, scene2:Scene ):int
			{
				if( scene1.start < scene2.start ) return -1;
				if( scene1.start > scene2.start ) return 1;
				
				Assert.assertTrue( false );	//scenes shouldn't have identical starts!
				return 0;
			}
			
			orderedScenes.sort( compareSceneOrder );
			
			return orderedScenes;			
		}
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{         
				case "play":
					_playing = ( int( value ) != 0 );
					return true;
					
				case "tick":
					_playPosition = int( value );
					return true;				
				
				case "rate":
					_rate = int( value );
					return true;
					
				case "start":		//temporary while these fields are still in database - to be removed!
				case "end":			//temporary while these fields are still in database - to be removed!
				case "loop":		//temporary while these fields are still in database - to be removed!
					return true;	//temporary while these fields are still in database - to be removed!				

				case "scene":
					if( String( value ).length > 0 )
					{
						_selectedSceneID = model.getIDFromPathArray( model.getPathArrayFromID( id ).concat( String( value ) ) );
					}
					else
					{
						_selectedSceneID = -1;
					}
					
					return true;

				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		
		public function getNewSceneName():String
		{
			var existingNameMap:Object = new Object;
			var numberOfExistingScenes:int = 0;
			
			for each( var scene:Scene in scenes )
			{
				existingNameMap[ scene.name ] = 1;
				numberOfExistingScenes++;
			} 
			
			for( var number:int = numberOfExistingScenes + 1; ; number++ )
			{
				var candidateName:String = "Scene" + String( number );
				if( !existingNameMap.hasOwnProperty( candidateName ) )
				{
					return candidateName;
				}
			}
			
			Assert.assertTrue( false );
			return null;  
		}				
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Player";
	
		public static const defaultPlayerName:String = "Player1";
		
		
		private var _playing:Boolean = false;
		private var _playPosition:int = 0;
		private var _rate:int = 40;				//default rate
		private var _selectedSceneID:int = -1;
		
		private var _scenes:Object = new Object;
	}
}
