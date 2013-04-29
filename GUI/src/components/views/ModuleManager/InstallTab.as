package components.views.ModuleManager
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.Text;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	
	import components.controller.moduleManagement.InstallEmbeddedModules;
	import components.controller.moduleManagement.InstallModules;
	import components.controller.moduleManagement.UninstallModules;
	import components.controller.userDataCommands.SetInstallResult;
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

			addUpdateMethod( SetInstallResult, onInstallResult );

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
			
			
			_installationReportLabel.text = "Installation Report:";
			
			addChild( _installationReportLabel );
			_installationReportLabel.visible = false;
			
			_installationReport.visible = false;
			_installationReport.setStyle( "borderStyle", "none" );
			_installationReport.setStyle( "paddingLeft", 20 );
			_installationReport.setStyle( "paddingRight", 20 );
			_installationReport.setStyle( "paddingTop", 20 );
			_installationReport.setStyle( "paddingBottom", 20 );
			addChild( _installationReport );

			_closeInstallationReportButton.visible = false;
			_closeInstallationReportButton.setStyle( "skin", TextButtonSkin );
			_closeInstallationReportButton.label = "OK";
			_closeInstallationReportButton.addEventListener( MouseEvent.CLICK, onCloseInstallationReport );
			addChild( _closeInstallationReportButton );
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
						setButtonTextColor( _closeInstallationReportButton, 0x6D6D6D, 0x9e9e9e );
						_installationReport.setStyle( "color", 0x000000 );
						_installationReport.setStyle( "backgroundColor", 0xcfcfcf );
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						setButtonTextColor( _installButton, 0x939393, 0x626262 );
						setButtonTextColor( _uninstallButton, 0x939393, 0x626262 );
						setButtonTextColor( _installEmbeddedButton, 0x939393, 0x626262 );
						setButtonTextColor( _closeInstallationReportButton, 0x939393, 0x626262 );
						_installationReport.setStyle( "color", 0xffffff );
						_installationReport.setStyle( "backgroundColor", 0x313131 );
						break;
				}
				
				_3rdPartyModulesLabel.setStyle( "color", _labelColor );
				_embeddedModulesLabel.setStyle( "color", _labelColor );
				_installationReportLabel.setStyle( "color", _labelColor );
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

			_installationReportLabel.x = internalMargin;
			_installationReportLabel.y = internalMargin;
			
			_installationReport.x = internalMargin;
			_installationReport.y = internalMargin * 3;
			_installationReport.width = width - internalMargin * 2;
			_installationReport.height = height - _installationReport.y - internalMargin * 2 - FontSize.getTextRowHeight( this );
			
			_closeInstallationReportButton.width = width / 3;
			_closeInstallationReportButton.height = FontSize.getTextRowHeight( this );
			_closeInstallationReportButton.y = height - internalMargin - _closeInstallationReportButton.height;
			_closeInstallationReportButton.setStyle( "horizontalCenter", 0 );
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
		
		
		private function onInstallResult( event:SetInstallResult ):void
		{
			_installationReport.text = event.installResult;
			showInstallationReport = true;	
		}
		
		
		private function set showInstallationReport( showReport:Boolean ):void
		{
			_3rdPartyModulesLabel.visible = !showReport;
			_embeddedModulesLabel.visible = !showReport;
			_3rdPartyModulesList.visible = !showReport;
			_embeddedModulesList.visible = !showReport;
			_installButton.visible = !showReport;
			_uninstallButton.visible = !showReport;
			_installEmbeddedButton.visible = !showReport;
			
			_installationReportLabel.visible = showReport;
			_installationReport.visible = showReport;
			_closeInstallationReportButton.visible = showReport;
		}
		
		
		private function onCloseInstallationReport( event:Event ):void
		{
			showInstallationReport = false;
		}
		
		
		private var _3rdPartyModulesLabel:Label = new Label;
		private var _embeddedModulesLabel:Label = new Label;

		private var _3rdPartyModulesList:ModuleManagerList = new ModuleManagerList;
		private var _embeddedModulesList:ModuleManagerList = new ModuleManagerList;
		
		private var _installButton:Button = new Button;
		private var _uninstallButton:Button = new Button;
		private var _installEmbeddedButton:Button = new Button;

		private var _installationReportLabel:Label = new Label;
		private var _installationReport:TextArea = new TextArea;
		private var _closeInstallationReportButton:Button = new Button;
		
		private var _labelColor:uint;
	}
}