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
	import components.model.userData.TrackUserData;
	

	public class Track extends IntegraContainer
	{
		public function Track()
		{
			super();
			
			internalUserData = new TrackUserData; 
		}

		public function get blocks():Object { return _blocks; }
		public function get blockEnvelopes():Object { return _blockEnvelopes; }

		public function get userData():TrackUserData { return internalUserData as TrackUserData; }

		override public function childrenChanged():void 
		{
			super.childrenChanged();
			
			_blocks = new Object;
			_blockEnvelopes = new Object;
			
			for each( var child:IntegraDataObject in children )
			{
				if( child is Block )
				{
					_blocks[ child.id ] = child;
				}
				
				if( child is Envelope )
				{
					_blockEnvelopes[ child.id ] = child;
				}
			} 
		}

		private var _blocks:Object = new Object;
		private var _blockEnvelopes:Object = new Object;
 	}
}