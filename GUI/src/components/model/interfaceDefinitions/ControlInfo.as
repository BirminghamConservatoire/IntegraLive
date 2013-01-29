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
	import flexunit.framework.Assert;
	
	public class ControlInfo
	{
		public function ControlInfo()
		{
		}

		public function get type():String						{ return _type; }
		public function get stateInfo():StateInfo				{ return _stateInfo; }
		public function get canBeSource():Boolean				{ return _canBeSource; }
		public function get canBeTarget():Boolean				{ return _canBeTarget; }
		public function get isSentToHost():Boolean				{ return _isSentToHost; }
		
		public function set type( type:String ):void
		{ 
			switch( type )
			{
				case STATE:
					_type = type;
					break;
				
				case BANG:
					_type = type;
					_stateInfo = null;
					break;
				
				default:
					Assert.assertTrue( false );		//unhandled control type
			}
		}
		
		public function set stateInfo( stateInfo:StateInfo ):void				
		{ 
			Assert.assertTrue( type == STATE );
			_stateInfo = stateInfo;
		}
			
			
		public function set canBeSource( canBeSource:Boolean ):void		
		{ 
			_canBeSource = canBeSource; 
		}
		
		
		public function set canBeTarget( canBeTarget:Boolean ):void		
		{ 
			_canBeTarget = canBeTarget; 
		}

		
		public function set isSentToHost( isSentToHost:Boolean ):void
		{ 
			_isSentToHost = isSentToHost; 
		}

		
	
		private var _type:String;
		private var _stateInfo:StateInfo = null;
		private var _canBeSource:Boolean;
		private var _canBeTarget:Boolean;
		private var _isSentToHost:Boolean;
		
		public static const STATE:String = "state";
		public static const BANG:String = "bang";
	}
}
