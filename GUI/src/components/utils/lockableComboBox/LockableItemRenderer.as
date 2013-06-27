package components.utils.lockableComboBox
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.listClasses.ListItemRenderer;
	
	import components.views.Skins.LockButtonSkin;
	
	import flexunit.framework.Assert;
	
	public class LockableItemRenderer extends ListItemRenderer
	{
		public function LockableItemRenderer()
		{
			super();
			
			addEventListener( Event.RESIZE, onResize );
		}
		
		
		public static function get dontCloseFlag():Boolean { return _dontCloseFlag; }
		
		
		override public function set data( value:Object ):void
		{
			super.data = value;

			updatePadlock();

			updateLabel();
		}

		
		private function get shouldShowPadlock():Boolean 	{ return data.hasOwnProperty( "locked" ); }
		private function get padlockLocked():Boolean 		{ return shouldShowPadlock && data.locked == true; }
		private function get disabled():Boolean 			{ return padlockLocked || data.hasOwnProperty( "disabled" ); }
		
		
		private function updatePadlock():void
		{
			if( shouldShowPadlock )
			{
				if( !_padlock )
				{
					var padlockColor:uint = getStyle( "color" );
					
					_padlock = new Button;
					_padlock.toggle = true;
					_padlock.setStyle( "skin", LockButtonSkin );
					_padlock.setStyle( "color", padlockColor );
					_padlock.setStyle( "fillColor", padlockColor );
					_padlock.addEventListener( MouseEvent.CLICK, onClickPadlock );
					_padlock.addEventListener( MouseEvent.DOUBLE_CLICK, onClickPadlock );
					_padlock.addEventListener( MouseEvent.MOUSE_UP, onMouseUpPadlock );
					positionPadlock();
					
					addChild( _padlock );
					
					addEventListener( MouseEvent.CLICK, onClick );
					addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
				}
				
				_padlock.selected = padlockLocked;
			}
			else
			{
				if( _padlock )
				{
					removeChild( _padlock );
					_padlock = null;
				}
			}
		}
		
		
		private function onAddedToStage( event:Event ):void
		{
			if( shouldShowPadlock && !padlockLocked )
			{
				//relock on open
				data.locked = true;
				updatePadlock();
			}
		}
		
		
		private function onMouseUpPadlock( event:MouseEvent ):void
		{
			Assert.assertTrue( shouldShowPadlock );

			_dontCloseFlag = true;
			callLater( clearDontCloseFlag );
		}
		
		
		private function clearDontCloseFlag():void
		{
			_dontCloseFlag = false;
		}
		
		
		private function onClickPadlock( event:MouseEvent ):void
		{
			Assert.assertTrue( shouldShowPadlock );
			
			data.locked = !data.locked;
			updatePadlock();
			updateLabel();
		}
		
		
		private function onClick( event:MouseEvent ):void
		{
			if( disabled )
			{
				_dontCloseFlag = true;
				callLater( clearDontCloseFlag );				
			}
		}
		
		
		private function onResize( event:Event ):void
		{
			if( _padlock )
			{
				positionPadlock();
			}
		}
		
		
		private function positionPadlock():void
		{
			Assert.assertNotNull( _padlock );
			
			var padlockMargin:Number = height * 0.2;
			var padlockSize:Number = height - ( padlockMargin * 2 );
			
			_padlock.x = width - padlockMargin - padlockSize;
			_padlock.y = padlockMargin;
			_padlock.width = padlockSize;
			_padlock.height = padlockSize;
		}
		
		
		private function updateLabel():void
		{
			label.alpha = disabled ? 0.5 : 1;
		}
		
		
		private var _padlock:Button = null;
		
		private static var _dontCloseFlag:Boolean = false;
	}
}