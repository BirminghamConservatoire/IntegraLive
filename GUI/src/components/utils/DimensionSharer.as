package components.utils
{
	import flash.events.Event;
	
	import flexunit.framework.Assert;
	import components.views.viewContainers.IntegraViewEvent;
	import components.views.IntegraView;
	

	public class DimensionSharer
	{
		public function DimensionSharer()
		{
		}
		
		
		public function set view1( view1:IntegraView ):void
		{
			Assert.assertNotNull( view1 );
			
			if( _view1 )
			{
				_view1.removeEventListener( Event.RESIZE, onResizeView1 );
				_view1.removeEventListener( IntegraViewEvent.COLLAPSE_CHANGED, onExpandCollapseView1 );
			}
			
			_view1 = view1;
			_view1.addEventListener( Event.RESIZE, onResizeView1 );
			_view1.addEventListener( IntegraViewEvent.COLLAPSE_CHANGED, onExpandCollapseView1 );
		}

		
		public function set view2( view2:IntegraView ):void
		{
			Assert.assertNotNull( view2 );
			
			if( _view2 )
			{
				_view2.removeEventListener( Event.RESIZE, onResizeView2 );
				_view2.removeEventListener( IntegraViewEvent.COLLAPSE_CHANGED, onExpandCollapseView2 );
			}
			
			_view2 = view2;
			_view2.addEventListener( Event.RESIZE, onResizeView2 );
			_view2.addEventListener( IntegraViewEvent.COLLAPSE_CHANGED, onExpandCollapseView2 );
		}
		
		
		public function set dimension( dimension:String ):void
		{
			Assert.assertTrue( dimension == WIDTH || dimension == HEIGHT );
			
			_dimension = dimension;
		}
		
		
		private function onResizeView1( event:Event ):void
		{
			if( !_view2 ) return;
			
			switch( _dimension )
			{
				case WIDTH:
					if( _view2.width == _view1.width ) return;
					
					_view2.width = _view1.width;
					break;

				case HEIGHT:
					if( _view2.height == _view1.height ) return;

					_view2.height = _view1.height;
					break;
			}
			
			_view2.dispatchEvent( new IntegraViewEvent( IntegraViewEvent.RESIZED_BY_DIMENSION_SHARER ) );
		}

		
		private function onResizeView2( event:Event ):void
		{
			if( !_view1 ) return;
			
			switch( _dimension )
			{
				case WIDTH:
					if( _view2.width == _view1.width ) return;
					
					_view1.width = _view2.width;
					break;
				
				case HEIGHT:
					if( _view2.height == _view1.height ) return;
					
					_view1.height = _view2.height;
					break;
			}
			
			_view1.dispatchEvent( new IntegraViewEvent( IntegraViewEvent.RESIZED_BY_DIMENSION_SHARER ) );
		}
		
		
		private function onExpandCollapseView1( event:IntegraViewEvent ):void
		{
			/*if( _dimension == HEIGHT )
			{
				_view2.collapsed = _view1.collapsed;
			}*/
		}

		
		private function onExpandCollapseView2( event:IntegraViewEvent ):void
		{
			/*if( _dimension == HEIGHT )
			{
				_view1.collapsed = _view2.collapsed;
			}*/
		}
		
		
		private var _view1:IntegraView = null;
		private var _view2:IntegraView = null;
		private var _dimension:String = null;
		
		public static const WIDTH:String = "WIDTH";
		public static const HEIGHT:String = "HEIGHT";
			
	}
}