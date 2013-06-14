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
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.InterfaceDefinition;

	public class SwitchAllObjectVersions extends ServerCommand
	{
		public function SwitchAllObjectVersions( fromGuid:String, toGuid:String )
		{
			super();
	
			_fromGuid = fromGuid;
			_toGuid = toGuid;		
		}
		
		public function get fromGuid():String { return _fromGuid; }
		public function get toGuid():String { return _toGuid; }
		
		override public function initialize( model:IntegraModel ):Boolean
		{
			var fromInterfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _fromGuid );
			var toInterfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( _toGuid );

			if( !fromInterfaceDefinition || !toInterfaceDefinition )
			{
				return false;
			}
			
			if( fromInterfaceDefinition.originGuid != toInterfaceDefinition.originGuid )
			{
				return false;
			}
			
			if( fromInterfaceDefinition.moduleGuid == toInterfaceDefinition.moduleGuid )
			{
				return false;
			}
			
			return true;				
		}
		
		
		override public function preChain( model:IntegraModel, controller:IntegraController ):void
		{
			switchBranch( model.project, controller );
		}
		
		
		private function switchBranch( object:IntegraDataObject, controller:IntegraController ):void
		{
			if( object.interfaceDefinition.moduleGuid == _fromGuid )
			{
				if( object is ModuleInstance )
				{
					controller.processCommand( new SwitchModuleVersion( object.id, _toGuid ) );
				}
				else
				{
					controller.processCommand( new SwitchObjectVersion( object.id, _toGuid ) );
				}
			}
			
			if( object is IntegraContainer )
			{
				for each( var child:IntegraDataObject in ( object as IntegraContainer ).children )
				{
					switchBranch( child, controller );
				}
			}
		}
	
		
		private var _fromGuid:String;
		private var _toGuid:String;		
	}
}