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
 
 
 
package components.views.ArrangeViewProperties
{
	import components.controller.serverCommands.AddScript;
	import components.controller.serverCommands.ExecuteScript;
	import components.controller.serverCommands.RemoveScript;
	import components.controller.serverCommands.SetScript;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Block;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.Script;
	import components.model.Track;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.LazyChangeReporter;
	import components.utils.Utilities;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.IntegraView;
	import components.views.Skins.AddButtonSkin;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import flexunit.framework.Assert;
	
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.core.ScrollPolicy;
	

	public class ScriptingView extends IntegraView
	{
		public function ScriptingView()
		{
			super();
			
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.OFF;

			_hBox.percentWidth = 100;
			_hBox.percentHeight = 100;
			_hBox.setStyle( "paddingLeft", _padding );
			_hBox.setStyle( "paddingRight", _padding );
			_hBox.setStyle( "paddingTop", _padding );
			_hBox.setStyle( "paddingBottom", _padding );
			
			_scriptList.width = 180;
			_scriptList.setStyle( "verticalGap", 0 );
			_scriptList.verticalScrollPolicy = ScrollPolicy.AUTO;
			_hBox.addChild( _scriptList );
		
			_newScriptButton.setStyle( "skin", AddButtonSkin );
			_newScriptButton.setStyle( "fillAlpha", 1 );
			_newScriptButton.toolTip = "Add Script";
			_newScriptButton.addEventListener( MouseEvent.CLICK, onClickNewScriptButton );
		
			_scriptArea.percentWidth = 100;
			_scriptArea.setStyle( "backgroundAlpha", 0 );
			_scriptArea.setStyle( "focusAlpha", 0 );
			_scriptArea.setStyle( "borderStyle", "none" );
			_scriptArea.wordWrap = false;
			_scriptArea.verticalScrollPolicy = ScrollPolicy.AUTO;
			_scriptArea.horizontalScrollPolicy = ScrollPolicy.AUTO;
			_hBox.addChild( _scriptArea );
			
			_lazyChangeReporter = new LazyChangeReporter( _scriptArea, commitScript );
			
			addChild( _hBox );
			
			contextMenuDataProvider = contextMenuData;

			addEventListener( Event.RESIZE, onResize );
			
			addUpdateMethod( AddScript, onScriptAdded );
			addUpdateMethod( RemoveScript, onScriptRemoved );
			addUpdateMethod( SetScript, onScriptChanged );
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
		}

		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			if( _selectedScriptID >= 0 )
			{
				var script:Script = model.getScript( _selectedScriptID );
				return script.info;
			}
			else
			{
				return InfoMarkupForViews.instance.getInfoForView( "ScriptingView" );
			}
		}	
		

		override public function styleChanged( style:String ):void
		{
			super.styleChanged( style );
			
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_newScriptButton.setStyle( "color", 0xcfcfcf );
						_newScriptButton.setStyle( "fillColor", 0x747474 );
					 	_scriptArea.setStyle( "color", 0x6D6D6D );
						break;
						
					case ColorScheme.DARK:
						_newScriptButton.setStyle( "color", 0x313131 );
						_newScriptButton.setStyle( "fillColor", 0x8c8c8c );
					 	_scriptArea.setStyle( "color", 0x939393 );
						break;
				}
				
				if( _selectedScriptID >= 0 )
				{
					_scriptArea.opaqueBackground = textAreaBackgroundColor;
				}
			}
				
			if( !style || style == FontSize.STYLENAME )
			{
				_newScriptButton.width = FontSize.getButtonSize( this );
				_newScriptButton.height = FontSize.getTextRowHeight( this ) + 4;
			}		
			
		}


		override protected function onAllDataChanged():void
		{
			_scriptListOwnerID = getScriptListOwner();
			updateScriptList();
			updateTextArea();
		} 


		private function onScriptAdded( command:AddScript ):void
		{
			if( command.parentID == _scriptListOwnerID )
			{
				addScript( model.getScript( command.scriptID ) );
			}
		}


		private function onScriptRemoved( command:RemoveScript ):void
		{
			var scriptID:int = command.scriptID;
			if( _scriptItems.hasOwnProperty( scriptID ) )
			{
				var scriptItem:ScriptListItem = _scriptItems[ scriptID ];
				Assert.assertNotNull( scriptItem );
				
				_scriptList.removeChild( scriptItem );
				scriptItem.free();
				delete _scriptItems[ scriptID ];
			}
		}


		private function onScriptChanged( command:SetScript ):void
		{
			if( command.scriptID == _selectedScriptID )
			{
				updateTextArea();
			} 
		}
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			var newScriptListOwner:int = getScriptListOwner();
			if( newScriptListOwner != _scriptListOwnerID )
			{
				_scriptListOwnerID = newScriptListOwner; 
				updateScriptList();	
			}
			
			var newSelectedScriptID:int = -1;
			if( model.selectedScript )
			{
				newSelectedScriptID = model.selectedScript.id;
			}
			
			if( newSelectedScriptID != _selectedScriptID )
			{
				updateTextArea();
			}
		}
		
		
		private function updateTextArea():void
		{
			_lazyChangeReporter.reset();
			
			var script:Script = model.selectedScript;
			if( script )
			{
				_selectedScriptID = script.id;

				_scriptArea.text = script.text;
				_scriptArea.opaqueBackground = textAreaBackgroundColor;
				
				_scriptArea.editable = true;			
				_scriptArea.focusEnabled = true;
				_scriptArea.enabled = true;
				
				_scriptArea.updateCodeHighlight();
			}
			else
			{
				_selectedScriptID = -1;

				_scriptArea.text = "";
				_scriptArea.opaqueBackground = null;
				
				_scriptArea.editable = false;			
				_scriptArea.focusEnabled = false;
				_scriptArea.enabled = false;
			}
		}
		
		
		private function get textAreaBackgroundColor():uint
		{
			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				default:
				case ColorScheme.LIGHT:
					return 0xdfdfdf;
					
				case ColorScheme.DARK:
					return 0x202020;
			}
		}


		private function updateScriptList():void
		{
			_scriptList.removeAllChildren();

			for each( var scriptListItem:ScriptListItem in _scriptItems )
			{
				scriptListItem.free();
			}
			
			_scriptItems = new Object;
			
			var scriptOwner:IntegraContainer = model.getDataObjectByID( _scriptListOwnerID ) as IntegraContainer;
			Assert.assertNotNull( scriptOwner );
			
			var scripts:Object = scriptOwner.scripts;
			Assert.assertNotNull( scripts );
			
			_scriptList.addChild( _newScriptButton );

			for each( var script:Script in scripts )
			{
				addScript( script );
			}
		}
		
		
		private function addScript( script:Script ):void
		{
			Assert.assertNotNull( script );
			var scriptID:int = script.id;
			
			var item:ScriptListItem = new ScriptListItem( scriptID );
			
			_scriptItems[ scriptID ] = item;
			
			for( var insertionIndex:int = 0; insertionIndex < _scriptList.numChildren - 1; insertionIndex++ )
			{
				var childID:int = ( _scriptList.getChildAt( insertionIndex ) as ScriptListItem ).scriptID;
				
				if( childID > scriptID )
				{
					break;
				}
			} 
			
			_scriptList.addChildAt( item, insertionIndex );
		}


		private function onClickNewScriptButton( event:MouseEvent ):void
		{
			Assert.assertTrue( model.getDataObjectByID( _scriptListOwnerID ) is IntegraContainer );
			
			controller.processCommand( new AddScript( _scriptListOwnerID ) );
		}
		
		
		private function onResize( event:Event ):void
		{
			_scriptList.height = height - _padding * 2;
			_scriptArea.height = height - _padding * 2;
		}
		
		
		private function commitScript():void
		{
			if( _selectedScriptID >= 0 )
			{
				controller.processCommand( new SetScript( _selectedScriptID, _scriptArea.text ) );
			}
		}
		
		
		private function onUpdateExecute( menuItem:Object ):void
		{
			menuItem.enabled = ( _selectedScriptID >= 0 );
		}
		
		
		private function execute():void
		{
			commitScript();
			controller.processCommand( new ExecuteScript( _selectedScriptID ) );	
		}
		
		
		private function getScriptListOwner():int
		{
			var block:Block = model.primarySelectedBlock;
			if( block ) 
			{
				return block.id;
			}
			
			var track:Track = model.selectedTrack;
			if( track )
			{
				return track.id;
			}
			
			return model.project.id;
		}
		
		
		private var _scriptListOwnerID:int = -1;
		private var _selectedScriptID:int = -1;
		private var _scriptItems:Object = new Object;
		
		private var _hBox:HBox = new HBox;
		private var _scriptList:VBox = new VBox;
		private var _newScriptButton:Button = new Button;
		private var _scriptArea:ScriptingViewTextArea = new ScriptingViewTextArea;
		private var _lazyChangeReporter:LazyChangeReporter = null;

		[Bindable] 
        private var contextMenuData:Array = 
        [
            { label: "Execute", keyEquivalent: "e", keyCode: Keyboard.E, ctrlKey: true, handler: execute, updater: onUpdateExecute } 
        ];
        
      	private const _padding:Number = 10;
	}
}