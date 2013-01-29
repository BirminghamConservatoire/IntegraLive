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


package components.utils
{
	public class Snapper
	{
		public function Snapper( defaultValue:Number, snapMargin:Number )
		{
			super();
			
			_unSnappedValue = defaultValue;
			_snapMargin = snapMargin;
		}

		
		public function get value():Number 				{ return snapped ? _snappedValue : _unSnappedValue;	}
		public function get snapped():Boolean 			{ return _snapped; }
		public function get snappedDistance():Number 	{ return _snappedDistance; }
		
		
		public function doSnap( snapValue:Number ):void
		{
			var distance:Number = Math.abs( snapValue - _unSnappedValue );  
			if( distance <= _snapMargin )
			{
				if( !_snapped || distance < _snappedDistance )
				{
					_snapped = true;
					_snappedValue = snapValue;
					_snappedDistance = distance;
				}
			}
		}
		
		
		private var _unSnappedValue:Number = -1;
		private var _snapMargin:Number = -1;
		
		private var _snappedValue:Number = -1;
		private var _snapped:Boolean = false;
		private var _snappedDistance:Number = -1;
		
		
	}
}