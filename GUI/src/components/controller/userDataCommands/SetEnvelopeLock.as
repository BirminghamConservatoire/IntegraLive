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
	import components.controller.UserDataCommand;
	import components.model.Block;
	import components.model.IntegraModel;
	
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;

	public class SetEnvelopeLock extends UserDataCommand
	{
		public function SetEnvelopeLock( blockID:int, envelopeLock:Boolean )
		{
			super();
			
			_blockID = blockID;
			_envelopeLock = envelopeLock;
		}
		
		
		public function get blockID():int { return _blockID; }
		public function get envelopeLock():Boolean { return _envelopeLock; }
		
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var block:Block = model.getBlock( _blockID );
			if( !block ) return false;
			
			return ( _envelopeLock != block.userData.envelopeLock );
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			var previousLock:Boolean = block.userData.envelopeLock;

			pushInverseCommand( new SetEnvelopeLock( _blockID, previousLock ) );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlock( _blockID );
			Assert.assertNotNull( block );
			
			block.userData.envelopeLock = _envelopeLock;
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetEnvelopeLock = previousCommand as SetEnvelopeLock;
			Assert.assertNotNull( previous );
			
			return( _blockID == previous._blockID ); 
		}		


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( _blockID );	
		}


		private var _blockID:int;
		private var _envelopeLock:Boolean
	}
}