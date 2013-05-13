package
{
	import flash.display.Sprite;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.core.IFlexModuleFactory;
	import flexunit.framework.Assert;
	
	
	public class AlertManager 
	{
		public function AlertManager()
		{
			Assert.assertNull( _singleInstance );
			_singleInstance = this;
		}
		
		
		public static function show(text:String = "", title:String = "", flags:uint = 0x4, parent:Sprite = null, closeHandler:Function = null, iconClass:Class = null, defaultButtonFlag:uint = 0x4, moduleFactory:IFlexModuleFactory = null ):Alert
		{
			var alert:Alert = Alert.show( text, title, flags, parent, closeHandler, iconClass, defaultButtonFlag, moduleFactory );
			alert.addEventListener( CloseEvent.CLOSE, instance.onCloseAlert, false, 1 );
			
			_numberOfAlerts++;
			
			return alert;
		}
		
		
		public static function get areThereAnyAlerts():Boolean
		{
			return ( _numberOfAlerts > 0 );
		}
		

		private static function get instance():AlertManager
		{
			if( !_singleInstance ) _singleInstance = new AlertManager;
			return _singleInstance;
		}
		
		
		private function onCloseAlert( event:CloseEvent ):void
		{
			_numberOfAlerts--;
			Assert.assertTrue( _numberOfAlerts >= 0 );
		}
		
		
		static private var _numberOfAlerts:int = 0;
		static private var _singleInstance:AlertManager = null;
	}
}