/**
 * @author		Matt Shaw <xmlrpc@mattism.com>>
 * @description	XMLRPCTests.as
 */

import as2unit.framework.TestCase;
import com.mattism.http.xmlrpc.ParserImpl;
import com.mattism.http.xmlrpc.Parser;

class com.mattism.http.xmlrpc.tests.TestParserImpl
extends TestCase {
	
	private var STRING_DATA:String = "This is a string";
	private var METHOD_RESPONSE_HEADER:String = 	'<?xml version="1.0" encoding="ISO-8859-1"?>'+
										 			'<methodResponse>			'+
													'	<params>				';
	private var METHOD_RESPONSE_FOOTER:String = 	'	</params>				'+
						 							'</methodResponse>			';
													
 	public function TestParserImpl( method:String ){
 		super( method );
 	}
 	
	public function testInt():Void {
		var p:Parser = new ParserImpl();
		var o:Object = p.parse( this.getIntResponse() );

		assertNotNull( o );
 		assertNotUndefined( o );
		assertEquals( o, 16 );
		assertTrue( o instanceof Number );
 	}
 	
 	public function testString():Void {
		var p:Parser = new ParserImpl();
		var o:Object = p.parse( this.getStringResponse() );

		assertNotNull( o );
 		assertNotUndefined( o );
		assertEquals( STRING_DATA, o );
		assertTrue( o instanceof String );
 	}
 	
 	public function testDate():Void {
		var p:Parser = new ParserImpl();
		var o:Object = p.parse( this.getDateResponse() );

		assertNotNull( o );
 		assertNotUndefined( o );
		assertEquals( "Sun Mar 15 10:56:32 GMT-0500 1981",o.toString() );
		assertEquals( 15, o.getDate() );
		assertEquals( 1981, o.getFullYear());
		assertEquals( 3,  o.getMonth()+1 );
		assertEquals( 10, o.getHours() );
		assertEquals( 56, o.getMinutes() );
		assertEquals( 32, o.getSeconds() );	
					
		assertTrue( o instanceof Date );
 	}
 	
 	public function testArray():Void {
		var p:Parser = new ParserImpl();
		var o:Object = p.parse( this.getArrayResponse() );

		assertNotNull( o );
 		assertNotUndefined( o );

		assertEquals( 3, o.length );
		assertEquals( 12345, o[0] );
		assertEquals( "hello", o[1] );
		assertEquals( "Sun Mar 15 10:56:32 GMT-0500 1981", o[2].toString() );

		assertTrue( o instanceof Array );
		assertTrue( o[0] instanceof Number );
		assertTrue( o[1] instanceof String );
		assertTrue( o[2] instanceof Date );						
 	}
 	
 	public function testStruct():Void {
		var p:Parser = new ParserImpl();
		var o:Object = p.parse( this.getStructResponse() );

		assertNotNull( o );
 		assertNotUndefined( o );
		assertEquals( 12345, o['test_int'] );
		assertEquals( "hello", o['test_string'] );
		assertEquals( "Sun Mar 15 10:56:32 GMT-0500 1981", o['test_date'].toString());

		assertTrue( o instanceof Object );
		assertTrue( o['test_int'] instanceof Number );
		assertTrue( o['test_string'] instanceof String );
		assertTrue( o['test_date'] instanceof Date );			
 	}
 	
 	
 	
 	private function getIntResponse():XML {
	 	var x:String = METHOD_RESPONSE_HEADER+
						'		<param>				'+
						'			<value>			'+
						'				<int>16</int>'+
						'			</value>		'+
						'		</param>			'+
						METHOD_RESPONSE_FOOTER;
						
		var xml:XML = new XML();
		xml.ignoreWhite=true;
		xml.parseXML(x);
		return xml;
 	}
 	
 	private function getStringResponse():XML {
	 	var x:String = METHOD_RESPONSE_HEADER+
						'		<param>				'+
						'			<value>			'+
						'				<string>'+STRING_DATA+'</string>'+
						'			</value>		'+
						'		</param>			'+
						METHOD_RESPONSE_FOOTER;
						
		var xml:XML = new XML();
		xml.ignoreWhite=true;
		xml.parseXML(x);
		return xml;
 	}
 	
 	private function getArrayResponse():XML {
	 	var x:String = METHOD_RESPONSE_HEADER+
						'		<param>				'+
						'			<value>			'+
						'				<array><data>'+
						'	 				<value><int>12345</int></value>'+
						'	 				<value><string>hello</string></value>'+						
						'	 				<value><dateTime.iso8601>1981-03-15T10:56:32</dateTime.iso8601></value>'+												
						'				</data></array>'+
						'			</value>		'+
						'		</param>			'+
						METHOD_RESPONSE_FOOTER;
						
		var xml:XML = new XML();
		xml.ignoreWhite=true;
		xml.parseXML(x);
		return xml;
 	}
 	
 	private function getStructResponse():XML {
	 	var x:String = METHOD_RESPONSE_HEADER+
						'	 	<param><value><struct>'+
						'			<member><name>test_int</name><value><int>12345</int></value></member>'+
						'	 		<member><name>test_string</name><value><string>hello</string></value></member>'+						
						'	 		<member><name>test_date</name><value><dateTime.iso8601>1981-03-15T10:56:32</dateTime.iso8601></value></member>'+												
						'		</struct></value></param>'+
						METHOD_RESPONSE_FOOTER;

		var xml:XML = new XML();
		xml.ignoreWhite=true;
		xml.parseXML(x);
		return xml;
 	}
 	
 	private function getBase64Response():XML {
	 	var x:String = METHOD_RESPONSE_HEADER+
						'		<param>				'+
						'			 <value><base64>dmFsdWVhYWI=</base64></value>'+
						'		</param>			'+
						METHOD_RESPONSE_FOOTER;
						
		var xml:XML = new XML();
		xml.ignoreWhite=true;
		xml.parseXML(x);
		return xml;
 	}
 	
 	private function getDateResponse():XML {
	 	var x:String = METHOD_RESPONSE_HEADER+
						'		<param>				'+
						'			 <value><dateTime.iso8601>1981-03-15T10:56:32</dateTime.iso8601></value>'+
						'		</param>			'+
						METHOD_RESPONSE_FOOTER;
						
		var xml:XML = new XML();
		xml.ignoreWhite=true;
		xml.parseXML(x);
		return xml;
 	}
 	
 	
 	
}