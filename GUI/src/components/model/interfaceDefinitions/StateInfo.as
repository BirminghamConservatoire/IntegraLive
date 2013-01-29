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


package components.model.interfaceDefinitions
{
	import flexunit.framework.Assert;
	

	public class StateInfo
	{
		public function StateInfo()
		{
		}

		public function get type():String 						{ return _type; }
		public function get constraint():Constraint 			{ return _constraint; }
		public function get defaultValue():Object 				{ return _defaultValue; }
		public function get scale():ControlScale 				{ return _scale; } 
		public function get stateLabels():Vector.<StateLabel> 	{ return _stateLabels; }
		public function get isInputFile():Boolean				{ return _isInputFile; }
		public function get isSavedToFile():Boolean				{ return _isSavedToFile; }

		public function set valueType( valueType:String ):void
		{
			switch( valueType )
			{
				case FLOAT:
				case INTEGER:
				case STRING:
					_type = valueType;
					break;
				
				default:
					Assert.assertTrue( false );		//unhandled value type
					break;					
			}
		}
			

		public function set defaultValue( defaultValue:Object ):void				
		{ 
			switch( type )
			{
				case FLOAT:
					Assert.assertTrue( defaultValue is Number );
					break;
				
				case INTEGER:
					Assert.assertTrue( defaultValue is int );
					break;
				
				case STRING:
					Assert.assertTrue( defaultValue is String );
					break;
				
				default:
					Assert.assertTrue( false );		//unhandled value type
					break;					
			}			
			
			_defaultValue = defaultValue; 
		}
		
		
		public function set isInputFile( isInputFile:Boolean ):void
		{ 
			_isInputFile = isInputFile;
		}

		
		public function set isSavedToFile( isSavedToFile:Boolean ):void
		{ 
			_isSavedToFile = isSavedToFile;
		}
		
		
		private var _type:String;
		private var _constraint:Constraint = new Constraint;
		private var _defaultValue:Object;
		private var _scale:ControlScale = new ControlScale; 
		private var _stateLabels:Vector.<StateLabel> = new Vector.<StateLabel>;
		private var _isInputFile:Boolean;
		private var _isSavedToFile:Boolean;

		
		public static const FLOAT:String = "float";
		public static const INTEGER:String = "integer";
		public static const STRING:String = "string";
	}
}
