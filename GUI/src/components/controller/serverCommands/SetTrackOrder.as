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
	import flexunit.framework.Assert;
	
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.Track;
	import components.utils.Utilities;

	public class SetTrackOrder extends ServerCommand
	{
		public function SetTrackOrder( newOrder:Vector.<int> )
		{
			super();
			
			_newOrder = newOrder;
		}
		
		
		public function get newOrder():Vector.<int> { return _newOrder; }
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( _newOrder.length != Utilities.getNumberOfProperties( model.project.tracks ) )
			{
				Assert.assertTrue( false ); 	//wrong number of track ids
				return false;
			}
			
			var trackIDs:Object = new Object;
			
			for each( var trackID:int in _newOrder )
			{
				if( !model.getTrack( trackID ) )
				{
					Assert.assertTrue( false ); //track not found for id
					return false;
				}	
				
				if( trackIDs.hasOwnProperty( trackID ) )
				{
					Assert.assertTrue( false ); //duplicate id
					return false;
				}
			}
			
			return true;			
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var existingOrder:Vector.<int> = new Vector.<int>;
			
			for each( var track:Track in model.project.orderedTracks )
			{
				existingOrder.push( track.id );
			}
			
			pushInverseCommand( new SetTrackOrder( existingOrder ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			for( var i:int = 0; i < _newOrder.length; i++ )
			{
				model.getTrack( _newOrder[ i ] ).zIndex = i;
			} 
		}


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;

			for( var i:int = 0; i < _newOrder.length; i++ )
			{
				var trackPath:Array = model.getPathArrayFromID( _newOrder[ i ] );
				 
				methodCalls[ i ] = new Object;
				methodCalls[ i ].methodName = "command.set";
				methodCalls[ i ].params = [ trackPath.concat( "zIndex" ), i ]; 
			}			
			
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		protected override function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			if( !responseArray || responseArray.length != _newOrder.length )
			{
				return false;
			}
			
			for each( var responseEntry:Object in responseArray )
			{
				if( responseEntry[ 0 ].response != "command.set" )
				{
					return false;
				} 
			}
			
			return true;
		}		

		
		private var _newOrder:Vector.<int>;;		
	}
}