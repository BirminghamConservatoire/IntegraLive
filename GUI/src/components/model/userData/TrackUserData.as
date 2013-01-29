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


package components.model.userData
{
	import components.model.IntegraModel;
	
	
	public class TrackUserData extends UserData
	{
		public function TrackUserData()
		{
			super();
		}

		public function get color():uint { return _color; }
		public function get arrangeViewHeight():uint { return _arrangeViewHeight; }
		public function get arrangeViewExpanded():Boolean { return _arrangeViewExpanded; }
		public function get liveViewExpanded():Boolean { return _liveViewExpanded; }
		public function get arrangeViewCollapsed():Boolean { return !arrangeViewExpanded; }
		public function get liveViewCollapsed():Boolean { return !liveViewExpanded; }

		public function set color( color:uint ):void { _color = color; }
		public function set arrangeViewHeight( arrangeViewHeight:uint ):void { _arrangeViewHeight = arrangeViewHeight; }
		public function set arrangeViewExpanded( arrangeViewExpanded:Boolean ):void { _arrangeViewExpanded = arrangeViewExpanded; }
		public function set liveViewExpanded( liveViewExpanded:Boolean ):void { _liveViewExpanded = liveViewExpanded; }

		protected override function writeToXML( xml:XML, model:IntegraModel ):void
		{
			super.writeToXML( xml, model );
			
			xml.appendChild( <color>{ _color }</color> );
			xml.appendChild( <arrangeViewHeight>{ _arrangeViewHeight }</arrangeViewHeight> );
			xml.appendChild( <arrangeViewExpanded>{ _arrangeViewExpanded }</arrangeViewExpanded> );
			xml.appendChild( <liveViewExpanded>{ _liveViewExpanded }</liveViewExpanded> );
		}


		protected override function readFromXML( xml:XML, model:IntegraModel, myID:int ):void
		{
			super.readFromXML( xml, model, myID );
			
			if( xml.hasOwnProperty( "color" ) )
			{
				_color = xml.color;
			}

			if( xml.hasOwnProperty( "arrangeViewHeight" ) )
			{
				_arrangeViewHeight = xml.arrangeViewHeight;
			}

			if( xml.hasOwnProperty( "arrangeViewExpanded" ) )
			{
				_arrangeViewExpanded = ( xml.arrangeViewExpanded.toString() == "true" );
			}

			if( xml.hasOwnProperty( "liveViewExpanded" ) )
			{
				_liveViewExpanded = ( xml.liveViewExpanded.toString() == "true" );
			}
		}


		protected override function clear():void
		{
			super.clear();
			
			_color = 0;
			_arrangeViewHeight = 100;
			_arrangeViewExpanded = true;
			_liveViewExpanded = true;
		}

		private var _color:uint;
		private var _arrangeViewHeight:uint;
		private var _arrangeViewExpanded:Boolean;
		private var _liveViewExpanded:Boolean;
	}
}
