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
	import components.controller.IntegraController;
	import components.controller.ServerCommand;
	import components.model.IntegraModel;
	import components.model.Envelope;
	import components.model.ControlPoint;
	
	import flexunit.framework.Assert;


	public class RemoveControlPoint extends ServerCommand
	{
		public function RemoveControlPoint( controlPointID:int )
		{
			super();
			
			_controlPointID = controlPointID;
		}
		
		
		public function get controlPointID():int { return _controlPointID; }
		public function get envelopeID():int { return _envelopeID; }
		
		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var envelope:Envelope = model.getEnvelopeFromControlPoint( _controlPointID );
			Assert.assertNotNull( envelope );
			_envelopeID = envelope.id;
			
			return( model.getControlPoint( _controlPointID ) != null );
		}
		
		
		public override function generateInverse( model:IntegraModel ):void
		{
			var controlPoint:ControlPoint = model.getControlPoint( _controlPointID );
			Assert.assertNotNull( controlPoint );
			
			pushInverseCommand( new AddControlPoint( _envelopeID, controlPoint.tick, controlPoint.value, _controlPointID, controlPoint.name ) );
		}
		
		
		public override function execute( model:IntegraModel ):void
		{
			model.removeDataObject( _controlPointID );
		}
		
		
		public override function executeServerCommand( model:IntegraModel ):void
		{
			connection.addArrayParam( model.getPathArrayFromID( _controlPointID ) );
			connection.callQueued( "command.delete" );				
		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.delete" );
		}		

		
		private var _envelopeID:int;
		private var _controlPointID:int;
	}
}