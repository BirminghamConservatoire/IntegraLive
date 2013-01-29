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
	import components.controller.ServerCommand;
	import components.model.Scaler;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	
	import flexunit.framework.Assert;
	

	public class SetScalerOutputRange extends ServerCommand
	{
		public function SetScalerOutputRange( scalerID:int, minimum:Number, maximum:Number )
		{
			super();
			
			_scalerID = scalerID;
			_minimum = minimum;
			_maximum = maximum;
		}
		
		public function get scalerID():int { return _scalerID; }
		public function get minimum():int { return _minimum; }
		public function get maximum():int { return _maximum; }

		
		public override function generateInverse( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			pushInverseCommand( new SetScalerOutputRange( _scalerID, scaler.outRangeMin, scaler.outRangeMax ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			scaler.outRangeMin = _minimum;
			scaler.outRangeMax = _maximum;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var methodCalls:Array = new Array;
			
			var scalerPath:Array = model.getPathArrayFromID( _scalerID );

			methodCalls[ 0 ] = new Object;
			methodCalls[ 0 ].methodName = "command.set";
			methodCalls[ 0 ].params = [ scalerPath.concat( "outRangeMin" ), _minimum ]; 
	
			methodCalls[ 1 ] = new Object;
			methodCalls[ 1 ].methodName = "command.set";
			methodCalls[ 1 ].params = [ scalerPath.concat( "outRangeMax" ), _maximum ]; 
	
			connection.addArrayParam( methodCalls );
			connection.callQueued( "system.multicall" );						
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			var responseArray:Array = response as Array;
			Assert.assertNotNull( responseArray );

			if( responseArray.length != 2 ) return false;

			if( responseArray[ 0 ][ 0 ].response != "command.set" ) return false;
			if( responseArray[ 1 ][ 0 ].response != "command.set" ) return false;
			
			return true;
		}
		
		
		private var _scalerID:int;
		private var _minimum:Number;
		private var _maximum:Number; 
	}
}