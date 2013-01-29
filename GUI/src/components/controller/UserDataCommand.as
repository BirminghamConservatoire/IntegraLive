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


package components.controller
{
	import __AS3__.vec.Vector;
	
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.LiveViewControl;
	import components.utils.ControlMeasurer;
	import components.utils.FontSize;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flexunit.framework.Assert;
	
	
	public class UserDataCommand extends Command
	{
		public function UserDataCommand()
		{
			super();
		}


		public function getObjectsWhoseUserDataIsAffected( model:IntegraModel, results:Vector.<int> ):void 
		{ 
			Assert.assertTrue( false );		//derived classes should override	
		}

	
		//protected helpers for use in derived command classes
		protected function findNewLiveViewControlPosition( widgetDefinition:WidgetDefinition, existingControls:Object ):Rectangle
		{
			var minimumSpacing:Number = 20;
			
			var size:Point = new Point( widgetDefinition.position.width, widgetDefinition.position.height );
			
			var newPosition:Rectangle = new Rectangle( minimumSpacing, minimumSpacing, size.x, size.y );
			
			while( doesCandidateLiveViewControlPositionIntersectOtherControls( newPosition, minimumSpacing, existingControls ) )
			{
				newPosition.x += minimumSpacing; 
			}
			
			return newPosition;			
		}

		//private helpers used by protected helpers
		private function doesCandidateLiveViewControlPositionIntersectOtherControls( candidatePosition:Rectangle, minimumSpacing:Number, existingControls:Object ):Boolean
		{
			var inflatedPosition:Rectangle = new Rectangle( candidatePosition.x - minimumSpacing, candidatePosition.y - minimumSpacing, candidatePosition.width + minimumSpacing, candidatePosition.height + minimumSpacing );
			
			for each( var otherControl:LiveViewControl in existingControls )
			{
				if( otherControl.position.intersects( inflatedPosition ) )
				{
					return true;
				}
			}	
			
			return false;		  
		}
	}
}