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

package components.views.InfoView
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Button;
	import mx.managers.PopUpManager;
	
	import spark.components.Application;
	
	import components.controller.serverCommands.SetObjectInfo;
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.views.IntegraView;
	import components.views.Skins.TextButtonSkin;
	
	import flexunit.framework.Assert;

	public class EditInfoButton extends IntegraView
	{
		public function EditInfoButton( info:Info, infoView:InfoView )
		{
			Assert.assertNotNull( info );
			Assert.assertTrue( info.canEdit );
			Assert.assertTrue( info.ownerID >= 0 );
			
			_info = info;
			_infoView = infoView;
			
			_editButton.label = "Edit";
			_editButton.setStyle( "skin", TextButtonSkin );
			_editButton.selected = false;
			addChild( _editButton );
			addEventListener( MouseEvent.CLICK, onClickEditButton );
			addEventListener( MouseEvent.DOUBLE_CLICK, onClickEditButton );
			addEventListener( Event.REMOVED_FROM_STAGE, closeInfoEditor );
			
			addUpdateMethod( SetObjectInfo, onSetObjectInfo );
		}

		
		public function showEditor():void
		{
			Assert.assertNull( _infoEditor );
			
			_infoEditor = new InfoEditor( "Edit Info for " + _info.title, _info.ownerID );
			
			var myRect:Rectangle = getRect( application );
			_infoEditor.width = 350;
			_infoEditor.height = 250;
			_infoEditor.x = myRect.right - _infoEditor.width;
			_infoEditor.y = myRect.y - _infoEditor.height - 2;
			
			_infoEditor.addEventListener( InfoEditor.CLOSE_INFO_EDITOR, closeInfoEditor );
			_infoEditor.markdown = _info.markdown;
			
			PopUpManager.addPopUp( _infoEditor, application );
			PopUpManager.bringToFront( _infoEditor );
			
			_editButton.selected = true;
		}
		
		
		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( _infoEditor ) 
			{
				_infoEditor.onStyleChanged( style );
			}
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						setButtonTextColor( _editButton, 0x6D6D6D );
						
						break;
					
					case ColorScheme.DARK:
						setButtonTextColor( _editButton, 0x939393 );
						
						break;
				}
				
				invalidateDisplayList();
			}
		}
		
		
		override protected function onAllDataChanged():void
		{
			if( _infoEditor ) _infoEditor.markdown = _info.markdown;
		}
			
		
		private function onSetObjectInfo( command:SetObjectInfo ):void
		{
			if( _infoEditor && command.objectID == _info.ownerID )
			{
				_infoEditor.markdown = _info.markdown;
			}
		}

		
		private function onClickEditButton( event:MouseEvent ):void
		{
			if( isEditing )
			{
				hideEditor();
			}
			else
			{
				showEditor();
			}
		}
		
		
		private function setButtonTextColor( button:Button, color:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
		}
		
		
		private function get isEditing():Boolean
		{
			return ( _infoEditor != null );
		}
		
		
		private function hideEditor():void
		{
			Assert.assertNotNull( _infoEditor );

			var toRemove:InfoEditor = _infoEditor;
			_infoEditor = null;
			
			PopUpManager.removePopUp( toRemove );
			
			callLater( _infoView.setFocus );
			
			_editButton.selected = false;
		}
		
		
		private function closeInfoEditor( event:Event ):void
		{
			if( _infoEditor )
			{
				hideEditor();
			}
		}
		
		
		private function get application():Application
		{
			for( var iterator:DisplayObjectContainer = this; iterator; iterator = iterator.parent )
			{
				if( iterator is Application ) return iterator as Application;
			}
			
			Assert.assertTrue( false );
			return null;
		}
		
		

		private var _editButton:Button = new Button;

		private var _infoEditor:InfoEditor = null;
		
		private var _info:Info = null;
		private var _infoView:InfoView = null;
		
		private static const _editButtonText:String = "Edit";
	}
}