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


package components.views.ModuleManager
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	
	import components.controller.moduleManagement.InstallEmbeddedModules;
	import components.controller.moduleManagement.InstallModules;
	import components.controller.moduleManagement.UninstallModules;
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.InterfaceInfo;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.TextButtonSkin;
	
	
	public class InstallTab extends IntegraView
	{
		public function InstallTab()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    

			addEventListener( Event.RESIZE, onResize );

			addChild( _3rdPartyModulesLabel );
			addChild( _embeddedModulesLabel );
			
			_3rdPartyModulesLabel.text = "Installed 3rd party modules:";
			_3rdPartyModulesList.multiSelection = true;
			_3rdPartyModulesList.addEventListener( ModuleManagerListItem.SELECT_EVENT, on3rdPartySelected );
			addChild( _3rdPartyModulesList );
			
			_embeddedModulesLabel.text = "Embedded modules:";
			_embeddedModulesList.multiSelection = true;
			_embeddedModulesList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onEmbeddedSelected );
			addChild( _embeddedModulesList );

			_installButton.setStyle( "skin", TextButtonSkin );
			_installButton.label = "Install From File";
			_installButton.addEventListener( MouseEvent.CLICK, onClickInstallButton );
			addChild( _installButton );

			_uninstallButton.setStyle( "skin", TextButtonSkin );
			_uninstallButton.label = "Uninstall";
			_uninstallButton.addEventListener( MouseEvent.CLICK, onClickUninstallButton );
			addChild( _uninstallButton );
			
			_installEmbeddedButton.setStyle( "skin", TextButtonSkin );
			_installEmbeddedButton.label = "Install To Disk";
			_installEmbeddedButton.addEventListener( MouseEvent.CLICK, onClickInstallEmbeddedButton );
			addChild( _installEmbeddedButton );
			
			_info.setStyle( "borderStyle", "solid" );
			_info.setStyle( "borderThickness", 2 );
			_info.setStyle( "cornerRadius", ModuleManagerList.cornerRadius );
			addChild( _info );
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( Utilities.isEqualOrDescendant( event.target, _3rdPartyModulesList ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerInstallTab3rdPartyList" );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _embeddedModulesList ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerInstallTabEmbeddedList" );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _installButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerInstallTabInstallButton" );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _uninstallButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerInstallTabUninstallButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _installEmbeddedButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerInstallTabInstallEmbeddedButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _info ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerInstallTabInfo" );
			}
			
			return null;
		}		
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_labelColor = 0x747474;
						setButtonTextColor( _installButton, 0x6D6D6D, 0x9e9e9e );
						setButtonTextColor( _uninstallButton, 0x6D6D6D, 0x9e9e9e );
						setButtonTextColor( _installEmbeddedButton, 0x6D6D6D, 0x9e9e9e );
						_info.setStyle( "borderColor", 0xcfcfcf );
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						setButtonTextColor( _installButton, 0x939393, 0x626262 );
						setButtonTextColor( _uninstallButton, 0x939393, 0x626262 );
						setButtonTextColor( _installEmbeddedButton, 0x939393, 0x626262 );
						_info.setStyle( "borderColor", 0x313131 );
						break;
				}
				
				_3rdPartyModulesLabel.setStyle( "color", _labelColor );
				_embeddedModulesLabel.setStyle( "color", _labelColor );
			}
		}
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		}
		
		
		private function updateAll():void
		{
			_3rdPartyModulesList.items = getModulesBySource( InterfaceDefinition.MODULE_THIRD_PARTY );
			updateUninstallEnable();
				
			_embeddedModulesList.items = getModulesBySource( InterfaceDefinition.MODULE_EMBEDDED );
			updateInstallEmbeddedEnable();
			
			updateInfo();
		}

		
		private function get internalMargin():Number
		{
			return FontSize.getTextRowHeight( this ) / 2;
		}
		
		
		private function get thirdPartyListRect():Rectangle
		{
			return new Rectangle( internalMargin, internalMargin * 3, width / 3 - internalMargin * 2, height - internalMargin * 4 );
		}

		
		private function onResize( event:Event ):void
		{
			var thirdPartyListRect:Rectangle = thirdPartyListRect;
			var thirdPartyListRectDeflated:Rectangle = thirdPartyListRect.clone();
			thirdPartyListRectDeflated.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			_3rdPartyModulesList.x = thirdPartyListRectDeflated.x;
			_3rdPartyModulesList.y = thirdPartyListRectDeflated.y;
			_3rdPartyModulesList.width = thirdPartyListRectDeflated.width;
			_3rdPartyModulesList.height = thirdPartyListRectDeflated.height - internalMargin * 2 - FontSize.getTextRowHeight( this );
			
			_3rdPartyModulesLabel.x = internalMargin;
			_3rdPartyModulesLabel.y = internalMargin;

			_uninstallButton.x = thirdPartyListRect.x;
			_uninstallButton.width = thirdPartyListRect.width;
			_uninstallButton.height = FontSize.getTextRowHeight( this );
			_uninstallButton.y = thirdPartyListRect.bottom - FontSize.getTextRowHeight( this );
			
			var rightPane:Rectangle = thirdPartyListRect.clone();
			rightPane.offset( width / 3, 0 );

			_embeddedModulesLabel.x = rightPane.x;
			_embeddedModulesLabel.y = internalMargin;
			
			var embeddedModulesRect:Rectangle = rightPane.clone();
			embeddedModulesRect.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			embeddedModulesRect.height -= FontSize.getTextRowHeight( this ) * 2 + internalMargin * 4;
			_embeddedModulesList.x = embeddedModulesRect.x;
			_embeddedModulesList.y = embeddedModulesRect.y;
			_embeddedModulesList.width = embeddedModulesRect.width;
			_embeddedModulesList.height = embeddedModulesRect.height;
			
			_installEmbeddedButton.x = rightPane.x;
			_installEmbeddedButton.width = rightPane.width;
			_installEmbeddedButton.height = FontSize.getTextRowHeight( this );
			_installEmbeddedButton.y = rightPane.bottom - internalMargin * 2 - FontSize.getTextRowHeight( this ) * 2;

			_installButton.x = rightPane.x;
			_installButton.width = rightPane.width;
			_installButton.height = FontSize.getTextRowHeight( this );
			_installButton.y = rightPane.bottom - _installEmbeddedButton.height;

			rightPane.offset( width / 3, 0 );
			_info.x = rightPane.x;
			_info.y = rightPane.y;
			_info.width = rightPane.width;
			_info.height = rightPane.height;
		}
		
		
		private function setButtonTextColor( button:Button, color:uint, disabledColor:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
			button.setStyle( "disabledColor", disabledColor );
		}
		
		
		private function getModulesBySource( moduleSource:String ):Vector.<ModuleManagerListItem>
		{
			var modules:Vector.<ModuleManagerListItem> = new Vector.<ModuleManagerListItem>;

			for each( var moduleGuid:String in model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( moduleGuid );
				if( interfaceDefinition.moduleSource == moduleSource )
				{
					var item:ModuleManagerListItem = new ModuleManagerListItem;
					item.interfaceDefinition = interfaceDefinition;
					modules.push( item );
				}
			}
			
			
			modules.sort( moduleCompareFunction );

			return modules;
		}
		
		
		private function moduleCompareFunction( a:ModuleManagerListItem, b:ModuleManagerListItem ):Number
		{
			return a.compare( b );
		}		
		
		
		private function on3rdPartySelected( event:Event ):void
		{
			updateUninstallEnable();
			
			_embeddedModulesList.deselectAll();
			updateInstallEmbeddedEnable();
			
			updateInfo();
		}
		
		
		private function onEmbeddedSelected( event:Event ):void
		{
			updateInstallEmbeddedEnable();
			
			_3rdPartyModulesList.deselectAll();
			updateUninstallEnable();
			
			updateInfo();
		}
		
		
		private function updateUninstallEnable():void
		{
			_uninstallButton.enabled = _3rdPartyModulesList.anyAreSelected;
		}

		
		private function updateInstallEmbeddedEnable():void
		{
			_installEmbeddedButton.enabled = _embeddedModulesList.anyAreSelected;
		}
		
		
		private function onClickInstallButton( event:MouseEvent ):void
		{
			InstallModules.doFileDialog();
		}

		
		private function onClickUninstallButton( event:MouseEvent ):void
		{
			var moduleGuidsToUninstall:Vector.<String> = new Vector.<String>;
			
			for each( var item:ModuleManagerListItem in _3rdPartyModulesList.items )
			{
				if( item.selected )
				{
					moduleGuidsToUninstall.push( item.guid );
				}
			}
						
			UninstallModules.doFileDialog( model, moduleGuidsToUninstall );
		}

		
		private function onClickInstallEmbeddedButton( event:MouseEvent ):void
		{
			var embeddedModulesGuidsToInstall:Vector.<String> = new Vector.<String>;
			
			for each( var item:ModuleManagerListItem in _embeddedModulesList.items )
			{
				if( item.selected )
				{
					embeddedModulesGuidsToInstall.push( item.guid );
				}
			}
			
			controller.activateUndoStack = false;
			controller.processCommand( new InstallEmbeddedModules( embeddedModulesGuidsToInstall ) );
			controller.activateUndoStack = true;
		}
		
		
		private function updateInfo():void
		{
			var markdown:String = null;
			
			var selectedItems:Vector.<ModuleManagerListItem> = _3rdPartyModulesList.selectedItems;
			if( selectedItems.length > 0 )
			{
				if( selectedItems.length > 1 )
				{
					markdown = "More than one module is selected";
				}
				else
				{
					markdown = makeInfoMarkdown( selectedItems[ 0 ].interfaceDefinition );
				}
			}
			else
			{
				selectedItems = _embeddedModulesList.selectedItems;

				if( selectedItems.length > 0 )
				{
					if( selectedItems.length > 1 )
					{
						markdown = "More than one module is selected";
					}
					else
					{
						markdown = makeInfoMarkdown( selectedItems[ 0 ].interfaceDefinition );
					}
				}
				else
				{
					markdown = "No modules are selected";
				}
			}
			
			_info.markdown = markdown;
		}
		
		
		private function makeInfoMarkdown( interfaceDefinition:InterfaceDefinition ):String
		{
			var interfaceInfo:InterfaceInfo = interfaceDefinition.interfaceInfo;
			
			var markdown:String = "##![](app:/icons/module_48x48x32.png) " + interfaceInfo.label + "\n\n";
			
			markdown += interfaceInfo.description + "\n\n";
			
			markdown += "**Last modified:** " + interfaceInfo.modifiedDateLabel + "\n\n";
			markdown += "**Author:** " + interfaceInfo.authorLabel + "\n\n";
			
			return markdown;			
		}
		
		
		private var _3rdPartyModulesLabel:Label = new Label;
		private var _embeddedModulesLabel:Label = new Label;

		private var _3rdPartyModulesList:ModuleManagerList = new ModuleManagerList;
		private var _embeddedModulesList:ModuleManagerList = new ModuleManagerList;
		
		private var _installButton:Button = new Button;
		private var _uninstallButton:Button = new Button;
		private var _installEmbeddedButton:Button = new Button;

		private var _info:ModuleInfo = new ModuleInfo;
		
		private var _labelColor:uint;
	}
}