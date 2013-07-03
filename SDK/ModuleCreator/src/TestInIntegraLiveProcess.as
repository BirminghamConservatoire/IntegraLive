package
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.filesystem.File;
	
	public class TestInIntegraLiveProcess extends NativeProcess
	{
		public function TestInIntegraLiveProcess( moduleFileName:String )
		{
			super();
			
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo;
			startupInfo.executable = Config.singleInstance.integraLiveExecutable;
			
			var arguments:Vector.<String> = new Vector.<String>;
			arguments.push( moduleFileName );
			
			startupInfo.arguments = arguments;

			start( startupInfo );

			_moduleFileNames.push( moduleFileName );
		}
		
		
		static public function deleteTestModuleDirectories():void
		{
			for each( var moduleFileName:String in _moduleFileNames )
			{
				var moduleFile:File = new File( moduleFileName );
				moduleFile.parent.deleteDirectory( true );
			}
		}
		
		
		private static var _moduleFileNames:Vector.<String> = new Vector.<String>;
	}
}