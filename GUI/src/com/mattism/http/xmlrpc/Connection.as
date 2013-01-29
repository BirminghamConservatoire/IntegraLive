/**
* @author	Matt Shaw <xmlrpc@mattism.com>
* @url		http://sf.net/projects/xmlrpcflash
* 			http://www.osflash.org/doku.php?id=xmlrpcflash
*
* @author   Daniel Mclaren (http://danielmclaren.net)
* @note     Updated to Actionscript 3.0
* 			
* @description	This is the expected interface for a Connection class
* 				implementation used for XMLRPC. Any class that wants to behave
* 				as an XMLRPC Connection needs to implement this interface.
*/

package com.mattism.http.xmlrpc
{
	import flash.events.IEventDispatcher;
	
	import com.mattism.http.xmlrpc.MethodFault;

	public interface Connection extends IEventDispatcher {
	
		/**
		* Sets the URL of the remote XMLRPC service
		*
		* @description  This URL will be the path to your remote XMLRPC
		* .				service that you have setup. Refer to your specific XMLRPC
		* 				server implementation for more info.
		*
		* @usage	<code>myConn.setUrl("http://mysite.com/xmlrpcProxy");</code>
		* @param	A URL (String)
		*/
		function setUrl( s:String ):void;
		
		/**
		* Gets the URL of the remote XMLRPC service
		*
		* @description  Returns the URL set by the user. Returns undefined if no URL
		* 				has been specified.
		*
		* @usage	<code>var url:String = myConn.getUrl();</code>
		* @param	None..
		*/
		function getUrl():String;
		
		/**
		* Calls a remote method at the URL specified via {@link #setUrl}
		*
		* @description  Calls a remote method at the URL specified via {@link #setUrl}
		*
		* @usage	<code>myConn.call("getMenu");</code>
		* @param	A remote method name (String).
		*/
		function call( method:String ):void;
		
		function getResponse():Object;
		
		function getFault():MethodFault;
		
		function addParam( o:Object, type:String ):void;
		
	}
}