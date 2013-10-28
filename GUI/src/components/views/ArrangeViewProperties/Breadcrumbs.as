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
	import components.controller.serverCommands.RenameObject;
	import components.controller.serverCommands.SelectScene;
	import components.controller.userDataCommands.SetPrimarySelectedChild;
	import components.model.Info;
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.InfoView.InfoMarkupForViews;
	import components.views.IntegraView;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import flashx.textLayout.formats.TextDecoration;
	
	import flexunit.framework.Assert;
	
	import mx.containers.HBox;
	import mx.controls.Label;
	import mx.events.ResizeEvent;
	

	public class Breadcrumbs extends IntegraView
	{
		public function Breadcrumbs()
		{
			super();
		
			addUpdateMethod( SetPrimarySelectedChild, onSelectionChanged );
			addUpdateMethod( SelectScene, onSceneSelectionChanged );
			addUpdateMethod( RenameObject, onObjectRenamed );
			
			_hbox.setStyle( "horizontalGap", 0 );
			_hbox.setStyle( "paddingLeft", 0 );
			_hbox.setStyle( "paddingRight", 0 );
			_hbox.setStyle( "verticalAlign", "middle" );
			addElement( _hbox );
			
			addEventListener( Event.RESIZE, onResize ); 
		}
		
		
		override public function getInfoToDisplay( event:Event ):Info
		{
			return InfoMarkupForViews.instance.getInfoForView( "ArrangeViewProperties/Breadcrumbs" );
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
						_color = lightColor;
						break;
						
					case ColorScheme.DARK:
						_color = darkColor;
						break;
				}

				for each( var child:Label in _hbox.getChildren() )
				{
					child.setStyle( "color", _color );
				}
			}

			if( !style || style == FontSize.STYLENAME )
			{
				callLater( update );
			}
		}


		override protected function onAllDataChanged():void
		{
			update();
		}
		
		
		
		private function onSelectionChanged( command:SetPrimarySelectedChild ):void
		{
			update();
		}

		
		private function onSceneSelectionChanged( command:SelectScene ):void
		{
			update();
		}
		
		
		private function onObjectRenamed( command:RenameObject ):void
		{
			update();
		}
		
		
		private function update():void
		{
			_hbox.removeAllChildren();
			
			if( model.selectedTrack != null )
			{
				addLink( model.project.name, onDeselectEverything );
				
				if( model.primarySelectedBlock != null )
				{
					addLink( model.selectedTrack.name, onDeselectBlock );
				} 
			}
			else
			{
				if( model.selectedScene != null )
				{
					addLink( model.project.name, onDeselectEverything );
				}
			}
			
			_hbox.validateNow();
			width = _hbox.measuredWidth;
		}
		
		
		private function addLink( linkName:String, clickHandler:Function ):void
		{
			var link:Label = new Label;
			link.text = linkName;
			link.setStyle( "color", _color );
			link.setStyle( "verticalCenter", 0 );
			
			link.addEventListener( MouseEvent.ROLL_OVER, rollOverHandler );
			link.addEventListener( MouseEvent.ROLL_OUT, rollOutHandler );
			link.addEventListener( MouseEvent.CLICK, clickHandler );
			
			link.height = getLabelHeight( link );
			
			_hbox.addChild( link );
			
			var raquo:Label = new Label;
			raquo.text = "»";
			raquo.setStyle( "color", _color );
			raquo.setStyle( "verticalCenter", 0 );

			raquo.height = link.height;
			
			_hbox.addChild( raquo );
		}
		
		
		private function onDeselectEverything( event:MouseEvent ):void
		{
			if( model.primarySelectedBlock )
			{
				Assert.assertNotNull( model.selectedTrack );
				controller.processCommand( new SetPrimarySelectedChild( model.selectedTrack.id, -1 ) );
			}

			if( model.selectedTrack )
			{
				controller.processCommand( new SetPrimarySelectedChild( model.project.id, -1 ) );
			}

			if( model.selectedScene )
			{
				controller.processCommand( new SelectScene( -1 ) );
			}
		}


		private function onDeselectBlock( event:MouseEvent ):void
		{
			Assert.assertNotNull( model.primarySelectedBlock );
			Assert.assertNotNull( model.selectedTrack );

			controller.processCommand( new SetPrimarySelectedChild( model.selectedTrack.id, -1 ) );
		}

		
		private function rollOverHandler( event:MouseEvent ):void
		{
			Assert.assertTrue( event.target is Label );	
			
			var link:Label = event.target as Label;
			link.setStyle( "textDecoration", TextDecoration.UNDERLINE );
		}

		
		private function rollOutHandler( event:MouseEvent ):void
		{
			Assert.assertTrue( event.target is Label );	

			var link:Label = event.target as Label;
			link.setStyle( "textDecoration", TextDecoration.NONE );
		}

		
		private function onResize( event:ResizeEvent ):void
		{
			_hbox.height = height;
		}
		

		private function getLabelHeight( label:Label ):Number
		{
			if( !isNaN( label.textWidth ) ) 
			{
				//trick the label into remeasuring its height
				var prevText:String = label.text;
				label.text += "!";
				label.validateNow();
				label.text = prevText;
				label.validateNow();
			}
			
			return label.textHeight * 1.2;
		}		
		
		
		private var _hbox:HBox = new HBox;
		
		private var _color:uint = 0;
		
		private static const lightColor:uint = 0x747474;
		private static const darkColor:uint = 0x8c8c8c;
	}
}