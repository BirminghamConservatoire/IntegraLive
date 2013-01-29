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
	
	public class Midi extends IntegraDataObject
	{
		public function Midi()
		{
			super();
		}

	
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			if( attributeName.substr( 0, ccAttributePrefix.length ) == ccAttributePrefix )
			{
				var ccNumber:int = int( attributeName.substr( ccAttributePrefix.length ) );
				if( ccNumber >= 0 && ccNumber < numberOfCCNumbers )
				{
					_ccState[ ccNumber ] = int( value );
					return true;
				}
			}
			
			
			return false;
		}
		
		
		private var _ccState:Vector.<int> = new Vector.<int>( numberOfCCNumbers, true );
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "MIDI";
		
		public static const defaultMidiName:String = "MIDI1";
		
		public static const noteAttributePrefix:String = "note";
		public static const ccAttributePrefix:String = "cc";
		
		public static const numberOfCCNumbers:int = 128;		
		public static const numberOfMidiNotes:int = 128;		
	}
}
