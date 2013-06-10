package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.ComboBox;
	import mx.events.DropdownEvent;
	import mx.events.ListEvent;
	
	public class TagEditor extends ComboBox
	{
		public function TagEditor()
		{
			super();

			editable = true;
			
			var standardTags:Array = new Array;
			for each( var standardTag:String in Config.singleInstance.standardTags )
			{
				standardTags.push( standardTag );
			}
			
			dataProvider = standardTags;
			rowCount = standardTags.length;
			
			restrict = "A-Za-z0-9 ";
			
			doubleClickEnabled = true;
			addEventListener( DropdownEvent.CLOSE, onCloseDropdown );
			addEventListener( MouseEvent.DOUBLE_CLICK, onDoubleClick );
		}
		
		
		public function get tag():String
		{
			return ( value as String ).toLowerCase();
		}
		
		
		public static function isTagValid( tag:String ):Boolean
		{
			for( var i:int = 0; i < tag.length; i++ )
			{
				if( validChars.indexOf( tag.substr( i , 1 ) ) < 0 )
				{
					return false;
				}
			}
			
			return true;
		}
		
		
		private function onDoubleClick( event:MouseEvent ):void
		{
			open();
		}
		
		
		private function onCloseDropdown( event:DropdownEvent ):void
		{
			dispatchEvent( new Event( TAG_EDITOR_CLOSED_EVENT, true ) );
		}

		
		private static const validChars:String = "abcdefghijklmnopqrstuvwxyz0123456789 ";
		
		public static const TAG_EDITOR_CLOSED_EVENT:String = "TagEditorClosed";
	}
}