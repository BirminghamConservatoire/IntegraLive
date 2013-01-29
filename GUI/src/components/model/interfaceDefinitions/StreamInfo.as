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
	
	public class StreamInfo
	{
		public function StreamInfo()
		{
		}

		public function get streamType():String { return _streamType; }
		public function get streamDirection():String { return _streamDirection; }

		public function set streamType( streamType:String ):void
		{
			Assert.assertTrue( streamType == TYPE_AUDIO );
			_streamType = streamType;
		}
		
		public function set streamDirection( streamDirection:String ):void
		{
			switch( streamDirection )
			{
				case DIRECTION_INPUT:
				case DIRECTION_OUTPUT:
					_streamDirection = streamDirection;
					break;
			
				default:
					Assert.assertTrue( false );		//unhandled stream direction
					break;
			}		
		}
		
		private var _streamType:String;
		private var _streamDirection:String;
		
		public static const TYPE_AUDIO:String = "audio";

		public static const DIRECTION_INPUT:String = "input";
		public static const DIRECTION_OUTPUT:String = "output";
	}
}
