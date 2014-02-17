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
	import mx.controls.Label;
	import mx.events.ListEvent;
	import mx.events.ResizeEvent;
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.AddMidiControlInput;
	import components.controller.serverCommands.RemoveMidiControlInput;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetMidiControlAutoLearn;
	import components.controller.serverCommands.SetMidiControlInputValues;
	import components.model.Connection;
	import components.model.Info;
	import components.model.MidiControlInput;
	import components.model.Player;
	import components.model.Project;
	import components.model.Scene;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	import components.views.Skins.MidiButtonSkin;
	
	import flexunit.framework.Assert;
	

	public class ProjectPropertiesTitlebar extends IntegraView
	{
		public function ProjectPropertiesTitlebar()
		{
			super();
		
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			addUpdateMethod( SetMidiControlInputValues, onMidiControlValuesChanged );
			addUpdateMethod( SetMidiControlAutoLearn, onMidiControlValuesChanged );
			
			_prevMidiLabel.text = "Prev Scene";
			_prevMidiLabel.setStyle( "verticalCenter", 0 );
			
			_prevMidiLearnButton.toggle = true;
			_prevMidiLearnButton.setStyle( "skin", MidiButtonSkin );
			_prevMidiLearnButton.setStyle( "color", 0x808080 );
			
			_prevMidiSettingLabel.text = "";
			_prevMidiSettingLabel.setStyle( "verticalCenter", 0 );
			
			_removePrevMidiButton.setStyle( "skin", CloseButtonSkin );
			_removePrevMidiButton.setStyle( "fillAlpha", 1 );

			_nextMidiLabel.text = "Next Scene";
			_nextMidiLabel.setStyle( "verticalCenter", 0 );
			
			_nextMidiLearnButton.toggle = true;
			_nextMidiLearnButton.setStyle( "skin", MidiButtonSkin );
			_nextMidiLearnButton.setStyle( "color", 0x808080 );
			
			_nextMidiSettingLabel.text = "";
			_nextMidiSettingLabel.setStyle( "verticalCenter", 0 );
			
			_removeNextMidiButton.setStyle( "skin", CloseButtonSkin );
			_removeNextMidiButton.setStyle( "fillAlpha", 1 );
			
			_hbox.setStyle( "horizontalGap", 10 );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			_hbox.addElement( _prevMidiLabel );
			_hbox.addElement( _prevMidiLearnButton );
			_hbox.addElement( _prevMidiSettingLabel );
			_hbox.addElement( _removePrevMidiButton );
			_hbox.addElement( _nextMidiLabel );
			_hbox.addElement( _nextMidiLearnButton );
			_hbox.addElement( _nextMidiSettingLabel );
			_hbox.addElement( _removeNextMidiButton );
			
			addElement( _hbox );

			_prevMidiLearnButton.addEventListener( MouseEvent.CLICK, onPrevMidiLearnButton );
			_prevMidiLearnButton.addEventListener( MouseEvent.DOUBLE_CLICK, onPrevMidiLearnButton );
			_removePrevMidiButton.addEventListener( MouseEvent.CLICK, onRemovePrevMidi );

			_nextMidiLearnButton.addEventListener( MouseEvent.CLICK, onNextMidiLearnButton );
			_nextMidiLearnButton.addEventListener( MouseEvent.DOUBLE_CLICK, onNextMidiLearnButton );
			_removeNextMidiButton.addEventListener( MouseEvent.CLICK, onRemoveNextMidi );
			
			addEventListener( Event.RESIZE, onResize ); 
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "ArrangeViewProperties/ProjectPropertiesTitlebar" );
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_prevMidiLabel.setStyle( "color", 0x747474 );
						_prevMidiSettingLabel.setStyle( "color", 0x747474 );
						_removePrevMidiButton.setStyle( "color", 0xcfcfcf );
						_removePrevMidiButton.setStyle( "fillColor", 0x747474 );
						_nextMidiLabel.setStyle( "color", 0x747474 );
						_nextMidiSettingLabel.setStyle( "color", 0x747474 );
						_removeNextMidiButton.setStyle( "color", 0xcfcfcf );
						_removeNextMidiButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_prevMidiLabel.setStyle( "color", 0x8c8c8c );
						_prevMidiSettingLabel.setStyle( "color", 0x8c8c8c );
						_removePrevMidiButton.setStyle( "color", 0x313131 );
						_removePrevMidiButton.setStyle( "fillColor", 0x8c8c8c );
						_nextMidiLabel.setStyle( "color", 0x8c8c8c );
						_nextMidiSettingLabel.setStyle( "color", 0x8c8c8c );
						_removeNextMidiButton.setStyle( "color", 0x313131 );
						_removeNextMidiButton.setStyle( "fillColor", 0x8c8c8c );
						break;
						
					default:
						break;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				var buttonSize:Number = FontSize.getButtonSize( this );
				_prevMidiLearnButton.height = _prevMidiLearnButton.width = buttonSize;
				_removePrevMidiButton.height = _removePrevMidiButton.width = buttonSize;
				_nextMidiLearnButton.height = _nextMidiLearnButton.width = buttonSize;
				_removeNextMidiButton.height = _removeNextMidiButton.width = buttonSize;
			}
		}


		override protected function onAllDataChanged():void
		{
			update();
		}
		
		
		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			update();
		}

		
		private function onMidiControlValuesChanged( command:ServerCommand ):void
		{
			update();
		}
		
		
		private function update():void
		{
			var project:Project = model.project;
			var player:Player = project.player;
			
			var prevMidiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( player.id, "prev" ); 
			if( prevMidiControlInput )
			{
				_prevMidiLearnButton.selected = prevMidiControlInput.autoLearn;
				_prevMidiSettingLabel.text = prevMidiControlInput.getAsString();
				_removePrevMidiButton.visible = true;
			}
			else
			{
				_prevMidiLearnButton.selected = false;
				_prevMidiSettingLabel.text = "";
				_removePrevMidiButton.visible = false;
			}
			
			var nextMidiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( player.id, "next" ); 
			if( nextMidiControlInput )
			{
				_nextMidiLearnButton.selected = nextMidiControlInput.autoLearn;
				_nextMidiSettingLabel.text = nextMidiControlInput.getAsString();
				_removeNextMidiButton.visible = true;
			}
			else
			{
				_nextMidiLearnButton.selected = false;
				_nextMidiSettingLabel.text = "";
				_removeNextMidiButton.visible = false;
			}
		}


	
		
		
		private function onResize( event:ResizeEvent ):void
		{
			_hbox.height = height;

			_prevMidiLabel.height = height;
			_prevMidiSettingLabel.height = height;
			_nextMidiLabel.height = height;
			_nextMidiSettingLabel.height = height;
		}

		
		private function midiLearn( endpointName:String ):void
		{
			var player:Player = model.project.player;
			Assert.assertNotNull( player );
			
			var midiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( player.id, endpointName );
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
				
				controller.processCommand( new SetConnectionRouting( downstreamConnection.id, downstreamConnection.sourceObjectID, downstreamConnection.sourceAttributeName, player.id, endpointName ) );
				
				controller.processCommand( new SetMidiControlAutoLearn( addMidiControlInputCommand.midiControlInputID, true ) );
			}
		}

		
		private function onPrevMidiLearnButton( event:Event ):void
		{
			midiLearn( "prev" );
		}
		
		
		private function onNextMidiLearnButton( event:Event ):void
		{
			midiLearn( "next" );
		}		
		
		
		private function removeMidi( endpointName:String ):void
		{
			var player:Player = model.project.player;
			Assert.assertNotNull( player );
			
			var midiControlInput:MidiControlInput = model.getUpstreamMidiControlInput( player.id, endpointName );
			Assert.assertNotNull( midiControlInput );
			
			controller.processCommand( new RemoveMidiControlInput( midiControlInput.id ) );
		}
		
		
		private function onRemovePrevMidi( event:Event ):void
		{
			removeMidi( "prev" );
		}		

		
		private function onRemoveNextMidi( event:Event ):void
		{
			removeMidi( "next" );
		}		
		
		
		private var _hbox:HBox = new HBox;

		private var _prevMidiLabel:Label = new Label;
		private var _prevMidiLearnButton:Button = new Button;
		private var _prevMidiSettingLabel:Label = new Label;
		private var _removePrevMidiButton:Button = new Button;

		private var _nextMidiLabel:Label = new Label;
		private var _nextMidiLearnButton:Button = new Button;
		private var _nextMidiSettingLabel:Label = new Label;
		private var _removeNextMidiButton:Button = new Button;
		
	}
}