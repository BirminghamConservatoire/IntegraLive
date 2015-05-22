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
	
	import flexunit.framework.Assert;
	

	public class SetScalerInputMode extends ServerCommand
	{
		public function SetScalerInputMode( scalerID:int, mode:String )
		{
			super();

			switch( mode )
			{
				case Scaler.INPUT_MODE_SNAP:
				case Scaler.INPUT_MODE_IGNORE:
					break;
				
				default:
					Assert.assertTrue( false );
			}

			_scalerID = scalerID;
			_mode = mode;
		}
		
		
		public function get scalerID():int { return _scalerID; }
		public function get mode():String { return _mode; }

		
		public override function generateInverse( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			pushInverseCommand( new SetScalerInputMode( _scalerID, scaler.inMode ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			var scaler:Scaler = model.getScaler( _scalerID );
			Assert.assertNotNull( scaler );
			
			scaler.inMode = _mode;
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			var scalerPath:Array = model.getPathArrayFromID( _scalerID );
			
			connection.addArrayParam( scalerPath.concat( "inMode" ) );
			connection.addParam( _mode, XMLRPCDataTypes.STRING );	
			
			connection.callQueued( "command.set" );		
		}
		
		
		override protected function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}
		
		
		private var _scalerID:int;
		private var _mode:String;
	}
}