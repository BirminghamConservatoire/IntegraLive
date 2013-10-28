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

package components.views.ModuleGraph
{
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.BevelFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.TextInput;
	
	import components.controller.IntegraController;
	import components.controller.serverCommands.RenameObject;
	import components.controller.userDataCommands.SetModuleInstanceLiveViewControls;
	import components.model.Info;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.ModuleInstance;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.TickButtonSkin;
	
	import flexunit.framework.Assert;


	public class ModuleGraphElement extends Canvas
	{
		public function ModuleGraphElement( moduleID:int, model:IntegraModel, controller:IntegraController )
		{
			super();

			horizontalScrollPolicy = "off";
			verticalScrollPolicy = "off";

			_moduleID = moduleID;
			_model = model;
			_controller = controller;

			_nameEdit.setStyle( "left", 0 );
			_nameEdit.setStyle( "right", 0 );
			_nameEdit.setStyle( "bottom", 0 );
			_nameEdit.setStyle( "textAlign", "center" );
			_nameEdit.setStyle( "borderStyle", "none" );
			_nameEdit.setStyle( "focusAlpha", 0 );
			_nameEdit.setStyle( "backgroundAlpha", 0 );
			_nameEdit.addEventListener( MouseEvent.DOUBLE_CLICK, onOpenNameEdit );
			_nameEdit.addEventListener( FocusEvent.FOCUS_OUT, onNameEditChange );
			_nameEdit.addEventListener( KeyboardEvent.KEY_UP, onNameEditKeyUp );
			_nameEdit.restrict = IntegraDataObject.legalObjectNameCharacterSet;
			setNameEditable( false );
			updateNameEdit();
			addChild( _nameEdit );

			_liveButton.toggle = true;
			_liveButton.setStyle( "right", liveButtonOffset );
			_liveButton.setStyle( "top", liveButtonOffset );
			_liveButton.setStyle( "skin", TickButtonSkin );
			_liveButton.addEventListener( MouseEvent.CLICK, onClickLiveButton );
			_liveButton.addEventListener( MouseEvent.DOUBLE_CLICK, onClickLiveButton );
			addChild( _liveButton );
			
			updateBevelFilter();
		}
		
		
		public function get moduleID():int { return _moduleID; }

		public function addInputPin( inputPin:ConnectionPin ):void
		{
			_inputPins.push( inputPin );
		}


		public function addOutputPin( outputPin:ConnectionPin ):void
		{
			_outputPins.push( outputPin );
		}
		
		
		public function set liveViewElement( isLiveView:Boolean ):void
		{
			_liveButton.selected = isLiveView;
		}


		public function updateNameEdit():void
		{
			if( _moduleID < 0 ) return;

			if( _nameEdit.editable ) 
			{
				commitNameEdit();
			}
		
			_nameEdit.text = _model.getModuleInstance( moduleID ).name;
		}


		public function updateIOPins():void
		{
			var shouldMoveToFront:Boolean = isSelected() || isPrimarySelected();
		
			var gridSize:Number = FontSize.getTextRowHeight( this );
			if( isNaN( gridSize ) ) 
			{
				return;
			}
			
			var maximumPinSpacing:Number = gridSize * 0.75; 
			var pinSpacing:Number = Math.min( maximumPinSpacing, height / Math.max( Math.max( _inputPins.length, _outputPins.length ), 1 ) );

			var pinHeight:Number = FontSize.getTextRowHeight( this );
			var pinWidth:Number = pinHeight * 2;
			pinHeight = Math.min( pinHeight, pinSpacing * 0.9 );
			 
			for( var i:int = 0; i < _inputPins.length; i++ )
			{
				var pin:ConnectionPin = _inputPins[ i ];
				pin.x = x - pinWidth - 1;
				pin.y = y + pinSpacing / 4 + i * pinSpacing;
				pin.width = pinWidth;
				pin.height = pinHeight;
				pin.redraw();
				
				if( shouldMoveToFront )
				{
					moveToFront( pin );
				}
			}

			for( i = 0; i < _outputPins.length; i++ )
			{
				pin = _outputPins[ i ];
				pin.x = x + width + 1;
				pin.y = y + pinSpacing / 4 + i * pinSpacing;
				pin.width = pinWidth;
				pin.height = pinHeight;
				pin.redraw();
				
				if( shouldMoveToFront )
				{
					moveToFront( pin );
				}
			}
		}
		
		
		public function moveElementToFront():void
		{
			moveToFront( this );
		}
		

		public function isMouseInRepositionArea():Boolean
		{
			var globalMouse:Point = localToGlobal( new Point( mouseX, mouseY ) );
			if( !hitTestPoint( globalMouse.x, globalMouse.y ) )
			{
				return false;
			} 
			
			if( _liveButton.hitTestPoint( globalMouse.x, globalMouse.y ) )
			{
				return false;
			}
			
			return true;
		}
		
		
		public function getLinkPoint( attributeName:String, linkPoint:Point, trackOffset:Point ):void
		{
			for each( var pin:ConnectionPin in _inputPins )
			{
				if( pin.attributeName == attributeName )
				{
					linkPoint.copyFrom( pin.linkPoint );
					trackOffset.copyFrom( getTrackPoint( _inputPins ).subtract( linkPoint ) );
					return;
				}
			}
			
			for each( pin in _outputPins )
			{
				if( pin.attributeName == attributeName )
				{
					linkPoint.copyFrom( pin.linkPoint );
					trackOffset.copyFrom( getTrackPoint( _outputPins ).subtract( linkPoint ) );
					return;
				}
			}
		}
		
		
		public function getFirstInputPoint( linkPoint:Point, trackOffset:Point ):void
		{
			Assert.assertTrue( _inputPins.length > 0 );

			linkPoint.copyFrom( _inputPins[ 0 ].linkPoint );
			trackOffset.copyFrom( getTrackPoint( _inputPins ).subtract( linkPoint ) );
		}


		public function getFirstOutputPoint( linkPoint:Point, trackOffset:Point ):void
		{
			Assert.assertTrue( _outputPins.length > 0 );

			linkPoint.copyFrom( _outputPins[ 0 ].linkPoint );
			trackOffset.copyFrom( getTrackPoint( _outputPins ).subtract( linkPoint ) );
		}
		
		
		public function getInfoToDisplay( event:Event ):Info
		{
			if( event.target == _liveButton )
			{
				return InfoMarkupForViews.instance.getInfoForView( "ModuleGraph/LiveViewButton" );
			}
			else
			{
				var moduleInstance:ModuleInstance = _model.getModuleInstance( _moduleID );
				Assert.assertNotNull( moduleInstance );
			
				return moduleInstance.interfaceDefinition.interfaceInfo.info;
			}
		}

		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					case ColorScheme.LIGHT:
						_normalBottomBackgroundColor = 0xffffff;
						_normalTopBackgroundColor = 0xe6e6e6;
						_selectedBottomBackgroundColor = 0xe4e4e4;
						_selectedTopBackgroundColor = 0xcfcfcf;
						_borderColor = 0x5d5d5d;
						break;
						
					case ColorScheme.DARK:
						_normalBottomBackgroundColor = 0x000000;
						_normalTopBackgroundColor = 0x1a1a1a;
						_selectedBottomBackgroundColor = 0x1c1c1c;
						_selectedTopBackgroundColor = 0x313131;
						_borderColor = 0xa3a3a3;
						break;
				}
				
				invalidateDisplayList();
				updateBevelFilter();
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				_liveButton.width = FontSize.getButtonSize( this );
				_liveButton.height = FontSize.getButtonSize( this );
			}
		}
		
		
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );	
			
			if( !parent ) return;

            graphics.clear();

			var selected:Boolean = isSelected();
			var primarySelected:Boolean = isPrimarySelected();
			
			var topBackgroundColor:int = selected ? _selectedTopBackgroundColor : _normalTopBackgroundColor; 
			var bottomBackgroundColor:int = selected ? _selectedBottomBackgroundColor : _normalBottomBackgroundColor; 

			var colors:Array = [ topBackgroundColor, bottomBackgroundColor ];
			var alphas:Array = [ 1, 1 ];
			var ratios:Array = [0x00, 0xFF];

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, Math.PI / 2 );

			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
			if( primarySelected )
			{
				graphics.lineStyle( 2, _borderColor );
			}
			else
			{
				graphics.lineStyle( 1, _borderColor, 0.3 );
			}
			
        	graphics.drawRoundRect( 0, 0, width, height, cornerRadius, cornerRadius );
        	graphics.endFill();		
        } 
        
        
		private function onClickLiveButton( event:Event ):void
		{
			_controller.processCommand( new SetModuleInstanceLiveViewControls( _moduleID, !_model.hasLiveViewControls( _moduleID ) ) );			
		}
		
		
		private function isSelected():Boolean
		{
			if( _moduleID < 0 ) return false;
			
			return _model.isObjectSelected( _moduleID );
		}	


		private function isPrimarySelected():Boolean
		{
			if( _moduleID < 0 ) return false;

			return _model.isModuleInstancePrimarySelected( _moduleID );
		}	


		private function updateBevelFilter():void
		{
			var highlightColor:uint;
			var shadowColor:uint;

			switch( getStyle( ColorScheme.STYLENAME ) )
			{
				case ColorScheme.LIGHT:
					highlightColor = 0xd0d0d0;
					shadowColor = 0xb0b0b0;
					break;
					
				case ColorScheme.DARK:
					highlightColor = 0x707070;
					shadowColor = 0x101010;
					break;
			}		
			
			var filterArray:Array = new Array;
			var filter:BevelFilter = new BevelFilter( 5, 45, highlightColor, 0.5, shadowColor, 0.5 );
			filterArray.push( filter );
			
			filters = filterArray;
		}
		
		
		private function onOpenNameEdit( event:MouseEvent ):void
		{
			setNameEditable( true );
		}
		
		
		private function onNameEditChange( event:FocusEvent ):void
		{
			commitNameEdit();
		}
		
		
		private function commitNameEdit():void
		{
			if( _nameEdit.text != _model.getModuleInstance( _moduleID ).name )
			{
				_controller.processCommand( new RenameObject( _moduleID, _nameEdit.text ) );
			} 
			
			setNameEditable( false );
		}
		

		private function onNameEditKeyUp( event:KeyboardEvent ):void
		{
			switch( event.keyCode )
			{
				case Keyboard.ENTER:
					setFocus();			//force changes to be committed
					break;

				case Keyboard.ESCAPE:
					updateNameEdit();
					setNameEditable( false );
					break;
					
				default:
					break;
			} 
		}
		
		
		private function setNameEditable( editable:Boolean ):void
		{
			_nameEdit.editable = editable;			
			_nameEdit.focusEnabled = editable;
			_nameEdit.enabled = editable;
			
			if( editable )
			{
				_nameEdit.selectionBeginIndex = 0;
				_nameEdit.selectionEndIndex = _nameEdit.text.length;
				_nameEdit.setFocus();
			}
		}		
		
		
		private function moveToFront( element:DisplayObject ):void
		{
			if( !element.parent || !element.parent.contains( element ) ) 
			{
				return;
			}
			
			element.parent.setChildIndex( element, element.parent.numChildren - 1 );
		}
		
		
		private function getTrackPoint( pins:Vector.<ConnectionPin> ):Point 
		{
			Assert.assertTrue( pins && pins.length > 0 );
			
			var firstPin:Point = pins[ 0 ].linkPoint;
			var lastPin:Point = pins[ pins.length - 1 ].linkPoint;
			
			return Point.interpolate( firstPin, lastPin, 0.5 );
		}
		
		
   		private var _moduleID:int;
   		
   		private var _model:IntegraModel;
		private var _controller:IntegraController;

		private var _nameEdit:TextInput = new TextInput;
		private var _liveButton:Button = new Button;

		private var _inputPins:Vector.<ConnectionPin> = new Vector.<ConnectionPin>;
		private var _outputPins:Vector.<ConnectionPin> = new Vector.<ConnectionPin>;

		private var _normalBottomBackgroundColor:uint;
		private var _normalTopBackgroundColor:uint;
		private var _selectedBottomBackgroundColor:uint;
		private var _selectedTopBackgroundColor:uint;
		private var _borderColor:uint;
		private var _addedToStage:Boolean = false;
		
		private static const cornerRadius:Number = 12;
		private static const liveButtonOffset:int = 4;
	}
}
