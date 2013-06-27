package components.utils.lockableComboBox
{
	import flash.events.Event;
	
	import mx.controls.ComboBox;
	import mx.core.ClassFactory;
	
	public class LockableComboBox extends ComboBox
	{
		public function LockableComboBox()
		{
			super();
			
			itemRenderer = new ClassFactory( LockableItemRenderer );
		}
		
		
		public function set selectedIndexRegardlessOfLock( value:int ):void
		{
			super.selectedIndex = value;
		}
		
		
		override public function set selectedIndex( value:int ):void
		{
			if( value >= 0 && value < dataProvider.length ) 
			{
				var item:Object = dataProvider.getItemAt( value );
				
				if( item.hasOwnProperty( "disabled" ) || ( item.hasOwnProperty( "locked" ) && item.locked ) )
				{
					_discardedRecentChange = true;
					callLater( clearDiscardedChangeFlag );
					return;
				}
			}

			super.selectedIndex = value;
		}
		
		
		override public function close( trigger:Event = null ):void
		{
			if( _discardedRecentChange ) return;
			
			if( LockableItemRenderer.dontCloseFlag ) return;
			
			super.close( trigger );
		}
		
		
	
		private function clearDiscardedChangeFlag():void
		{
			_discardedRecentChange = false;
		}
		
		
		private var _discardedRecentChange:Boolean = false;
		
		
	}
}