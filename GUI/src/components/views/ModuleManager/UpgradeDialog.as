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
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.core.ScrollPolicy;
	
	import components.controller.IntegraController;
	import components.controller.serverCommands.UpgradeModules;
	import components.controller.userDataCommands.SetViewMode;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.userData.ColorScheme;
	import components.model.userData.ViewMode;
	import components.utils.Config;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.CheckBoxTickIcon;
	import components.views.Skins.CloseButtonSkin;
	import components.views.Skins.TextButtonSkin;
	
	import flexunit.framework.Assert;

	public class UpgradeDialog extends IntegraView
	{
		public function UpgradeDialog() 
		{
			super();
			
			verticalScrollPolicy = ScrollPolicy.OFF;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			
			
			_titleLabel.text = "Upgrade Modules";
			_titleLabel.setStyle( "verticalAlign", "center" );
			addChild( _titleLabel );
			
			_titleCloseButton.setStyle( "skin", CloseButtonSkin );
			_titleCloseButton.setStyle( "fillAlpha", 1 );
			_titleCloseButton.setStyle( "color", _borderColor );
			_titleCloseButton.addEventListener( MouseEvent.CLICK, onClose );
			addChild( _titleCloseButton );

			_description.setStyle( "backgroundAlpha", "0" );
			_description.setStyle( "borderStyle", "none" );
			_description.setStyle( "focusAlpha", 0 );
			_description.setStyle( "paddingLeft", 20 );
			_description.setStyle( "paddingRight", 20 );
			_description.setStyle( "paddingTop", 20 );
			_description.setStyle( "paddingBottom", 20 );
			addChild( _description );
			
			_closeButton.setStyle( "skin", TextButtonSkin );
			_moduleManagerButton.setStyle( "skin", TextButtonSkin );
			_upgradeButton.setStyle( "skin", TextButtonSkin );
			
			_closeButton.label = "Don't Upgrade";
			_moduleManagerButton.label = "Module Manager...";
			_upgradeButton.label = "Upgrade";
			
			_alwaysUpgradeCheckbox.label = "Always Upgrade";
			
			_upgradeButton.addEventListener( MouseEvent.CLICK, onUpgrade );
			_moduleManagerButton.addEventListener( MouseEvent.CLICK, onModuleManager );
			_closeButton.addEventListener( MouseEvent.CLICK, onClose );

			_alwaysUpgradeCheckbox.addEventListener( MouseEvent.CLICK, toggleAlwaysUpgrade );
			
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			
			addChild( _closeButton );
			addChild( _moduleManagerButton );
			addChild( _upgradeButton );
			addChild( _alwaysUpgradeCheckbox );
			
			onStyleChanged( null );
		}
		
		
		public function set objectID( objectID:int ):void
		{
			_objectID = objectID;
			
			var model:IntegraModel = IntegraModel.singleInstance;
			var dataObject:IntegraDataObject = model.getDataObjectByID( _objectID );
			Assert.assertNotNull( dataObject );
			
			var markdown:String;
			
			if( dataObject is IntegraContainer )
			{
				markdown = "__Improved modules are available for ";
			}
			else
			{
				markdown = "__Improved version is available for ";
			}
			
			markdown += Utilities.escapeUnderscores( model.getPathStringFromID( objectID ) );
			markdown += "__.\n\n";
			
			markdown += "__Would you like to upgrade the ";
			
			if( dataObject is IntegraContainer )
			{
				markdown += Utilities.getClassNameFromObject( dataObject ).toLowerCase();
			}
			else
			{
				markdown += dataObject.interfaceDefinition.interfaceInfo.label;
			}
			
			markdown += "__?";
			
			markdown += "\n\nA backup will be saved to " + UpgradeModules.getBackupName( model );
			
			var url:String = Config.singleInstance.moduleUpgradeHelpLink;
			
			markdown += "\n\nFor an explanation of project upgrades click [here](" + url + ")";
			
			_description.markdown = markdown;
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			var viewInfos:InfoMarkupForViews = InfoMarkupForViews.instance;
			
			if( Utilities.isEqualOrDescendant( event.target, _upgradeButton ) )
			{
				return viewInfos.getInfoForView( "UpgradeDialog/UpgradeButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _moduleManagerButton ) )
			{
				return viewInfos.getInfoForView( "UpgradeDialog/ModuleManagerButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _closeButton ) )
			{
				return viewInfos.getInfoForView( "UpgradeDialog/CloseButton" );
			}

			if( Utilities.isEqualOrDescendant( event.target, _alwaysUpgradeCheckbox ) )
			{
				return viewInfos.getInfoForView( "UpgradeDialog/AlwaysUpgradeButton" );
			}

			return viewInfos.getInfoForView( "UpgradeDialog/Dialog" );
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
						_borderColor = 0xaaccdf;
						_titleCloseButton.setStyle( "color", _borderColor );
						_titleCloseButton.setStyle( "fillColor", 0x000000 );
						_titleLabel.setStyle( "color", 0x000000 );
						_description.setStyle( "color", 0x747474 );
						_description.setStyle( "backgroundColor", 0xcfcfcf );
						setButtonTextColor( _upgradeButton, 0x6D6D6D, 0x9e9e9e );
						setButtonTextColor( _moduleManagerButton, 0x6D6D6D, 0x9e9e9e );
						setButtonTextColor( _closeButton, 0x6D6D6D, 0x9e9e9e );
						_alwaysUpgradeCheckbox.setStyle( CheckBoxTickIcon.GLOWCOLOR_STYLENAME, 0xaaccdf );
						break;
					
					case ColorScheme.DARK:
						_backgroundColor = 0x000000;
						_borderColor = 0x214356;
						_titleCloseButton.setStyle( "color", _borderColor );
						_titleCloseButton.setStyle( "fillColor", 0xffffff );
						_titleLabel.setStyle( "color", 0xffffff );
						_description.setStyle( "color", 0x8c8c8c );
						_description.setStyle( "backgroundColor", 0x313131 );
						setButtonTextColor( _upgradeButton, 0x939393, 0x626262 );
						setButtonTextColor( _moduleManagerButton, 0x939393, 0x626262 );
						setButtonTextColor( _closeButton, 0x939393, 0x626262 );
						_alwaysUpgradeCheckbox.setStyle( CheckBoxTickIcon.GLOWCOLOR_STYLENAME, 0x214356 );
						break;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				updateSize();
			}
		}
		
		
		override protected function updateDisplayList( width:Number, height:Number):void
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
		
		
		private function get titleHeight():Number
		{
			return FontSize.getTextRowHeight( this );
		}

		
		private function onAddedToStage( event:Event ):void
		{
			_alwaysUpgradeCheckbox.selected = IntegraModel.singleInstance.alwaysUpgrade;			
		}
		
		
		private function updateSize():void
		{
			if( !parentDocument ) return;
			
			//calculate window size
			var rowHeight:Number = FontSize.getTextRowHeight( this );
			width = Math.min( rowHeight * 22, parentDocument.width );
			height = Math.min( rowHeight * 12, parentDocument.height );
			
			var internalMargin:Number = rowHeight / 2;
			
			//position title controls
			_titleCloseButton.width = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.height = FontSize.getButtonSize( this ) * 1.1;
			_titleCloseButton.x = ( titleHeight - _titleCloseButton.width ) / 2;
			_titleCloseButton.y = ( titleHeight - _titleCloseButton.width ) / 2;
			
			_titleLabel.x = titleHeight;
			_titleLabel.y = titleHeight / 6;
			_titleLabel.height = FontSize.getTextRowHeight( this );
			
			//position main controls
			_description.x = internalMargin;
			_description.y = rowHeight * 2;
			_description.width = width - internalMargin * 2;
			_description.height = height - _description.y - internalMargin * 4 - rowHeight * 2;
			
			_upgradeButton.width = _moduleManagerButton.width = _closeButton.width = width / 3 - internalMargin * 2;
			_upgradeButton.height = _moduleManagerButton.height = _closeButton.height = rowHeight;
			_upgradeButton.y = _moduleManagerButton.y = _closeButton.y = height - internalMargin * 2 - rowHeight * 2;

			_closeButton.x = internalMargin;
			_moduleManagerButton.x = width / 3 + internalMargin;
			_upgradeButton.x = width * 2/3 + internalMargin;
			
			_alwaysUpgradeCheckbox.x = _upgradeButton.x;
			_alwaysUpgradeCheckbox.setStyle( "bottom", internalMargin );
			
			_upgradeButton.invalidateDisplayList();
			_moduleManagerButton.invalidateDisplayList();
			_closeButton.invalidateDisplayList();
		}
		

		private function setButtonTextColor( button:Button, color:uint, disabledColor:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
			button.setStyle( "disabledColor", disabledColor );
		}
		
		
		private function onClose( event:Event ):void
		{
			var viewMode:ViewMode = IntegraModel.singleInstance.project.projectUserData.viewMode.clone();
			viewMode.closeUpgradeDialog();
			
			IntegraController.singleInstance.processCommand( new SetViewMode( viewMode ) );
		}
		
		
		private function onUpgrade( event:Event ):void
		{
			var viewMode:ViewMode = IntegraModel.singleInstance.project.projectUserData.viewMode.clone();
			viewMode.closeUpgradeDialog();
			
			IntegraController.singleInstance.processCommand( new SetViewMode( viewMode ) );

			IntegraController.singleInstance.processCommand( new UpgradeModules( _objectID ) );
		}
		
		
		private function onModuleManager( event:Event ):void
		{
			var viewMode:ViewMode = IntegraModel.singleInstance.project.projectUserData.viewMode.clone();
			viewMode.openModuleManager( true );
			
			IntegraController.singleInstance.processCommand( new SetViewMode( viewMode ) );
		}


		private function toggleAlwaysUpgrade( event:Event ):void
		{
			IntegraModel.singleInstance.alwaysUpgrade = _alwaysUpgradeCheckbox.selected;
		}
		
		

		private var _objectID:int;

		private var _titleLabel:Label = new Label;
		private var _titleCloseButton:Button = new Button;

		private var _description:ModuleInfo = new ModuleInfo;
		private var _upgradeButton:Button = new Button;
		private var _moduleManagerButton:Button = new Button;
		private var _closeButton:Button = new Button;
		private var _alwaysUpgradeCheckbox:CheckBox = new CheckBox;
		
		private var _backgroundColor:uint;
		private var _borderColor:uint;
		
		private static const _borderThickness:Number = 4;
		private static const _cornerRadius:Number = 15;
	}
}
