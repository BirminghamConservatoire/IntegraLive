package components.utils
{
	import flexunit.framework.Assert;
	
	public class ModalState
	{
		public static function get isInModalState():Boolean { return  _isInModalState; }
		public static function set isInModalState( isInModalState:Boolean ):void { _isInModalState = isInModalState; }
	
		private static var _isInModalState:Boolean = false;
	}
}