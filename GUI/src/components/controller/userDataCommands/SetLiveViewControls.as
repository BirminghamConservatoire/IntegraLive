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
	import __AS3__.vec.Vector;
	
	import components.controller.UserDataCommand;
	import components.model.Block;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;
	

	public class SetLiveViewControls extends UserDataCommand
	{
		public function SetLiveViewControls( blockID:int, liveViewControls:Object )
		{
			super();
			
			_blockID = blockID;
			_liveViewControls = liveViewControls;
		}
		
		
		public function get blockID():int { return _blockID; }
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			pushInverseCommand( new SetLiveViewControls( _blockID, block.blockUserData.liveViewControls ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );

			block.blockUserData.liveViewControls = _liveViewControls;
		}
		
		
		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _blockID );	
		}
		
		
		private var _blockID:int;
		private var _liveViewControls:Object;
	}
}