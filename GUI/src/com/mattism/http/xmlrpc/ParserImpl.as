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
	import com.mattism.http.xmlrpc.Parser;
	import com.mattism.http.xmlrpc.util.XMLRPCUtils;
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	import components.utils.Trace;
	
	public class ParserImpl	implements Parser {
		
		// Metadata
		private var _VERSION:String = "1.0.0";
		private var _PRODUCT:String = "ParserImpl";
	
		// Constants
		private var ELEMENT_NODE:Number = 1;
		private var TEXT_NODE:Number = 3;
		
		private var METHOD_RESPONSE_NODE:String = "methodResponse";
		private var PARAMS_NODE:String = "params";
		private var PARAM_NODE:String = "param";
		private var VALUE_NODE:String = "value";
		private var FAULT_NODE:String = "fault";
		private var ARRAY_NODE:String = "array";
		
		private var DATA_NODE:String = "data";
		private var STRUCT_NODE:String = "struct";
		private var MEMBER_NODE:String = "member";
		
		public function parse( xml:XML ):Object {
			if ( xml.toString().toLowerCase().indexOf('<html') >= 0 ){
				Trace.error("WARNING: XML-RPC Response looks like an html page.");
				return xml.toString();
			}
			
			return this._parse( xml );
		}
		
		private function _parse( node:XML ):Object {		
			var data:Object;
			var i:int;
			
			if (node.nodeKind() == 'text') {
				return node.toString();
			}
			else if (node.nodeKind() == 'element') {
				
				if (
					node.name() == METHOD_RESPONSE_NODE || 
					node.name() == PARAMS_NODE		  ||				
					node.name() == VALUE_NODE 		  || 
					node.name() == PARAM_NODE 		  ||
					node.name() == FAULT_NODE 		  ||
					node.name() == ARRAY_NODE
					) {
					
					this.debug("_parse(): >> " + node.name());
					if (node.name() == VALUE_NODE && node.*.length() <= 0) return null;
					return this._parse( node.*[0] );
				}
				else if (node.name() == DATA_NODE) {
					this.debug("_parse(): >> Begin Array");
					data = new Array();
					for (i=0; i<node.children().length(); i++) {
						var temp:Object = this._parse(node.children()[i]);
						if( isWhitespaceString( temp ) )
						{
							continue;
						}
						data.push( temp );
						this.debug("_parse(): adding data to array: "+data[data.length-1]);
					}
					this.debug("_parse(): << End Array");
					return data;
				}
				else if (node.name() == STRUCT_NODE) {
					this.debug("_parse(): >> Begin Struct");
					data = new Object();
					for (i=0; i<node.children().length();i++) {
						temp = this._parse(node.children()[i]);
						if( isWhitespaceString( temp ) )
						{
							continue;
						}
						data[temp.name]=temp.value;
						this.debug("_parse(): Struct item "+temp.name + ":" + temp.value);
					}
					this.debug("_parse(): << End Stuct");
					return data;
				}
				else if (node.name() == MEMBER_NODE) {
					/* 
					* The member tag is *special*. The returned
					* value is *always* a hash (or in Flash-speak,
					* it is always an Object).
					*/
					data = new Object();
					data.name = node.name[0].toString();
					data.value = this._parse(node.value[0]);
					
					return data;
				}
				else if (node.name() == "name") {
					return this._parse(node.*[0]);
				}
				else if ( XMLRPCUtils.isSimpleType(node.name()) ) {
					return this.createSimpleType( node.name(), node.* );
				}
			}
			
			this.debug("Received an invalid Response.");
			return null;
		}
		
		
		private function isWhitespaceString( object:Object ):Boolean
		{
			var string:String = object as String;
			if( !string ) return false;
			
			const stripWhitespace:RegExp = /[\s\r\n]*/gim;
			
			var replaced:String = string.replace( stripWhitespace, '' );
			
			return (replaced.length == 0 );
		}
		
		private function createSimpleType( type:String, value:String ):Object {
			switch (type){
				case XMLRPCDataTypes.i4:	
				case XMLRPCDataTypes.INT:	
				case XMLRPCDataTypes.DOUBLE:						
					return new Number( value );
					break;
					
				case XMLRPCDataTypes.STRING:
					return new String( value );
					break;
				
				case XMLRPCDataTypes.DATETIME:
					return this.getDateFromIso8601( value );
					break;
					
				case XMLRPCDataTypes.BASE64:
					return value;
					break;
					
				case XMLRPCDataTypes.CDATA:
					return value;
					break;
	
				case XMLRPCDataTypes.BOOLEAN:
					if (value=="1" || value.toLowerCase()=="true"){
						return new Boolean(true);
					}
					else if (value=="0" || value.toLowerCase()=="false"){
						return new Boolean(false);
					}
					break;
					
			}
			
			return value;
		}
		
		private function getDateFromIso8601( iso:String ):Date {
			// yyyy-MM-dd'T'HH:mm:ss
			var tmp:Array = iso.split("T");
			var date_str:String = tmp[0];
			var time_str:String = tmp[1];
			var date_parts:Array = date_str.split("-");
			var time_parts:Array = time_str.split(":");		
			
			return new Date(date_parts[0],date_parts[1]-1,date_parts[2],time_parts[0],time_parts[1],time_parts[2]);
		}
											
		private function debug(a:String):void {
			//trace(this._PRODUCT + " -> " + a);
		}
	}
}