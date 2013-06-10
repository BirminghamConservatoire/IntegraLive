package
{
	import flash.events.Event;
	
	import mx.controls.List;
	import mx.events.ListEventReason;
	
	public class TagList extends List
	{
		public function TagList()
		{
			super();
			
			addEventListener( TagEditor.TAG_EDITOR_CLOSED_EVENT, onTagEditorClosed );
		}
		
		
		public function editSelection():void
		{
			editedItemPosition = { columnIndex : 0, rowIndex : selectedIndex };
			
			callLater( openItemEditor );
		}
		
		
		private function openItemEditor():void
		{
			if( itemEditorInstance is TagEditor )
			{
				( itemEditorInstance as TagEditor ).open();
			}
		}
			
		
		private function onTagEditorClosed( event:Event ):void
		{
			endEdit( ListEventReason.OTHER );
		}
	}
}