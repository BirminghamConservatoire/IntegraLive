/**
* @author	Matt Shaw <xmlrpc@mattism.com>
* @url		http://sf.net/projects/xmlrpcflash
* 			http://www.osflash.org/doku.php?id=xmlrpcflash		
*
* @author   Daniel Mclaren (http://danielmclaren.net)
* @note     Updated to Actionscript 3.0
*
* @author   Ricardo 
* @note     Bug fixes for parameter values of zero or ''.
* @see      http://danielmclaren.net/2007/08/03/xmlrpc-for-actionscript-30-free-library#comment-327
*/

package com.mattism.http.xmlrpc
{
	import com.mattism.http.xmlrpc.MethodCall;
	import com.mattism.http.xmlrpc.util.XMLRPCDataTypes;
	import com.mattism.http.xmlrpc.util.XMLRPCUtils;
	import components.utils.Trace;
	
	public class MethodCallImpl
	implements MethodCall
	{
		
		private var _VERSION:String = "1.0";
		private var _PRODUCT:String = "MethodCallImpl";
		private var _parameters:Array;
		private var _name:String;
		private var _xml:XML;
		
		static public function set debugMode( debugMode:Boolean ):void { _debugMode = debugMode; } 
		
		public function MethodCallImpl(){
			this.removeParams();
	
			//this.debug("MethodCallImpl instance created. (v" + _VERSION + ")");
		}
		
		
		public function setName( name:String ):void {
			this._name=name;
		}
		
		public function addParam(param_value:Object,param_type:String):void {
			//this.debug("MethodCallImpl.addParam("+arguments+")");
			this._parameters.push({type:param_type,value:param_value});
		}
		
		public function removeParams():void {
			this._parameters=new Array();
		}
	
		public function getXml():XML {
			//this.debug("getXml()");
			
			var ParentNode:XML;
			var ChildNode:XML;
			
			// Create the <methodCall>...</methodCall> root node
			ParentNode = <methodCall />;
			this._xml = ParentNode;
			
			// Create the <methodName>...</methodName> node
			ChildNode = <methodName>{this._name}</methodName>;
			ParentNode.appendChild(ChildNode);
			
			// Create the <params>...</params> node
			ChildNode = <params />;
			ParentNode.appendChild(ChildNode);
			ParentNode = ChildNode;
			
			// build nodes that hold all the params
			//this.debug("Render(): Creating the params node.");
			
			var i:Number;		
			for (i=0; i<this._parameters.length; i++) {
				//this.debug("PARAM: " + [this._parameters[i].type,this._parameters[i].value]);
				ChildNode = <param />;
				ChildNode.appendChild( this.createParamsNode(this._parameters[i]) );
				ParentNode.appendChild(ChildNode);
			}
			//this.debug("Render(): Resulting XML document:");
			this.debug("Render(): " + this._xml.toXMLString());
			
			//debug(this._xml.toXMLString());
			
			return this._xml;
		}
			
		private function createParamsNode( parameter:Object ):XML {
			//this.debug("CreateParameterNode()");
			var Node:XML = <value />;
			var TypeNode:XML;
			var v:Object;

			if (!parameter.value && parameter
				&& (!parameter.type || parameter.type == XMLRPCDataTypes.ARRAY
					|| parameter.type == XMLRPCDataTypes.STRUCT))
			{
				parameter = {value:parameter};
				
				// Default to 
				if (!parameter.type){
					v = parameter.value;
					if ( v is String )
						parameter.type=XMLRPCDataTypes.STRING;
					else if ( v is Array )
						parameter.type=XMLRPCDataTypes.ARRAY;
					else
						parameter.type=XMLRPCDataTypes.STRUCT;
				}
			}
			
			if ( typeof parameter == "object") {
	
				
				// Default to 
				if (!parameter.type){
					v = parameter.value;
					if ( v is Array )
						parameter.type=XMLRPCDataTypes.ARRAY;
					else if ( v is Object && !v is String )
						parameter.type=XMLRPCDataTypes.STRUCT;
					else
						parameter.type=XMLRPCDataTypes.STRING;
				}
	
				// Handle Explicit Simple Objects
				if ( XMLRPCUtils.isSimpleType(parameter.type) ) {
					//cdata is really a string type with a cdata wrapper, so don't really make a 'cdata' tag
					parameter = this.fixCDATAParameter(parameter);
					
					//this.debug("CreateParameterNode(): Creating object '"+parameter.value+"' as type "+parameter.type);
					TypeNode = <{parameter.type}>{parameter.value}</{parameter.type}>;
					Node.appendChild(TypeNode);
					return Node;
				}
				// Handle Array Objects
				if (parameter.type == XMLRPCDataTypes.ARRAY) {
					var DataNode:XML;
					//this.debug("CreateParameterNode(): >> Begin Array");
					TypeNode = <array />;
					DataNode = <data />;
					//for (var i:String in parameter.value) {
					//	DataNode.appendChild(this.createParamsNode(parameter.value[i]));
					//}
					for (var i:int=0; i<parameter.value.length; i++) {
						DataNode.appendChild( this.createParamsNode( parameter.value[i] ) );
					}
					TypeNode.appendChild(DataNode);
					//this.debug("CreateParameterNode(): << End Array");
					Node.appendChild(TypeNode);
					return Node;
				}
				// Handle Struct Objects
				if (parameter.type == XMLRPCDataTypes.STRUCT) {
					//this.debug("CreateParameterNode(): >> Begin struct");
					TypeNode = <struct />;
					for (var x:String in parameter.value) {
						var MemberNode:XML = <member />;
	
						// add name node
						MemberNode.appendChild(<name>{x}</name>);
	
						// add value node

						//Bugfix by Leighton Hargreaves 25-11-09 
						//This is the original line of code.  It doesn't work when properties of the struct are themselves arrays or structs
						//MemberNode.appendChild(<value>{parameter.value[x]}</value>);

						//This is the modified line of code.  It appears to work with nested structs and arrays
						MemberNode.appendChild( this.createParamsNode( parameter.value[x] ) );
						
						TypeNode.appendChild(MemberNode);
					}
					//this.debug("CreateParameterNode(): << End struct");
					Node.appendChild(TypeNode);
					return Node;
				}
			}
			
			return Node;
		}
		
		
		/*///////////////////////////////////////////////////////
		fixCDATAParameter()
		?:      Turns a cdata parameter into a string parameter with 
				CDATA wrapper
		IN:	    Possible CDATA parameter
		OUT:	Same parameter, CDATA'ed is necessary
		///////////////////////////////////////////////////////*/
		private function fixCDATAParameter(parameter:Object):Object{
			if (parameter.type==XMLRPCDataTypes.CDATA){
				parameter.type=XMLRPCDataTypes.STRING;
				parameter.value='<![CDATA['+parameter.value+']]>';  
			}
			return parameter;
		}
		
		
		public function cleanUp():void {
			//this.removeParams();
			//this.parseXML(null);
		}
	
		private function debug(a:Object):void {
			if( _debugMode )
			{
				Trace.verbose(a);
			}
		}
		
		static private var _debugMode:Boolean = false;
	}
}