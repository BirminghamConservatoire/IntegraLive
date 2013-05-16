package components.views.ModuleLibrary
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.TextInput;
	
	import components.views.Skins.TickButtonSkin;
	import components.views.Skins.UpDownButtonSkin;
	
	public class SearchBox extends Canvas
	{
		public function SearchBox()
		{
			super();
			
			_input.setStyle( "top", _inputMargin );
			_input.setStyle( "bottom", _inputMargin );
			
			_input.setStyle( "color", '#808080' );

			_input.setStyle( "borderSkin", null );
			_input.setStyle( "focusAlpha", 0 );
			_input.setStyle( "backgroundAlpha", 0 );
			addChild( _input );
			
			addEventListener( Event.RESIZE, onResize );
			
			_input.addEventListener( Event.CHANGE, onChangeInput );
			_input.addEventListener( KeyboardEvent.KEY_DOWN, onKeyDownInput );

			_next.setStyle( "top", _inputMargin );
			_next.setStyle( "bottom", _inputMargin );
			_prev.setStyle( "top", _inputMargin );
			_prev.setStyle( "bottom", _inputMargin );
			
			_next.setStyle( "skin", UpDownButtonSkin );
			_prev.setStyle( "skin", UpDownButtonSkin );
			_next.setStyle( "color", "#808080" );
			_prev.setStyle( "color", "#808080" );
			_next.setStyle( UpDownButtonSkin.DIRECTION_STYLENAME, UpDownButtonSkin.DOWN );
			_prev.setStyle( UpDownButtonSkin.DIRECTION_STYLENAME, UpDownButtonSkin.UP );
			
			_next.addEventListener( MouseEvent.CLICK, onClickNext );
			_prev.addEventListener( MouseEvent.CLICK, onClickPrev );

			_next.enabled = false;
			_prev.enabled = false;
			
			addChild( _next );
			addChild( _prev );
		}

		
		public function get searchText():String { return _input.text; }
		
		override protected function updateDisplayList( width:Number, height:Number):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();
			
			//drag magnifying glass
			var magnifierColor:uint = _input.getStyle( "color" );
			
			var magnifierRect:Rectangle = new Rectangle( 0, 0, height, height );
			magnifierRect.inflate( -height / 4, -height / 4 );
			
			var circleRadius:Number = magnifierRect.width * 0.33;
			var circleCenter:Point = new Point( magnifierRect.right - circleRadius, magnifierRect.top + circleRadius );
			
			graphics.lineStyle( 2, magnifierColor );
			graphics.drawCircle( circleCenter.x, circleCenter.y, circleRadius );
			
			var handleOffset:Number = circleRadius * Math.SQRT1_2;
			graphics.moveTo( circleCenter.x - handleOffset, circleCenter.y + handleOffset );
			graphics.lineTo( magnifierRect.left, magnifierRect.bottom );
		}
		
		
		private function onResize( event:Event ):void
		{
			_input.x = height + _inputMargin;
			_input.width = width - height * 3 - _inputMargin * 2;
			
			_next.x = width - height * 2 + _inputMargin;
			_next.width = height - 2 * _inputMargin;

			_prev.x = width - height + _inputMargin;
			_prev.width = height - 2 * _inputMargin;
		}
		
		
		private function onChangeInput( event:Event ):void
		{
			if( searchText.length > 0 )
			{
				_next.enabled = true;
				_prev.enabled = true;
				dispatchEvent( new Event( SEARCH_CHANGE_EVENT ) );
			}
			else
			{
				_next.enabled = false;
				_prev.enabled = false;
			}
		}
		
		
		private function onKeyDownInput( event:KeyboardEvent ):void
		{
			if( searchText.length > 0 )
			{
				switch( event.keyCode )
				{
					case Keyboard.DOWN:
						dispatchEvent( new Event( SEARCH_NEXT_EVENT ) );
						break;
	
					case Keyboard.UP:
						dispatchEvent( new Event( SEARCH_NEXT_EVENT ) );
						break;
				}
			}
		}
		
		
		private function onClickNext( event:MouseEvent ):void
		{
			dispatchEvent( new Event( SEARCH_NEXT_EVENT ) );
		}

		
		private function onClickPrev( event:MouseEvent ):void
		{
			dispatchEvent( new Event( SEARCH_PREV_EVENT ) );
		}
		
		
		private var _input:TextInput = new TextInput;
		private var _next:Button = new Button;
		private var _prev:Button = new Button;
		
		private var _inputMargin:Number = 3;
		
		
		static public const SEARCH_CHANGE_EVENT:String = "SearchChange"; 
		static public const SEARCH_NEXT_EVENT:String = "SearchNext"; 
		static public const SEARCH_PREV_EVENT:String = "SearchPrev"; 
	}
}