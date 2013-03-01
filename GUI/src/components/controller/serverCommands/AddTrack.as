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
	import __AS3__.vec.Vector;
	
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.controller.userDataCommands.SetTrackColor;
	import components.model.IntegraContainer;
	import components.model.IntegraModel;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;

	public class AddTrack extends ServerCommand
	{
		public function AddTrack( trackID:int = -1, trackName:String = null, color:int = -1, zIndex:int = -1 )
		{
			super();
			
			_trackID = trackID;
			_trackName = trackName;
			_color = color;
			_zIndex = zIndex; 
		}
		
		
		public function get trackID():int { return _trackID; }
		public function get trackName():String { return _trackName; }
		public function get color():int { return _color; }
		public function get zIndex():int { return _zIndex; }
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _trackID < 0 )
			{
				_trackID = model.generateNewID();
			}

			if( !_trackName )
			{
				var definition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( IntegraContainer._serverInterfaceName );
				_trackName = model.project.getNewChildName( "Track", definition.moduleGuid );
			}

			if( _color < 0 )
			{
				_color = getNewTrackColor( model );
			}
			
			if( _zIndex < 0 )
			{
				_zIndex = 0;
				for each( var track:Track in model.project.tracks )
				{
					_zIndex = Math.max( _zIndex, track.zIndex + 1 ); 
				}
			}
			else
			{
				for each( track in model.project.tracks )
				{
					if( track.zIndex == _zIndex ) 
					{
						return false;	//this zIndex already in use!
					}
				}
			}
			
			return true;
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			pushInverseCommand( new RemoveTrack( _trackID ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var track:Track = new Track;
			track.id = _trackID;
			track.name = _trackName;
			track.zIndex = _zIndex;

			model.addDataObject( model.project.id, track ); 			
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;

			var projectPath:Array = model.getPathArrayFromID( model.project.id );

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.new";
			methodCalls[ 0 ].params = [ model.getCoreInterfaceGuid( IntegraContainer._serverInterfaceName ), _trackName, projectPath ];

			var trackPath:Array = projectPath.concat( _trackName );

			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ trackPath.concat( "zIndex" ), _zIndex ];
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			if( response.length != 2 ) 
			{	
				return false;	
			}
			
			if( response[ 0 ][ 0 ].response != "command.new" ) return false;
			if( response[ 1 ][ 0 ].response != "command.set" ) return false;
						
			return true;
		}		

		
		public override function postChain( model:IntegraModel, controller:IntegraController ):void
		{
			//track midi
			controller.processCommand( new AddMidi( _trackID ) );
			
			//track color
			controller.processCommand( new SetTrackColor( _trackID, _color ) );	
			
			//info (use view-specific value, because we want different default for project/track/block)
			controller.processCommand( new SetObjectInfo( _trackID, InfoMarkupForViews.instance.getInfoForView( "ArrangeViewTrack" ).markdown ) );
			
			//track selection
			controller.processCommand( new SetPrimarySelectedChild( model.project.id, _trackID ) );
		}


		private function getNewTrackColor( model:IntegraModel ):uint
		{
			const defaultColors:Array = [ 0x16a2f1, 0xe95d0e, 0xf116d4, 0xf0f116, 0xf11616, 0x41f116 ];
			
			return defaultColors[ Utilities.getNumberOfProperties( model.project.tracks ) % defaultColors.length ]; 
		}



		private var _trackID:int;
		private var _trackName:String;
		private var _color:int;
		private var _zIndex:int;		
	}
}