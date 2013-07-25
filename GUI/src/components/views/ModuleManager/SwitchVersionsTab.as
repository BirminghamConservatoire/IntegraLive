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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	import mx.events.ScrollEvent;
	
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
	import components.controller.serverCommands.UpgradeModules;
	import components.model.Info;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CheckBoxTickIcon;
	import components.views.Skins.TextButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class SwitchVersionsTab extends IntegraView
	{
		public function SwitchVersionsTab()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    

			addUpdateMethod( LoadModule, onUpdateNeeded );
			addUpdateMethod( UnloadModule, onUpdateNeeded );
			addUpdateMethod( ImportModule, onUpdateNeeded );
			addUpdateMethod( ImportTrack, onUpdateNeeded );
			addUpdateMethod( ImportBlock, onUpdateNeeded );
			addUpdateMethod( RemoveTrackImport, onUpdateNeeded );
			addUpdateMethod( RemoveBlockImport, onUpdateNeeded );
			addUpdateMethod( SwitchModuleVersion, onVersionsSwitched );
			addUpdateMethod( SwitchObjectVersion, onVersionsSwitched );
			
			addEventListener( Event.RESIZE, onResize );
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			
			addChild( _switchablesLabel );
			addChild( _alternativeVersionsLabel );

			_switchableModuleList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onSwitchableSelected );
			_switchableModuleList.addEventListener( ModuleManagerList.SELECTION_FINISHED_EVENT, onSelectionFinished );
			_switchableModuleList.addEventListener( ScrollEvent.SCROLL, onScrollList );
			addChild( _switchableModuleList );
			
			_upgradeAllButton.setStyle( "skin", TextButtonSkin );
			_upgradeAllButton.label = "Upgrade All";
			_upgradeAllButton.addEventListener( MouseEvent.CLICK, onClickUpgradeAllButton );
			addChild( _upgradeAllButton );
			
			_alternativeVersionsList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onAlternativeVersionSelected );
			_alternativeVersionsList.addEventListener( ModuleManagerList.SELECTION_FINISHED_EVENT, onSelectionFinished );
			_alternativeVersionsList.addEventListener( ScrollEvent.SCROLL, onScrollList );
			addChild( _alternativeVersionsList );
			
			_switchVersionsButton.setStyle( "skin", TextButtonSkin );
			_switchVersionsButton.label = "Switch Versions";
			_switchVersionsButton.addEventListener( MouseEvent.CLICK, onClickSwitchVersionsButton );
			addChild( _switchVersionsButton );
			
			_alwaysUpgradeCheckbox.label = "Always Upgrade";
			_alwaysUpgradeCheckbox.addEventListener( MouseEvent.CLICK, onClickAlwaysUpgrade );
			addChild( _alwaysUpgradeCheckbox );
			
			_arrowCanvas.addChild( _arrowMask );
			_arrowCanvas.mask = _arrowMask;
			addChild( _arrowCanvas );
			
			_info.setStyle( "borderStyle", "solid" );
			_info.setStyle( "borderThickness", 2 );
			addChild( _info );
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( Utilities.isEqualOrDescendant( event.target, _switchableModuleList ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerSwitchVersionsTabSwitchableList" );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _alternativeVersionsList ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerSwitchVersionsTabAlternativeVersionsList" );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _upgradeAllButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerSwitchVersionsUpgradeAllButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _switchVersionsButton ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerSwitchVersionsTabSwitchButton" );
			}
			
			if( Utilities.isEqualOrDescendant( event.target, _info ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerSwitchVersionsTabInfo" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _alwaysUpgradeCheckbox ) )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleManagerSwitchVersionsTabAlwaysUpgrade" );
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
						_arrowColor = 0x000000;
						setButtonTextColor( _upgradeAllButton, 0x6D6D6D, 0x9e9e9e );
						setButtonTextColor( _switchVersionsButton, 0x6D6D6D, 0x9e9e9e );
						_info.setStyle( "borderColor", 0xcfcfcf );
						_alwaysUpgradeCheckbox.setStyle( CheckBoxTickIcon.GLOWCOLOR_STYLENAME, 0xaaccdf );
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						_arrowColor = 0xffffff;
						setButtonTextColor( _upgradeAllButton, 0x939393, 0x626262 );
						setButtonTextColor( _switchVersionsButton, 0x939393, 0x626262 );
						_info.setStyle( "borderColor", 0x313131 );
						_alwaysUpgradeCheckbox.setStyle( CheckBoxTickIcon.GLOWCOLOR_STYLENAME, 0x214356 );
						break;
				}
				
				_switchablesLabel.setStyle( "color", _labelColor );
				_alternativeVersionsLabel.setStyle( "color", _labelColor );
			}
		}
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		}
		
		
		private function onAddedToStage( event:Event ):void
		{
			_alwaysUpgradeCheckbox.selected = model.alwaysUpgrade;			
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
		
		
		private function onVersionsSwitched( command:SwitchObjectVersion ):void
		{
			updateArrows();
			updateSwitchEnable();
			deferInfoUpdate();
		}
		
		
		private function updateAll():void
		{
			var switchables:Vector.<ModuleManagerListItem> = switchableModules;

			_switchableModuleList.items = switchables;
			_alternativeVersionsList.removeAllItems();
			
			if( switchables.length > 0 )
			{
				_switchablesLabel.text = "Modules";

				_alternativeVersionsLabel.text = "Alternative Versions";
				_alternativeVersionsLabel.visible = true;
				
				_switchableModuleList.visible = true;
				_alternativeVersionsList.visible = true;
				_upgradeAllButton.visible = true;
				_switchVersionsButton.visible = true;
				_info.visible = true;
				
				updateSwitchEnable();
				
				deferInfoUpdate();
			}
			else
			{
				_switchablesLabel.text = "No alternative versions are available";
				_alternativeVersionsLabel.visible = false;

				_switchableModuleList.visible = false;
				_alternativeVersionsList.visible = false;
				_upgradeAllButton.visible = false;
				_switchVersionsButton.visible = false;
				_info.visible = false;
			}

			updateArrows();
			
			_updateFlagged = false;
		}

		
		private function get internalMargin():Number
		{
			return FontSize.getTextRowHeight( this ) / 2;
		}
		
		
		private function get switchableListRect():Rectangle
		{
			return new Rectangle( internalMargin, internalMargin * 3, width / 4 - internalMargin * 3, height - internalMargin * 4 );
		}

		
		private function onResize( event:Event ):void
		{
			_switchablesLabel.x = internalMargin;
			_switchablesLabel.y = internalMargin;

			var switchableListRect:Rectangle = switchableListRect;
			var switchableListRectDeflated:Rectangle = switchableListRect.clone();
			switchableListRectDeflated.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			_switchableModuleList.x = switchableListRectDeflated.x;
			_switchableModuleList.y = switchableListRectDeflated.y;
			_switchableModuleList.width = switchableListRectDeflated.width;
			_switchableModuleList.height = switchableListRectDeflated.height;

			var rightPane:Rectangle = switchableListRect.clone();
			rightPane.offset( width / 4 + internalMargin * 1.5, 0 );
			rightPane.height -= ( FontSize.getTextRowHeight( this ) + internalMargin * 2 );

			_alternativeVersionsLabel.x = rightPane.left;
			_alternativeVersionsLabel.y = internalMargin;
			
			var alternativeVersionsRect:Rectangle = rightPane.clone();
			alternativeVersionsRect.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			alternativeVersionsRect.height;
			
			_alternativeVersionsList.x = alternativeVersionsRect.x;
			_alternativeVersionsList.y = alternativeVersionsRect.y;
			_alternativeVersionsList.width = alternativeVersionsRect.width;
			_alternativeVersionsList.height = alternativeVersionsRect.height;
			
			_switchVersionsButton.x = rightPane.x;
			_switchVersionsButton.width = rightPane.width;
			_switchVersionsButton.height = FontSize.getTextRowHeight( this );
			_switchVersionsButton.y = rightPane.bottom + internalMargin * 2;
			
			_info.x = rightPane.right + internalMargin * 2;
			_info.y = rightPane.top;
			_info.width = width - _info.x - internalMargin;
			_info.height = rightPane.height;
			
			_upgradeAllButton.x = _info.x;
			_upgradeAllButton.width = rightPane.width;
			_upgradeAllButton.height = FontSize.getTextRowHeight( this );
			_upgradeAllButton.y = rightPane.bottom + internalMargin * 2;

			_arrowMask.graphics.clear();
			_arrowMask.graphics.beginFill( 0x808080 );
			_arrowMask.graphics.drawRect( switchableListRect.right, switchableListRect.top, rightPane.left - switchableListRect.right, switchableListRect.height );
			_arrowMask.graphics.endFill();
			
			_alwaysUpgradeCheckbox.setStyle( "right", internalMargin * 2 );
			_alwaysUpgradeCheckbox.y = rightPane.bottom + internalMargin * 2;
			
			drawArrows();
		}
		
		
		private function setButtonTextColor( button:Button, color:uint, disabledColor:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
			button.setStyle( "disabledColor", disabledColor );
		}
		
		
		private function get switchableModules():Vector.<ModuleManagerListItem>
		{
			var switchableModules:Vector.<ModuleManagerListItem> = new Vector.<ModuleManagerListItem>;

			var allModuleIDs:Object = new Object;
			model.project.getAllModuleGuidsInTree( allModuleIDs );

			var switchableMap:Object = new Object;
			
			for( var moduleGuid:String in allModuleIDs )
			{
				var interfaceDefinition:InterfaceDefinition = model.getInterfaceDefinitionByModuleGuid( moduleGuid );
				
				var interfaceDefinitions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
				Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
				
				if( interfaceDefinitions.length > 1 )
				{
					var defaultVersion:InterfaceDefinition = interfaceDefinitions[ 0 ];
					
					if( switchableMap.hasOwnProperty( defaultVersion.moduleGuid ) )
					{
						continue;
					}
					
					var item:ModuleManagerListItem = new ModuleManagerListItem;
					item.useTint = true;
					item.interfaceDefinition = defaultVersion;
					switchableModules.push( item );
					
					switchableMap[ defaultVersion.moduleGuid ] = 1;
				}
			}
			
			switchableModules.sort( moduleCompareFunction );

			return switchableModules;
		}
		
		
		private function moduleCompareFunction( a:ModuleManagerListItem, b:ModuleManagerListItem ):Number
		{
			return a.compare( b );
		}		
		
		
		private function onSwitchableSelected( event:Event ):void
		{
			Assert.assertNotNull( _switchableModuleList.selectedItem );			
			
			updateAlternativeVersions( _switchableModuleList.selectedItem.interfaceDefinition );
			
			updateSwitchEnable();
			
			updateArrows();
			
			_info.markdown = "";
		}
		
		
		private function onAlternativeVersionSelected( event:Event ):void
		{
			updateSwitchEnable();
			
			_info.markdown = "";
		}
		
		
		private function onSelectionFinished( event:Event ):void
		{
			deferInfoUpdate();
		}

		
		private function updateAlternativeVersions( switchableInterface:InterfaceDefinition ):void
		{
			var versions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( switchableInterface.originGuid );
			
			var items:Vector.<ModuleManagerListItem> = new Vector.<ModuleManagerListItem>;
			var lastModuleSource:String = null;
			
			for each( var version:InterfaceDefinition in versions )
			{
				var item:ModuleManagerListItem = new ModuleManagerListItem;
				item.interfaceDefinition = version;
				
				if( version.moduleSource != lastModuleSource )
				{
					item.hasSectionHeading();
					lastModuleSource = version.moduleSource;
				}
				
				item.addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClickAlternativeVersion );
				item.useTint = true;
				items.push( item );
			}
			
			_alternativeVersionsList.items = items;
		}
		
		
		private function onDoubleClickAlternativeVersion( event:MouseEvent ):void
		{
			Assert.assertTrue( _alternativeVersionsList.selectedItem == event.currentTarget );
			
			switchVersions();
		}
		
		
		private function updateSwitchEnable():void
		{
			_switchVersionsButton.enabled = false;
			if( !_switchableModuleList.selectedItem || !_alternativeVersionsList.selectedItem )
			{
				return;
			}
			
			for each( var versionInUse:ModuleManagerListItem in _arrowTargets )
			{
				if( versionInUse != _alternativeVersionsList.selectedItem )
				{
					_switchVersionsButton.enabled = true;
					return;
				}
			}
		}

		
		private function onClickSwitchVersionsButton( event:MouseEvent ):void
		{
			switchVersions();
		}
		
		
		private function onClickAlwaysUpgrade( event:MouseEvent ):void
		{
			model.alwaysUpgrade = _alwaysUpgradeCheckbox.selected;
		}
		
		
		private function switchVersions():void
		{
			var switchableVersion:ModuleManagerListItem = _switchableModuleList.selectedItem;
			Assert.assertNotNull( switchableVersion );
			
			var switchableVersions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( switchableVersion.interfaceDefinition.originGuid );
			
			var targetVersion:ModuleManagerListItem = _alternativeVersionsList.selectedItem;
			Assert.assertNotNull( targetVersion );
			
			var targetModuleGuid:String = targetVersion.guid;
			
			for each( var versionToSwitch:InterfaceDefinition in switchableVersions )
			{
				var guidToSwitch:String = versionToSwitch.moduleGuid;
				if( guidToSwitch != targetModuleGuid )
				{
					controller.processCommand( new SwitchAllObjectVersions( model.project.id, guidToSwitch, targetModuleGuid ) );
				}
			}
		}

		
		private function onClickUpgradeAllButton( event:MouseEvent ):void
		{
			controller.processCommand( new UpgradeModules( model.project.id ) );
		}
		
		
		private function onScrollList( event:ScrollEvent ):void
		{
			drawArrows();
		}
		
		
		private function updateArrows():void
		{
			_arrowTargets = new Vector.<ModuleManagerListItem>;
			
			if( _switchableModuleList.selectedItem )
			{
				//build map of all module guids
				var allModuleGuids:Object = new Object;
				model.project.getAllModuleGuidsInTree( allModuleGuids );
				
				//now iterate through alternative items, adding to list as necessary
				for each( var alternativeItem:ModuleManagerListItem in _alternativeVersionsList.items )
				{
					if( allModuleGuids.hasOwnProperty( alternativeItem.guid ) )
					{
						_arrowTargets.push( alternativeItem );
					}
				}
			}
			
			drawArrows();
		}
		
		
		private function drawArrows():void
		{
			_arrowCanvas.graphics.clear();
			
			var arrowStartItem:ModuleManagerListItem = _switchableModuleList.selectedItem;
			if( arrowStartItem )
			{
				var arrowGap:Number = ModuleManagerList.cornerRadius + internalMargin / 2;

				var startX:Number = _switchableModuleList.x + _switchableModuleList.width + arrowGap;
				var endX:Number = _alternativeVersionsList.x - arrowGap;

				var startY:Number = _switchableModuleList.y + _switchableModuleList.getItemArrowPointY( arrowStartItem ); 
				
				var arrowStartPoint:Point = new Point( startX, startY );
				
				for each( var arrowEndItem:ModuleManagerListItem in _arrowTargets )
				{
					var endY:Number = _alternativeVersionsList.y + _alternativeVersionsList.getItemArrowPointY( arrowEndItem );
					var arrowEndPoint:Point = new Point( endX, endY );
					
					drawArrow( arrowStartPoint, arrowEndPoint );
				}
			}
		}

		
		private function drawArrow( from:Point, to:Point ):void
		{
			var gridSize:Number = FontSize.getTextRowHeight( this );
			var arrowheadLength:Number = _arrowheadLength * gridSize;
			var arrowheadWidth:Number = _arrowheadWidth * gridSize;
			
			to.x -= arrowheadLength;
			
			var center:Point = Point.interpolate( from, to, 0.5 );
			
			var tangentStrength:Number = 0.75;
			
			//curvy line
			_arrowCanvas.graphics.lineStyle( _arrowWidth, _arrowColor ); 
			_arrowCanvas.graphics.moveTo( from.x, from.y );
			_arrowCanvas.graphics.curveTo( center.x * tangentStrength + from.x * ( 1 - tangentStrength ), from.y, center.x, center.y );
			_arrowCanvas.graphics.curveTo( center.x * tangentStrength + to.x * ( 1 - tangentStrength ), to.y, to.x, to.y );
			
			//draw arrowhead
			_arrowCanvas.graphics.beginFill( _arrowColor );
			_arrowCanvas.graphics.moveTo( to.x + arrowheadLength, to.y );
			_arrowCanvas.graphics.lineTo( to.x, to.y - arrowheadWidth );
			_arrowCanvas.graphics.lineTo( to.x, to.y + arrowheadWidth );
			_arrowCanvas.graphics.endFill();
		}	
		
		
		private function deferInfoUpdate():void
		{
			_info.markdown = "Updating...";
			callLater( callLater, [ updateInfo ] );			
		}
		
		
		private function updateInfo():void
		{
			var infoGenerator:ModuleManagementInfoGenerator = new ModuleManagementInfoGenerator;
			
			var switchableItem:ModuleManagerListItem = _switchableModuleList.selectedItem;
			if( !switchableItem )
			{
				_info.markdown = "No module is selected";
				return;				
			}

			var targetVersionItem:ModuleManagerListItem = _alternativeVersionsList.selectedItem;
			if( !targetVersionItem )
			{
				_info.markdown = "No alternative version is selected";
				return;				
			}
			
			var targetVersion:InterfaceDefinition = targetVersionItem.interfaceDefinition;
			
			var versionsToSwitch:Vector.<InterfaceDefinition> = new Vector.<InterfaceDefinition>; 
			var allInstanceNames:String = "";
			var instanceNamesPerVersion:Object = new Object;

			for each( var itemInUse:ModuleManagerListItem in _arrowTargets )
			{
				var versionInUse:InterfaceDefinition = itemInUse.interfaceDefinition;
				
				if( versionInUse != targetVersion )
				{
					var instanceNames:String = infoGenerator.getInstanceNames( versionInUse );
					if( instanceNames.length > 0 )
					{
						versionsToSwitch.push( versionInUse );
						allInstanceNames += instanceNames;
						instanceNamesPerVersion[ versionInUse.moduleGuid ] = instanceNames;
					}
				}
			}
			
			if( allInstanceNames.length == 0 )
			{
				_info.markdown = "This is the version currently being used";
				return;
			}
			
			var markdown:String = "#Affected Modules:\n\n" + allInstanceNames + "\n\n";
			
			markdown += "##Change Details\n\n";

			Assert.assertTrue( versionsToSwitch.length > 0 );
			var multipleVersionsInUse:Boolean = ( versionsToSwitch.length > 1 );

			for each( var versionToSwitch:InterfaceDefinition in versionsToSwitch )
			{
				markdown += "##![](app:/icons/module_48x48x32.png) " + switchableItem.toString() + "\n\n";

				if( multipleVersionsInUse )
				{
					markdown += instanceNamesPerVersion[ versionToSwitch.moduleGuid ];
					markdown += "\n";
				}

				markdown += infoGenerator.getModuleSwitchReport( versionToSwitch, targetVersion );
				markdown += "\n\n";
			}
			
			_info.markdown = markdown;			
		}

		
		private var _switchablesLabel:Label = new Label;
		private var _alternativeVersionsLabel:Label = new Label;
		private var _switchableModuleList:ModuleManagerList = new ModuleManagerList;
		private var _alternativeVersionsList:ModuleManagerList = new ModuleManagerList;

		private var _info:ModuleInfo = new ModuleInfo;
		
		private var _upgradeAllButton:Button = new Button;
		private var _switchVersionsButton:Button = new Button;

		private var _alwaysUpgradeCheckbox:CheckBox = new CheckBox;

		
		private var _labelColor:uint;
		
		private var _updateFlagged:Boolean = false;
		
		private var _arrowTargets:Vector.<ModuleManagerListItem> = new Vector.<ModuleManagerListItem>;

		private var _arrowColor:uint = 0;
		private var _arrowCanvas:Canvas = new Canvas;
		private var _arrowMask:Canvas = new Canvas;

		
		private static const _arrowheadLength:Number = 0.3;
		private static const _arrowheadWidth:Number = 0.15;
		private static const _arrowWidth:Number = 2;
	}
}