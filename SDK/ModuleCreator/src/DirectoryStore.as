package
{
	import flash.filesystem.File;
	import flash.net.SharedObject;
	
	import flexunit.framework.Assert;
	
	public class DirectoryStore
	{
		public function DirectoryStore()
		{
			Assert.assertNull( _singleInstance );	//no need to create more than one DirectoryStore instance
			
			_sharedObject = SharedObject.getLocal( "Directories" );
		}
		
		
		public static function get singleInstance():DirectoryStore
		{
			if( !_singleInstance ) _singleInstance = new DirectoryStore;
			return _singleInstance;
		} 		

		
		public function get moduleDirectory():String
		{
			return getter( "moduleDirectory" );
		}


		public function get templateDirectory():String
		{
			return getter( "templateDirectory" );
		}

		
		public function get workingDirectory():String
		{
			return getter( "workingDirectory" );
		}
		
		
		public function get bundleDirectory():String
		{
			return getter( "bundleDirectory" );
		}
		

		public function set moduleDirectory( directory:String ):void
		{
			_sharedObject.data.moduleDirectory = directory;
		}

		
		public function set templateDirectory( directory:String ):void
		{
			_sharedObject.data.templateDirectory = directory;
		}

		
		public function set workingDirectory( directory:String ):void
		{
			_sharedObject.data.workingDirectory = directory;
		}

		
		public function set bundleDirectory( directory:String ):void
		{
			_sharedObject.data.bundleDirectory = directory;
		}
		
		
		private function getter( requestedDirectory:String ):String
		{
			if( _sharedObject.data.hasOwnProperty( requestedDirectory ) )
			{
				return _sharedObject.data[ requestedDirectory ];	
			}
			else
			{
				return File.documentsDirectory.nativePath;
			}			
		}
		
		
		
		private static var _singleInstance:DirectoryStore = null;
		
		private var _sharedObject:SharedObject;
	}
}