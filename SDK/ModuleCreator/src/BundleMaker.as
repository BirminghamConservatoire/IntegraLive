package
{
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	public class BundleMaker
	{
		public function BundleMaker() 
		{
			_selectModules.addEventListener( FileListEvent.SELECT_MULTIPLE, onSelectModules );
			_createBundle.addEventListener( Event.SELECT, onSelectBundleToCreate );
			
			_extractBundle.addEventListener( Event.SELECT, onSelectBundleToExtract );
			_extractionDirectory.addEventListener( Event.SELECT, onSelectExtractionDirectory );
		}
		
		
		public function createModuleBundle( event:Event ):void
		{
			var moduleFilter:FileFilter = new FileFilter( "Integra Modules", "*." + Globals.moduleFileExtension );
			
			_selectModules.browseForOpenMultiple( "Select Modules to include in your Bundle...", [ moduleFilter ] );
		}
		
		
		public function extractModuleBundle( event:Event ):void
		{
			var bundleFilter:FileFilter = new FileFilter( "Integra Module Bundles", "*." + Globals.bundleFileExtension );
			
			_extractBundle.browseForOpen( "Select Bundle To Extract...", [ bundleFilter ] );
		}
		
		
		private function onSelectModules( event:FileListEvent ):void
		{
			_modulesToBundle = event.files;
			DirectoryStore.singleInstance.moduleDirectory = ( _modulesToBundle[ 0 ] as File ).parent.nativePath;
			
			_createBundle.browseForSave( "Export Bundle As..." );
		}
		
		
		private function onSelectBundleToCreate( event:Event ):void
		{
			DirectoryStore.singleInstance.bundleDirectory = _createBundle.parent.nativePath;

			if( !_createBundle.extension || _createBundle.extension != Globals.bundleFileExtension )
			{
				_createBundle.nativePath = _createBundle.nativePath + "." + Globals.bundleFileExtension;
			}
			
			var bundleZipFile:FZip = new FZip();
			var moduleFiles:String = "Added Modules:\n";

			for each( var moduleFile:File in _modulesToBundle )
			{
				var fileSize:int = moduleFile.size;
				var fileStream:FileStream = new FileStream();
				fileStream.open( moduleFile, FileMode.READ );
				var content:ByteArray = new ByteArray();
				fileStream.readBytes( content );
				fileStream.close();
				
				bundleZipFile.addFile( moduleFile.name, content );
				
				moduleFiles += ( "\n    " + moduleFile.name );
			}
			
			var outputFileStream:FileStream = new FileStream();
			outputFileStream.open( _createBundle, FileMode.WRITE );
			bundleZipFile.serialize( outputFileStream );
			outputFileStream.close();	
			
			AlertManager.show( moduleFiles, "Bundle Created Successfully" );
		}
		
		
		private function onSelectBundleToExtract( event:Event ):void
		{
			DirectoryStore.singleInstance.bundleDirectory = _extractBundle.parent.nativePath;
			
			_extractionDirectory.browseForDirectory( "Choose Module Extraction Directory..." );
		}
		
		
		private function onSelectExtractionDirectory( event:Event ):void
		{
			DirectoryStore.singleInstance.moduleDirectory = _extractionDirectory.nativePath;
			
			var fileStream:FileStream = new FileStream();
			fileStream.open( _extractBundle, FileMode.READ );
			var rawBytes:ByteArray = new ByteArray();
			fileStream.readBytes( rawBytes );
			fileStream.close();			
			
			var bundleZipFile:FZip = new FZip();
			bundleZipFile.loadBytes( rawBytes );
			
			var resultsString:String = "Extracted Modules:\n\n";
			
			var numberOfFiles:uint = bundleZipFile.getFileCount();
			for( var i:int = 0; i < numberOfFiles; i++ )
			{
				var moduleFile:FZipFile = bundleZipFile.getFileAt( i );
				var moduleFileName:String = moduleFile.filename;
				
				var outputFile:File = _extractionDirectory.resolvePath( moduleFileName );
				
				if( outputFile.exists )
				{
					resultsString += "\nCan't extract to " + outputFile.nativePath + " - file already exists!";
				}
				else
				{
					var outputFileStream:FileStream = new FileStream;
					outputFileStream.open( outputFile, FileMode.WRITE );
					outputFileStream.writeBytes( moduleFile.content );
					outputFileStream.close();
					
					resultsString += "\nExtracted " + moduleFileName;
				}
			}
			
			AlertManager.show( resultsString, "Bundle Extraction Complete" );
		}
		
		
		private var _selectModules:File = new File( DirectoryStore.singleInstance.moduleDirectory );
		private var _createBundle:File = new File( DirectoryStore.singleInstance.bundleDirectory );

		private var _extractBundle:File = new File( DirectoryStore.singleInstance.bundleDirectory );
		private var _extractionDirectory:File = new File( DirectoryStore.singleInstance.moduleDirectory );
		
		private var _modulesToBundle:Array = null;
	}
}