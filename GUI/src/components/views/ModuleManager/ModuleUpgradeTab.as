package components.views.ModuleManager
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.controls.Alert;
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
	import components.controller.serverCommands.SwitchAllModuleVersions;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.serverCommands.UnloadModule;
	import components.model.Block;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.libraries.Library;
	import components.utils.libraries.LibraryItem;
	import components.views.IntegraView;
	import components.views.Skins.TextButtonSkin;
	import components.views.Skins.TickButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class ModuleUpgradeTab extends IntegraView
	{
		public function ModuleUpgradeTab()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    

			addUpdateMethod( SwitchModuleVersion, onUpdateNeeded );
			addUpdateMethod( LoadModule, onUpdateNeeded );
			addUpdateMethod( UnloadModule, onUpdateNeeded );
			addUpdateMethod( ImportModule, onUpdateNeeded );
			addUpdateMethod( ImportTrack, onUpdateNeeded );
			addUpdateMethod( ImportBlock, onUpdateNeeded );
			addUpdateMethod( RemoveTrackImport, onUpdateNeeded );
			addUpdateMethod( RemoveBlockImport, onUpdateNeeded );
			
			addEventListener( Event.RESIZE, onResize );
			
			addChild( _upgradeLabel );
			
			_upgradableModuleList.setStyle( "borderThickness", _listBorder );
			_upgradableModuleList.setStyle( "cornerRadius", _listBorder );
			_upgradableModuleList.addEventListener( LibraryItem.TICK_EVENT, onItemTicked );
			addChild( _upgradableModuleList );
			
			_upgradeAllLabel.text = "Upgrade All";
			addChild( _upgradeAllLabel );
			
			_upgradeAllButton.setStyle( "skin", TickButtonSkin );
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
						_controlBackgroundColor = 0xcfcfcf;
						setButtonTextColor( _upgradeButton, 0x6D6D6D, 0x9e9e9e );
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						_controlBackgroundColor = 0x313131;
						setButtonTextColor( _upgradeButton, 0x939393, 0x626262 );
						break;
				}
				
				_upgradeLabel.setStyle( "color", _labelColor );
				_upgradeAllLabel.setStyle( "color", _labelColor );
				
				_upgradableModuleList.setStyle( "borderColor", _controlBackgroundColor );
				_upgradableModuleList.setStyle( "backgroundColor", _controlBackgroundColor );
				
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
		
		
		private function updateAll():void
		{
			var upgradables:Array = upgradableModules;
			
			if( upgradables.length > 0 )
			{
				_upgradeLabel.text = "Improved versions available:";

				_upgradableModuleList.data = upgradables;
				
				_upgradeAllButton.selected = allAreTicked;
				
				_upgradableModuleList.visible = true;
				_upgradeAllLabel.visible = true;
				_upgradeAllButton.visible = true;
				_upgradeButton.visible = true;
				_upgradeButton.enabled = anyAreTicked;
			}
			else
			{
				_upgradeLabel.text = "All modules are using the best available version";

				_upgradableModuleList.visible = false;
				_upgradeAllLabel.visible = false;
				_upgradeAllButton.visible = false;
				_upgradeButton.visible = false;
			}
			
			_updateFlagged = false;
		}

		
		private function get internalMargin():Number
		{
			return FontSize.getTextRowHeight( this ) / 2;
		}
		
		
		private function get moduleListRect():Rectangle
		{
			return new Rectangle( internalMargin, internalMargin * 2, width / 2 - internalMargin * 1.5, height - internalMargin * 3 );
		}

		
		private function onResize( event:Event ):void
		{
			var moduleListRect:Rectangle = moduleListRect;
			moduleListRect.inflate( -_listBorder, -_listBorder );
			_upgradableModuleList.x = moduleListRect.x;
			_upgradableModuleList.y = moduleListRect.y;
			_upgradableModuleList.width = moduleListRect.width;
			_upgradableModuleList.height = moduleListRect.height;
			
			_upgradeLabel.x = internalMargin;
			_upgradeLabel.y = internalMargin;
			
			var rightPane:Rectangle = new Rectangle( moduleListRect.right + internalMargin, moduleListRect.y );
			rightPane.width = width - internalMargin - rightPane.x;
			rightPane.height = height - internalMargin - rightPane.y;
			
			_upgradeAllButton.x = rightPane.x;
			_upgradeAllButton.y = rightPane.y;
			_upgradeAllButton.width = FontSize.getButtonSize( this );
			_upgradeAllButton.height = FontSize.getButtonSize( this );

			_upgradeAllLabel.x = rightPane.x + FontSize.getButtonSize( this );
			_upgradeAllLabel.y = rightPane.y;
			
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
		
		
		private function get upgradableModules():Array
		{
			var upgradableModules:Array = new Array;
			var moduleIDsAddedMap:Object = new Object;
			
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					for each( var module:ModuleInstance in block.modules )
					{
						var interfaceDefinition:InterfaceDefinition = module.interfaceDefinition;
						
						if( moduleIDsAddedMap.hasOwnProperty( interfaceDefinition.moduleGuid ) )
						{
							continue;
						}
						
						var interfaceDefinitions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
						Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
						
						if( interfaceDefinition != interfaceDefinitions[ 0 ] )
						{
							var listEntry:ModuleManagerListEntry = new ModuleManagerListEntry( interfaceDefinition );
							upgradableModules.push( listEntry );
							
							moduleIDsAddedMap[ interfaceDefinition.moduleGuid ] = 1;
						}
					}
				}
			}
			
			upgradableModules.sort( moduleCompareFunction );

			return upgradableModules;
		}
		
		
		private function moduleCompareFunction( a:ModuleManagerListEntry, b:ModuleManagerListEntry ):Number
		{
			return a.compare( b );
		}		
		
		
		private function get allAreTicked():Boolean
		{
			for( var i:int = 0; i < _upgradableModuleList.numChildren; i++ )
			{
				if( !_upgradableModuleList.getLibraryItemAt( i ).ticked ) 
				{
					return false;
				}
			}
			
			return true;
		}

		
		private function get anyAreTicked():Boolean
		{
			for( var i:int = 0; i < _upgradableModuleList.numChildren; i++ )
			{
				if( _upgradableModuleList.getLibraryItemAt( i ).ticked ) 
				{
					return true;
				}
			}
			
			return false;
		}
		
		
		private function onItemTicked( event:Event ):void
		{
			_upgradeAllButton.selected = allAreTicked;
			_upgradeButton.enabled = anyAreTicked;
		}
		
		
		private function onClickSelectAllButton( event:MouseEvent ):void
		{
			for( var i:int = 0; i < _upgradableModuleList.numChildren; i++ )
			{
				_upgradableModuleList.getLibraryItemAt( i ).ticked = _upgradeAllButton.selected;
			}
			
			_upgradeButton.enabled = _upgradeAllButton.selected;
		}
		
		
		private function onClickUpgradeButton( event:MouseEvent ):void
		{
			var data:Array = _upgradableModuleList.data as Array;
				
			for each( var upgradeItem:ModuleManagerListEntry in _upgradableModuleList.data as Array )
			{
				if( !upgradeItem.ticked ) 
				{
					continue;
				}
					
				var fromInterfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( upgradeItem.guid );
				Assert.assertNotNull( fromInterfaceDefinition );
				
				var alternativeVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( fromInterfaceDefinition.originGuid );
				Assert.assertTrue( alternativeVersions && alternativeVersions.length > 1 );
				
				var toInterfaceDefinition:InterfaceDefinition = alternativeVersions[ 0 ];

				Assert.assertTrue( toInterfaceDefinition != fromInterfaceDefinition && toInterfaceDefinition.originGuid == fromInterfaceDefinition.originGuid );

				controller.processCommand( new SwitchAllModuleVersions( fromInterfaceDefinition.moduleGuid, toInterfaceDefinition.moduleGuid ) );
			}
		}
		
		
		private var _upgradeLabel:Label = new Label;
		private var _upgradableModuleList:Library = new Library;
		
		private var _upgradeAllLabel:Label = new Label;
		private var _upgradeAllButton:Button = new Button;

		private var _upgradeButton:Button = new Button;
		
		private var _controlBackgroundColor:uint;
		private var _labelColor:uint;
		
		private var _updateFlagged:Boolean = false;
		
		private static const _listBorder:Number = 4;
	}
}