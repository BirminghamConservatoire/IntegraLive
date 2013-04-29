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
	import components.controller.serverCommands.SwitchAllObjectVersions;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.serverCommands.SwitchObjectVersion;
	import components.controller.serverCommands.UnloadModule;
	import components.controller.userDataCommands.PollForUpgradableModules;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
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
			addUpdateMethod( PollForUpgradableModules, onPollForUpgradableModules );
			
			addEventListener( Event.RESIZE, onResize );
			
			addChild( _upgradeLabel );

			_upgradableModuleList.multiSelection = true;
			_upgradableModuleList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onItemSelected );
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
				_upgradeButton.visible = true;
				_upgradeButton.enabled = _upgradableModuleList.anyAreSelected;
			}
			else
			{
				_upgradeLabel.text = "All modules are using the best available version";

				_upgradableModuleList.visible = false;
				_upgradeAllButton.visible = false;
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
			return new Rectangle( internalMargin, internalMargin * 3, width / 2 - internalMargin * 1.5, height - internalMargin * 4 );
		}

		
		private function onResize( event:Event ):void
		{
			var moduleListRect:Rectangle = moduleListRect;
			var moduleListRectDeflated:Rectangle = moduleListRect.clone();
			moduleListRectDeflated.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			_upgradableModuleList.x = moduleListRectDeflated.x;
			_upgradableModuleList.y = moduleListRectDeflated.y;
			_upgradableModuleList.width = moduleListRectDeflated.width;
			_upgradableModuleList.height = moduleListRectDeflated.height;
			
			_upgradeLabel.x = internalMargin;
			_upgradeLabel.y = internalMargin;
			
			var rightPane:Rectangle = new Rectangle( moduleListRect.right + internalMargin, moduleListRect.y );
			rightPane.width = width - internalMargin - rightPane.x;
			rightPane.height = height - internalMargin - rightPane.y;
			
			_upgradeAllButton.x = rightPane.x;
			_upgradeAllButton.y = rightPane.y;
			_upgradeAllButton.width = rightPane.width;
			_upgradeAllButton.height = FontSize.getTextRowHeight( this );

			_upgradeButton.x = rightPane.x;
			_upgradeButton.width = rightPane.width;
			_upgradeButton.height = FontSize.getTextRowHeight( this );
			_upgradeButton.y = rightPane.bottom - _upgradeButton.height;
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

		
		private var _upgradeLabel:Label = new Label;
		private var _upgradableModuleList:ModuleManagerList = new ModuleManagerList;
		
		private var _upgradeAllButton:Button = new Button;

		private var _upgradeButton:Button = new Button;
		
		private var _labelColor:uint;
		
		private var _updateFlagged:Boolean = false;
	}
}