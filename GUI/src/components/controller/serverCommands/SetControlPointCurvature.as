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
	
	import components.controller.ServerCommand;
	import components.model.Block;
	import components.model.Connection;
	import components.model.ControlPoint;
	import components.model.Envelope;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	
	import flexunit.framework.Assert;

	public class SetControlPointCurvature extends ServerCommand
	{
		public function SetControlPointCurvature( controlPointID:int, curvature:Number )
		{
			super();
			
		 	_controlPointID = controlPointID;
			_curvature = curvature;
		}

		
		public function get controlPointID():int { return _controlPointID; }
		public function get curvature():Number { return _curvature; }

		
		public override function initialize( model:IntegraModel ):Boolean
		{
			var controlPoint:ControlPoint = model.getControlPoint( _controlPointID );
			if( !controlPoint ) return false;
			
			return true;
		} 

		
		public override function generateInverse( model:IntegraModel ):void
		{
			var controlPoint:ControlPoint = model.getControlPoint( _controlPointID );
			Assert.assertNotNull( controlPoint );

			pushInverseCommand( new SetControlPointCurvature( _controlPointID, controlPoint.curvature ) );
		}


		public override function execute( model:IntegraModel ):void
		{
			var controlPoint:ControlPoint = model.getControlPoint( _controlPointID );
			Assert.assertNotNull( controlPoint );
			
			controlPoint.curvature = _curvature;
		}			


		public override function executeServerCommand( model:IntegraModel ):void
		{
			var controlPointPath:Array = model.getPathArrayFromID( _controlPointID );

			connection.addArrayParam( controlPointPath.concat( "curvature" ) );
			connection.addParam( _curvature, XMLRPCDataTypes.DOUBLE );
			
			connection.callQueued( "command.set" );
		}


		protected override function testServerResponse( response:Object ):Boolean
		{
			return( response.response == "command.set" );
		}	
		

		private var _controlPointID:int;
		private var _curvature:Number; 
	}
}