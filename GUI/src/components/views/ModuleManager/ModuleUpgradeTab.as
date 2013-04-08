package components.views.ModuleManager
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import mx.controls.Label;
	import mx.core.ScrollPolicy;
	
	import components.model.Block;
	import components.model.ModuleInstance;
	import components.model.Track;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.libraries.Library;
	import components.views.IntegraView;
	import components.views.ModuleLibrary.ModuleLibraryListEntry;
	
	import flexunit.framework.Assert;
	
	public class ModuleUpgradeTab extends IntegraView
	{
		public function ModuleUpgradeTab()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;  
			verticalScrollPolicy = ScrollPolicy.OFF;    

			addEventListener( Event.RESIZE, onResize );
			
			addChild( _upgradeLabel );
			
			_upgradableModuleList.setStyle( "borderThickness", _listBorder );
			_upgradableModuleList.setStyle( "cornerRadius", _listBorder );
			addChild( _upgradableModuleList );
			
			
		}
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_controlBackgroundColor = 0x747474;
						break;
					
					case ColorScheme.DARK:
						_controlBackgroundColor = 0x8c8c8c;
						break;
				}
				
				_upgradeLabel.setStyle( "color", _controlBackgroundColor );
				_upgradableModuleList.setStyle( "borderColor", _controlBackgroundColor );
				_upgradableModuleList.setStyle( "backgroundColor", _controlBackgroundColor );
			}
		}
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		}
		
		
		private function updateAll():void
		{
			var upgradables:Array = getUpgradableModules();
			
			if( upgradables.length > 0 )
			{
				_upgradeLabel.text = "Better versions Available:";

				_upgradableModuleList.data = upgradables;
				_upgradableModuleList.visible = true;
			}
			else
			{
				_upgradeLabel.text = "All modules are using the best available version";

				_upgradableModuleList.visible = false;
			}
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
		}
		
		
		private function getUpgradableModules():Array
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
		
		
		private var _upgradeLabel:Label = new Label; 
		
		private var _upgradableModuleList:Library = new Library;
		private var _controlBackgroundColor:uint;
		
		private static const _listBorder:Number = 4;
	}
}