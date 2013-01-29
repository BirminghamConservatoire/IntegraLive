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
	import com.mattism.http.xmlrpc.MethodFault;
	
	public class MethodFaultImpl 
	implements MethodFault
	{
		
		private var _fault:Object;
		
		public function MethodFaultImpl( o:Object ){
			if ( o ) this.setFaultObject( o );
		}
		
		public function getFaultCode():Number {
			return Number( this._fault.faultCode );
		}
		
		public function getFaultString():String {
			return String( this._fault.faultString );
		}
		
		public function getArgs():Array {
			return new Array( this._fault.args );
		}
		
		public function setFaultObject( o:Object ):void {
			this._fault=o;
		}
		
		public function toString():String
		{
			return "[MethodFaultImpl(faultCode=" + _fault.faultCode + ", faultString=" + _fault.faultString + ")]";
		}
	}
}

/*

<?xml version='1.0'?>
<methodResponse>
	<fault>
		<value>
			<struct>
				<member>
					<name>faultCode</name>
					<value><int>-2</int></value>
				</member>
				<member>
					<name>args</name>
					<value>
						<array>
							<data>
							</data>
						</array>
					</value>
				</member>
				<member>
					<name>faultString</name>
					<value>
						<string>Unexpected Zope error value: NotFound -  
							Site Error 
							An error was encountered while publishing this resource.
							
							Debugging Notice  
							
							Zope has encountered a problem publishing your object. 
							The object at http://www.zope.org/Members/logik/objectIds has an empty or missing docstring. Objects must have a docstring to be published.
							
							
							Troubleshooting Suggestions 
							
							
							The URL may be incorrect. 
							The parameters passed to this resource may be incorrect. 
							A resource that this resource relies on may be
							encountering an error. 
							
							
							For more detailed information about the error, please
							refer to the error log.
							
							
							If the error persists please contact the site maintainer.
							Thank you for your patience.
						</string>
					</value>
				</member>
			</struct>
		</value>
	</fault>
</methodResponse>
*/