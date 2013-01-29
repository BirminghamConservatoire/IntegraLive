/**
* @author	Matt Shaw <xmlrpc@mattism.com>
* @url		http://sf.net/projects/xmlrpcflash
* 			http://www.osflash.org/doku.php?id=xmlrpcflash			
*
* @author   Daniel Mclaren (http://danielmclaren.net)
* @note     Updated to Actionscript 3.0
*/

package com.mattism.http.xmlrpc
{
	public interface MethodCall
	{
		
		function setName( name:String ):void;
		
		function addParam( arg:Object, type:String ):void;
		
		function removeParams():void;
	
		function getXml():XML;
	
	}
}