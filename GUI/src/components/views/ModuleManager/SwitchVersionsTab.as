package components.views.ModuleManager
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
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
	import components.controller.serverCommands.SwitchAllModuleVersions;
	import components.controller.serverCommands.SwitchModuleVersion;
	import components.controller.serverCommands.UnloadModule;
	import components.model.Block;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
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
			
			addEventListener( Event.RESIZE, onResize );
			
			addChild( _switchablesLabel );

			_switchableModuleList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onSwitchableSelected );
			_switchableModuleList.addEventListener( ScrollEvent.SCROLL, onScrollList );
			addChild( _switchableModuleList );
			
			_alternativeVersionsList.addEventListener( ModuleManagerListItem.SELECT_EVENT, onAlternativeVersionSelected );
			_alternativeVersionsList.addEventListener( ScrollEvent.SCROLL, onScrollList );
			addChild( _alternativeVersionsList );
			
			_switchVersionsButton.setStyle( "skin", TextButtonSkin );
			_switchVersionsButton.label = "Switch Versions";
			_switchVersionsButton.addEventListener( MouseEvent.CLICK, onClickSwitchVersionsButton );
			addChild( _switchVersionsButton );
			
			_arrowCanvas.addChild( _arrowMask );
			_arrowCanvas.mask = _arrowMask;
			addChild( _arrowCanvas );
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
						//_controlBackgroundColor = 0xcfcfcf;
						setButtonTextColor( _switchVersionsButton, 0x6D6D6D, 0x9e9e9e );
						break;
					
					case ColorScheme.DARK:
						_labelColor = 0x8c8c8c;
						_arrowColor = 0xffffff;
						//_controlBackgroundColor = 0x313131;
						setButtonTextColor( _switchVersionsButton, 0x939393, 0x626262 );
						break;
				}
				
				_switchablesLabel.setStyle( "color", _labelColor );
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
		
		
		private function onVersionsSwitched( command:SwitchModuleVersion ):void
		{
			updateArrows();
		}
		
		
		private function updateAll():void
		{
			var switchables:Vector.<ModuleManagerListItem> = switchableModules;
			
			if( switchables.length > 0 )
			{
				_switchablesLabel.text = "Alternative versions available:";

				_switchableModuleList.items = switchables;
				
				_alternativeVersionsList.removeAllItems();
				
				_switchableModuleList.visible = true;
				_alternativeVersionsList.visible = true;
				_switchVersionsButton.visible = true;
				
				updateSwitchEnable();
			}
			else
			{
				_switchablesLabel.text = "No alternative versions are available";

				_switchableModuleList.visible = false;
				_alternativeVersionsList.visible = false;
				_switchVersionsButton.visible = false;
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
			return new Rectangle( internalMargin, internalMargin * 3, width / 2 - internalMargin * 3, height - internalMargin * 4 );
		}

		
		private function onResize( event:Event ):void
		{
			var switchableListRect:Rectangle = switchableListRect;
			var switchableListRectDeflated:Rectangle = switchableListRect.clone();
			switchableListRectDeflated.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			_switchableModuleList.x = switchableListRectDeflated.x;
			_switchableModuleList.y = switchableListRectDeflated.y;
			_switchableModuleList.width = switchableListRectDeflated.width;
			_switchableModuleList.height = switchableListRectDeflated.height;
			
			_switchablesLabel.x = internalMargin;
			_switchablesLabel.y = internalMargin;
			
			var rightPane:Rectangle = switchableListRect.clone();
			rightPane.offset( width - rightPane.right - internalMargin, 0 );
			
			var alternativeVersionsRect:Rectangle = rightPane.clone();
			alternativeVersionsRect.inflate( -ModuleManagerList.cornerRadius, -ModuleManagerList.cornerRadius );
			alternativeVersionsRect.height -= FontSize.getTextRowHeight( this ) * 2;
			_alternativeVersionsList.x = alternativeVersionsRect.x;
			_alternativeVersionsList.y = alternativeVersionsRect.y;
			_alternativeVersionsList.width = alternativeVersionsRect.width;
			_alternativeVersionsList.height = alternativeVersionsRect.height;
			
			
			_switchVersionsButton.x = rightPane.x;
			_switchVersionsButton.width = rightPane.width;
			_switchVersionsButton.height = FontSize.getTextRowHeight( this );
			_switchVersionsButton.y = rightPane.bottom - _switchVersionsButton.height;
			
			_arrowMask.graphics.clear();
			_arrowMask.graphics.beginFill( 0x808080 );
			_arrowMask.graphics.drawRect( switchableListRect.right, switchableListRect.top, rightPane.left - switchableListRect.right, switchableListRect.height );
			_arrowMask.graphics.endFill();
			
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
			var moduleIDsAddedMap:Object = new Object;
			
			for each( var track:Track in model.project.tracks )
			{
				for each( var block:Block in track.blocks )
				{
					for each( var module:ModuleInstance in block.modules )
					{
						var interfaceDefinition:InterfaceDefinition = module.interfaceDefinition;
						
						var interfaceDefinitions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( interfaceDefinition.originGuid );
						Assert.assertTrue( interfaceDefinitions && interfaceDefinitions.length > 0 );
						
						if( interfaceDefinitions.length > 1 )
						{
							var defaultVersion:InterfaceDefinition = interfaceDefinitions[ 0 ];
							
							if( moduleIDsAddedMap.hasOwnProperty( defaultVersion.moduleGuid ) )
							{
								continue;
							}
							
							var item:ModuleManagerListItem = new ModuleManagerListItem;
							item.useTint = true;
							item.interfaceDefinition = defaultVersion;
							switchableModules.push( item );
							
							moduleIDsAddedMap[ defaultVersion.moduleGuid ] = 1;
						}
					}
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
		}
		
		
		private function onAlternativeVersionSelected( event:Event ):void
		{
			
			updateSwitchEnable();
		}

		
		private function updateAlternativeVersions( switchableInterface:InterfaceDefinition ):void
		{
			var versions:Vector.<InterfaceDefinition> = model.getInterfaceDefinitionsByOriginGuid( switchableInterface.originGuid );
			
			var items:Vector.<ModuleManagerListItem> = new Vector.<ModuleManagerListItem>;
			for each( var version:InterfaceDefinition in versions )
			{
				var item:ModuleManagerListItem = new ModuleManagerListItem;
				item.interfaceDefinition = version;
				item.useTint = true;
				items.push( item );
			}
			
			_alternativeVersionsList.items = items;
		}
		
		
		private function updateSwitchEnable():void
		{
			_switchVersionsButton.enabled = ( _switchableModuleList.selectedItem != null && _alternativeVersionsList.selectedItem != null );
		}

		
		private function onClickSwitchVersionsButton( event:MouseEvent ):void
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
					controller.processCommand( new SwitchAllModuleVersions( guidToSwitch, targetModuleGuid ) );
				}
			}
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
				for each( var track:Track in model.project.tracks )
				{
					for each( var block:Block in track.blocks )
					{
						for each( var module:ModuleInstance in block.modules )
						{
							allModuleGuids[ module.interfaceDefinition.moduleGuid ] = 1;
						}
					}
				}
				
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

				var startY:Number = _switchableModuleList.y + _switchableModuleList.getItemYCenter( arrowStartItem ); 
				
				var arrowStartPoint:Point = new Point( startX, startY );
				
				for each( var arrowEndItem:ModuleManagerListItem in _arrowTargets )
				{
					var endY:Number = _alternativeVersionsList.y + _alternativeVersionsList.getItemYCenter( arrowEndItem );
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

		
		private var _switchablesLabel:Label = new Label;
		private var _switchableModuleList:ModuleManagerList = new ModuleManagerList;
		private var _alternativeVersionsList:ModuleManagerList = new ModuleManagerList;
		
		private var _switchVersionsButton:Button = new Button;
		
		private var _controlBackgroundColor:uint;
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