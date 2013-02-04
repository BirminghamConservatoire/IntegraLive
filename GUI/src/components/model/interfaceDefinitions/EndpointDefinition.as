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
	
	import flexunit.framework.Assert;
	
	
	public class EndpointDefinition
	{
		public function EndpointDefinition()
		{
		}
		
		public function get name():String				{ return _name; }
		public function get label():String				{ return _label; }
		public function get description():String		{ return _description; }
		public function get type():String				{ return _type; }
		public function get controlInfo():ControlInfo	{ return _controlInfo; }
		public function get streamInfo():StreamInfo		{ return _streamInfo; }

		public function get isStateful():Boolean
		{
			return ( type == CONTROL && controlInfo.type == ControlInfo.STATE );
		}
		
		
		public function get canBeConnectionSource():Boolean
		{
			if( type != CONTROL ) return false;
			if( controlInfo.type == ControlInfo.STATE && controlInfo.stateInfo.type == StateInfo.STRING ) return false;
			
			return controlInfo.canBeSource;
		}


		public function get canBeConnectionTarget():Boolean
		{
			if( type != CONTROL ) return false;
			if( controlInfo.type == ControlInfo.STATE && controlInfo.stateInfo.type == StateInfo.STRING ) return false;
			
			return controlInfo.canBeTarget;
		}
		
		
		public function set name( name:String ):void				{ _name = name; }
		public function set label( label:String	):void				{ _label = label; } 
		public function set description( description:String	):void	{ _description = description; }
		
		
		public function set controlInfo( controlInfo:ControlInfo ):void		
		{ 
			_type = CONTROL;
			_controlInfo = controlInfo; 
			_streamInfo = null;
		}
		
		
		public function set streamInfo( streamInfo:StreamInfo ):void			
		{ 
			_type = STREAM;
			_controlInfo = null;
			_streamInfo = streamInfo; 
		}
		
		
		private var _name:String;
		private var _label:String;
		private var _description:String;
		private var _type:String;
		private var _controlInfo:ControlInfo = null;
		private var _streamInfo:StreamInfo = null;
		
		public static const CONTROL:String = "control";
		public static const STREAM:String = "stream";
	}
}
