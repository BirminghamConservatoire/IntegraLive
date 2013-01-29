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


package components.utils
{
	import components.controller.userDataCommands.SetTimeDomainSnaplines;
	import components.model.userData.TimelineState;
	
	import mx.containers.Canvas;
	
	public class TimeDomainSnapLines extends Canvas
	{
		public function TimeDomainSnapLines()
		{
			super();
			
			percentWidth = 100;
			percentHeight = 100;
		}
		
		
		public function update( command:SetTimeDomainSnaplines, timelineState:TimelineState ):void
		{
			graphics.clear();
			
			graphics.lineStyle( _thickness, _color, _alpha );
			
			for each( var ticks:int in command.snapTicks )
			{
				var snapX:Number = timelineState.ticksToPixels( ticks );
				
				if( snapX < -_thickness || snapX >= width + _thickness )
				{
					continue;
				}
				
				graphics.moveTo( snapX, 0 );
				graphics.lineTo( snapX, height );
			}
		}
		
		private const _thickness:Number = 4;
		private const _color:uint= 0x808080;
		private const _alpha:Number = 0.3;
	}
}