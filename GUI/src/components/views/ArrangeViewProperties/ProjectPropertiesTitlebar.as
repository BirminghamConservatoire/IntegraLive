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
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.serverCommands.SetPlayerMidiNavigation;
	import components.model.Info;
	import components.model.Midi;
	import components.model.Player;
	import components.model.Project;
	import components.model.userData.ColorScheme;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.IntegraView;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import flexunit.framework.Assert;
	
	import mx.containers.HBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	import mx.events.ListEvent;
	import mx.events.ResizeEvent;
	

	public class ProjectPropertiesTitlebar extends IntegraView
	{
		public function ProjectPropertiesTitlebar()
		{
			super();
		
			addUpdateMethod( SetConnectionRouting, onConnectionRoutingChanged );
			
			_prevMidiNoteLabel.text = "Prev Scene: Midi Note";
			_prevMidiNoteLabel.setStyle( "verticalCenter", 0 );

			_prevCCNumberLabel.text = "CC Number";
			_prevCCNumberLabel.setStyle( "verticalCenter", 0 );

			_nextMidiNoteLabel.text = "Next Scene: Midi Note";
			_nextMidiNoteLabel.setStyle( "verticalCenter", 0 );
			
			_nextCCNumberLabel.text = "CC Number";
			_nextCCNumberLabel.setStyle( "verticalCenter", 0 );
			
			_prevMidiNoteCombo.rowCount = 12;
			_prevCCNumberCombo.rowCount = 12;
			_nextMidiNoteCombo.rowCount = 12;
			_nextCCNumberCombo.rowCount = 12;
			
			_hbox.setStyle( "horizontalGap", 10 );
			_hbox.setStyle( "verticalAlign", "middle" );
			
			_hbox.addElement( _prevMidiNoteLabel );
			_hbox.addElement( _prevMidiNoteCombo );
			_hbox.addElement( _prevCCNumberLabel );
			_hbox.addElement( _prevCCNumberCombo );
			_hbox.addElement( _nextMidiNoteLabel );
			_hbox.addElement( _nextMidiNoteCombo );
			_hbox.addElement( _nextCCNumberLabel );
			_hbox.addElement( _nextCCNumberCombo );
			
			addElement( _hbox );
			
			_prevMidiNoteCombo.addEventListener( ListEvent.CHANGE, onChangePrevMidiNote );
			_prevCCNumberCombo.addEventListener( ListEvent.CHANGE, onChangePrevCCNumber );
			_nextMidiNoteCombo.addEventListener( ListEvent.CHANGE, onChangeNextMidiNote );
			_nextCCNumberCombo.addEventListener( ListEvent.CHANGE, onChangeNextCCNumber );
			
			addEventListener( Event.RESIZE, onResize ); 
		}
		
		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "ProjectPropertiesTitlebar" );
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_prevMidiNoteLabel.setStyle( "color", 0x747474 );
						_prevCCNumberLabel.setStyle( "color", 0x747474 );
						_nextMidiNoteLabel.setStyle( "color", 0x747474 );
						_nextCCNumberLabel.setStyle( "color", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_prevMidiNoteLabel.setStyle( "color", 0x8c8c8c );
						_prevCCNumberLabel.setStyle( "color", 0x8c8c8c );
						_nextMidiNoteLabel.setStyle( "color", 0x8c8c8c );
						_nextCCNumberLabel.setStyle( "color", 0x8c8c8c );
						break;
						
					default:
						break;
				}
			}
		}


		override protected function onAllDataChanged():void
		{
			populateMidiNoteCombo( _prevMidiNoteCombo );
			populateMidiNoteCombo( _nextMidiNoteCombo );
			populateCCNumberCombo( _prevCCNumberCombo );
			populateCCNumberCombo( _nextCCNumberCombo );

			update();
		}
		
		
		private function onConnectionRoutingChanged( command:SetConnectionRouting ):void
		{
			update();
		}
		
		
		private function update():void
		{
			var project:Project = model.project;
			var player:Player = project.player;
			
			_prevMidiNoteCombo.selectedIndex = _mapMidiNoteToComboIndex[ project.getConnectedMidiNote( player.id, "prev" ) ]; 
			_nextMidiNoteCombo.selectedIndex = _mapMidiNoteToComboIndex[ project.getConnectedMidiNote( player.id, "next" ) ]; 
			_prevCCNumberCombo.selectedIndex = _mapCCNumberToComboIndex[ project.getConnectedCCNumber( player.id, "prev" ) ]; 
			_nextCCNumberCombo.selectedIndex = _mapCCNumberToComboIndex[ project.getConnectedCCNumber( player.id, "next" ) ]; 
		}


	
		private function onChangePrevMidiNote( event:ListEvent ):void
		{
			var project:Project = model.project;
			var player:Player = project.player;

			var prevCCNumber:int = project.getConnectedCCNumber( player.id, "prev" );
			var nextCCNumber:int = project.getConnectedCCNumber( player.id, "next" );
			var nextMidiNote:int = project.getConnectedMidiNote( player.id, "next" );
			
			controller.processCommand( new SetPlayerMidiNavigation( nextMidiNote, nextCCNumber, _mapComboIndexToMidiNote[ _prevMidiNoteCombo.selectedIndex ], prevCCNumber ) );
		}

		
		private function onChangePrevCCNumber( event:ListEvent ):void
		{
			var project:Project = model.project;
			var player:Player = project.player;
			
			var nextCCNumber:int = project.getConnectedCCNumber( player.id, "next" );
			var prevMidiNote:int = project.getConnectedMidiNote( player.id, "prev" );
			var nextMidiNote:int = project.getConnectedMidiNote( player.id, "next" );
			
			controller.processCommand( new SetPlayerMidiNavigation( nextMidiNote, nextCCNumber, prevMidiNote, _mapComboIndexToCCNumber[ _prevCCNumberCombo.selectedIndex ] ) );
		}

		
		private function onChangeNextMidiNote( event:ListEvent ):void
		{
			var project:Project = model.project;
			var player:Player = project.player;
			
			var prevCCNumber:int = project.getConnectedCCNumber( player.id, "prev" );
			var nextCCNumber:int = project.getConnectedCCNumber( player.id, "next" );
			var prevMidiNote:int = project.getConnectedMidiNote( player.id, "prev" );
			
			controller.processCommand( new SetPlayerMidiNavigation( _mapComboIndexToMidiNote[ _nextMidiNoteCombo.selectedIndex ], nextCCNumber, prevMidiNote, prevCCNumber ) );
		}
		
		
		private function onChangeNextCCNumber( event:ListEvent ):void
		{
			var project:Project = model.project;
			var player:Player = project.player;
			
			var prevCCNumber:int = project.getConnectedCCNumber( player.id, "prev" );
			var prevMidiNote:int = project.getConnectedMidiNote( player.id, "prev" );
			var nextMidiNote:int = project.getConnectedMidiNote( player.id, "next" );
			
			controller.processCommand( new SetPlayerMidiNavigation( nextMidiNote, _mapComboIndexToCCNumber[ _nextCCNumberCombo.selectedIndex ], prevMidiNote, prevCCNumber ) );
		}
		
		
		private function onResize( event:ResizeEvent ):void
		{
			_hbox.height = height;

			_prevMidiNoteCombo.height = height;
			_prevCCNumberCombo.height = height;
			_nextMidiNoteCombo.height = height;
			_nextCCNumberCombo.height = height;
		}
		

		
		private function populateMidiNoteCombo( combo:ComboBox ):void
		{
			var midiNoteData:Array = new Array;

			for( var i:int = -1; i < Midi.numberOfMidiNotes; i++ )
			{
				_mapComboIndexToMidiNote[ midiNoteData.length ] = i; 
				_mapMidiNoteToComboIndex[ i ] = midiNoteData.length; 

				midiNoteData.push( Utilities.getMidiNoteName( i ) );
			}
			
			combo.dataProvider = midiNoteData;
		}

		
		private function populateCCNumberCombo( combo:ComboBox ):void
		{
			var ccNumberData:Array = new Array;
			
			for( var i:int = -1; i < Midi.numberOfCCNumbers; i++ )
			{
				_mapComboIndexToCCNumber[ ccNumberData.length ] = i; 
				_mapCCNumberToComboIndex[ i ] = ccNumberData.length; 
				
				ccNumberData.push( Utilities.getCCNumberName( i ) );
			}
			
			combo.dataProvider = ccNumberData;
		}

		
		private var _hbox:HBox = new HBox;
		
		private var _prevMidiNoteLabel:Label = new Label;
		private var _prevMidiNoteCombo:ComboBox = new ComboBox;
		private var _prevCCNumberLabel:Label = new Label;
		private var _prevCCNumberCombo:ComboBox = new ComboBox;
		private var _nextMidiNoteLabel:Label = new Label;
		private var _nextMidiNoteCombo:ComboBox = new ComboBox;
		private var _nextCCNumberLabel:Label = new Label;
		private var _nextCCNumberCombo:ComboBox = new ComboBox;
		
		private var _mapComboIndexToMidiNote:Array = new Array; 	//midi note of each combo index 
		private var _mapMidiNoteToComboIndex:Array = new Array; 	//combo index of each midi note  

		private var _mapComboIndexToCCNumber:Array = new Array; 	//cc number of each combo index 
		private var _mapCCNumberToComboIndex:Array = new Array; 	//combo index of each cc number
	}
}