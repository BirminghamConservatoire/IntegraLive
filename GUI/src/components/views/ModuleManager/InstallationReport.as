package components.views.ModuleManager
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.managers.PopUpManager;
	
	import components.model.userData.ColorScheme;
	import components.utils.FontSize;
	import components.views.Skins.TextButtonSkin;

	public class InstallationReport extends Canvas
	{
		public function InstallationReport() 
		{
			super();
			
			_label.setStyle( "fontWeight", "bold" );
			_label.text = "Installation Report:";
			
			addChild( _label );
			
			_report.setStyle( "borderStyle", "none" );
			_report.setStyle( "focusAlpha", 0 );
			_report.setStyle( "paddingLeft", 20 );
			_report.setStyle( "paddingRight", 20 );
			_report.setStyle( "paddingTop", 20 );
			_report.setStyle( "paddingBottom", 20 );
			addChild( _report );
			
			_closeButton.setStyle( "skin", TextButtonSkin );
			_closeButton.label = "OK";
			_closeButton.addEventListener( MouseEvent.CLICK, onCloseReport );
			addChild( _closeButton );
		}
		
		
		public function displayReport( text:String, parent:DisplayObject ):void
		{
			_report.text = text;
			
			if( !_showing )
			{
				PopUpManager.addPopUp( this, parent, true );
				PopUpManager.centerPopUp( this );
				_showing = true;
			}
		}
		
		
		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_backgroundColor = 0xffffff;
						_borderColor = 0xaaccdf;
						_label.setStyle( "color", 0x747474 );
						setButtonTextColor( _closeButton, 0x6D6D6D, 0x9e9e9e );
						_report.setStyle( "color", 0x747474 );
						_report.setStyle( "backgroundColor", 0xcfcfcf );
						break;
					
					case ColorScheme.DARK:
						_backgroundColor = 0x000000;
						_borderColor = 0x214356;
						_label.setStyle( "color", 0x8c8c8c );
						setButtonTextColor( _closeButton, 0x939393, 0x626262 );
						_report.setStyle( "color", 0x8c8c8c );
						_report.setStyle( "backgroundColor", 0x313131 );
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
			
			graphics.beginFill( _backgroundColor );
			graphics.lineStyle( 4, _borderColor );
			
			graphics.drawRoundRect( 0, 0, width, height, ModuleManagerList.cornerRadius * 2, ModuleManagerList.cornerRadius * 2 );  
		}
		
		
		private function updateSize():void
		{
			if( !parentDocument ) return;
			
			//calculate window size
			var rowHeight:Number = FontSize.getTextRowHeight( this );
			width = Math.min( rowHeight * 20, parentDocument.width );
			height = Math.min( rowHeight * 12, parentDocument.height );
			
			var internalMargin:Number = rowHeight / 2;
			
			_label.x = internalMargin;
			_label.y = internalMargin;
			
			_report.x = internalMargin;
			_report.y = internalMargin * 3;
			_report.width = width - internalMargin * 2;
			_report.height = height - _report.y - internalMargin * 3 - FontSize.getTextRowHeight( this );
			
			_closeButton.width = width / 3;
			_closeButton.height = FontSize.getTextRowHeight( this );
			_closeButton.y = height - internalMargin - _closeButton.height;
			_closeButton.setStyle( "horizontalCenter", 0 );			
		}
		

		private function setButtonTextColor( button:Button, color:uint, disabledColor:uint ):void
		{
			button.setStyle( "color", color );
			button.setStyle( "textRollOverColor", color );
			button.setStyle( "textSelectedColor", color );
			button.setStyle( "disabledColor", disabledColor );
		}
		
		
		private function onCloseReport( event:Event ):void
		{
			PopUpManager.removePopUp( this );
			_showing = false;
		}

		private var _showing:Boolean = false;
		
		private var _label:Label = new Label;
		private var _report:TextArea = new TextArea;
		private var _closeButton:Button = new Button;
		
		private var _backgroundColor:uint;
		private var _borderColor:uint;

	}
}