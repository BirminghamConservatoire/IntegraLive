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

	public class SetModulePosition extends UserDataCommand
	{
		public function SetModulePosition( instanceID:int, position:Rectangle )
		{
			super();
			
			_instanceID = instanceID;
			_position = position;
		}
		
		
		public function get instanceID():int { return _instanceID; }
		public function get position():Rectangle { return _position; }
		
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var previousPosition:Rectangle = model.getModulePosition( _instanceID, false );
			if( position && previousPosition )
			{
				return !_position.equals( previousPosition );
			}
			else
			{
				return ( position || previousPosition );
			}
		}
		
		
		override public function generateInverse( model:IntegraModel ):void
		{
			var previousPosition:Rectangle = model.getModulePosition( _instanceID, false );

			pushInverseCommand( new SetModulePosition( _instanceID, previousPosition ) );
		}
		
		
		override public function execute( model:IntegraModel ):void
		{
			var block:Block = model.getBlockFromModuleInstance( _instanceID );
			Assert.assertNotNull( block );
			
			if( _position )
			{
				block.blockUserData.modulePositions[ _instanceID ] = _position;
			}
			else
			{
				delete block.blockUserData.modulePositions[ _instanceID ];
			}
		}


		public override function canReplacePreviousCommand( previousCommand:Command ):Boolean 
		{
			var previous:SetModulePosition = previousCommand as SetModulePosition;
			Assert.assertNotNull( previous );
			
			return( _instanceID == previous._instanceID ); 
		}		


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.getBlockFromModuleInstance( _instanceID ).id );	
		}

				
		private var _instanceID:int;
		private var _position:Rectangle;
	}
}