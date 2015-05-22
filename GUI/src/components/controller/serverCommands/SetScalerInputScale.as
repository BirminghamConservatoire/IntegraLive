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
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.Scaler;
	import components.model.interfaceDefinitions.ControlScale;
	
	import flexunit.framework.Assert;
	

	public class SetScalerInputScale extends ServerCommand
	{
		public function SetScalerInputScale( scalerID:int, scale:String )
		{
			super();

			_scalerID = scalerID;
			_scale = scale;
		}
		
		
		public function get scalerID():int { return _scalerID; }
		public function get scale():String { return _scale; }

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			if( !model.getScaler( _scalerID ) ) return false;
			
			switch( _scale )
			{
				case ControlScale.LINEAR:
				case ControlScale.EXPONENTIAL:
				case ControlScale.DECIBEL:
					break;
				
				default:
					return false;
			}
			
			return true;
		}
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			pushInverseCommand( new SetScalerInputScale( _scalerID, scaler.inScale ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			scaler.inScale = _scale;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var scalerPath:Array = model.getPathArrayFromID( _scalerID );
			
			connection.addArrayParam( scalerPath.concat( "inScale" ) );
			connection.addParam( _scale, XMLRPCDataTypes.STRING );	
			
			connection.callQueued( "command.set" );		
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}
		
		
		private var _scalerID:int;
		private var _scale:String;
	}
}