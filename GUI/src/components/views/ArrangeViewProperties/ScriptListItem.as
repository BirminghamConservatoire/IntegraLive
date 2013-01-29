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
	import components.controller.serverCommands.RemoveScript;
	import components.controller.serverCommands.RenameObject;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.Script;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.Skins.CloseButtonSkin;
	
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	
	import mx.controls.Button;
	import mx.controls.TextInput;
	import mx.core.ScrollPolicy;
	
	public class ScriptListItem extends IntegraView
	{
		public function ScriptListItem( scriptID:int )
		{
			super();
			
			_scriptID = scriptID;
			
			verticalScrollPolicy = ScrollPolicy.OFF;   
			horizontalScrollPolicy = ScrollPolicy.OFF; 
			
			_nameEdit.percentHeight = 100;
			_nameEdit.setStyle( "left", 0 );
			_nameEdit.setStyle( "top", 4 );
			_nameEdit.setStyle( "bottom", 0 );
			_nameEdit.setStyle( "borderStyle", "none" );
			_nameEdit.setStyle( "focusAlpha", 0 );
			_nameEdit.setStyle( "backgroundAlpha", 0 );

			_nameEdit.addEventListener( MouseEvent.DOUBLE_CLICK, onOpenNameEdit );
			_nameEdit.addEventListener( FocusEvent.FOCUS_OUT, onNameEditChange );
			_nameEdit.addEventListener( KeyboardEvent.KEY_UP, onNameEditKeyUp );
			_nameEdit.restrict = IntegraDataObject.legalObjectNameCharacterSet;

			addEventListener( MouseEvent.MOUSE_OVER, onMouseOverNameEdit );
			addEventListener( MouseEvent.MOUSE_OUT, onMouseOutNameEdit );
			addEventListener( MouseEvent.CLICK, onClickNameEdit );

			setNameEditable( false );
			addChild( _nameEdit );
			
			_deleteButton.setStyle( "skin", CloseButtonSkin );
			_deleteButton.setStyle( "fillAlpha", 1 );
			_deleteButton.setStyle( "right", 5 );
			_deleteButton.setStyle( "verticalCenter", 0 );
			_deleteButton.toolTip = "Delete Script";
			addChild( _deleteButton );
		
			addUpdateMethod( RenameObject, onObjectRenamed );
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
		}
		
	
		public function get scriptID():int { return _scriptID; }


		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				updateSelection();
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_deleteButton.setStyle( "color", 0xcfcfcf );
						_deleteButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_deleteButton.setStyle( "color", 0x313131 );
						_deleteButton.setStyle( "fillColor", 0x8c8c8c );
						break;
						
					default:
						return;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				var rowHeight:Number = FontSize.getTextRowHeight( this ); 
				height = rowHeight + 4;
				_nameEdit.setStyle( "right", rowHeight + 10 );
				_deleteButton.width = FontSize.getButtonSize( this );
				_deleteButton.height = FontSize.getButtonSize( this );
			}
		}


		override protected function onAllDataChanged():void
		{
			updateNameEdit();
			updateSelection();
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			if( command.objectID == _scriptID )
			{
				updateNameEdit();
			}
		}
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			updateSelection();
		}


		private function onMouseOverNameEdit( event:MouseEvent ):void
		{
			if( !event.buttonDown )
			{
				_mouseOver = true;
				updateBackgroundColor();
			}
		}


		private function onMouseOutNameEdit( event:MouseEvent ):void
		{
			_mouseOver = false;
			updateBackgroundColor();
		}
		
		
		private function onClickNameEdit( event:MouseEvent ):void
		{
			if( event.target == _deleteButton ) 
			{
				controller.processCommand( new RemoveScript( _scriptID ) );
			}
			else
			{
				var parent:IntegraContainer = model.getContainerFromScript( _scriptID );
				Assert.assertNotNull( parent );
				controller.processCommand( new SetPrimarySelectedChild( parent.id, _scriptID ) );
			}
		}
		
		
		private function onOpenNameEdit( event:MouseEvent ):void
		{
			setNameEditable( true );
		}

		
		private function onNameEditChange( event:FocusEvent ):void
		{
			var newName:String = _nameEdit.text;
			setNameEditable( false );
			updateNameEdit();

			controller.processCommand( new RenameObject( _scriptID, newName ) );
		}
		
		
		private function onNameEditKeyUp( event:KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case Keyboard.ENTER:
					setFocus();					//force changes to be committed
					break;

				case Keyboard.ESCAPE:
					updateNameEdit();			//reject changes
					setNameEditable( false );
					break;
					
				default:
					break;
			} 
		}		
		
		
		private function updateNameEdit():void
		{
			var script:Script = model.getScript( _scriptID );
			Assert.assertNotNull( script );
			
			 _nameEdit.text = script.name;
		}
		
		
		private function updateSelection():void
		{
			_selected = false;
			if( model.selectedScript )
			{
				_selected = ( _scriptID == model.selectedScript.id );
			}
			
			alpha = _selected ? 1 : 0.8; 

			var textColor:uint = 0;
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				case ColorScheme.LIGHT:
					textColor = _selected ? 0x000000 : 0x404040;
					break;
					
				case ColorScheme.DARK:
					textColor = _selected ? 0xffffff : 0xc0c0c0;
					break;
					
				default:
					return;
			}

			_nameEdit.setStyle( "color", textColor );
			_nameEdit.setStyle( "disabledColor", textColor );
			
			updateBackgroundColor();
		}
		
		
		private function updateBackgroundColor():void
		{
			if( _mouseOver || _selected )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						opaqueBackground = 0xb0b0b0;
						break;
						
					case ColorScheme.DARK:
						opaqueBackground = 0x505050;
						break;
						
					default:
						break;
				}
			}
			else
			{
				opaqueBackground = null;
			}
		}
		
		
		private function setNameEditable( editable:Boolean ):void
		{
			_nameEdit.editable = editable;			
			_nameEdit.focusEnabled = editable;
			_nameEdit.enabled = editable;
			
			if( editable )
			{
				_nameEdit.selectionBeginIndex = 0;
				_nameEdit.selectionEndIndex = _nameEdit.text.length;
				_nameEdit.setFocus();
			}
		}				
		
		
		private var _mouseOver:Boolean = false;
		private var _scriptID:int = -1;
		private var _selected:Boolean = false;

		private var _nameEdit:TextInput = new TextInput;
		private var _deleteButton:Button = new Button;
	}
}