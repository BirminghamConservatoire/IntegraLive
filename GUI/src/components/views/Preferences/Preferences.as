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


package components.views.Preferences
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.controls.Button;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	import mx.events.ListEvent;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.ResetAudioAndMidiSettings;
	import components.controller.serverCommands.SetAudioDriver;
	import components.controller.serverCommands.SetAudioInputDevice;
	import components.controller.serverCommands.SetAudioOutputDevice;
	import components.controller.serverCommands.SetAudioSettings;
	import components.controller.serverCommands.SetAvailableAudioDevices;
	import components.controller.serverCommands.SetAvailableAudioDrivers;
	import components.controller.serverCommands.SetAvailableSampleRates;
	import components.controller.serverCommands.SetAvailableMidiDevices;
	import components.controller.serverCommands.SetAvailableMidiDrivers;
	import components.controller.serverCommands.SetMidiDriver;
	import components.controller.serverCommands.SetMidiInputDevice;
	import components.controller.serverCommands.SetMidiOutputDevice;
	import components.controller.userDataCommands.SetViewMode;
	import components.model.Info;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.preferences.AudioSettings;
	import components.model.preferences.MidiSettings;
	import components.model.userData.ColorScheme;
	import components.model.userData.ViewMode;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	import components.views.Skins.NumberEditSkin;
	import components.views.Skins.TextButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class Preferences extends IntegraView
	{
		public function Preferences()
		{
			super();
			
			addUpdateMethod( SetAudioInputDevice, onPreferencesChanged );
			addUpdateMethod( SetAudioOutputDevice, onPreferencesChanged );
			addUpdateMethod( SetAudioDriver, onPreferencesChanged );
			addUpdateMethod( SetAudioSettings, onPreferencesChanged );
			addUpdateMethod( SetMidiInputDevice, onPreferencesChanged );
			addUpdateMethod( SetMidiOutputDevice, onPreferencesChanged );
			addUpdateMethod( SetMidiDriver, onPreferencesChanged );
			addUpdateMethod( SetAvailableAudioDrivers, onPreferencesChanged );
			addUpdateMethod( SetAvailableMidiDrivers, onPreferencesChanged );
			addUpdateMethod( SetAvailableAudioDevices, onPreferencesChanged );
			addUpdateMethod( SetAvailableMidiDevices, onPreferencesChanged );
			addUpdateMethod( SetAvailableSampleRates, onPreferencesChanged );
			
			horizontalScrollPolicy = ScrollPolicy.OFF; 
			verticalScrollPolicy = ScrollPolicy.OFF;   
			
			_titleLabel.text = "Preferences";
			_titleLabel.setStyle( "verticalAlign", "center" );
			addElement( _titleLabel );

			_titleCloseButton.setStyle( "skin", CloseButtonSkin );
			_titleCloseButton.setStyle( "fillAlpha", 1 );
			_titleCloseButton.addEventListener( MouseEvent.CLICK, onClickTitleCloseButton );
			addElement( _titleCloseButton );

			initializeLabel( _audioDriverLabel, "Audio Driver" );		
			initializeLabel( _audioInLabel, "Audio Input" );
			initializeLabel( _audioInChannelsLabel, "Input Channels" );
			initializeLabel( _audioOutLabel, "Audio Output" );
			initializeLabel( _audioOutChannelsLabel, "Output Channels" );
			initializeLabel( _sampleRateLabel, "Sample Rate" );
			initializeLabel( _midiDriverLabel, "MIDI Driver" );
			initializeLabel( _midiInLabel, "MIDI Input" );
			initializeLabel( _midiOutLabel, "MIDI Output" );

			initializeIntegerEdit( _audioInChannelsEdit, onFocusOutAudioIntegerEdit );
			initializeIntegerEdit( _audioOutChannelsEdit, onFocusOutAudioIntegerEdit );
			
			_resetButton.label = "Reset to Defaults";
			_resetButton.setStyle( "right", 20 );
			_resetButton.setStyle( "bottom", 20 );
			_resetButton.setStyle( "skin", TextButtonSkin );
			_resetButton.addEventListener( MouseEvent.CLICK, onClickResetButton );
			addElement( _resetButton );
			
			styleChanged( null );
		}

		
		override public function getInfoToDisplay( event:Event ):Info 
		{
			return InfoMarkupForViews.instance.getInfoForView( "Preferences" );
		}
		
		
		public function onStyleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_backgroundColor = 0xffffff;
						_borderColor = 0xaaccdf;
						_titleCloseButton.setStyle( "color", _borderColor );
						_titleCloseButton.setStyle( "fillColor", 0x000000 );
						_titleLabel.setStyle( "color", 0x000000 );
						
						_audioDriverLabel.setStyle( "color", 0x747474 );
						_audioInLabel.setStyle( "color", 0x747474 );
						_audioInChannelsLabel.setStyle( "color", 0x747474 );
						_audioOutLabel.setStyle( "color", 0x747474 );
						_audioOutChannelsLabel.setStyle( "color", 0x747474 );
						_sampleRateLabel.setStyle( "color", 0x747474 );
						_midiDriverLabel.setStyle( "color", 0x747474 );
						_midiInLabel.setStyle( "color", 0x747474 );
						_midiOutLabel.setStyle( "color", 0x747474 );
						
						_audioInChannelsEdit.setStyle( "color", 0xcfcfcf );
						_audioOutChannelsEdit.setStyle( "color", 0xcfcfcf );
						
						setButtonTextColor( _resetButton, 0x6D6D6D );
						
						break;

					case ColorScheme.DARK:
						_backgroundColor = 0x000000;
						_borderColor = 0x214356;
						_titleCloseButton.setStyle( "color", _borderColor );
						_titleCloseButton.setStyle( "fillColor", 0xffffff );
						_titleLabel.setStyle( "color", 0xffffff );

						_audioDriverLabel.setStyle( "color", 0x8c8c8c );
						_audioInLabel.setStyle( "color", 0x8c8c8c );
						_audioInChannelsLabel.setStyle( "color", 0x8c8c8c );
						_audioOutLabel.setStyle( "color", 0x8c8c8c );
						_audioOutChannelsLabel.setStyle( "color", 0x8c8c8c );
						_sampleRateLabel.setStyle( "color", 0x8c8c8c );

						_midiDriverLabel.setStyle( "color", 0x8c8c8c );
						_midiInLabel.setStyle( "color", 0x8c8c8c );
						_midiOutLabel.setStyle( "color", 0x8c8c8c );
						
						_audioInChannelsEdit.setStyle( "color", 0x313131 );
						_audioOutChannelsEdit.setStyle( "color", 0x313131 );

						setButtonTextColor( _resetButton, 0x939393 );

						break;
				}
				
				invalidateDisplayList();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				Assert.assertNotNull( parentDocument );
				setStyle( FontSize.STYLENAME, parentDocument.getStyle( FontSize.STYLENAME ) );
				updateSize();
				invalidateDisplayList();
			}
		}
				

		public function updateSize():void
		{
			Assert.assertNotNull( parentDocument );

			//calculate window size
			var rowHeight:Number = FontSize.getTextRowHeight( this );
			width = Math.min( rowHeight * 20, parentDocument.width );
			height = Math.min( rowHeight * 18, parentDocument.height );

			//position title controls
			_titleCloseButton.width = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.height = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.x = ( titleHeight - _titleCloseButton.width ) / 2;
			_titleCloseButton.y = ( titleHeight - _titleCloseButton.width ) / 2;
			
			_titleLabel.x = titleHeight;
			_titleLabel.y = titleHeight / 6;
			_titleLabel.height = rowHeight;

			//position main controls
			var controlRect:Rectangle = new Rectangle( rowHeight * 2, titleHeight * 1.5, width - rowHeight * 4, height - titleHeight * 2 );
			rowHeight = Math.min( rowHeight, controlRect.height / 9 );
						
			_audioDriverLabel.x = _audioInLabel.x = _audioOutLabel.x = _sampleRateLabel.x = controlRect.left;
			_audioInChannelsLabel.x = _audioOutChannelsLabel.x = controlRect.left;
            _midiDriverLabel.x = _midiInLabel.x = _midiOutLabel.x = controlRect.left;
			
			_audioDriverLabel.height = _audioInLabel.height = _audioOutLabel.height = _sampleRateLabel.height = rowHeight;
			_audioInChannelsLabel.height = _audioOutChannelsLabel.height = rowHeight;
			_midiDriverLabel.height = _midiInLabel.height = _midiOutLabel.height = rowHeight;

			var controlLeft:Number = controlRect.left + FontSize.getTextRowHeight( this ) * 5;
			_audioDriverCombo.x = _audioInCombo.x = _audioOutCombo.x = _sampleRateCombo.x = controlLeft;
			_audioInChannelsEdit.x = _audioOutChannelsEdit.x = controlLeft;
			_midiDriverCombo.x = _midiInCombo.x = _midiOutCombo.x = controlLeft;
			
			var controlWidth:Number = controlRect.right - controlLeft;
			_audioDriverCombo.width = _audioInCombo.width = _audioOutCombo.width = _sampleRateCombo.width = controlWidth; 
			_audioInChannelsEdit.width = _audioOutChannelsEdit.width = controlWidth;
			_midiDriverCombo.width = _midiInCombo.width = _midiOutCombo.width = controlWidth;

			_audioDriverCombo.height = _audioInCombo.height = _audioOutCombo.height = _sampleRateCombo.height = rowHeight; 
			_audioInChannelsEdit.height = _audioOutChannelsEdit.height = rowHeight;
			_midiDriverCombo.height = _midiInCombo.height = _midiOutCombo.height = rowHeight;

			_audioDriverLabel.y = _audioDriverCombo.y = controlRect.y;
			_audioInLabel.y = _audioInCombo.y = controlRect.y + rowHeight * 1.1;
			_audioOutLabel.y = _audioOutCombo.y = controlRect.y + rowHeight * 2.2;

			_audioInChannelsLabel.y = _audioInChannelsEdit.y = controlRect.y + rowHeight * 4.2;
			_audioOutChannelsLabel.y = _audioOutChannelsEdit.y = controlRect.y + rowHeight * 5.3;

			_sampleRateLabel.y = _sampleRateCombo.y = controlRect.y + rowHeight * 7.3;

			_midiDriverLabel.y = _midiDriverCombo.y = controlRect.y + rowHeight * 10.4;
			_midiInLabel.y = _midiInCombo.y = controlRect.y + rowHeight * 11.5;
			_midiOutLabel.y = _midiOutCombo.y = controlRect.y + rowHeight * 12.6;
			
			//mx.managers.PopUpManager.centerPopUp( this );
		}
		
		
		protected override function onAllDataChanged():void
		{
			//delete & recreate combos, to fix strange OsX-only rendering bug

			if( _audioDriverCombo ) removeChild( _audioDriverCombo );
			if( _audioInCombo ) removeChild( _audioInCombo );
			if( _audioOutCombo ) removeChild( _audioOutCombo );
			if( _sampleRateCombo ) removeChild( _sampleRateCombo );
			if( _midiDriverCombo ) removeChild( _midiDriverCombo );
			if( _midiInCombo ) removeChild( _midiInCombo );
			if( _midiOutCombo ) removeChild( _midiOutCombo );

			_audioDriverCombo = new ComboBox;
			_audioInCombo = new ComboBox;
			_audioOutCombo = new ComboBox;
			_sampleRateCombo = new ComboBox;
			_midiDriverCombo = new ComboBox;
			_midiInCombo = new ComboBox;
			_midiOutCombo = new ComboBox;

			initializeCombo( _audioDriverCombo, onChangeAudioDriver );
			initializeCombo( _audioInCombo, onChangeAudioInputDevice );
			initializeCombo( _audioOutCombo, onChangeAudioOutputDevice );
			initializeCombo( _sampleRateCombo, onChangeAudioSampleRate );
			initializeCombo( _midiDriverCombo, onChangeMidiDriver );
			initializeCombo( _midiInCombo, onChangeMidiInputDevice );
			initializeCombo( _midiOutCombo, onChangeMidiOutputDevice );
			
			setComboContents();
			
			setControlStates();   

			updateSize();
		}


		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( _borderThickness, _borderColor ); 
			graphics.beginFill( _backgroundColor );
			graphics.drawRoundRect( 0, 0, width, height, _cornerRadius, _cornerRadius );
			graphics.endFill();
			
			graphics.beginFill( _borderColor );
			graphics.drawRoundRectComplex( 0, 0, width, titleHeight, _cornerRadius, _cornerRadius, 0, 0 );
			graphics.endFill();
		}
		
		
		private function initializeLabel( label:Label, text:String ):void
		{
			label.text = text;
			label.setStyle( "verticalAlign", "center" );
			addElement( label );
		}


		private function initializeCombo( combo:ComboBox, eventHandler:Function ):void
		{
			combo.rowCount = 10;
			combo.setStyle( "textAlign", "center" );
			combo.addEventListener( ListEvent.CHANGE, eventHandler );
			addElement( combo );
		}


		private function initializeIntegerEdit( textInput:TextInput, eventHandler:Function ):void
		{
			textInput.restrict = "0123456789";
			textInput.maxChars = 4;
			textInput.setStyle( "textAlign", "center" );
			textInput.setStyle( "borderSkin", NumberEditSkin );
			textInput.setStyle( "focusAlpha", 0 );
			textInput.addEventListener( FocusEvent.FOCUS_OUT, eventHandler );
			textInput.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDownIntegerEdit );
			addElement( textInput );
		}
		
		
		private function onPreferencesChanged( command:ServerCommand ):void
		{
			onAllDataChanged();
		}
		
		
 		private function setComboContents():void
		{
			var audioSettings:AudioSettings = model.audioSettings;
			var midiSettings:MidiSettings = model.midiSettings;
			
			//set combo contents for audio driver
			var data:Array = new Array;
			for each( var audioDriver:String in audioSettings.availableDrivers )
			{
				data.push( audioDriver );
			}
			
			_audioDriverCombo.dataProvider = data;
			_audioDriverCombo.enabled = ( data.length > 1 );
			
			//set combo contents for audio input devices
			data = new Array;
			for each( var audioInputDevice:String in audioSettings.availableInputDevices )
			{
				data.push( audioInputDevice );
			}
			
			_audioInCombo.dataProvider = data;
			_audioInCombo.enabled = ( data.length > 1 );
			
			//set combo contents for audio output devices
			data = new Array;
			for each( var audioOutputDevice:String in audioSettings.availableOutputDevices )
			{
				data.push( audioOutputDevice );
			}
			
			_audioOutCombo.dataProvider = data;
			_audioOutCombo.enabled = ( data.length > 1 );

			
			//set combo contents for sample rate
			data = new Array;
			for each( var sampleRate:int in audioSettings.availableSampleRates )
			{
				data.push( sampleRate );
			}
			
			_sampleRateCombo.dataProvider = data;
			_sampleRateCombo.enabled = ( data.length > 1 );
			
			//set combo contents for midi driver
			data = new Array;
			for each( var midiDriver:String in midiSettings.availableDrivers )
			{
				data.push( midiDriver );
			}
			
			_midiDriverCombo.dataProvider = data;
			_midiDriverCombo.enabled = ( data.length > 1 );
			
			//set combo contents for midi input devices
			data = new Array;
			for each( var midiInputDevice:String in midiSettings.availableInputDevices )
			{
				data.push( midiInputDevice );
			}
			
			_midiInCombo.dataProvider = data;
			_midiInCombo.enabled = ( data.length > 1 );
			
			//set combo contents for midi input devices
			data = new Array;
			for each( var midiOutputDevice:String in midiSettings.availableOutputDevices )
			{
				data.push( midiOutputDevice );
			}
			
			_midiOutCombo.dataProvider = data;
			_midiOutCombo.enabled = ( data.length > 1 );
		}

		
		private function setControlStates():void
		{
			Assert.assertNotNull( _audioDriverCombo );
			Assert.assertNotNull( _audioInCombo );
			Assert.assertNotNull( _audioOutCombo );
			Assert.assertNotNull( _sampleRateCombo );
			Assert.assertNotNull( _midiDriverCombo );
			Assert.assertNotNull( _midiInCombo );
			Assert.assertNotNull( _midiOutCombo );

			var audioSettings:AudioSettings = model.audioSettings;
			Assert.assertNotNull( audioSettings );

			_audioDriverCombo.selectedItem = audioSettings.selectedDriver;
			_audioInCombo.selectedItem = audioSettings.selectedInputDevice;
			_audioOutCombo.selectedItem = audioSettings.selectedOutputDevice;
			_sampleRateCombo.selectedItem = audioSettings.sampleRate;
			_audioInChannelsEdit.text = String( audioSettings.inputChannels );
			_audioOutChannelsEdit.text = String( audioSettings.outputChannels );

			var midiSettings:MidiSettings = model.midiSettings;
			Assert.assertNotNull( midiSettings );
			
			_midiDriverCombo.selectedItem = midiSettings.selectedDriver;
			_midiInCombo.selectedItem = midiSettings.selectedInputDevice;
			_midiOutCombo.selectedItem = midiSettings.selectedOutputDevice;
		}


		private function onChangeAudioDriver( event:ListEvent ):void
		{
			var audioDriver:String = String( _audioDriverCombo.selectedItem );

			controller.activateUndoStack = false;
			
			controller.processCommand( new SetAudioDriver( audioDriver ) );

			controller.activateUndoStack = true;
		}
		
		
		private function onChangeAudioInputDevice( event:ListEvent ):void
		{
			var audioSettings:AudioSettings = model.audioSettings;
			Assert.assertNotNull( audioSettings );
			
			var audioInputDevice:String = String( _audioInCombo.selectedItem ); 

			controller.activateUndoStack = false;
			
			controller.processCommand( new SetAudioInputDevice( audioInputDevice ) );
			
			controller.activateUndoStack = true;
		}
		
		
		private function onChangeAudioOutputDevice( event:ListEvent ):void
		{
			var audioSettings:AudioSettings = model.audioSettings;
			Assert.assertNotNull( audioSettings );
			
			var audioOutputDevice:String = String( _audioOutCombo.selectedItem );
			
			controller.activateUndoStack = false;
			
			controller.processCommand( new SetAudioOutputDevice( audioOutputDevice ) );
				
			controller.activateUndoStack = true;
		}
		
		
		private function onChangeAudioSampleRate( event:ListEvent ):void
		{
			updateAudioSettingsFromDialog();			
		}
		
		
		private function onChangeMidiDriver( event:ListEvent ):void
		{
			var midiDriver:String = String( _midiDriverCombo.selectedItem );
			
			controller.activateUndoStack = false;
			
			controller.processCommand( new SetMidiDriver( midiDriver ) );
			
			controller.activateUndoStack = true;
		}

		
		private function onChangeMidiInputDevice( event:ListEvent ):void
		{
			var midiSettings:MidiSettings = model.midiSettings;
			Assert.assertNotNull( midiSettings );
			
			var midiInputDevice:String = String( _midiInCombo.selectedItem );
			
			controller.activateUndoStack = false;
			
			controller.processCommand( new SetMidiInputDevice( midiInputDevice ) );
				
			controller.activateUndoStack = true;
		}

		
		private function onChangeMidiOutputDevice( event:ListEvent ):void
		{
			var midiSettings:MidiSettings = model.midiSettings;
			Assert.assertNotNull( midiSettings );
			
			var midiOutputDevice:String = String( _midiOutCombo.selectedItem );
			
			controller.activateUndoStack = false;
			
			controller.processCommand( new SetMidiOutputDevice( midiOutputDevice ) );
				
			controller.activateUndoStack = true;
		}
		
		
		private function onFocusOutAudioIntegerEdit( event:FocusEvent ):void
		{
			updateAudioSettingsFromDialog();
		}
		
		
		private function onKeyDownIntegerEdit( event:KeyboardEvent ):void
		{
			if( event.charCode == Keyboard.ENTER )
			{
				setFocus();	  //cause integer edit to lose focus, triggering controller command
			}
		}
		
		
		private function updateAudioSettingsFromDialog():void
		{
			var audioSettingsDefinition:InterfaceDefinition = model.getCoreInterfaceDefinitionByName( AudioSettings._serverInterfaceName );
			Assert.assertNotNull( audioSettingsDefinition );

			var inputChannelsEndpointDefinition:EndpointDefinition = audioSettingsDefinition.getEndpointDefinition( "inputChannels" );
			var outputChannelsEndpointDefinition:EndpointDefinition = audioSettingsDefinition.getEndpointDefinition( "outputChannels" );
			
			var inputChannels:int = Math.max( inputChannelsEndpointDefinition.controlInfo.stateInfo.constraint.minimum, Math.min( inputChannelsEndpointDefinition.controlInfo.stateInfo.constraint.maximum, int( _audioInChannelsEdit.text ) ) );
			var outputChannels:int = Math.max( outputChannelsEndpointDefinition.controlInfo.stateInfo.constraint.minimum, Math.min( outputChannelsEndpointDefinition.controlInfo.stateInfo.constraint.maximum, int( _audioOutChannelsEdit.text ) ) );

			var sampleRate:int = int( _sampleRateCombo.selectedItem );
			
			controller.activateUndoStack = false;

			controller.processCommand( new SetAudioSettings( sampleRate, inputChannels, outputChannels ) );	

			controller.activateUndoStack = true;
		}
	
		
		private function setButtonTextColor( button:Button, color:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
		}
		
		
		private function onClickTitleCloseButton( event:MouseEvent ):void
		{
			var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
			viewMode.preferencesOpen = false;
			
			controller.activateUndoStack = false;
			controller.processCommand( new SetViewMode( viewMode ) );
			controller.activateUndoStack = true;
		}
		
		
		private function onClickResetButton( event:MouseEvent ):void
		{
			controller.activateUndoStack = false;
			controller.processCommand( new ResetAudioAndMidiSettings() );
			controller.activateUndoStack = true;
		}
			
		
		private function get titleHeight():Number
		{
			return FontSize.getTextRowHeight( this );
		}
		
		
		private var _titleLabel:Label = new Label;
		private var _titleCloseButton:Button = new Button;
		
		private var _audioDriverCombo:ComboBox = null;
		private var _audioInCombo:ComboBox = null;
		private var _audioOutCombo:ComboBox = null;
		private var _sampleRateCombo:ComboBox = null;
		private var _audioInChannelsEdit:TextInput = new TextInput;
		private var _audioOutChannelsEdit:TextInput = new TextInput;
		private var _midiDriverCombo:ComboBox = null;
		private var _midiInCombo:ComboBox = null;
		private var _midiOutCombo:ComboBox = null;
		
		
		private var _audioDriverLabel:Label = new Label;
		private var _audioInLabel:Label = new Label;
		private var _audioOutLabel:Label = new Label;
		private var _audioInChannelsLabel:Label = new Label;
		private var _audioOutChannelsLabel:Label = new Label;
		private var _sampleRateLabel:Label = new Label;
		private var _midiDriverLabel:Label = new Label;
		private var _midiInLabel:Label = new Label;
		private var _midiOutLabel:Label = new Label;

		private var _resetButton:Button = new Button;
		
		private var _backgroundColor:uint = 0;
		private var _borderColor:uint = 0;
		
		private const _borderThickness:Number = 4;
		private const _cornerRadius:Number = 15;
	}
}
