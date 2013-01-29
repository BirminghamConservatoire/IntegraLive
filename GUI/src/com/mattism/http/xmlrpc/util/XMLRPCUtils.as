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
	
	public class XMLRPCUtils {
	
		public static var SIMPLE_TYPES:Array = [ XMLRPCDataTypes.BASE64,
											XMLRPCDataTypes.INT,
											XMLRPCDataTypes.i4,
											XMLRPCDataTypes.STRING,
											XMLRPCDataTypes.CDATA,
											XMLRPCDataTypes.DOUBLE,
											XMLRPCDataTypes.DATETIME,
											XMLRPCDataTypes.BOOLEAN
										];
									
		public static function isSimpleType( type:String ):Boolean {
			var i:Number;
			for ( i=0; i<SIMPLE_TYPES.length; i++ ){
				if( type==SIMPLE_TYPES[i] ){ 
					return true;
				}
			}
			
			return false;
		}
	
	}
}