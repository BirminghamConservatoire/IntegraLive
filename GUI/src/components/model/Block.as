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


package components.model
{
	import __AS3__.vec.Vector;
	
	import components.model.userData.BlockUserData;
	
	import flexunit.framework.Assert;
	
	public class Block extends IntegraContainer
	{
		public function Block()
		{
			super();
			
			internalUserData = new BlockUserData;
			
			createDummyBlockEnvelope();
		}

		public static function get newBlockSeconds():Number { return _newBlockSeconds; }
		public static function get minimumBlockLength():int { return _minimumBlockLength; }
	
		public function get modules():Object { return _modules; }
		public function get envelopes():Object { return _envelopes; }
		
		public function get userData():BlockUserData { return internalUserData as BlockUserData; }
		
		public function get blockEnvelope():Envelope { return _blockEnvelope }
		public function set blockEnvelope( blockEnvelope:Envelope ):void { _blockEnvelope = blockEnvelope; }

		public function get start():int 
		{
			Assert.assertNotNull( _blockEnvelope );
			return _blockEnvelope.startTicks;
		}


		public function set start( start:int ):void
		{
			Assert.assertNotNull( _blockEnvelope );
			_blockEnvelope.startTicks = start;
		}


		public function get length():int 
		{
			Assert.assertNotNull( _blockEnvelope );

			var orderedControlPoints:Vector.<ControlPoint> = _blockEnvelope.orderedControlPoints;
			Assert.assertTrue( orderedControlPoints.length == 4 );
			
			return orderedControlPoints[ 3 ].tick;
		}
		
		
		public function set length( length:int ):void
		{
			Assert.assertNotNull( _blockEnvelope );
			Assert.assertTrue( length >= minimumBlockLength );
			
			var orderedControlPoints:Vector.<ControlPoint> = _blockEnvelope.orderedControlPoints;
			Assert.assertTrue( orderedControlPoints.length == 4 );
			
			orderedControlPoints[ 2 ].tick = length - 1;
			orderedControlPoints[ 3 ].tick = length;
		}


		public function get centre():int { return start + length / 2; }

		public function get end():int { return start + length; }
		public function set end( end:int ):void { length = end - start; }

		
		public function copyBlockProperties( toCopy:Block ):void
		{
			copyContainerProperties( toCopy );
			
			Assert.assertTrue( _blockEnvelope );
			start = toCopy.start;
			length = toCopy.length;
		}		

		
		public function getEnvelope( targetModuleID:int, targetAttribute:String ):Envelope
		{
			for each( var connection:Connection in connections )
			{
				if( connection.targetObjectID == targetModuleID && connection.targetAttributeName == targetAttribute )
				{
					if( _envelopes.hasOwnProperty( connection.sourceObjectID ) && connection.sourceAttributeName == "currentValue" )
					{
						return _envelopes[ connection.sourceObjectID ];
					}
				}
			}
	
			return null;
		}

		
		override public function childrenChanged():void 
		{
			super.childrenChanged();
			
			_modules = new Object;
			_envelopes = new Object;
			
			for each( var child:IntegraDataObject in children )
			{
				if( child is ModuleInstance )
				{
					_modules[ child.id ] = child;
				}

				if( child is Envelope )
				{
					_envelopes[ child.id ] = child;
				}
			} 
		}

		
		private function createDummyBlockEnvelope():void
		{
			Assert.assertNull( _blockEnvelope );
			_blockEnvelope = new Envelope;
			
			var controlPoint1:ControlPoint = new ControlPoint;
			controlPoint1.id = 0;
			controlPoint1.tick = 0;
			controlPoint1.value = 0;
			
			var controlPoint2:ControlPoint = new ControlPoint;
			controlPoint2.id = 1;
			controlPoint2.tick = 1;
			controlPoint2.value = 1;

			var controlPoint3:ControlPoint = new ControlPoint;
			controlPoint3.id = 2;
			controlPoint3.tick = 2;
			controlPoint3.value = 1;

			var controlPoint4:ControlPoint = new ControlPoint;
			controlPoint4.id = 3;
			controlPoint4.tick = 3;
			controlPoint4.value = 0;
			
			_blockEnvelope.controlPoints[ controlPoint1.id ] = controlPoint1;
			_blockEnvelope.controlPoints[ controlPoint2.id ] = controlPoint2;
			_blockEnvelope.controlPoints[ controlPoint3.id ] = controlPoint3;
			_blockEnvelope.controlPoints[ controlPoint4.id ] = controlPoint4;
		}

		
		private var _modules:Object = new Object;
		private var _envelopes:Object = new Object;
		
		private var _blockEnvelope:Envelope = null;
		
		private static const _newBlockSeconds:int = 20;		
		private static const _minimumBlockLength:int = 10;
	}
}