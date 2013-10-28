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
	import flash.events.Event;
	
	import mx.core.ScrollPolicy;
	
	import components.controlSDK.core.ControlManager;
	import components.controller.serverCommands.SetBlockTrack;
	import components.controller.serverCommands.SetContainerActive;
	import components.controller.serverCommands.SetModuleAttribute;
	import components.controller.userDataCommands.SetTrackColor;
	import components.model.Block;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.ModuleInstance;
	import components.model.Project;
	import components.model.Track;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.WidgetDefinition;
	import components.model.userData.ColorScheme;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;
	

	
	public class AggregateVUContainer extends IntegraView
	{
		public function AggregateVUContainer()
		{
			super();
		
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;

			var controlClass:Class = ControlManager.getClassReference( _vuMeterControlName );
			if( !controlClass )
			{
				Assert.assertTrue( false );
				return;
			}
			
			setStyle( "disabledOverlayAlpha", 0 );
			
			_control = new ControlManager( controlClass, this, null );

			_control.leftPadding = 0;
			_control.rightPadding = 0;
			_control.topPadding = 0;
			_control.bottomPadding = 0;

			var controlAttributes:Object = _control.attributes;
			Assert.assertTrue( Utilities.getNumberOfProperties( controlAttributes ) == 1 );
			Assert.assertTrue( controlAttributes.hasOwnProperty( _vuMeterControlAttributeName ) );
			Assert.assertTrue( controlAttributes[ _vuMeterControlAttributeName ] == CONTROL_ATTRIBUTE_TYPE_NUMBER );
			
			setControlBackgroundColors();
			setControlForegroundColor();
			setControlAttributeLabels();
			setControlAllowedValues();
			setControlValue( 0 );
			setControlTextEquivalents();
			setControlWritableFlags();
			setControlRepositionable();
			
			addUpdateMethod( SetModuleAttribute, onModuleAttributeChanged );
			addUpdateMethod( SetTrackColor, onTrackColorChanged );
			addUpdateMethod( SetBlockTrack, onBlockChangedTrack );
			addUpdateMethod( SetContainerActive, onContainerActiveChanged );
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			var container:IntegraContainer = model.getContainer( _containerID );
			Assert.assertNotNull( container );
			
			if( container is Project ) return InfoMarkupForViews.instance.getInfoForView( "VU/Project" );
			if( container is Track ) return InfoMarkupForViews.instance.getInfoForView( "VU/Track" );
			if( container is Block ) return InfoMarkupForViews.instance.getInfoForView( "VU/Block" );
			
			Assert.assertTrue( false );
			return null;
		}
		
		
		public function set containerID( containerID:int ):void
		{
			 _containerID = containerID;
		 	setControlForegroundColor();
		}
		
		
		public function set backgroundColors( backgroundColors:Array ):void
		{
			Assert.assertTrue( backgroundColors.length == 2 );
			
			_topBackgroundColor = backgroundColors[ 0 ];
			_bottomBackgroundColor = backgroundColors[ 1 ];
			
			setControlBackgroundColors();
		}
		
		
 		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				if( _containerID == model.project.id )
				{
					setControlForegroundColor();
				}
			}
		}

		
		override protected function onAllDataChanged():void
		{
			//update tracked endpoints from model
			_mapTrackedInterfaceGuidsToEndpoints = new Object;
			
			for each( var interfaceName:String in _audioOutputInterfaces )
			{
				var coreInterfaceDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( interfaceName );
				if( !coreInterfaceDefinition )
				{
					continue;
				}
				
				var allVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( coreInterfaceDefinition.originGuid );
				for each( var interfaceDefinition:InterfaceDefinition in allVersions )
				{
					var guid:String = interfaceDefinition.moduleGuid;
					
					for each( var widget:WidgetDefinition in interfaceDefinition.widgets )
					{
						if( widget.type == _vuMeterControlName )
						{
							for each( var endpointName:String in widget.attributeToEndpointMap )
							{
								var endpointsForThisInterface:Object = null;
								
								if( _mapTrackedInterfaceGuidsToEndpoints.hasOwnProperty( guid ) )
								{
									endpointsForThisInterface = _mapTrackedInterfaceGuidsToEndpoints[ guid ];
								}
								else
								{
									endpointsForThisInterface = new Object;
									_mapTrackedInterfaceGuidsToEndpoints[ guid ] = endpointsForThisInterface;
								}
								
								endpointsForThisInterface[ endpointName ] = 1;
							}
						}
					}
				}
			}
		}
		

		private function setControlValue( value:Number ):void
		{
			var controlValues:Object = new Object;
			controlValues[ _vuMeterControlAttributeName ] = value;
			_control.setControlValues( controlValues );
		}
		
		
		private function setControlTextEquivalents():void
		{
			var controlTextEquivalents:Object = new Object;
			controlTextEquivalents[ _vuMeterControlAttributeName ] = "";
			_control.setControlTextEquivalents( controlTextEquivalents );
		}
		
		
		private function setControlWritableFlags():void
		{
			var writableFlags:Object = new Object;
			writableFlags[ _vuMeterControlAttributeName ] = true;
			_control.setControlWritableFlags( writableFlags ); 
		}
		
		
		private function setControlAllowedValues():void
		{
			_control.setControlAllowedValues( new Object ); 
		}
		
		
		private function setControlRepositionable():void
		{
			_control.setControlRepositionable( false );
		}
		
		
		private function setControlForegroundColor():void
		{
			if( _containerID < 0 ) 
			{
				return;
			}
			
			var color:uint = model.getContainerColor( _containerID );
			
			_control.setControlForegroundColor( color );
		}

		
		private function setControlBackgroundColors():void
		{
			_control.setControlBackgroundColors( _topBackgroundColor, _bottomBackgroundColor );
		}
		
		
		private function setControlAttributeLabels():void
		{
			var attributeLabels:Object = new Object;
			attributeLabels[ _vuMeterControlAttributeName ] = "";
			_control.setControlAttributeLabels( attributeLabels );
		}
		
		
		private function onModuleAttributeChanged( command:SetModuleAttribute ):void
		{
			if( !_containerID < 0 )
			{
				return;
			}
			
			var moduleID:int = command.moduleID;
			var module:ModuleInstance = model.getModuleInstance( moduleID );
			Assert.assertNotNull( module );

			var interfaceDefinition:InterfaceDefinition = module.interfaceDefinition;
			Assert.assertNotNull( interfaceDefinition );
			
			if( !_mapTrackedInterfaceGuidsToEndpoints.hasOwnProperty( interfaceDefinition.moduleGuid ) ) 
			{
				return;
			}

			var endpointsToTrack:Object = _mapTrackedInterfaceGuidsToEndpoints[ interfaceDefinition.moduleGuid ];
			if( !endpointsToTrack.hasOwnProperty( command.endpointName ) )
			{
				return;
			}
			
			var isChild:Boolean = false;
			for( var ancestorObject:IntegraDataObject = model.getParent( moduleID ); ancestorObject; ancestorObject = model.getParent( ancestorObject.id ) )
			{
				if( ancestorObject.id == _containerID )
				{
					isChild = true;
					break;
				}  
			} 
			
			if( !isChild )
			{
				return;
			}
			
			var endpointDefinition:EndpointDefinition = interfaceDefinition.getEndpointDefinition( command.endpointName );
			Assert.assertNotNull( endpointDefinition && endpointDefinition.controlInfo.stateInfo );
			
			Assert.assertTrue( command.value is Number );
			var value:Number = ControlScaler.endpointValueToControlUnit( Number( command.value ), endpointDefinition.controlInfo.stateInfo ); 
			setControlValue( value );
		}
		
		
		private function onTrackColorChanged( command:SetTrackColor ):void
		{
			if( _containerID < 0 ) 
			{
				return;
			}
			
			var trackID:int = command.trackID;
			var parent:IntegraDataObject = model.getParent( _containerID );
			if( !parent )
			{
				Assert.assertEquals( _containerID, model.project.id );
				return;
			}
			
			if( _containerID != trackID && parent.id !== trackID )
			{
				return;			
			} 
			
			setControlForegroundColor();
		}
		
		
		private function onBlockChangedTrack( command:SetBlockTrack ):void
		{
			if( command.blockID == _containerID )
			{
				setControlForegroundColor();
			}			
		}
		
		
		private function onContainerActiveChanged( command:SetContainerActive ):void
		{
			if( model.isEqualOrAncestor( command.containerID, _containerID ) )
			{
				setControlForegroundColor();
			}
		}
		
		
		private var _containerID:int = -1;
		
		private var _control:ControlManager = null;

		private var _bottomBackgroundColor:uint = 0;
		private var _topBackgroundColor:uint = 0;

		private var _mapTrackedInterfaceGuidsToEndpoints:Object = new Object;
		
		private static const _vuMeterControlName:String = "VuMeter"; 
		private static const _vuMeterControlAttributeName:String = "level";

		private static const _audioOutputInterfaces:Array = [ "AudioOut", "StereoAudioOut", "QuadAudioOut" ];
		
	    private static const CONTROL_ATTRIBUTE_TYPE_NUMBER:String = "n";
	}
}