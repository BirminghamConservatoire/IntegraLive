package
{
	import flash.desktop.NativeApplication;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	
	import mx.core.UIComponent;
	
	import flexunit.framework.Assert;
	
	
	public class Globals extends EventDispatcher
	{
		static public const alertTitle:String = "IID Editor";
		
		static public const modifiedEvent:String = "IID_FILE_MODIFIED";
		static public const widgetAssignmentModifiedEvent:String = "WIDGET_ASSIGNMENT_MODIFIED";
		static public const endpointRenamedEvent:String = "ENDPOINT_RENAMED";
		
		static public const dataDirectoryName:String = "dataDirectory";
		static public const reservedEndpointNames:Array = [ "init", "fini", "ping" ];

		
		static public const infoSchemaVersionMajor:int = 1;
		static public const infoSchemaVersionMinor:int = 0;

		static public const externalPadding:Number = 5;
		
		static public const descriptionHeight:Number = 100;
		
		static public const floatType:String = "Float";
		static public const intType:String = "Integer";
		static public const stringType:String = "String";
		
		static public const lowerCaseChars:String = "abcdefghijklmnopqrstuvwxyz";
		
		static public const printableCharacterRestrict:String = "A-Za-z0-9 !\"£$%\\^&*()\\-=_+[]{};'#:@~,./<>?\\\\|°±¹²³¼½¾";
		
		static public const moduleFileExtension:String = "module";
		static public const moduleToplevelDirectoryName:String = "integra_module_data";
		static public const moduleImplementationDirectoryName:String = moduleToplevelDirectoryName + "/implementation";

		static public const bundleFileExtension:String = "bundle";
		
		static public const testingModuleFileName:String = "ModuleInDevelopment-4df2725b-f0ba-400a-9899-5f14632dd550." + moduleFileExtension;		

		
		static public function labelColumnWidth( nesting:int = 0 ):Number { return 180 - nesting * 7; }
		static public function propertyColumnWidth( nesting:int = 0 ):Number { return 200 - nesting * 7; }
		
		static public function get isWindows():Boolean 	{ return ( Capabilities.os.indexOf( "Windows" ) >= 0 ); 	}
		static public function get isMac():Boolean		{ return ( Capabilities.os.indexOf( "Mac OS" ) >= 0 );		}
		
		static public function get versionNumber():String
		{
			var descriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
			
			var ns:Namespace = descriptor.namespaceDeclarations()[0];
			var versionString:String = descriptor.ns::versionLabel;
			
			if( !versionString || versionString.length == 0 )
			{
				versionString = descriptor.ns::versionNumber;
				
				if( !versionString || versionString.length == 0 )
				{
					versionString = "<unknown version>";
				}
			}
			
			return versionString;			
		}
		
		static public function doTypesMatch( value:String, type:String ):Boolean
		{
			var number:Number;
			
			switch( type )
			{
				case floatType:
					if( value.length == 0 ) return false;
					
					number = Number( value );
					return !isNaN( number );
					
				case intType:
					if( value.length == 0 ) return false;

					number = Number( value );
					return ( !isNaN( number ) && number == Math.round( number ) );

				case stringType:
					return true;
					
				default:
					Assert.assertTrue( false );
					return false;
			}
		}
		
		static public function restrictToNumber( input:UIComponent ):void
		{
			Assert.assertTrue( input.hasOwnProperty( _restrictProperty ) );

			input[ _restrictProperty ] = "\\-.0123456789";
		}
		
		
		static public function restrictToInteger( input:UIComponent ):void
		{
			Assert.assertTrue( input.hasOwnProperty( _restrictProperty ) );
			
			input[ _restrictProperty ] = "\\-0123456789";
		}
		
		
		static public function restrictToUnsignedInteger( input:UIComponent ):void
		{
			Assert.assertTrue( input.hasOwnProperty( _restrictProperty ) );
			
			input[ _restrictProperty ] = "0123456789";
		}
		
		
		static public function getNumberOfProperties( object:Object ):uint 
		{
			var numberOfProperties:uint = 0;
			for each( var property:String in object )
			{
				numberOfProperties++;
			}
			
			return numberOfProperties;
		}
		
		
		static public function isObjectEmpty( object:Object ):Boolean
		{
			for each( var property:String in object )
			{
				return false;
			}
			
			return true;			
		}
		
		
		static private const _restrictProperty:String = "restrict";
	}
}