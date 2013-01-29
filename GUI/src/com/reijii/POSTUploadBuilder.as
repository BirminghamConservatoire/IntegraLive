package com.reijii
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	/**
	 * Main target of this class is to upload mutiple data by one user action.
	 * 
	 * Takes an array with prepared DTO as input;
	 * Returns ByteArray to use as post data in UrlRequest as output; ByteArray is formatter as multipart/form-data request, 
	 * as format is similar to FireFox request.
	 * 
	 * DTO can be generated via POSTUploadBuilder.buildUploadDataVO method.
	 * DTO structure:
	 * 
	 * fileName : String;
	 * fileData : ByteArray;
	 * dataName : String;
	 * 
	 * Usage example:
	 * 
	 * 		var request : URLRequest = new URLRequest( "http://somehost/upload  );
	 *					
	 *		request.contentType	= 'multipart/form-data; boundary=' + POSTUploadBuilder.boundary;
	 *		request.method		= URLRequestMethod.POST;
	 *		
	 *		var arr : Array = [];
	 *		
	 * 		for ( var i:uint = 0; i < fileList.length; ++i )
	 *		{
	 *			arr.push( POSTUploadBuilder.buildUploadDataVO( fileList[i].name, fileList[i].data, fileList[i].name ) );
	 *		}			
	 *		
	 *		request.data		= POSTUploadBuilder.buildPOSTData( arr );
	 *		
	 *		var loader : URLLoader = new URLLoader();
	 *		
	 *		loader.addEventListener( Event.COMPLETE, onUploadComplete );
	 *		loader.addEventListener( IOErrorEvent.IO_ERROR, onUploadError );
	 *		loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onUploadError );
	 *		
	 *		loader.dataFormat = URLLoaderDataFormat.BINARY;
	 *		
	 *		loader.load( request ); 
	 *
	 * @author Dmitry 'Reijii' Kochetov
	 * @version Dec 11, 2009
	 * @skype kodjii
	 *
	 * This work is licensed under a Creative Commons Attribution-Share Alike 3.0 Unported
	 * @see http://creativecommons.org/licenses/by-sa/3.0/
	 */
	
	public class POSTUploadBuilder
	{
		private static var _boundary		: String = "";
		private static var _mainBoundary	: String = "";
		
		public static function get boundary () : String 
		{			
			if ( _boundary.length == 0 ) 
			{
				var i	: uint = 0;
				var len	: uint = 0x20;
				
				for ( ; i < len; ++i ) 
				{
					_boundary += String.fromCharCode( uint( 97 + Math.random() * 25 ) );
				}
			}
			
			return _boundary;
		}
		
		public static function buildUploadDataVO ( $fileName:String, $fileData:ByteArray, $dataName:String = "Filename" ) : UploadDataVO
		{
			var trim : RegExp = /^\s*|\s*$/;
			
			if ( $fileName == null || $fileName.replace( trim, "" ) == "" )
			{
				throw new Error( "POSTUploadBuilder.buildUploadDataVO: Please specify valid file name for the upload target. This field must be not null or empty string" );
			}
			
			if ( $fileData == null )
			{
				throw new Error( "POSTUploadBuilder.buildUploadDataVO: Please specify valid file data for the upload target. This field must be not null" );
			}
			
			var data : UploadDataVO = new UploadDataVO();
			
			data.name		= $fileName.replace( trim, "" );
			data.data		= $fileData;
			data.dataName	= ( $dataName.replace( trim, "" ) == "Filename" ) ? $dataName.replace( trim, "" ) + uint( getTimer() + Math.random() * 15 ) : $dataName.replace( trim, "" );
			
			return data;
		}
		
		public static function buildVariable( key:String, value:Object ) : VariableData
		{
			var variable:VariableData = new VariableData;
			variable.key = key;
			variable.value = value ? value.toString() : "<null>";
			return variable;			
		}
		
		public static function buildPOSTData ( $filelist:Array, variables:Array ) : ByteArray 
		{
			var i			: uint = 0;
			var len			: uint = 0;
			var postData	: ByteArray = new ByteArray();
			
			postData.endian = Endian.BIG_ENDIAN;
			
			_mainBoundary = _boundary;
			
			len = $filelist.length;
			
			for ( ; i < len; ++i )
			{
				postData = addFile( postData, $filelist[i], true );
			}
			
			///test code to add variables
			for each( var variable:VariableData in variables )
			{
				if( !variable.key ) continue;
				
				postData = addBoundary( postData );
				postData = addLineBreak( postData );
				postData = addString( postData, "Content-Disposition: form-data; name=\"" );
				postData = addString( postData, variable.key );
				postData = addQuotation( postData );
				postData = addLineBreak( postData );
				postData = addLineBreak( postData );
				postData = addString( postData, variable.value );
				postData = addLineBreak( postData );
			}
			
			
			/*postData = addFilenameParam( postData );
			
			postData = addLineBreak( postData );
			postData = addLineBreak( postData );
			
			postData = addBoundary( postData );
			
			postData = addDoubledash( postData );*/
			
			return postData;
		}
		
		private static function addFilenameParam ( postData:ByteArray ) : ByteArray
		{
			var i			: uint = 0;
			var strBytes	: String;
			
			postData = addBoundary( postData );
			postData = addLineBreak( postData );
			
			strBytes = 'Content-Disposition: form-data; name="Filename"';
			
			for ( i = 0; i < strBytes.length; ++i ) 
			{
				postData.writeByte( strBytes.charCodeAt(i) );
			}
			
			postData = addLineBreak( postData );
			postData = addLineBreak( postData );
			
			postData.writeUTFBytes( _boundary );
			
			postData = addLineBreak( postData );
			
			return postData;
		}
		
		
		private static function addString( postData:ByteArray, string:String ) : ByteArray
		{
			postData.writeUTFBytes( string );
			return postData;			
		}
		
		private static function addFile ( postData:ByteArray, fileVO:UploadDataVO, generateBoundary:Boolean = false ) : ByteArray
		{
			var i			: uint = 0;
			var strBytes	: String;
			
			// add file content
			postData = addBoundary( postData );
			postData = addLineBreak( postData );
			
			strBytes = 'Content-Disposition: form-data; name="' + fileVO.dataName + '"; filename="' + fileVO.name + '"';
			
			for ( i = 0; i < strBytes.length; ++i ) 
			{
				postData.writeByte( strBytes.charCodeAt(i) );
			}
			
			//postData.writeUTFBytes( fileVO.name );
			//postData = addQuotation( postData );
			
			postData = addLineBreak( postData );
			
			strBytes = 'Content-Type: application/octet-stream';
			
			for ( i = 0; i < strBytes.length; ++i ) 
			{
				postData.writeByte( strBytes.charCodeAt(i) );
			}
			
			postData = addLineBreak( postData );
			postData = addLineBreak( postData );
			
			postData.writeBytes( fileVO.data, 0, fileVO.data.length );
			
			postData = addLineBreak( postData );
			//
			
			return postData;
		}
		
		private static function addBoundary ( data:ByteArray ) : ByteArray 
		{
			var boundaryLen : uint = POSTUploadBuilder.boundary.length;
			var i			: uint = 0;
			
			data = addDoubledash( data );
			
			for ( ; i < boundaryLen; ++i ) 
			{
				data.writeByte( _boundary.charCodeAt( i ) );
			}
			
			return data;
		}
		
		private static function addLineBreak ( data:ByteArray ) : ByteArray 
		{
			data.writeShort( 0x0d0a );
			
			return data;
		}

		private static function addQuotation ( data:ByteArray ) : ByteArray 
		{
			data.writeByte( 0x22 );
			
			return data;
		}
		
		private static function addDoubledash ( data:ByteArray ) : ByteArray 
		{
			data.writeShort( 0x2d2d );
			
			return data;
		}
	}
}
import flash.utils.ByteArray;

class UploadDataVO
{
	public var name		: String = null;
	public var data		: ByteArray = null;
	public var dataName : String = null;
	
}


class VariableData
{
	public var key		: String = null;
	public var value	: String = null;
	
}