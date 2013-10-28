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
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SelectScene;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetSceneMidiNavigation;
	import components.controller.serverCommands.SetSceneMode;
	import components.controller.userDataCommands.SetSceneKeybinding;
	import components.model.Info;
	import components.model.Midi;
	import components.model.Scene;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.model.userData.SceneUserData;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.IntegraView;
	import components.views.Skins.CloseButtonSkin;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import flexunit.framework.Assert;
	
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.events.ListEvent;
	import mx.events.ResizeEvent;
	

	public class ScenePropertiesTitlebar extends IntegraView
	{
		public function ScenePropertiesTitlebar()
		{
			super();
		
			addUpdateMethod( SelectScene, onSceneSelected );
			addUpdateMethod( SetSceneMode, onSceneModeChanged );
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( SetSceneKeybinding, onSceneKeybindingChanged );
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

			_midiNoteLabel.text = "MIDI Note";
			_midiNoteLabel.setStyle( "verticalCenter", 0 );
			
			_midiNoteCombo.rowCount = 12;

			_ccNumberLabel.text = "MIDI CC Number";
			_ccNumberLabel.setStyle( "verticalCenter", 0 );
			
			_ccNumberCombo.rowCount = 12;
			
			_modeLabel.text = "State";
			_modeLabel.setStyle( "verticalCenter", 0 );

			_hbox.setStyle( "horizontalGap", 10 );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			_hbox.addElement( _modeLabel );
			_hbox.addElement( _modeCombo );
			_hbox.addElement( _keybindingLabel );
			_hbox.addElement( _keybindingCombo );
			_hbox.addElement( _midiNoteLabel );
			_hbox.addElement( _midiNoteCombo );
			_hbox.addElement( _ccNumberLabel );
			_hbox.addElement( _ccNumberCombo );
			
			addElement( _hbox );
			
			_keybindingCombo.addEventListener( ListEvent.CHANGE, onChangeKeybinding );
			_modeCombo.addEventListener( ListEvent.CHANGE, onChangeMode );
			_midiNoteCombo.addEventListener( ListEvent.CHANGE, onChangeMidiNote );
			_ccNumberCombo.addEventListener( ListEvent.CHANGE, onChangeCCNumber );
			
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
						_midiNoteLabel.setStyle( "color", 0x747474 );
						_ccNumberLabel.setStyle( "color", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_modeLabel.setStyle( "color", 0x8c8c8c );
						_keybindingLabel.setStyle( "color", 0x8c8c8c );
						_midiNoteLabel.setStyle( "color", 0x8c8c8c );
						_ccNumberLabel.setStyle( "color", 0x8c8c8c );
						break;
						
					default:
						break;
				}
			}
		}


		override protected function onAllDataChanged():void
		{
			populateModesCombo();
			populateMidiNoteCombo();
			populateCCNumberCombo();
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
				_midiNoteCombo.selectedIndex = -1;
				_ccNumberCombo.selectedIndex = -1;
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
			
			_midiNoteCombo.selectedIndex = _mapMidiNoteToComboIndex[ model.project.getConnectedMidiNote( scene.id, "activate" ) ]; 
			_ccNumberCombo.selectedIndex = _mapCCNumberToComboIndex[ model.project.getConnectedCCNumber( scene.id, "activate" ) ]; 
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

		
		private function onChangeMidiNote( event:ListEvent ):void
		{
			var scene:Scene = model.selectedScene;
			Assert.assertNotNull( scene );
			
			var ccNumber:int = model.project.getConnectedCCNumber( scene.id, "activate" );
			controller.processCommand( new SetSceneMidiNavigation( scene.id, _mapComboIndexToMidiNote[ _midiNoteCombo.selectedIndex ], ccNumber ) );
		}

		
		private function onChangeCCNumber( event:ListEvent ):void
		{
			var scene:Scene = model.selectedScene;
			Assert.assertNotNull( scene );
			
			var midiNote:int = model.project.getConnectedMidiNote( scene.id, "activate" );
			controller.processCommand( new SetSceneMidiNavigation( scene.id, midiNote, _mapComboIndexToCCNumber[ _ccNumberCombo.selectedIndex ] ) );
		}
		

		private function onResize( event:ResizeEvent ):void
		{
			_hbox.height = height;
			_modeCombo.height = height;
			_keybindingCombo.height = height;
			_midiNoteCombo.height = height;
			_ccNumberCombo.height = height;
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

		
		private function populateMidiNoteCombo():void
		{
			var midiNoteData:Array = new Array;

			for( var i:int = -1; i < Midi.numberOfMidiNotes; i++ )
			{
				_mapComboIndexToMidiNote[ midiNoteData.length ] = i; 
				_mapMidiNoteToComboIndex[ i ] = midiNoteData.length; 

				midiNoteData.push( Utilities.getMidiNoteName( i ) );
			}
			
			_midiNoteCombo.dataProvider = midiNoteData;
		}

		
		private function populateCCNumberCombo():void
		{
			var ccNumberData:Array = new Array;
			
			for( var i:int = -1; i < Midi.numberOfCCNumbers; i++ )
			{
				_mapComboIndexToCCNumber[ ccNumberData.length ] = i; 
				_mapCCNumberToComboIndex[ i ] = ccNumberData.length; 
				
				ccNumberData.push( Utilities.getCCNumberName( i ) );
			}
			
			_ccNumberCombo.dataProvider = ccNumberData;
		}

		
		private var _hbox:HBox = new HBox;
		
		private var _keybindingLabel:Label = new Label;
		private var _keybindingCombo:ComboBox = new ComboBox;
		private var _midiNoteLabel:Label = new Label;
		private var _midiNoteCombo:ComboBox = new ComboBox;
		private var _ccNumberLabel:Label = new Label;
		private var _ccNumberCombo:ComboBox = new ComboBox;
		private var _modeLabel:Label = new Label;
		private var _modeCombo:ComboBox = new ComboBox;
		
		private var _mapComboIndexToMidiNote:Array = new Array; 	//midi note of each combo index 
		private var _mapMidiNoteToComboIndex:Array = new Array; 	//combo index of each midi note  

		private var _mapComboIndexToCCNumber:Array = new Array; 	//cc number of each combo index 
		private var _mapCCNumberToComboIndex:Array = new Array; 	//combo index of each cc number
		
		private static const _noKeybinding:String = "<none>"; 
	}
}