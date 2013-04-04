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


package components.views.LiveView
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import __AS3__.vec.Vector;
	
	import components.controller.serverCommands.AddScene;
	import components.controller.serverCommands.RemoveScene;
	import components.controller.serverCommands.SelectScene;
	import components.controller.userDataCommands.SetColorScheme;
	import components.controller.userDataCommands.SetSceneKeybinding;
	import components.model.Info;
	import components.model.Scene;
	import components.model.userData.ColorScheme;
	import components.model.userData.SceneUserData;
	import components.model.userData.ViewMode;
	import components.utils.DragImage;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.MouseCapture;
	import components.views.InfoView.InfoMarkupForViews;
	
	import flexunit.framework.Assert;

	public class KeybindingView extends IntegraView
	{
		public function KeybindingView()
		{
			super();
		
			minHeight = 100;
			height = 200;
			maxHeight = 400;
			
			horizontalScrollPolicy = ScrollPolicy.OFF; 
			verticalScrollPolicy = ScrollPolicy.OFF;   
			
			addUpdateMethod( AddScene, onSceneAdded );
			addUpdateMethod( RemoveScene, onSceneRemoved );
			addUpdateMethod( SetSceneKeybinding, onSceneKeybindingChanged );
			addUpdateMethod( SelectScene, onSceneSelected );
			addColorChangingCommand( SetColorScheme );
			
			addEventListener( Event.RESIZE, onResize );

			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );

			for( var i:int = 0; i < SceneUserData.KEYBINDINGS.length; i++ )
			{
				createKeyIcon( SceneUserData.KEYBINDINGS.charAt( i ) );
			}
		}


		override public function get title():String 
		{ 
			return "Scene Shortcuts"; 
		}
		

		override public function get color():uint
		{
			switch( model.project.userData.colorScheme )
			{
				default:
				case ColorScheme.LIGHT:
					return 0x747474;
					
				case ColorScheme.DARK:
					return 0x8c8c8c;
			}
		}
		
		
		override public function get isSidebarColours():Boolean { return true; }

		
		override public function getInfoToDisplay( event:MouseEvent ):Info
		{
			var keyIcon:KeyIcon = Utilities.getAncestorByType( event.target, KeyIcon ) as KeyIcon;
			if( keyIcon )
			{
				if( _mapKeyToSceneID.hasOwnProperty( keyIcon.keyLabel ) )
				{
					var sceneID:int = _mapKeyToSceneID[ keyIcon.keyLabel ];
					
					return model.getScene( sceneID ).info;					
				}
			}
			
			return InfoMarkupForViews.instance.getInfoForView( "SceneShortcuts" );
		}
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		}


		private function onSceneAdded( command:AddScene ):void
		{
			updateAll();
		}


		private function onSceneRemoved( command:RemoveScene ):void
		{
			updateAll();
		}


		private function onSceneKeybindingChanged( command:SetSceneKeybinding ):void
		{
			updateAll();
		}
		
		
		private function onSceneSelected( command:SelectScene ):void
		{
			updateKeyHighlighting();
		}
		
		
		private function onResize( event:Event ):void
		{
			repositionKeys();
		}
		
		
		private function updateAll():void
		{
			_mapKeyToSceneID = new Object;

			for each( var scene:Scene in model.project.player.scenes )
			{
				var key:String = scene.keybinding;
				if( !key )
				{
					continue;
				}
				
				Assert.assertFalse( _mapKeyToSceneID.hasOwnProperty( key ) );
				_mapKeyToSceneID[ key ] = scene.id;
			} 
			
			for( key in _keyIcons )
			{
				var keyIcon:KeyIcon = _keyIcons[ key ];
				Assert.assertNotNull( keyIcon );
				
				if( _mapKeyToSceneID.hasOwnProperty( key ) )
				{
					var sceneID:int = _mapKeyToSceneID[ key ];
					scene = model.getScene( sceneID );
					Assert.assertNotNull( scene );
					 
					keyIcon.sceneLabel = scene.name;
				}
				else
				{
					keyIcon.sceneLabel = "";
				}
			}
			
			updateKeyHighlighting();
		}
		
		
		private function updateKeyHighlighting():void
		{
			var selectedSceneID:int = model.selectedScene ? model.selectedScene.id : -1; 
			
			for( var key:String in _keyIcons )
			{
				var keyIcon:KeyIcon = _keyIcons[ key ];
				Assert.assertNotNull( keyIcon );
				
				if( _mapKeyToSceneID.hasOwnProperty( key ) )
				{
					var sceneID:int = _mapKeyToSceneID[ key ];
					keyIcon.highlighted = ( sceneID == selectedSceneID );  
				}
				else
				{
					keyIcon.highlighted = false;  
				}
			}
		}
		
		
		private function createKeyIcon( key:String ):void
		{
			var keyIcon:KeyIcon = new KeyIcon;
			keyIcon.keyLabel = key;
			keyIcon.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDownKeyIcon );
			keyIcon.addEventListener( DragEvent.DRAG_OVER, onDragOver );
			keyIcon.addEventListener( DragEvent.DRAG_EXIT, onDragExit );
			keyIcon.addEventListener( DragEvent.DRAG_DROP, onDragDrop );
			 
			_keyIcons[ key ] = keyIcon;
			addElement( keyIcon );
		}
		

		private function repositionKeys():void
		{
			var longestKeyRow:Number = 0;
			var xOffset:Number = 0;
			for each( var keyRow:String in _keyRows )
			{
				longestKeyRow = Math.max( longestKeyRow, keyRow.length + xOffset );
				xOffset += _rowXoffset;
			}
			
			var maxKeyWidth:Number = ( width - _edgeMargin * 2 ) / ( longestKeyRow + 2 ) - _internalMargin;
			var maxKeyHeight:Number = ( height - _edgeMargin * 2 ) / _keyRows.length - _internalMargin;
			var keySize:Number = Math.min( maxKeyWidth, maxKeyHeight );
			var keySpace:Number = keySize + _internalMargin;
			
			var keyboardWidth:Number = longestKeyRow * keySpace - _internalMargin;
			var keyboardHeight:Number = _keyRows.length * keySpace - _internalMargin;
			
			var rowStartX:Number = ( width - keyboardWidth ) / 2;
			var rowY:Number = ( height - keyboardHeight ) / 2;
			
			var keyboardStartX:Number = rowStartX - keySpace;
			var keyboardEndX:Number = rowStartX + keyboardWidth + keySpace;
			
			var fillerIconIndex:int = 0;
			
			for each( keyRow in _keyRows )
			{
				//position left fillers
				//var amountOfLeftFiller:Number = ( rowStartX - keyboardStartX ) / keySpace;
				var amountOfLeftFiller:Number = Math.max( 1, ( rowStartX - keyboardStartX ) / keySpace );
				var numberOfLeftFillers:int = Math.floor( amountOfLeftFiller );
				Assert.assertTrue( numberOfLeftFillers >= 1 );

				var widthScaleOfFirstLeftFiller:Number = 1 + amountOfLeftFiller - numberOfLeftFillers; 
				Assert.assertTrue( widthScaleOfFirstLeftFiller >= 1 && widthScaleOfFirstLeftFiller <= 2 );

				for( var leftFillerIterator:int = 0; leftFillerIterator < numberOfLeftFillers; leftFillerIterator++ )
				{
					var leftFiller:KeyIcon = getFillerIcon( fillerIconIndex );
					fillerIconIndex++;
					
					if( leftFillerIterator == 0 )
					{
						leftFiller.x = keyboardStartX;
						leftFiller.width = keySize * widthScaleOfFirstLeftFiller;
					}
					else
					{
						leftFiller.x = keyboardStartX + leftFillerIterator * keySpace + ( widthScaleOfFirstLeftFiller - 1 ) * keySize;
						leftFiller.width = keySize;
					}
					
					leftFiller.y = rowY;
					leftFiller.height = keySize;
				} 

				//position right fillers
				var endOfKeyRow:Number = rowStartX + keyRow.length * keySpace - _internalMargin; 
				var amountOfRightFiller:Number = ( keyboardEndX - endOfKeyRow ) / keySpace;
				amountOfRightFiller = Math.max( 1, amountOfRightFiller ); 				
				
				var numberOfRightFillers:int = Math.floor( amountOfRightFiller );
				Assert.assertTrue( numberOfRightFillers >= 1 );

				var widthScaleOfLastRightFiller:Number = 1 + amountOfRightFiller - numberOfRightFillers; 
				Assert.assertTrue( widthScaleOfLastRightFiller >= 1 && widthScaleOfLastRightFiller <= 2 );

				for( var rightFillerIterator:int = 0; rightFillerIterator < numberOfRightFillers; rightFillerIterator++ )
				{
					var rightFiller:KeyIcon = getFillerIcon( fillerIconIndex );
					fillerIconIndex++;

					rightFiller.x = endOfKeyRow + rightFillerIterator * keySpace;
					
					if( rightFillerIterator < numberOfRightFillers - 1 )
					{
						rightFiller.width = keySize;
					}
					else
					{
						rightFiller.width = keySize * widthScaleOfLastRightFiller;
					}
					
					rightFiller.y = rowY;
					rightFiller.height = keySize;
				} 
				
				//position the actual keys
				for( var keyIterator:int = 0; keyIterator < keyRow.length; keyIterator++ )
				{
					var key:String = keyRow.charAt( keyIterator );
					
					if( !_keyIcons.hasOwnProperty( key ) )
					{
						Assert.assertTrue( false );
						continue;
					}
					
					var keyIcon:KeyIcon = _keyIcons[ key ];
					Assert.assertNotNull( keyIcon );
					
					keyIcon.width = keySize;
					keyIcon.height = keySize;
						
					keyIcon.x = rowStartX + keyIterator * keySpace;
					keyIcon.y = rowY;
				}
				
				rowStartX += ( _rowXoffset * keySpace );
				rowY += keySize + _internalMargin;
			}
			
			Assert.assertTrue( fillerIconIndex == _fillerIcons.length );
		}


		private function onAddedToStage( event:Event ):void
		{
			if( _addedToStage )	return;
			
			_addedToStage = true;
			
			systemManager.stage.addEventListener( KeyboardEvent.KEY_DOWN, onStageKeyDown );  			
		}


		private function onMouseDownKeyIcon( event:MouseEvent ):void
		{
			var keyIcon:KeyIcon = event.currentTarget as KeyIcon;
			var key:String = keyIcon.keyLabel;
			
			Assert.assertNull( _draggedSceneName );
			
			if( _mapKeyToSceneID.hasOwnProperty( key ) )
			{
				var sceneID:int = _mapKeyToSceneID[ keyIcon.keyLabel ];
				controller.processCommand( new SelectScene( sceneID ) );

				MouseCapture.instance.setCapture( keyIcon, onDragKeyIcon, onEndDragKeyIcon );
				_clickedKeyIcon = keyIcon;
				_clickPoint = new Point( mouseX, mouseY );
			}
		}
		
		
		private function onDragKeyIcon( event:MouseEvent ):void
		{
			if( _draggedSceneName ) return;
			
			if( _clickPoint.subtract( new Point( mouseX, mouseY ) ).length < _dragStartDistance ) return;
			
			_draggedSceneName = model.getScene( _mapKeyToSceneID[ _clickedKeyIcon.keyLabel ] ).name; 

			var dragSource:DragSource = new DragSource;
			dragSource.addData( _clickedKeyIcon, Utilities.getClassNameFromObject( _clickedKeyIcon ) );
			
			DragManager.doDrag( _clickedKeyIcon, dragSource, event );
			DragImage.addDragImage( _clickedKeyIcon, KeyIcon.highlightThickness );
			
			_clickedKeyIcon.sceneLabel = "";
			_clickedKeyIcon.highlighted = false;
			_draggedOntoOtherKey = false;
			_dragOverKey = null;
		}
		
		
		private function onEndDragKeyIcon():void
		{
			Assert.assertNotNull( _clickedKeyIcon );
			_clickedKeyIcon = null; 

			if( _draggedSceneName )
			{
				_draggedSceneName = null;
				DragImage.removeDragImage();
				
				updateAll();
			}
		}
		
		
		private function shouldAcceptDrag( event:DragEvent ):Boolean 
		{
			const hitDeflation:Number = 0.1;
			
			if( !event.dragSource.hasFormat( Utilities.getClassNameFromClass( KeyIcon ) ) )
			{
				return false;
			}
			
			var draggedKey:KeyIcon = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( KeyIcon ) ) as KeyIcon;
			var overKey:KeyIcon = event.target as KeyIcon;

			Assert.assertNotNull( draggedKey ); 
			Assert.assertNotNull( overKey ); 
			
			var overKeyRect:Rectangle = overKey.getRect( overKey );
			overKeyRect.inflate( -overKeyRect.width * hitDeflation, -overKeyRect.height * hitDeflation ); 
			if( !overKeyRect.contains( overKey.mouseX, overKey.mouseY ) )
			{
				return false;
			}			
			
			if( overKey == draggedKey ) 
			{
				return _draggedOntoOtherKey;
			}
			else
			{
				_draggedOntoOtherKey = true;
			}
			
			return !_mapKeyToSceneID.hasOwnProperty( overKey.keyLabel );
		}
		
		
		private function onDragOver( event:DragEvent ):void
		{
			if( !shouldAcceptDrag( event ) ) 
			{
				removeOverHighlighting();
				return;
			}
			
			_dragOverKey = event.target as KeyIcon;
			
			DragManager.acceptDragDrop( _dragOverKey );
			DragImage.suppressDragImage();
			
			_dragOverKey.sceneLabel = _draggedSceneName;
			var draggedKey:KeyIcon = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( KeyIcon ) ) as KeyIcon;
			
			if( model.selectedScene && model.selectedScene.id == _mapKeyToSceneID[ draggedKey.keyLabel ] )
			{
				_dragOverKey.highlighted = true;
			} 
		}
		
		
		private function onDragDrop( event:DragEvent ):void
		{
			var draggedKey:KeyIcon = event.dragSource.dataForFormat( Utilities.getClassNameFromClass( KeyIcon ) ) as KeyIcon;

			Assert.assertNotNull( draggedKey ); 
			Assert.assertNotNull( _dragOverKey );
			
			var sceneID:int = _mapKeyToSceneID[ draggedKey.keyLabel ];
			controller.processCommand( new SetSceneKeybinding( sceneID, _dragOverKey.keyLabel ) );
		}


		private function onDragExit( event:DragEvent ):void
		{
			removeOverHighlighting();
		}
		
		
		private function removeOverHighlighting():void
		{
			if( _dragOverKey )
			{
				_dragOverKey.highlighted = false;
				_dragOverKey.sceneLabel = "";
				_dragOverKey = null;
			}			
		}
		
		
		private function onStageKeyDown( event:KeyboardEvent ):void
		{
			if( model.project.userData.viewMode.mode != ViewMode.LIVE ) 
			{
				return;		//only fire scene shortcuts in Live view
			}
			
			if( event.target is TextField )
			{
				return;		//don't fire scene shortcuts when typing into a text field!
			}
			
			var key:String = String.fromCharCode( event.charCode ).toUpperCase();
			
			if( _mapKeyToSceneID.hasOwnProperty( key ) )
			{
				var sceneID:int = _mapKeyToSceneID[ key ];
				controller.processCommand( new SelectScene( sceneID ) );
				
				var keyIcon:KeyIcon = _keyIcons[ key ];
				Assert.assertNotNull( keyIcon );
			}
		}
		

		private function getFillerIcon( index:int ):KeyIcon
		{
			if( index >= _fillerIcons.length )
			{
				Assert.assertTrue( index == _fillerIcons.length ); 

				var newFillerIcon:KeyIcon = new KeyIcon;
				addElement( newFillerIcon );
				_fillerIcons.push( newFillerIcon );
			}
			
			return _fillerIcons[ index ];
		}
	
		
		private var _addedToStage:Boolean = false;
		
		private var _mapKeyToSceneID:Object = new Object;

		private var _keyIcons:Object = new Object;
		private var _fillerIcons:Vector.<KeyIcon> = new Vector.<KeyIcon>;
		
		private var _clickedKeyIcon:KeyIcon = null;
		private var _clickPoint:Point = null;
		private var _draggedSceneName:String = null;
		private var _dragOverKey:KeyIcon = null;
		private var _draggedOntoOtherKey:Boolean = false;

		private const _keyRows:Array = [ "1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM" ];
		private const _rowXoffset:Number = 0.334;
		private const _edgeMargin:Number = 10;
		private const _internalMargin:Number = 3;
		private const _dragStartDistance:Number = 3;
	}
}