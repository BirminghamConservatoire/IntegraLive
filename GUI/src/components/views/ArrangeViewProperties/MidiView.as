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
	
	import mx.containers.VBox;
	import mx.controls.Button;
	
	import components.controller.serverCommands.AddMidiControlInput;
	import components.controller.serverCommands.RemoveMidiControlInput;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.MidiControlInput;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.AddButtonSkin;
	
	import flexunit.framework.Assert;

	public class MidiView extends IntegraView
	{
		public function MidiView()
		{
			super();
			
			_vbox.percentWidth = 100;
			_vbox.percentHeight = 100;
			_vbox.setStyle( "paddingLeft", _padding );
			_vbox.setStyle( "paddingRight", _padding );
			_vbox.setStyle( "paddingTop", _padding );
			_vbox.setStyle( "paddingBottom", _padding );
			addElement( _vbox );
			
			_newItemButton.setStyle( "skin", AddButtonSkin );
			_newItemButton.setStyle( "fillAlpha", 1 );
			_newItemButton.addEventListener( MouseEvent.CLICK, onClickNewItemButton );
			
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( AddMidiControlInput, onMidiControlInputAdded );
			addUpdateMethod( RemoveMidiControlInput, onMidiControlInputRemoved );
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
						_newItemButton.setStyle( "color", 0xcfcfcf );
						_newItemButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_newItemButton.setStyle( "color", 0x313131 );
						_newItemButton.setStyle( "fillColor", 0x8c8c8c );
						break;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				_newItemButton.width = FontSize.getButtonSize( this );
				_newItemButton.height = FontSize.getTextRowHeight( this ) + 4;
			}
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( event.target == _newItemButton ) 
			{
				return InfoMarkupForViews.instance.getInfoForView( "ArrangeViewProperties/CreateMidiButton" );
			}

			return InfoMarkupForViews.instance.getInfoForView( "ArrangeViewProperties/MidiView" );
		}		
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		} 
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			var containerID:int = -1;
			var selectedContainer:IntegraContainer = model.selectedContainer;
			if( selectedContainer )
			{
				containerID = selectedContainer.id;
			}
			
			if( containerID != _containerID )
			{
				updateAll();
			}
		}
		
		
		private function updateAll():void
		{
			_vbox.removeAllChildren();
			for each( var midiItem:MidiItem in _midiItems )
			{
				midiItem.free();
			}
			_midiItems = new Object;
			
			var container:IntegraContainer = model.selectedContainer;
			if( container )
			{
				_containerID = container.id;
				
				_vbox.addElement( _newItemButton );
				
				for each( var midiControlInput:MidiControlInput in container.midiControlInputs )
				{
					addMidiViewItem( midiControlInput );
				}
			}
			else
			{
				_containerID = -1;
			}
		}


		private function onMidiControlInputAdded( command:AddMidiControlInput ):void
		{
			if( command.containerID != _containerID ) 
			{
				return;
			}

			var midiControlInput:MidiControlInput = model.getMidiControlInput( command.midiControlInputID );
			Assert.assertNotNull( midiControlInput );
			
			addMidiViewItem( midiControlInput );
		}



		private function onMidiControlInputRemoved( command:RemoveMidiControlInput ):void
		{
			var midiControlInputID:int = command.midiControlInputID;
			if( !_midiItems.hasOwnProperty( midiControlInputID ) )
			{
				return;
			}
			
			removeMidiViewItem( midiControlInputID );
		}
		
		
		private function addMidiViewItem( midiControlInput:MidiControlInput ):void
		{
			Assert.assertNotNull( midiControlInput );
			var item:MidiItem = new MidiItem( midiControlInput.id );
			
			_midiItems[ midiControlInput.id ] = item;
			
			for( var insertionIndex:int = 0; insertionIndex < _vbox.numChildren - 1; insertionIndex++ )
			{
				var childID:int = ( _vbox.getChildAt( insertionIndex ) as MidiItem ).midiControlInputID;
				
				if( childID > midiControlInput.id )
				{
					break;
				}
			} 
			
			_vbox.addElementAt( item, insertionIndex );
		}
		
		
		private function removeMidiViewItem( midiControlInputID:int ):void
		{
			var midiItem:MidiItem = _midiItems[ midiControlInputID ];
			Assert.assertNotNull( midiItem );
			
			_vbox.removeChild( midiItem );
			midiItem.free();
			delete _midiItems[ midiControlInputID ];
		}
		
		
		private function onClickNewItemButton( event:MouseEvent ):void
		{
			var container:IntegraContainer = model.selectedContainer;
			Assert.assertNotNull( container );
			
			controller.processCommand( new AddMidiControlInput( container.id ) ); 
		}
		
		
		private var _containerID:int = -1;
		private var _vbox:VBox = new VBox;
		private var _newItemButton:Button = new Button;
				
		private var _midiItems:Object = new Object;		//maps midiControlInput ids to routing items

      	private const _padding:Number = 10;
	}
}