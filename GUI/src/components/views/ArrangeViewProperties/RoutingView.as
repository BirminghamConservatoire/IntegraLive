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
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.VBox;
	import mx.controls.Button;
	
	import components.controller.serverCommands.AddScaledConnection;
	import components.controller.serverCommands.RemoveScaledConnection;
	import components.controller.serverCommands.SetConnectionRouting;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Info;
	import components.model.IntegraContainer;
	import components.model.Scaler;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.utils.Utilities;
	import components.views.IntegraView;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.Skins.AddButtonSkin;
	
	import flexunit.framework.Assert;

	
	public class RoutingView extends IntegraView
	{
		public function RoutingView()
		{
			super();
			
			_vbox.percentWidth = 100;
			_vbox.percentHeight = 100;
			_vbox.setStyle( "paddingLeft", _padding );
			_vbox.setStyle( "paddingRight", _padding );
			_vbox.setStyle( "paddingTop", _padding );
			_vbox.setStyle( "paddingBottom", _padding );
			addElement( _vbox );
			
			_newItemButton.setStyle( "skin", AddButtonSkin );
			_newItemButton.setStyle( "fillAlpha", 1 );
			_newItemButton.addEventListener( MouseEvent.CLICK, onClickNewItemButton );
			
			addUpdateMethod( SetPrimarySelectedChild, onPrimarySelectionChanged );
			addUpdateMethod( AddScaledConnection, onScaledConnectionAdded );
			addUpdateMethod( RemoveScaledConnection, onScaledConnectionRemoved );
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
						_newItemButton.setStyle( "color", 0xcfcfcf );
						_newItemButton.setStyle( "fillColor", 0x747474 );
						break;
						
					case ColorScheme.DARK:
						_newItemButton.setStyle( "color", 0x313131 );
						_newItemButton.setStyle( "fillColor", 0x8c8c8c );
						break;
				}
			}
			
			if( !style || style == FontSize.STYLENAME )
			{
				_newItemButton.width = FontSize.getButtonSize( this );
				_newItemButton.height = FontSize.getTextRowHeight( this ) + 4;
			}
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			if( event.target == _newItemButton ) 
			{
				return InfoMarkupForViews.instance.getInfoForView( "CreateRoutingButton" );
			}

			return InfoMarkupForViews.instance.getInfoForView( "RoutingView" );
		}		
		
		
		override protected function onAllDataChanged():void
		{
			updateAll();
		} 
		
		
		private function onPrimarySelectionChanged( command:SetPrimarySelectedChild ):void
		{
			var containerID:int = -1;
			var selectedContainer:IntegraContainer = model.selectedContainer;
			if( selectedContainer )
			{
				containerID = selectedContainer.id;
			}
			
			if( containerID != _containerID )
			{
				updateAll();
			}
		}
		
		
		private function updateAll():void
		{
			_vbox.removeAllChildren();
			for each( var routingItem:RoutingItem in _routingItems )
			{
				routingItem.free();
			}
			_routingItems = new Object;
			
			var container:IntegraContainer = model.selectedContainer;
			if( container )
			{
				_containerID = container.id;
				
				_vbox.addElement( _newItemButton );
				
				for each( var scaler:Scaler in container.scalers )
				{
					addRoutingViewItem( scaler );
				}
			}
			else
			{
				_containerID = -1;
			}
		}


		private function onScaledConnectionAdded( command:AddScaledConnection ):void
		{
			if( command.containerID != _containerID ) 
			{
				return;
			}

			var scaler:Scaler = model.getScaler( command.scalerID );
			Assert.assertNotNull( scaler );
			
			addRoutingViewItem( scaler );
		}



		private function onScaledConnectionRemoved( command:RemoveScaledConnection ):void
		{
			var scalerID:int = command.scalerID;
			if( !_routingItems.hasOwnProperty( scalerID ) )
			{
				return;
			}
			
			removeRoutingViewItem( scalerID );
		}
		
		
		private function addRoutingViewItem( scaler:Scaler ):void
		{
			Assert.assertNotNull( scaler );
			var item:RoutingItem = new RoutingItem( scaler.id );
			
			_routingItems[ scaler.id ] = item;
			
			for( var insertionIndex:int = 0; insertionIndex < _vbox.numChildren - 1; insertionIndex++ )
			{
				var childID:int = ( _vbox.getChildAt( insertionIndex ) as RoutingItem ).scalerID;
				
				if( childID > scaler.id )
				{
					break;
				}
			} 
			
			_vbox.addElementAt( item, insertionIndex );
		}
		
		
		private function removeRoutingViewItem( scalerID:int ):void
		{
			var routingItem:RoutingItem = _routingItems[ scalerID ];
			Assert.assertNotNull( routingItem );
			
			_vbox.removeChild( routingItem );
			routingItem.free();
			delete _routingItems[ scalerID ];
			
		}
		
		
		private function onClickNewItemButton( event:MouseEvent ):void
		{
			var container:IntegraContainer = model.selectedContainer;
			Assert.assertNotNull( container );
			
			controller.processCommand( new AddScaledConnection( container.id ) ); 
		}
		
		
		private var _containerID:int = -1;
		private var _vbox:VBox = new VBox;
		private var _newItemButton:Button = new Button;
				
		private var _routingItems:Object = new Object;		//maps connection ids to routing items

      	private const _padding:Number = 10;
	}
}