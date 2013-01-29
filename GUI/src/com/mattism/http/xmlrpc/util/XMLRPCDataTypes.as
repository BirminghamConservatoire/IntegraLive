/**
* @author	Matt Shaw <xmlrpc@mattism.com>
* @url		http://sf.net/projects/xmlrpcflash
* 			http://www.osflash.org/doku.php?id=xmlrpcflash	
*
* @author   Daniel Mclaren (http://danielmclaren.net)
* @note     Updated to Actionscript 3.0		
*/

package com.mattism.http.xmlrpc.util
{
	public class XMLRPCDataTypes {

		public static var STRING:String   = "string";
		public static var CDATA:String    = "cdata";
		public static var i4:String       = "i4";
		public static var INT:String      = "int";
		public static var BOOLEAN:String  = "boolean";
		public static var DOUBLE:String   = "double";
		public static var DATETIME:String = "dateTime.iso8601";
		public static var BASE64:String   = "base64";
		public static var STRUCT:String   = "struct";
		public static var ARRAY:String    = "array";
		
	}
}

/*
<i4> or <int>		java.lang.Integer	Number
<boolean>			java.lang.Boolean	Boolean
<string>			java.lang.String	String
<double>			java.lang.Double	Number
<dateTime.iso8601>	java.util.Date		Date
<struct>			java.util.Hashtable	Object
<array>				java.util.Vector	Array
<base64>			byte[ ]				Base64
*/