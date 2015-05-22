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
	import com.mattism.http.xmlrpc.Connection;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.events.ListEvent;
	import mx.events.ResizeEvent;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddMidiControlInput;
	import components.controller.serverCommands.RemoveMidiControlInput;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SelectScene;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetMidiControlAutoLearn;
	import components.controller.serverCommands.ConfigureMidiControlInput;
	import components.controller.serverCommands.SetSceneMode;
	import components.controller.userDataCommands.SetSceneKeybinding;
	import components.model.Connection;
	import components.model.Info;
	import components.model.MidiControlInput;
	import components.model.Scene;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.model.userData.SceneUserData;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	import components.views.Skins.MidiButtonSkin;
	
	import flexunit.framework.Assert;
	

	public class ScenePropertiesTitlebar extends IntegraView
	{
		public function ScenePropertiesTitlebar()
		{
			super();
		
			addUpdateMethod( SelectScene, onSceneSelected );
			addUpdateMethod( SetSceneMode, onSceneModeChanged );
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( SetSceneKeybinding, onSceneKeybindingChanged );
			addUpdateMethod( ConfigureMidiControlInput, onMidiControlValuesChanged );
			addUpdateMethod( SetMidiControlAutoLearn, onMidiControlValuesChanged );
			addUpdateMethod( RenameObject, onObjectRenamed );
			
			_keybindingLabel.text = "Key";
			_keybindingLabel.setStyle( "verticalCenter", 0 );

			var keybindingData:Array = new Array;
			keybindingData.push( _noKeybinding );
			for( var i:int = 0; i < SceneUserData.KEYBINDINGS.length; i++ )
			{
				keybindingData.push( SceneUserData.KEYBINDINGS.charAt( i ) );
			}
			_keybindingCombo.dataProvider = keybindingData;
			_keybindingCombo.rowCount = 10;

			_midiLabel.text = "Midi";
			_midiLabel.setStyle( "verticalCenter", 0 );

			_midiLearnButton.toggle = true;
			_midiLearnButton.setStyle( "skin", MidiButtonSkin );
			_midiLearnButton.setStyle( "color", 0x808080 );
			
			_midiSettingLabel.text = "";
			_midiSettingLabel.setStyle( "verticalCenter", 0 );
			
			_removeMidiButton.setStyle( "skin", CloseButtonSkin );
			_removeMidiButton.setStyle( "fillAlpha", 1 );
			
			_modeLabel.text = "State";
			_modeLabel.setStyle( "verticalCenter", 0 );

			_hbox.setStyle( "horizontalGap", 10 );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			_hbox.addElement( _modeLabel );
			_hbox.addElement( _modeCombo );
			_hbox.addElement( _keybindingLabel );
			_hbox.addElement( _keybindingCombo );
			_hbox.addElement( _midiLabel );
			_hbox.addElement( _midiLearnButton );
			_hbox.addElement( _midiSettingLabel );
			_hbox.addElement( _removeMidiButton );
			
			
			addElement( _hbox );
			
			_keybindingCombo.addEventListener( ListEvent.CHANGE, onChangeKeybinding );
			_modeCombo.addEventListener( ListEvent.CHANGE, onChangeMode );
			_midiLearnButton.addEventListener( MouseEvent.CLICK, onMidiLearnButton );
			_midiLearnButton.addEventListener( MouseEvent.DOUBLE_CLICK, onMidiLearnButton );
			_removeMidiButton.addEventListener( MouseEvent.CLICK, onRemoveMidi );
			
			addEventListener( Event.RESIZE, onResize ); 
		}

		
		override public function getInfoToDisplay( event:Event ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "ArrangeViewProperties/ScenePropertiesTitlebar" );
		}		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_keybindingLabel.setStyle( "color", 0x747474 );
						_modeLabel.setStyle( "color", 0x747474 );
						_midiLabel.setStyle( "color", 0x747474 );
						_midiSettingLabel.setStyle( "color", 0x747474 );
						_removeMidiButton.setStyle( "color", 0xcfcfcf );
						_removeMidiButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_modeLabel.setStyle( "color", 0x8c8c8c );
						_keybindingLabel.setStyle( "color", 0x8c8c8c );
						_midiLabel.setStyle( "color", 0x8c8c8c );
						_midiSettingLabel.setStyle( "color", 0x8c8c8c );
						_removeMidiButton.setStyle( "color", 0x313131 );
						_removeMidiButton.setStyle( "fillColor", 0x8c8c8c );
						break;
						
					default:
						break;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				var buttonSize:Number = FontSize.getButtonSize( this );
				_midiLearnButton.height = _midiLearnButton.width = buttonSize;
				_removeMidiButton.height = _removeMidiButton.width = buttonSize;
			}
		}


		override protected function onAllDataChanged():void
		{
			populateModesCombo();
			update();
		}


		private function onSceneSelected( command:SelectScene ):void
		{
			update();
		}
		
		
		private function onSceneModeChanged( command:SetSceneMode ):void
		{
			update();
		}
		
		
		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			update();
		}
		
		
		private function onSceneKeybindingChanged( command:SetSceneKeybinding ):void
		{
			update();
		}
		
		
		private function onMidiControlValuesChanged( command:ServerCommand ):void
		{
			update();
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			if( model.selectedScene && command.objectID == model.selectedScene.id )
			{
				update();
			}
		}

		
		private function update():void
		{
			var scene:Scene = model.selectedScene;
			if( !scene )
			{
				_modeCombo.selectedIndex = -1;
				_keybindingCombo.selectedIndex = -1;
				_midiLearnButton.selected = false;
				_removeMidiButton.visible = false;
				return;
			}
			
			selectComboItem( _modeCombo, scene.mode );
			
			if( scene.keybinding == SceneUserData.NO_KEYBINDING )
			{
				selectComboItem( _keybindingCombo, _noKeybinding );
			}
			else
			{
				selectComboItem( _keybindingCombo, scene.keybinding );
			}
			
			var midiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( scene.id, "activate" ); 
			if( midiControlInput )
			{
				_midiLearnButton.selected = midiControlInput.autoLearn;
				_midiSettingLabel.text = midiControlInput.getAsString();
				_removeMidiButton.visible = true;
			}
			else
	 		{
				_midiLearnButton.selected = false;
				_midiSettingLabel.text = "";
				_removeMidiButton.visible = false;
			}
		}


		private function selectComboItem( combo:ComboBox, itemToSelect:String ):void
		{
			for( var i:int = 0; i < combo.dataProvider.length; i++ )
			{
				if( itemToSelect == combo.dataProvider[ i ] )
				{
					combo.selectedIndex = i;
					return;
				}
			}

			combo.selectedIndex = -1;			
		}
		
		
		private function onChangeMode( event:ListEvent ):void
		{
			var scene:Scene = model.selectedScene;
			Assert.assertNotNull( scene );
			
			controller.processCommand( new SetSceneMode( scene.id, String( _modeCombo.selectedItem ) ) );
		}
		
		
		private function onChangeKeybinding( event:ListEvent ):void
		{
			var scene:Scene = model.selectedScene;
			Assert.assertNotNull( scene );
			
			if( _keybindingCombo.selectedItem == _noKeybinding )
			{
				controller.processCommand( new SetSceneKeybinding( scene.id, SceneUserData.NO_KEYBINDING ) );
			}
			else
			{
				controller.processCommand( new SetSceneKeybinding( scene.id, String( _keybindingCombo.selectedItem ) ) );
			}
		}

		
		private function onResize( event:ResizeEvent ):void
		{
			_hbox.height = height;
			_modeCombo.height = height;
			_keybindingCombo.height = height;
			_midiLabel.height = height;
			_midiSettingLabel.height = height;
		}
		
		
		private function populateModesCombo():void
		{
			var modes:Array = new Array;
			var sceneInterfaceDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( Scene._serverInterfaceName );
			if( sceneInterfaceDefinition )
			{
				var modesEndpoint:EndpointDefinition = sceneInterfaceDefinition.getEndpointDefinition( "mode" );
				Assert.assertNotNull( modesEndpoint );
			
				for each( var mode:String in modesEndpoint.controlInfo.stateInfo.constraint.allowedValues )
				{
					modes.push( mode );
				}
			}
			
			_modeCombo.dataProvider = modes;
			_modeCombo.rowCount = modes.length;
		}

		
		private function onMidiLearnButton( event:Event ):void
		{
			var scene:Scene = model.selectedScene;
			Assert.assertNotNull( scene );
			
			var midiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( scene.id, "activate" );
			if( midiControlInput )
			{
				if( midiControlInput.autoLearn )
				{
					controller.processCommand( new RemoveMidiControlInput( midiControlInput.id ) );
				}
				else
				{
					controller.processCommand( new SetMidiControlAutoLearn( midiControlInput.id, true ) );
				}
			}
			else
			{
				var addMidiControlInputCommand:AddMidiControlInput = new AddMidiControlInput( model.project.id );
				controller.processCommand( addMidiControlInputCommand );
				
				midiControlInput = model.getMidiControlInput( addMidiControlInputCommand.midiControlInputID );
				var downstreamConnection:components.model.Connection = midiControlInput.scaler.downstreamConnection;
				
				controller.processCommand( new SetConnectionRouting( downstreamConnection.id, downstreamConnection.sourceObjectID, downstreamConnection.sourceAttributeName, scene.id, "activate" ) );
				
				controller.processCommand( new SetMidiControlAutoLearn( addMidiControlInputCommand.midiControlInputID, true ) );
			}
		}

		
		private function onRemoveMidi( event:Event ):void
		{
			var scene:Scene = model.selectedScene;
			Assert.assertNotNull( scene );
			
			var midiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( scene.id, "activate" );
			Assert.assertNotNull( midiControlInput );
			
			controller.processCommand( new RemoveMidiControlInput( midiControlInput.id ) );
		}
		
		
		private var _hbox:HBox = new HBox;
		
		private var _keybindingLabel:Label = new Label;
		private var _keybindingCombo:ComboBox = new ComboBox;
		private var _midiLabel:Label = new Label;
		private var _midiLearnButton:Button = new Button;
		private var _midiSettingLabel:Label = new Label;
		private var _removeMidiButton:Button = new Button;
		private var _modeLabel:Label = new Label;
		private var _modeCombo:ComboBox = new ComboBox;
		
		private static const _noKeybinding:String = "<none>"; 
	}
}