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
	
	import components.controller.ServerCommand;
	import components.controller.serverCommands.ImportBlock;
	import components.controller.serverCommands.ImportModule;
	import components.controller.serverCommands.ImportTrack;
	import components.controller.serverCommands.LoadModule;
	import components.controller.serverCommands.RemoveBlockImport;
	import components.controller.serverCommands.RemoveTrackImport;
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SwitchAllObjectVersions;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.serverCommands.SwitchObjectVersion;
	import components.controller.serverCommands.UnloadModule;
	import components.controller.userDataCommands.PollForUpgradableModules;
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.TextButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class UpgradeTab extends IntegraView
	{
		public function UpgradeTab()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    

			addUpdateMethod( SwitchModuleVersion, onUpdateNeeded );
			addUpdateMethod( SwitchObjectVersion, onUpdateNeeded );
			addUpdateMethod( LoadModule, onUpdateNeeded );
			addUpdateMethod( UnloadModule, onUpdateNeeded );
			addUpdateMethod( ImportModule, onUpdateNeeded );
			addUpdateMethod( ImportTrack, onUpdateNeeded );
			addUpdateMethod( ImportBlock, onUpdateNeeded );
			addUpdateMethod( RemoveTrackImport, onUpdateNeeded );
			addUpdateMethod( RemoveBlockImport, onUpdateNeeded );
			addUpdateMethod( RenameObject, onObjectRenamed );
			addUpdateMethod( PollForUpgradableModules, onPollForUpgradableModules );
			
			addEventListener( Event.RESIZE, onResize );
			
			addChild( _upgradeLabel );

			_upgradableModuleList.multiSelection = true;
			_upgradableModuleList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onItemSelected );
			_upgradableModuleList.addEventListener( ModuleManagerList.SELECTION_FINISHED_EVENT, onSelectionFinished );
			addChild( _upgradableModuleList );
			
			_upgradeAllButton.setStyle( "skin", TextButtonSkin );
			_upgradeAllButton.label = "Select All";
			_upgradeAllButton.toggle = true;
			_upgradeAllButton.addEventListener( MouseEvent.CLICK, onClickSelectAllButton );
			_upgradeAllButton.addEventListener( MouseEvent.DOUBLE_CLICK, onClickSelectAllButton );
			addChild( _upgradeAllButton );
			
			_upgradeButton.setStyle( "skin", TextButtonSkin );
			_upgradeButton.label = "Upgrade Modules";
			_upgradeButton.addEventListener( MouseEvent.CLICK, onClickUpgradeButton );
			addChild( _upgradeButton );
			
			addChild( _info );
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( Utilities.isEqualOrDescendant( event.target, _upgradableModuleList ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerUpgradeTabModuleList" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _upgradeAllButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerUpgradeTabSelectAllButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _upgradeButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerUpgradeTabUpgradeButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _info ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerUpgradeTabInfo" );
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
						setButtonTextColor( _upgradeButton, 0x6D6D6D, 0x9e9e9e );
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						setButtonTextColor( _upgradeButton, 0x939393, 0x626262 );
						break;
				}
				
				_upgradeLabel.setStyle( "color", _labelColor );
				
				_upgradeAllButton.setStyle( "color", _labelColor );
			}
		}
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		}
		
		
		private function onUpdateNeeded( command:ServerCommand ):void
		{
			if( !_updateFlagged )
			{
				/* this mechanism prevents multiple updates when many modules are switched */
				_updateFlagged = true;
				callLater( updateAll );
			}
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			deferInfoUpdate();
		}
		
		
		private function onPollForUpgradableModules( command:PollForUpgradableModules ):void
		{
			if( command.foundUpgradableModules )
			{
				_upgradableModuleList.selectAll();
				updateAll();
			}
		}
		
		
		private function updateAll():void
		{
			var selectedItems:Object = getSelectedItems();
			
			var upgradables:Vector.<ModuleManagerListItem> = upgradableModules;
			
			if( upgradables.length > 0 )
			{
				_upgradeLabel.text = "Improved versions available:";

				_upgradableModuleList.items = upgradables;

				setSelectedItems( selectedItems );				
				
				_upgradeAllButton.selected = _upgradableModuleList.allAreSelected;
				
				_upgradableModuleList.visible = true;
				_upgradeAllButton.visible = true;
				_info.visible = true;
				_upgradeButton.visible = true;
				_upgradeButton.enabled = _upgradableModuleList.anyAreSelected;
				
				deferInfoUpdate();
			}
			else
			{
				_upgradeLabel.text = "All modules are using the best available version";

				_upgradableModuleList.visible = false;
				_upgradeAllButton.visible = false;
				_info.visible = false;
				_upgradeButton.visible = false;
			}
			
			_updateFlagged = false;
		}
		
		
		private function getSelectedItems():Object
		{
			var selectedItems:Object = new Object;
			
			for each( var item:ModuleManagerListItem in _upgradableModuleList.items )
			{
				selectedItems[ item.guid ] = item.selected;
			}
			
			return selectedItems;
		}

		
		private function setSelectedItems( selectedItems:Object ):void
		{
			for each( var item:ModuleManagerListItem in _upgradableModuleList.items )
			{
				if( selectedItems.hasOwnProperty( item.guid ) )
				{
					item.selected = selectedItems[ item.guid ];
				}
				else
				{
					item.selected = true;
				}
			}
		}

		
		private function get internalMargin():Number
		{
			return FontSize.getTextRowHeight( this ) / 2;
		}
		
		
		private function get moduleListRect():Rectangle
		{
			return new Rectangle( internalMargin, internalMargin * 3, width / 3 - internalMargin * 1.5, height - internalMargin * 6 - FontSize.getTextRowHeight( this ) );
		}

		
		private function onResize( event:Event ):void
		{
			_upgradeLabel.x = internalMargin;
			_upgradeLabel.y = internalMargin;

			var moduleListRect:Rectangle = moduleListRect;

			var moduleListRectDeflated:Rectangle = moduleListRect.clone();
			moduleListRectDeflated.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			_upgradableModuleList.x = moduleListRectDeflated.x;
			_upgradableModuleList.y = moduleListRectDeflated.y;
			_upgradableModuleList.width = moduleListRectDeflated.width;
			_upgradableModuleList.height = moduleListRectDeflated.height;
			
			_upgradeAllButton.x = moduleListRect.x;
			_upgradeAllButton.y = moduleListRect.bottom + internalMargin * 2;
			_upgradeAllButton.width = moduleListRect.width;
			_upgradeAllButton.height = FontSize.getTextRowHeight( this );
			
			var rightPane:Rectangle = new Rectangle();
			rightPane.x = width / 3 + internalMargin * 1.5;
			rightPane.y = moduleListRect.y;
			rightPane.width = width - internalMargin - rightPane.x;
			rightPane.height = moduleListRect.height;

			_info.x = rightPane.x;
			_info.y = rightPane.y;
			_info.width = rightPane.width;
			_info.height = rightPane.height;
			
			_upgradeButton.x = rightPane.x;
			_upgradeButton.width = rightPane.width;
			_upgradeButton.height = FontSize.getTextRowHeight( this );
			_upgradeButton.y = rightPane.bottom + internalMargin * 2;
		}
		
		
		private function setButtonTextColor( button:Button, color:uint, disabledColor:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
			button.setStyle( "disabledColor", disabledColor );
		}
		
		
		private function get upgradableModules():Vector.<ModuleManagerListItem>
		{
			var upgradableModules:Vector.<ModuleManagerListItem> = new Vector.<ModuleManagerListItem>;

			var allModuleIDs:Object = new Object;
			model.project.getAllModuleGuidsInTree( allModuleIDs );

			for( var moduleGuid:String in allModuleIDs )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( moduleGuid );
				
				var interfaceDefinitions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
				
				if( interfaceDefinition != interfaceDefinitions[ 0 ] )
				{
					//we don't expect to encounter old versions of implemented-in-lib-integra modules
					Assert.assertFalse( interfaceDefinition.interfaceInfo.implementedInLibintegra );
					
					var item:ModuleManagerListItem = new ModuleManagerListItem;
					item.interfaceDefinition = interfaceDefinition;
					upgradableModules.push( item );
				}
			}
			
			upgradableModules.sort( moduleCompareFunction );

			return upgradableModules;
		}
		
		
		private function moduleCompareFunction( a:ModuleManagerListItem, b:ModuleManagerListItem ):Number
		{
			return a.compare( b );
		}		
		
		
		private function onItemSelected( event:Event ):void
		{
			_upgradeAllButton.selected = _upgradableModuleList.allAreSelected;
			_upgradeButton.enabled = _upgradableModuleList.anyAreSelected;
			
			_info.markdown = "";
		}
		
		
		private function onSelectionFinished( event:Event ):void
		{
			deferInfoUpdate();
		}
		
		
		private function onClickSelectAllButton( event:MouseEvent ):void
		{
			if( _upgradeAllButton.selected )
			{
				_upgradableModuleList.selectAll();
				_upgradeButton.enabled = true;
			}
			else
			{
				_upgradableModuleList.deselectAll();
				_upgradeButton.enabled = false;
			}
			
			deferInfoUpdate();
		}
		
		
		private function deferInfoUpdate():void
		{
			_info.markdown = "Updating...";
			callLater( callLater, [ updateInfo ] );			
		}
		
		
		private function onClickUpgradeButton( event:MouseEvent ):void
		{
			var items:Vector.<ModuleManagerListItem> = _upgradableModuleList.items;
				
			for each( var upgradeItem:ModuleManagerListItem in items )
			{
				if( !upgradeItem.selected ) 
				{
					continue;
				}
					
				var fromInterfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( upgradeItem.guid );
				Assert.assertNotNull( fromInterfaceDefinition );
				
				var alternativeVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( fromInterfaceDefinition.originGuid );
				Assert.assertTrue( alternativeVersions && alternativeVersions.length > 1 );
				
				var toInterfaceDefinition:InterfaceDefinition = alternativeVersions[ 0 ];

				Assert.assertTrue( toInterfaceDefinition != fromInterfaceDefinition && toInterfaceDefinition.originGuid == fromInterfaceDefinition.originGuid );

				controller.processCommand( new SwitchAllObjectVersions( fromInterfaceDefinition.moduleGuid, toInterfaceDefinition.moduleGuid ) );
			}
		}
		
		
		private function updateInfo():void
		{
			var infoGenerator:ModuleManagementInfoGenerator = new ModuleManagementInfoGenerator;
			
			var instanceNames:String = "";
			var upgradables:Vector.<ModuleManagerListItem> = _upgradableModuleList.items;
			for each( var item:ModuleManagerListItem in upgradables )
			{
				if( !item.selected ) continue;
				
				instanceNames += infoGenerator.getInstanceNames( item.interfaceDefinition );
			}
			
			if( instanceNames.length == 0 )
			{
				_info.markdown = "No modules are selected for upgrading";
				return;
			}
			
			var markdown:String = "##The following modules will be upgraded:\n\n" + instanceNames;
		
			for each( item in upgradables )
			{
				if( !item.selected ) continue;
				
				markdown += "\n\n##Upgrade summary for " + item.interfaceDefinition.interfaceInfo.label + "\n\n";
				
				var alternativeVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( item.interfaceDefinition.originGuid );
				Assert.assertTrue( alternativeVersions && alternativeVersions.length > 1 );
				
				var targetInterfaceDefinition:InterfaceDefinition = alternativeVersions[ 0 ];
				
				Assert.assertTrue( item.interfaceDefinition != targetInterfaceDefinition && item.interfaceDefinition.originGuid == targetInterfaceDefinition.originGuid );

				var sourceInterfaceDefinitions:Vector.<InterfaceDefinition> = new Vector.<InterfaceDefinition>;
				sourceInterfaceDefinitions.push( item.interfaceDefinition );
				
				markdown += infoGenerator.getModuleDifferenceSummary( sourceInterfaceDefinitions, targetInterfaceDefinition, "Best version" );
			}

			_info.markdown = markdown;
		}
		
		
		private var _upgradeLabel:Label = new Label;
		private var _upgradableModuleList:ModuleManagerList = new ModuleManagerList;
		
		private var _upgradeAllButton:Button = new Button;

		private var _upgradeButton:Button = new Button;

		private var _info:ModuleInfo = new ModuleInfo;
		
		private var _labelColor:uint;
		
		private var _updateFlagged:Boolean = false;
	}
}