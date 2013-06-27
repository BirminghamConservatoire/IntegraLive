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
 
 
 

package components.views.ArrangeViewProperties
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.events.ListEvent;
	
	import components.controller.serverCommands.AddEnvelope;
	import components.controller.serverCommands.LoadModule;
	import components.controller.serverCommands.RemoveEnvelope;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.UnloadModule;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Block;
	import components.model.Connection;
	import components.model.Envelope;
	import components.model.Info;
	import components.model.IntegraDataObject;
	import components.model.ModuleInstance;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.lockableComboBox.LockableComboBox;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class BlockPropertiesTitlebar extends IntegraView
	{
		public function BlockPropertiesTitlebar()
		{
			super();
		
			addUpdateMethod( SetPrimarySelectedChild, onSelectionChanged );
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( LoadModule, onModuleLoaded );
			addUpdateMethod( UnloadModule, onModuleUnloaded );
			
			_envelopeLabel.text = "Envelope";
			_envelopeLabel.setStyle( "verticalCenter", 0 );

			_deleteEnvelopeButton.setStyle( "skin", CloseButtonSkin );
			_deleteEnvelopeButton.setStyle( "fillAlpha", 1 );
			
			_hbox.setStyle( "horizontalGap", 10 );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			_hbox.addChild( _envelopeLabel );
			_hbox.addChild( _deleteEnvelopeButton );
			
			addChild( _hbox );
			
			_deleteEnvelopeButton.addEventListener( MouseEvent.CLICK, onDeleteEnvelope );
			addEventListener( Event.RESIZE, onResize ); 
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_envelopeLabel.setStyle( "color", 0x747474 );
						_deleteEnvelopeButton.setStyle( "color", 0xcfcfcf ); 
						_deleteEnvelopeButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_envelopeLabel.setStyle( "color", 0x8c8c8c );
						_deleteEnvelopeButton.setStyle( "color", 0x313131 ); 
						_deleteEnvelopeButton.setStyle( "fillColor", 0x8c8c8c );
						break;
				}
			}
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( event.target == _deleteEnvelopeButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "DeleteEnvelopeButton" );	
			}
			else
			{
				return InfoMarkupForViews.instance.getInfoForView( "EnvelopeSelection" );	
			}
		}


		override protected function onAllDataChanged():void
		{
			updateModuleEnvelopeCombo();
			updateAttributeEnvelopeCombo();
		}


		private function onSelectionChanged( command:SetPrimarySelectedChild ):void
		{
			updateModuleEnvelopeCombo();
			updateAttributeEnvelopeCombo();
		}
		
		
		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				return;
			}
			
			updateModuleEnvelopeCombo();
			updateAttributeEnvelopeCombo();
		}

		
		private function onModuleLoaded( command:LoadModule ):void
		{
			updateModuleEnvelopeCombo();
		}


		private function onModuleUnloaded( command:UnloadModule ):void
		{
			updateModuleEnvelopeCombo();
		}
		
		
		private function createModuleEnvelopeCombo():void
		{
			//these combo boxes get freed and recreated every time they are repopulated, due to a 
			//bug in some implementations of the air runtime which causes them to display incorrectly
			//when they are repopulated by simply assigning a new dataProvider 

			Assert.assertNull( _envelopeModuleCombo );
			_envelopeModuleCombo = new ComboBox;
			_envelopeModuleCombo.rowCount = 10;
			_envelopeModuleCombo.height = height;
			_envelopeModuleCombo.prompt = "<module>";
			_envelopeModuleCombo.addEventListener( ListEvent.CHANGE, onChangeSelectedEnvelopeModule );
			
			_hbox.addChildAt( _envelopeModuleCombo, _hbox.getChildIndex( _envelopeLabel ) + 1 ); 
		} 


		private function removeModuleEnvelopeCombo():void
		{
			if( !_envelopeModuleCombo )	return;
			
			_envelopeModuleCombo.removeEventListener( ListEvent.CHANGE, onChangeSelectedEnvelopeModule );
			_hbox.removeChild( _envelopeModuleCombo );
			_envelopeModuleCombo = null;
		} 


		private function createModuleAttributeCombo():void
		{
			//these combo boxes get freed and recreated every time they are repopulated, due to a 
			//bug in some implementations of the air runtime which causes them to display incorrectly
			//when they are repopulated by simply assigning a new dataProvider 

			Assert.assertNull( _envelopeEndpointCombo );
			_envelopeEndpointCombo = new LockableComboBox;
			_envelopeEndpointCombo.rowCount = 10;
			_envelopeEndpointCombo.height = height;
			_envelopeEndpointCombo.prompt = "<attribute>";		
			_envelopeEndpointCombo.addEventListener( ListEvent.CHANGE, onChangeSelectedEnvelopeAttribute );
			_hbox.addChildAt( _envelopeEndpointCombo, _hbox.getChildIndex( _deleteEnvelopeButton ) );
		} 


		private function removeModuleAttributeCombo():void
		{
			if( !_envelopeEndpointCombo )	return;
			
			_envelopeEndpointCombo.removeEventListener( ListEvent.CHANGE, onChangeSelectedEnvelopeAttribute );
			_hbox.removeChild( _envelopeEndpointCombo );
			_envelopeEndpointCombo = null;
		} 

		
		private function updateModuleEnvelopeCombo():void
		{
			removeModuleEnvelopeCombo();
			createModuleEnvelopeCombo();
			
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				_envelopeModuleCombo.dataProvider = null;
				
				_envelopeLabel.visible = false;
				_envelopeModuleCombo.visible = false;
				_deleteEnvelopeButton.visible = false;
				return;
			}
			
			var selectedEnvelope:Envelope = model.selectedEnvelope;
			var selectedEnvelopeTarget:Connection = selectedEnvelope ? model.getEnvelopeTarget( selectedEnvelope.id ) : null;
			
			var selectedIndex:int = -1;

			var comboData:Array = new Array;
			
			for each( var module:ModuleInstance in block.modules )
			{
				if( selectedEnvelopeTarget && selectedEnvelopeTarget.targetObjectID == module.id )
				{
					selectedIndex = comboData.length;
				}
				
				comboData.push( module.name );
			}
			
			var comboEnabled:Boolean = ( comboData.length > 0 );
			
			_envelopeLabel.enabled = comboEnabled;
			_envelopeLabel.visible = true;
			
			_envelopeModuleCombo.visible = true;
			_envelopeModuleCombo.dataProvider = comboData;
			_envelopeModuleCombo.selectedIndex = selectedIndex;
			_envelopeModuleCombo.enabled = comboEnabled;
		}


		private function updateAttributeEnvelopeCombo():void
		{
			removeModuleAttributeCombo();
			createModuleAttributeCombo();

			var block:Block = model.primarySelectedBlock;
			if( !block || !_envelopeModuleCombo.selectedItem )
			{
				_envelopeEndpointCombo.dataProvider = null;
				_envelopeEndpointCombo.visible = false;
				_deleteEnvelopeButton.visible = false;
				return;
			}
			
			var selectedEnvelope:Envelope = model.selectedEnvelope;
			var selectedEnvelopeTarget:Connection = selectedEnvelope ? model.getEnvelopeTarget( selectedEnvelope.id ) : null;
			
			var selectedIndex:int = -1;

			var comboData:Array = new Array;

			var blockPath:Array = model.getPathArrayFromID( block.id );
			var moduleName:String = String( _envelopeModuleCombo.selectedItem );
			var moduleID:int = model.getIDFromPathArray( blockPath.concat( moduleName ) );
			var module:ModuleInstance = model.getModuleInstance( moduleID );
			Assert.assertNotNull( module ); 
			
			for each( var endpoint:EndpointDefinition in module.interfaceDefinition.endpoints )
			{
				if( !endpoint.isStateful ) continue;
				if( !endpoint.canBeConnectionTarget ) continue;

				switch( endpoint.controlInfo.stateInfo.type )
				{
				 	case StateInfo.FLOAT:
				 	case StateInfo.INTEGER:
						break;

				 	case StateInfo.STRING:
				 		continue;	//not currently supported as envelope target
				 		
					default:
						Assert.assertTrue( false );
						continue;
				}
				
				if( selectedEnvelopeTarget )
				{
					if( selectedEnvelopeTarget.targetObjectID == module.id && selectedEnvelopeTarget.targetAttributeName == endpoint.name )
					{
						selectedIndex = comboData.length;
					}
				}
				
				var comboItem:Object = new Object;
				comboItem.label = endpoint.name;
				var upstreamObjects:Vector.<IntegraDataObject> = new Vector.<IntegraDataObject>;
				if( model.isConnectionTarget( module.id, endpoint.name, upstreamObjects ) )
				{
					if( !containsAnEnvelope( upstreamObjects ) )
					{
						comboItem.locked = true;
					}
				}
				
				comboData.push( comboItem ); 
			}
			
			var comboEnabled:Boolean = ( comboData.length > 0 );
			
			_envelopeEndpointCombo.visible = true;
			_envelopeEndpointCombo.dataProvider = comboData;
			_envelopeEndpointCombo.selectedIndexRegardlessOfLock = selectedIndex;
			_envelopeEndpointCombo.enabled = comboEnabled;
				
			_deleteEnvelopeButton.visible = true;
			_deleteEnvelopeButton.enabled = ( selectedEnvelope != null );
		}
		
		
		private function containsAnEnvelope( objects:Vector.<IntegraDataObject> ):Boolean
		{
			for each( var object:IntegraDataObject in objects )
			{
				if( object is Envelope ) return true;
			}
			
			return false;
		}
		
		private function onChangeSelectedEnvelopeModule( event:ListEvent ):void
		{
			updateAttributeEnvelopeCombo();
		}
		
		
		
		private function onChangeSelectedEnvelopeAttribute( event:ListEvent ):void
		{
			var block:Block = model.primarySelectedBlock;
			if( !block )
			{
				Assert.assertTrue( false );
				return;
			}
			
			Assert.assertNotNull( _envelopeModuleCombo.selectedItem );
			
			var moduleName:String = String( _envelopeModuleCombo.selectedItem );  
			var attributeName:String = String( _envelopeEndpointCombo.selectedItem.label );
			
			var moduleID:int = model.getIDFromPathArray( model.getPathArrayFromID( block.id ).concat( moduleName ) );
			Assert.assertTrue( moduleID >= 0 );
			
			var envelopeToSelect:Envelope = block.getEnvelope( moduleID, attributeName );
			if( envelopeToSelect )
			{
				controller.processCommand( new SetPrimarySelectedChild( block.id, envelopeToSelect.id ) );
				return;
			}
			
			var module:ModuleInstance = model.getModuleInstance( moduleID );
			Assert.assertNotNull( module );

			controller.processCommand( new AddEnvelope( block.id, moduleID, attributeName, module.attributes[ attributeName ] ) );
		}
		
		
		private function onDeleteEnvelope( event:MouseEvent ):void
		{
			var envelope:Envelope = model.selectedEnvelope;
			if( !envelope )
			{
				Assert.assertTrue( false );
				return;
			}
			
			controller.processCommand( new RemoveEnvelope( envelope.id ) ); 
		}
		
		
		private function onResize( event:Event ):void
		{
			_hbox.height = height;
			if( _envelopeModuleCombo ) _envelopeModuleCombo.height = height;
			if( _envelopeEndpointCombo ) _envelopeEndpointCombo.height = height;
			_deleteEnvelopeButton.width = FontSize.getButtonSize( this );
			_deleteEnvelopeButton.height = FontSize.getButtonSize( this );
		}
		
				
		private var _hbox:HBox = new HBox;
		
		private var _envelopeLabel:Label = new Label;
		private var _envelopeModuleCombo:ComboBox = null;
		private var _envelopeEndpointCombo:LockableComboBox = null;
		private var _deleteEnvelopeButton:Button = new Button;
	}
}