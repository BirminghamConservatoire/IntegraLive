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


package components.model.userData
{
	import flash.geom.Rectangle;
	
	import mx.collections.XMLListCollection;
	
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Trace;
	
	import flexunit.framework.Assert;
	
	
	public class BlockUserData extends UserData
	{
		public function BlockUserData()
		{
			super();
		}

		public function get modulePositions():Object { return _modulePositions; }
		public function get liveViewControls():Object { return _liveViewControls; }
		
		public function get envelopeLock():Boolean { return _envelopeLock; } 
		public function get curvatureMode():Boolean { return _curvatureMode; } 

		public function set modulePositions( modulePositions:Object ):void { _modulePositions = modulePositions; }
		public function set liveViewControls( liveViewControls:Object ):void { _liveViewControls = liveViewControls; }
		public function set envelopeLock( envelopeLock:Boolean ):void { _envelopeLock = envelopeLock; }
		public function set curvatureMode( curvatureMode:Boolean ):void { _curvatureMode = curvatureMode; }


		public function getUnusedModulePosition( interfaceDefinition:InterfaceDefinition ):Rectangle
		{
			const moduleWidthInflation:Number = 1.8;
			const moduleHeightInflation:Number = 1.6;
			const gridColumns:int = 3;
			
			var moduleWidth:Number = ModuleInstance.getModuleWidth();
			var thisModuleHeight:Number = ModuleInstance.getModuleHeight( interfaceDefinition );
			var standardModuleHeight:Number = ModuleInstance.getModuleHeight( null );
			
			for( var yGrid:int = 0; ; yGrid++ )
			{
				for( var xGrid:int = 0; xGrid < gridColumns; xGrid++ )
				{
					var x:Number = ( xGrid + 0.5 ) * moduleWidth * moduleWidthInflation;
					var y:Number = ( yGrid + 0.5 ) * standardModuleHeight * moduleHeightInflation;
					
					var candidatePosition:Rectangle = new Rectangle( x, y, moduleWidth, thisModuleHeight );
					var testRectangle:Rectangle = candidatePosition.clone();
					testRectangle.inflate( ( moduleWidthInflation - 1 ) * moduleWidth * 0.999, 0 );

					var positionIsOK:Boolean = true;
					
					for each( var existingPosition:Rectangle in _modulePositions )
					{
						if( existingPosition.intersects( testRectangle ) )
						{
							positionIsOK = false;
							break;
						}
					}
					
					if( positionIsOK )
					{
						return candidatePosition;
					}
				}
			}
			
			Assert.assertTrue( false );
			return null;
		}
		

		protected override function writeToXML( xml:XML, model:IntegraModel ):void
		{
			super.writeToXML( xml, model );
			
			//module positions			
			var positionList:XMLListCollection = new XMLListCollection();
			for( var moduleInstanceID:String in _modulePositions )
			{
				if( !( model.getDataObjectByID( int( moduleInstanceID ) ) is ModuleInstance ) ) 
				{
					continue;
				}
				
				var module:ModuleInstance = model.getModuleInstance( int( moduleInstanceID ) );
				Assert.assertNotNull( module );

				var position:Rectangle = modulePositions[ moduleInstanceID ];
				
				var positionXML:XML = new XML( "<modulePosition name='" + module.name + "'></modulePosition>" );
				positionXML.appendChild( <x>{position.x}</x> );
				positionXML.appendChild( <y>{position.y}</y> );
				positionXML.appendChild( <width>{position.width}</width> );
				positionXML.appendChild( <height>{position.height}</height> );
				
				positionList.addItem( positionXML );
			} 
			xml.appendChild( <modulePositions>{positionList.source}</modulePositions> );

			//live view controls
			var liveViewControlsList:XMLListCollection = new XMLListCollection();
			for each( var liveViewControl:LiveViewControl in _liveViewControls )
			{
				module = model.getModuleInstance( liveViewControl.moduleID );
				Assert.assertNotNull( module );

				var liveViewControlXML:XML = new XML( "<liveViewControl/>" );
				liveViewControlXML.appendChild( <moduleName>{ module.name }</moduleName> );
				liveViewControlXML.appendChild( <controlInstanceName>{liveViewControl.controlInstanceName}</controlInstanceName> );
				liveViewControlXML.appendChild( <left>{liveViewControl.position.left}</left> );
				liveViewControlXML.appendChild( <top>{liveViewControl.position.top}</top> );
				liveViewControlXML.appendChild( <width>{liveViewControl.position.width}</width> );
				liveViewControlXML.appendChild( <height>{liveViewControl.position.height}</height> );
				
				liveViewControlsList.addItem( liveViewControlXML );		
			}
			xml.appendChild( <liveViewControls>{liveViewControlsList.source}</liveViewControls> );
			
			if( _envelopeLock )
			{
				xml.appendChild( <envelopeLock>true</envelopeLock> );
			}
			
			if( _curvatureMode )
			{
				xml.appendChild( <curvatureMode>true</curvatureMode> );
			}
		}


		protected override function readFromXML( xml:XML, model:IntegraModel, myID:int ):void
		{
			super.readFromXML( xml, model, myID );
			
			var myPath:Array = model.getPathArrayFromID( myID );
			
			//module positions
			var xmlModulePositions:XMLListCollection = new XMLListCollection( xml.modulePositions.modulePosition );
			for each( var modulePosition:XML in xmlModulePositions )
			{
				var id:int = model.getIDFromPathArray( myPath.concat( modulePosition.@name ) );
				if( !model.doesObjectExist( id ) || !model.getDataObjectByID( id ) is ModuleInstance )
				{
					Trace.progress( "skipping module position - can't resolve module name ", modulePosition.@name );
					continue;
				}

				_modulePositions[ id ] = new Rectangle( modulePosition.x, modulePosition.y, modulePosition.width, modulePosition.height );
			}

			//live view controls
			var xmlLiveViewControls:XMLListCollection = new XMLListCollection( xml.liveViewControls.liveViewControl );
			for each( var liveViewControlXML:XML in xmlLiveViewControls )
			{
				var liveViewControl:LiveViewControl = new LiveViewControl;
				liveViewControl.moduleID = model.getIDFromPathArray( myPath.concat( liveViewControlXML.moduleName ) );
				if(liveViewControl.moduleID < 0 )
				{
					Trace.progress( "skipping live view control - can't resolve module name ", liveViewControlXML.moduleName );
					continue;
				}
				
				liveViewControl.controlInstanceName = liveViewControlXML.controlInstanceName;
				liveViewControl.position = new Rectangle( liveViewControlXML.left, liveViewControlXML.top, liveViewControlXML.width, liveViewControlXML.height );  

				var liveViewControlID:String = liveViewControl.id;
				Assert.assertFalse( _liveViewControls.hasOwnProperty( liveViewControlID ) ); 
				_liveViewControls[ liveViewControlID ] = liveViewControl;		
			}
			
			if( xml.hasOwnProperty( "envelopeLock" ) )
			{
				_envelopeLock = ( xml.envelopLock.toString() == "true" );
			}
			else
			{
				_envelopeLock = false;
			}

			if( xml.hasOwnProperty( "curvatureMode" ) )
			{
				_curvatureMode = ( xml.curvatureMode.toString() == "true" );
			}
			else
			{
				_curvatureMode = false;
			}
		}


		protected override function clear():void
		{
			super.clear();
			
			_modulePositions = new Object;
			_liveViewControls = new Object;
			
			_envelopeLock = false;
			_curvatureMode = false;
		}


		private var _modulePositions:Object = new Object;

		private var _liveViewControls:Object = new Object;
		
		private var _envelopeLock:Boolean = false;
		private var _curvatureMode:Boolean = false;
	}
}
