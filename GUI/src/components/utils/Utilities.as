/* Integra Live graphical user interface
 *
 * Copyright (C) 2009 Birmingham City University
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA   02110-1301,
 * USA.
 */

package components.utils
{
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	
	public class Utilities
	{
		public static function get isWindows():Boolean
		{
			return ( Capabilities.os.indexOf( "Windows" ) >= 0 );
		}

		
		public static function get isMac():Boolean
		{
			return ( Capabilities.os.indexOf( "Mac OS" ) >= 0 );
		}
		
		
		public static function get isDebugging():Boolean
		{
			/*
			since we're shipping with debug info we can't use Capabilities.isDebugger!
			
			a cheeky way to tell if this is an 'actual' debug version
			is to test whether the application's directory contains 'debug' in it's name
			*/
				
			var applicationDirectoryName:String = File.applicationDirectory.name.toLowerCase();
				
			return( applicationDirectoryName.indexOf( "debug" ) >= 0 );	
		}
		
		
		public static function get integraFileExtension():String
		{
			return "integra";
		}

		
		public static function get moduleFileExtension():String
		{
			return "module";
		}

		
		public static function get bundleFileExtension():String
		{
			return "bundle";
		}
		
		
		static public function get printableCharacterRestrict():String 
		{
			return "A-Za-z0-9 !\"£$%\\^&*()\\-=_+[]{};'#:@~,./<>?\\\\|°±¹²³¼½¾";
		}
		
		
		static public function get moduleInDevelopmentFileName():String
		{
			return "ModuleInDevelopment-4df2725b-f0ba-400a-9899-5f14632dd550." + moduleFileExtension;
		}
		
		
		static public function handlePlatformIndependantMenuModifiers( menuItem:Object ):Array
		{
			var result:Array = new Array;

			if( menuItem.ctrlKey )
			{
               	if( isWindows ) 
                { 
                	result.push( Keyboard.CONTROL );
                }
                 
                if( isMac ) 
                { 
                	result.push( Keyboard.COMMAND );
                } 	
			}
			
			if( menuItem.shiftKey )
			{
               	result.push( Keyboard.SHIFT );
			}
			
			return result;			
		}


		public static function hasMultiselectionModifier( event:MouseEvent ):Boolean
		{
			if( isMac )
			{
				return event.ctrlKey && !event.controlKey;
			}
			else
			{
				return event.ctrlKey;
			}
		}
		
		
		public static function fileNameFromPath( path:String ):String 
		{
			var indexOfLastSlash:int = Math.max( path.lastIndexOf( "/" ), path.lastIndexOf( "\\" ) );
			
			if( indexOfLastSlash >= 0 )
			{
				return path.substr( indexOfLastSlash + 1 );
			}
			else
			{
				return path;	
			}
		}

		
		public static function fileTitleFromPath( path:String ):String 
		{
			var filename:String = fileNameFromPath( path );
			var extension:String = "." + integraFileExtension;
			if( filename.length > extension.length )
			{
				var lengthBeforeExtension:int = filename.length - extension.length;
				if( filename.substr( lengthBeforeExtension ) == extension )
				{
					return filename.substr( 0, lengthBeforeExtension );
				}
			}
			
			return filename;	
		}
		
		
		public static function get integraLiveVersion():String
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
		
		
		public static function get userName():String
		{
			//guess username from userDirectory.  Works for all OS according to a forum post!
			
			var userDirectory:String = File.userDirectory.nativePath;
			if( userDirectory.charAt( userDirectory.length - 1) == File.separator )
			{
				userDirectory = userDirectory.substring( 0, userDirectory.length - 1 );
			}
			
			return fileNameFromPath( userDirectory );
		}
		
		
		//this method differs from Rectangle.contains() in that it returns true when the point lies on the perimeter of the rectangle
		public static function pointIsInRectangle( rectangle:Rectangle, x:Number, y:Number ):Boolean
		{
			return ( x >= rectangle.left && y >= rectangle.top && x <= rectangle.right && y <= rectangle.bottom );			
		}
		
		
		public static function getNumberOfProperties( object:Object ):uint 
		{
			var numberOfProperties:uint = 0;
			for each( var property:String in object )
			{
				numberOfProperties++;
			}
			
			return numberOfProperties;
		}
		
		
		public static function isObjectEmpty( object:Object ):Boolean
		{
			for each( var property:String in object )
			{
				return false;
			}
			
			return true;			
		}
		
		
		public static function getClassNameFromQualifiedClassName( qualifiedClassName:String ):String
		{
			var sliceIndex:int = qualifiedClassName.lastIndexOf( "::" );
			if( sliceIndex >= 0 )
			{
				return qualifiedClassName.slice( sliceIndex + 2 ); 
			}
			else
			{
				return qualifiedClassName;
			}
		}

		
		public static function getClassNameFromObject( object:Object ):String
		{
			var qualifiedClassName:String = getQualifiedClassName( object );

			return getClassNameFromQualifiedClassName( qualifiedClassName );
		}


		public static function getClassNameFromClass( classtype:Class ):String
		{
			var qualifiedClassName:String = getQualifiedClassName( classtype );

			return getClassNameFromQualifiedClassName( qualifiedClassName );
		}
		
		
		public static function makeGreyscale( color:uint ):uint 
		{
			var redComponent:Number = ( color >> 16 ) & 0xff;
			var greenComponent:Number = ( color >> 8 ) & 0xff;  
			var blueComponent:Number = color & 0xff;
			
			var brightness:Number = ( redComponent + greenComponent + blueComponent ) / 3;
			
			var brightnessComponent:uint = Math.min( 255, Math.max( 0, Math.round( brightness ) ) );
			
			return ( brightnessComponent << 16 ) | ( brightnessComponent << 8 ) | brightnessComponent;  
		}
		
		
		public static function interpolateColors( color1:uint, color2:uint, interpolation:Number ):uint
		{
			var redComponent1:Number = ( color1 >> 16 ) & 0xff;
			var greenComponent1:Number = ( color1 >> 8 ) & 0xff;  
			var blueComponent1:Number = color1 & 0xff;

			var redComponent2:Number = ( color2 >> 16 ) & 0xff;
			var greenComponent2:Number = ( color2 >> 8 ) & 0xff;  
			var blueComponent2:Number = color2 & 0xff;

			var interpolation2:Number = Math.max( 0, Math.min( 1, interpolation ) );
			var interpolation1:Number = 1 - interpolation2;

			var redResult:int = redComponent1 * interpolation1 + redComponent2 * interpolation2;
			var greenResult:int = greenComponent1 * interpolation1 + greenComponent2 * interpolation2;
			var blueResult:int = blueComponent1 * interpolation1 + blueComponent2 * interpolation2; 			

			redResult = Math.max( 0, Math.min( 255, redResult ) );
			greenResult = Math.max( 0, Math.min( 255, greenResult ) );
			blueResult = Math.max( 0, Math.min( 255, blueResult ) );
			
			return ( redResult << 16 ) | ( greenResult << 8 ) | blueResult;
		}
		
		
		public static function applyTint( color:uint, tint:uint ):uint
		{
			var tintRed:Number = ( ( tint >> 16 ) & 0xff ) / 0xff;
			var tintGreen:Number = ( ( tint >> 8 ) & 0xff ) / 0xff;
			var tintBlue:Number = ( tint & 0xff ) / 0xff;
			
			var tintAverage:Number = ( tintRed + tintGreen + tintBlue ) / 3;
			
			var colorRed:Number = ( ( color >> 16 ) & 0xff ) / 0xff;
			var colorGreen:Number = ( ( color >> 8 ) & 0xff ) / 0xff;
			var colorBlue:Number = ( color & 0xff ) / 0xff;
			
			var outputRed:Number = Math.max( 0, Math.min( 1, colorRed * ( 1 - tintAverage ) + tintRed ) );
			var outputGreen:Number = Math.max( 0, Math.min( 1, colorGreen * ( 1 - tintAverage ) + tintGreen ) );
			var outputBlue:Number = Math.max( 0, Math.min( 1, colorBlue * ( 1 - tintAverage ) + tintBlue ) );
			
			return ( uint( outputRed * 0xff ) << 16 ) + ( uint( outputGreen * 0xff ) << 8 ) + uint( outputBlue * 0xff );
		}		
		
		
		public static function getUserBlockLibraryDirectory():String
		{
			var userBlockLibraryDirectory:File = new File( File.applicationStorageDirectory.nativePath + "/" + "BlockLibrary" );
			
			if( !userBlockLibraryDirectory.exists )
			{
				userBlockLibraryDirectory.createDirectory();
			}
			 
			return userBlockLibraryDirectory.nativePath;
		}


		public static function getSystemBlockLibraryDirectory():String
		{
			var systemBlockLibraryDirectory:File = new File( File.applicationDirectory.nativePath + "/" + "BlockLibrary" );
			
			if( !systemBlockLibraryDirectory.exists )
			{
				systemBlockLibraryDirectory.createDirectory();
			}
			 
			return systemBlockLibraryDirectory.nativePath;
		}
		
		
		public static function get3rdPartyModulesDirectory():String
		{
			var thirdPartyModulesDirectory:File = new File( File.applicationStorageDirectory.nativePath + "/" + "ThirdPartyModules" );
			
			if( !thirdPartyModulesDirectory.exists )
			{
				thirdPartyModulesDirectory.createDirectory();
			}
			
			return thirdPartyModulesDirectory.nativePath;
		}
		
		

		public static function getMidiNoteName( midiNote:int ):String
		{
			const midiNoteNames:Array = [ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" ];
			
			if( midiNote < 0 ) return "<none>";
			
			return midiNoteNames[ midiNote % 12 ] + String( Math.floor( midiNote / 12 ) -1 );
		}
		
		
		public static function getCCNumberName( ccNumber:int ):String
		{
			if( ccNumber < 0 ) return "<none>";
			
			return String( ccNumber );
		}
		
		
		public static function makeStringVectorFromPackedString( packedString:String, output:Vector.<String> ):void
		{
			/*
			Unpacks string lists, that have been concatenated into a single string 
			with each element prepended by its length and a colon
			
			Example: 
			"First Item", "Second Item" would be expected to be represented as 
			10:First Item11:Second Item
			
			If this encoding is not adhered to, aborts mid read and reports an error
			*/
			
			output.length = 0;
			
			var position:int = 0;
			
			while( position < packedString.length )
			{
				var indexOfColon:int = packedString.indexOf( ":", position );
				if( indexOfColon < 0 )
				{
					Trace.error( "Can't find colon from position", position, packedString );
					break;
				}
				
				var stringLengthSubstr:String = packedString.substr( position, indexOfColon - position );
				var stringLength:int = int( stringLengthSubstr );
				if( isNaN( stringLength ) )
				{
					Trace.error( "Can't parse string length at position", position, stringLengthSubstr, packedString );
					break;
				}
				
				if( indexOfColon + 1 + stringLength > packedString.length )
				{
					Trace.error( "Insufficient characters in packed string: position", position, packedString );
					break;
				}
				
				var content:String = packedString.substr( indexOfColon + 1, stringLength );
				output.push( content );
				
				position = indexOfColon + 1 + stringLength;				
			}
		}
		
		
		public static function makePackedStringFromStringVector( input:Vector.<String> ):String
		{
			/* 
			 Create string-representation of an array of strings
			 
			 These packed strings are used by the AudioSettings and MidiSettings interfaces, to encode lists of drivers/devices.
			 Each string in the array is prepended by its length and a colon, allowing unambiguous unpacking.
			 Example: { "First Item", "Second Item" } becomes "10:First Item11:Second Item"
			 */

			var output:String = "";
			for each( var string:String in input )
			{
				output += string.length;
				output += ":";
				output += string;;
			}
			
			return output;
		}
		

		public static function doesStringVectorContainString( stringVector:Vector.<String>, string:String ):Boolean
		{
			for each( var content:String in stringVector )
			{
				if( content == string )
				{
					return true;
				}
			}
			
			return false;
		}
		
		
		public static function areStringVectorsEqual( vector1:Vector.<String>, vector2:Vector.<String> ):Boolean
		{
			if( vector1.length != vector2.length ) return false;
			
			for( var i:int = 0; i < vector1.length; i++ )
			{
				if( vector1[ i ] != vector2[ i ] ) return false;
			}
			
			return true;			
		}
		
		
		public static function stringVectorToIntVector( input:Vector.<String>, output:Vector.<int> ):void
		{
			output.length = 0;
			
			for each( var string:String in input )
			{
				output.push( int( string ) );
			}
		}
		
		
		public static function isDescendant( candidateDescendant:DisplayObject, candidateAncestor:DisplayObjectContainer ):Boolean
		{
			for( var iterator:DisplayObjectContainer = candidateDescendant.parent; iterator; iterator = iterator.parent )
			{
				if( iterator == candidateAncestor )
				{
					return true;
				}
			}
			
			return false;
		}

		
		public static function isEqualOrDescendant( candidateDescendant:Object, candidateAncestor:DisplayObject ):Boolean
		{
			for( var iterator:DisplayObject = candidateDescendant as DisplayObject; iterator; iterator = iterator.parent )
			{
				if( iterator == candidateAncestor )
				{
					return true;
				}
			}
			
			return false;
		}
		
		
		
		
		public static function getAncestorByType( descendant:Object, ancestorType:Class ):DisplayObject
		{
			for( var iterator:DisplayObject = descendant as DisplayObject; iterator; iterator = iterator.parent )
			{
				if( iterator is ancestorType )
				{
					return iterator;
				}
			}
			
			return null;
		}
		
		
		static public function escapeUnderscores( input:String ):String
		{
			const source:String = "_";
			const target:String = "&#95;";
			
			var underscoreIndex:int = 0;
			
			while( true )
			{
				underscoreIndex = input.indexOf( source, underscoreIndex );
				if( underscoreIndex < 0 ) break;
				
				input = input.substr( 0, underscoreIndex ) + target + input.substr( underscoreIndex + 1 );
				underscoreIndex += target.length;
			}
			
			return input;
		}		
	}
}
