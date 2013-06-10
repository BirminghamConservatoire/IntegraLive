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
		
		
		private function onTagEditorClosed( event:Event ):void
		{
			endEdit( ListEventReason.OTHER );
		}
	}
}