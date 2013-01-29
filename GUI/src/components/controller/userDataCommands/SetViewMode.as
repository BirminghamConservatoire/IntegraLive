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
	import components.controller.IntegraController;
	import components.controller.UserDataCommand;
	import components.controller.serverCommands.SetPlayPosition;
	import components.model.Block;
	import components.model.IntegraModel;
	import components.model.userData.ViewMode;
	
	
	public class SetViewMode extends UserDataCommand
	{
		public function SetViewMode( viewMode:ViewMode )
		{
			super();
			
			_viewMode = viewMode;
		}
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			return ( model.project.userData.viewMode != _viewMode );	
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new SetViewMode( model.project.userData.viewMode ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.project.userData.viewMode = _viewMode;
		}
		
		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			if( _viewMode.mode == ViewMode.ARRANGE && _viewMode.blockPropertiesOpen )
			{
				var playPosition:int = model.project.player.playPosition;
				var block:Block = model.primarySelectedBlock;
				if( block && ( playPosition < block.start || playPosition > block.end ) )
				{
					controller.processCommand( new SetPlayPosition( block.start ) );					
				}
			}
		}


		public override function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void
		{
			results.push( model.project.id );	
		}		


		private var _viewMode:ViewMode;
	}
}