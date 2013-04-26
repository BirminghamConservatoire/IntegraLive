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
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.IntegraView;
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

			_3rdPartyModulesLabel.text = "3rd party modules:";
			_3rdPartyModulesList.multiSelection = true;
			_3rdPartyModulesList.addEventListener( ModuleManagerListItem.SELECT_EVENT, on3rdPartySelected );
			addChild( _3rdPartyModulesList );
			
			_embeddedModulesLabel.text = "Embedded modules:";
			_embeddedModulesList.multiSelection = true;
			_embeddedModulesList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onEmbeddedSelected );
			addChild( _embeddedModulesList );

			_installButton.setStyle( "skin", TextButtonSkin );
			_installButton.label = "Install From Disk";
			_installButton.addEventListener( MouseEvent.CLICK, onClickInstallButton );
			addChild( _installButton );

			_uninstallButton.setStyle( "skin", TextButtonSkin );
			_uninstallButton.label = "Uninstall Selected Modules";
			_uninstallButton.addEventListener( MouseEvent.CLICK, onClickUninstallButton );
			addChild( _uninstallButton );
			
			_installEmbeddedButton.setStyle( "skin", TextButtonSkin );
			_installEmbeddedButton.label = "Install Embedded Modules";
			_installEmbeddedButton.addEventListener( MouseEvent.CLICK, onClickInstallEmbeddedButton );
			addChild( _installEmbeddedButton );
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
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						setButtonTextColor( _installButton, 0x939393, 0x626262 );
						setButtonTextColor( _uninstallButton, 0x939393, 0x626262 );
						setButtonTextColor( _installEmbeddedButton, 0x939393, 0x626262 );
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
			var thirdPartyModules:Vector.<ModuleManagerListItem> = getModulesBySource( InterfaceDefinition.MODULE_THIRD_PARTY );
			
			if( thirdPartyModules.length > 0 )
			{
				_3rdPartyModulesList.items = thirdPartyModules;
				
				_embeddedModulesList.removeAllItems();
				
				updateUninstallEnable();
			}

			var embeddedModules:Vector.<ModuleManagerListItem> = getModulesBySource( InterfaceDefinition.MODULE_EMBEDDED );
			
			if( embeddedModules.length > 0 )
			{
				_embeddedModulesList.items = embeddedModules;
				
				updateInstallEmbeddedEnable();
			}
		}

		
		private function get internalMargin():Number
		{
			return FontSize.getTextRowHeight( this ) / 2;
		}
		
		
		private function get thirdPartyListRect():Rectangle
		{
			return new Rectangle( internalMargin, internalMargin * 3, width / 2 - internalMargin * 1.5, height - internalMargin * 6 );
		}

		
		private function onResize( event:Event ):void
		{
			var thirdPartyListRect:Rectangle = thirdPartyListRect;
			var thirdPartyListRectDeflated:Rectangle = thirdPartyListRect.clone();
			thirdPartyListRectDeflated.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			_3rdPartyModulesList.x = thirdPartyListRectDeflated.x;
			_3rdPartyModulesList.y = thirdPartyListRectDeflated.y;
			_3rdPartyModulesList.width = thirdPartyListRectDeflated.width;
			
			_3rdPartyModulesLabel.x = internalMargin;
			_3rdPartyModulesLabel.y = internalMargin;
			
			var rightPane:Rectangle = thirdPartyListRect.clone();
			rightPane.offset( width - rightPane.right - internalMargin, 0 );

			_embeddedModulesLabel.x = rightPane.x;
			_embeddedModulesLabel.y = internalMargin;
			
			var embeddedModulesRect:Rectangle = rightPane.clone();
			embeddedModulesRect.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			embeddedModulesRect.height -= FontSize.getTextRowHeight( this ) * 2;
			_embeddedModulesList.x = embeddedModulesRect.x;
			_embeddedModulesList.y = embeddedModulesRect.y;
			_embeddedModulesList.width = embeddedModulesRect.width;
			
			_installButton.x = thirdPartyListRect.x;
			_installButton.width = thirdPartyListRect.width;
			_installButton.height = FontSize.getTextRowHeight( this );
			_installButton.y = height - internalMargin - _installButton.height;

			_uninstallButton.x = thirdPartyListRect.x;
			_uninstallButton.width = thirdPartyListRect.width;
			_uninstallButton.height = FontSize.getTextRowHeight( this );
			_uninstallButton.y = _installButton.y - internalMargin - _uninstallButton.height;

			_installEmbeddedButton.x = rightPane.x;
			_installEmbeddedButton.width = rightPane.width;
			_installEmbeddedButton.height = FontSize.getTextRowHeight( this );
			_installEmbeddedButton.y = height - internalMargin - _installEmbeddedButton.height;

			_3rdPartyModulesList.height = _uninstallButton.y - internalMargin - _3rdPartyModulesList.y - ModuleManagerList.cornerRadius;
			_embeddedModulesList.height = _installEmbeddedButton.y - internalMargin - _embeddedModulesList.y - ModuleManagerList.cornerRadius;
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
		}
		
		
		private function onEmbeddedSelected( event:Event ):void
		{
			updateInstallEmbeddedEnable();
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
		
		
		private var _3rdPartyModulesLabel:Label = new Label;
		private var _embeddedModulesLabel:Label = new Label;

		private var _3rdPartyModulesList:ModuleManagerList = new ModuleManagerList;
		private var _embeddedModulesList:ModuleManagerList = new ModuleManagerList;
		
		private var _installButton:Button = new Button;
		private var _uninstallButton:Button = new Button;
		private var _installEmbeddedButton:Button = new Button;
		
		private var _labelColor:uint;
	}
}