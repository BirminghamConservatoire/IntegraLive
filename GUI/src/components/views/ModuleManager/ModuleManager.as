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
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.containers.TabNavigator;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	
	import components.controller.userDataCommands.PollForUpgradableModules;
	import components.controller.userDataCommands.SetViewMode;
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.model.userData.ViewMode;
	import components.utils.FontSize;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CloseButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class ModuleManager extends IntegraView
	{
		public function ModuleManager()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF; 
			verticalScrollPolicy = ScrollPolicy.OFF;   
			
			_titleLabel.text = "Module Manager";
			_titleLabel.setStyle( "verticalAlign", "center" );
			addChild( _titleLabel );

			_titleCloseButton.setStyle( "skin", CloseButtonSkin );
			_titleCloseButton.setStyle( "fillAlpha", 1 );
			_titleCloseButton.setStyle( "color", _borderColor );
			_titleCloseButton.addEventListener( MouseEvent.CLICK, onClickTitleCloseButton );
			addChild( _titleCloseButton );
			
			_upgradeTab.label = "Upgrade";
			_switchVersionsTab.label = "Manage";
			_installTab.label = "Install / Uninstall";

			_tabNavigator.addChild( _upgradeTab );
			_tabNavigator.addChild( _switchVersionsTab );
			_tabNavigator.addChild( _installTab );
			
			addChild( _tabNavigator );
			
			addUpdateMethod( PollForUpgradableModules, onPollForUpgradableModules );
			
			onStyleChanged( null );
		}

		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "ModuleManager" );
		}
		
		
		public function onStyleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_backgroundColor = 0xffffff;
						_borderColor = 0xc9e2f0;
						_titleCloseButton.setStyle( "color", _borderColor );
						_titleCloseButton.setStyle( "fillColor", 0x000000 );
						_titleLabel.setStyle( "color", 0x000000 );
						break;

					case ColorScheme.DARK:
						_backgroundColor = 0x000000;
						_borderColor = 0x344c59;
						_titleCloseButton.setStyle( "color", _borderColor );
						_titleCloseButton.setStyle( "fillColor", 0xffffff );
						_titleLabel.setStyle( "color", 0xffffff );
						break;
				}
				
				invalidateDisplayList();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				if( parentDocument )
				{
					setStyle( FontSize.STYLENAME, parentDocument.getStyle( FontSize.STYLENAME ) );
					updateSize();
					invalidateDisplayList();
				}
			}
		}
				

		public function updateSize():void
		{
			Assert.assertNotNull( parentDocument );

			//calculate window size
			var rowHeight:Number = FontSize.getTextRowHeight( this );
			width = Math.min( rowHeight * 20, parentDocument.width );
			height = Math.min( rowHeight * 18, parentDocument.height );

			//position title controls
			_titleCloseButton.width = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.height = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.x = ( titleHeight - _titleCloseButton.width ) / 2;
			_titleCloseButton.y = ( titleHeight - _titleCloseButton.width ) / 2;
			
			_titleLabel.x = titleHeight;
			_titleLabel.y = titleHeight / 6;
			_titleLabel.height = rowHeight;

			//position main controls
			_tabNavigator.setStyle( "top", titleHeight + _borderThickness );
			_tabNavigator.setStyle( "left", _borderThickness );
			_tabNavigator.setStyle( "right", _borderThickness );
			_tabNavigator.setStyle( "bottom", _borderThickness );
		}
		
		
		protected override function onAllDataChanged():void
		{
			updateSize();
		}


		protected override function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			graphics.lineStyle( _borderThickness, _borderColor ); 
			graphics.beginFill( _backgroundColor );
			graphics.drawRoundRect( 0, 0, width, height, _cornerRadius, _cornerRadius );
			graphics.endFill();
			
			graphics.beginFill( _borderColor );
			graphics.drawRoundRectComplex( 0, 0, width, titleHeight, _cornerRadius, _cornerRadius, 0, 0 );
			graphics.endFill();
		}
		
		
		private function onClickTitleCloseButton( event:MouseEvent ):void
		{
			var viewMode:ViewMode = model.project.projectUserData.viewMode.clone();
			viewMode.moduleManagerOpen = false;
			
			controller.activateUndoStack = false;
			controller.processCommand( new SetViewMode( viewMode ) );
			controller.activateUndoStack = true;
		}
		
		
		private function get titleHeight():Number
		{
			return FontSize.getTextRowHeight( this );
		}
		
		
		private function onPollForUpgradableModules( command:PollForUpgradableModules ):void
		{
			if( command.foundUpgradableModules )
			{
				_tabNavigator.selectedChild = _upgradeTab;
			}
		}
		
		
		private var _titleLabel:Label = new Label;
		private var _titleCloseButton:Button = new Button;
		
		private var _tabNavigator:TabNavigator = new TabNavigator;
		private var _upgradeTab:UpgradeTab = new UpgradeTab;
		private var _switchVersionsTab:Canvas = new SwitchVersionsTab;
		private var _installTab:Canvas = new Canvas;
		
		private var _backgroundColor:uint = 0;
		private var _borderColor:uint = 0;
		
		private const _borderThickness:Number = 4;
		private const _cornerRadius:Number = 15;
	}
}
