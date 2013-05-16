package
{
	import mx.controls.TextInput;
	
	public class TagEditor extends TextInput
	{
		public function TagEditor()
		{
			super();
			
			maxChars = 60;
			restrict = "A-Za-z0-9 ";
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
		
		
		private static const validChars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ";
	}
}