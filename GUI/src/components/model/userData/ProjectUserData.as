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
	
	import mx.collections.XMLListCollection;

	
	public class ProjectUserData extends UserData
	{
		public function ProjectUserData()
		{
			super();
		}

		public function get viewMode():ViewMode { return _viewMode; }
		public function get timelineState():TimelineState { return _timelineState; }
		public function get colorScheme():String { return _colorScheme; }
		public function get highContrast():Boolean { return _highContrast; }

		public function set viewMode( mode:ViewMode ):void { _viewMode = mode; }
		public function set timelineState( timelineState:TimelineState ):void { _timelineState = timelineState; } 
		public function set colorScheme( colorScheme:String ):void { _colorScheme = colorScheme; }
		public function set highContrast( highContrast:Boolean ):void { _highContrast = highContrast; }


		protected override function writeToXML( xml:XML, model:IntegraModel ):void
		{
			super.writeToXML( xml, model );
			
			//view mode
			xml.appendChild( <viewMode>{_viewMode.mode}</viewMode> );
			xml.appendChild( <blockPropertiesOpen>{_viewMode.blockPropertiesOpen}</blockPropertiesOpen> );
			xml.appendChild( <preferencesOpen>{_viewMode.preferencesOpen}</preferencesOpen> );

			//timeline state
			xml.appendChild( <timelineScroll>{_timelineState.scroll}</timelineScroll> );
			xml.appendChild( <timelineZoom>{_timelineState.zoom}</timelineZoom> );

			//color scheme
			xml.appendChild( <colorScheme>{_colorScheme}</colorScheme> );
			
			//high contrast
			if( _highContrast )
			{
				xml.appendChild( <highContrast>true</highContrast> );
			}
		}


		protected override function readFromXML( xml:XML, model:IntegraModel, myID:int ):void
		{
			//view mode
			if( xml.hasOwnProperty( "viewMode" ) )
			{
				_viewMode.mode = xml.viewMode;
			}

			if( xml.hasOwnProperty( "blockPropertiesOpen" ) )
			{
				_viewMode.blockPropertiesOpen = ( xml.blockPropertiesOpen == "true" );
			}

			if( xml.hasOwnProperty( "preferencesOpen" ) )
			{
				_viewMode.preferencesOpen = ( xml.preferencesOpen == "true" );
			}

			//timeline state
			if( xml.hasOwnProperty( "timelineScroll" ) )
			{
				_timelineState.scroll = xml.timelineScroll;
			}

			if( xml.hasOwnProperty( "timelineZoom" ) )
			{
				_timelineState.zoom = xml.timelineZoom;
			}

			//color scheme
			if( xml.hasOwnProperty( "colorScheme" ) )
			{
				_colorScheme = xml.colorScheme;
			}

			//high contrast 
			if( xml.hasOwnProperty( "highContrast" ) )
			{
				_highContrast = ( xml.highContrast.toString() == "true" );
			}
			else
			{
				_highContrast = false;
			}
			
			super.readFromXML( xml, model, myID );
		}


		protected override function clear():void
		{
			super.clear();
			
			_viewMode.clear();
			_timelineState.clear();
			_colorScheme = ColorScheme.LIGHT;
			_highContrast = false;
		}


		private var _viewMode:ViewMode = new ViewMode;
		private var _timelineState:TimelineState = new TimelineState;
		private var _colorScheme:String = ColorScheme.LIGHT;
		private var _highContrast:Boolean = false;
	}
}
