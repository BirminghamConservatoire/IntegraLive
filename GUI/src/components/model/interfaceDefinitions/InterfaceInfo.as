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


package components.model.interfaceDefinitions
{
	import components.model.Info;

	public class InterfaceInfo
	{
		public function InterfaceInfo()
		{
		}

		public function get name():String 							{ return _name; }
		public function get label():String 							{ return _label; }
		public function get description():String 					{ return _description; }
		public function get tags():Vector.<String> 					{ return _tags; }
		public function get implementedInLibintegra():Boolean 		{ return _implementedInLibintegra; }
		public function get implementationList():Vector.<String> 	{ return _implementationList; }
		public function get author():String							{ return _author; }
		public function get createdDate():Date						{ return _createdDate; }
		public function get modifiedDate():Date 					{ return _modifiedDate; }
		public function get info():Info								{ return _info; }
		
		public function set name( name:String ):void 				{ _name = name; }
		public function set label( label:String ):void 				
		{ 	
			_label = label;
			_info.title = label; 
		}
		
		public function set description( description:String ):void 	
		{ 
			_description = description; 
			_info.markdown = description; 
		}
		
		public function set tags( tags:Vector.<String> ):void 		{ _tags = tags; }
		public function set implementedInLibintegra( implementedInLibintegra:Boolean ):void { _implementedInLibintegra = implementedInLibintegra; }
		public function set implementationList( implementationList:Vector.<String> ):void { _implementationList = implementationList; }
		public function set author( author:String ):void 			{ _author = author; }
		public function set createdDate( createdDate:Date ):void 	{ _createdDate = createdDate; }
		public function set modifiedDate( modifiedDate:Date ):void 	{ _modifiedDate = modifiedDate; }

		
		private var _name:String;
		private var _label:String;
		private var _description:String;
		private var _tags:Vector.<String> = new Vector.<String>;
		private var _implementedInLibintegra:Boolean;
		private var _implementationList:Vector.<String> = new Vector.<String>;
		private var _author:String;
		private var _createdDate:Date;
		private var _modifiedDate:Date;
		
		private var _info:Info = new Info;
	}
}
