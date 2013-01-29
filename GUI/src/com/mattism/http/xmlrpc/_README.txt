##
#	XMLRPC for ActionScript 2.0             
#	http://xmlrpcflash.mattism.com
##

Getting Started
	
	* Put the XML-RPC classes in your class path, starting with the com folder
	* Check out the fla's in the examples folder.

Troubleshooting Client Errors:
	
	* XML-RPC Works in IDE But Not In Browser
		
		Check your cross-domain security setup:
		* http://www.macromedia.com/devnet/flash/articles/fplayer_security_03.html
		* http://moock.org/asdg/technotes/crossDomainPolicyFiles/

	* Security tips from Rákos Attila <tenegri@tengerstudio.com>
		
		By default you cannot connect from your Flash movie to a server other
		than that one which is hosting your swf. However there are several
		solutions:
		
		1. Set up a gateway on the server hosting your movie for transferring
		requests and responses between the target server and your flash movie
		
		2. Place a small swf on the target server and load it into your movie
		(since this swf is originated from the target server you can load
		data from the server through it)
		
		3. Create a policy file in the root directory of the target server
		which allows establishing connection for flash movies originated
		from different domains
		
		And there is some further reading on security restrictions and policy
		files:
		
		http://www.macromedia.com/devnet/flash/articles/fplayer8_security.html
		http://www.macromedia.com/devnet/flash/articles/fplayer_security.html

		If you are using Flash 8 and trying to connect from
		a local flash movie, there is a new default security method, which
		restricts communication via the Internet. By default local swf-s can
		access only local files and are not allowed to access remote data,
		however this behavior can be changed in the Publish settings of the
		Flash IDE, and by that way your local swf-s can communicate with the
		internet, but cannot access local files. Projectors (exe) are not
		bound by these restrictions and even local swf can be granted with
		full access rights using the Settings Manager or by placing a
		configuration file on the computer.

Troubleshooting Server Errors:

	* Server Throws a Serialization/Marhsalling Error/Fault
	
		Often a server that supports XML-RPC will not use any descretion 
		when trying to serialize an object into XML. If the server comes 
		across a complex object, it will throw some sort of error. Obviously
		that error message will differ, but it will be along the lines of
		"Error... serializing/marhsalling object/data/etc". This error occurs
		because XML is plain-text so our objects have to be able to translate
		to plain-text and be a simple object (int,string,hash,array) so that 
		another platform (in this case Flash) can instantiate it. So an example
		of this problem would be if you are calling a method on the server that
		gets member data out of a database. Let's say you are calling a method
		called getMember() which returns a Member object. This Member object is
		most likely going to throw an error when the server tries to serialize 
		it because the object is too complex. The Member object could contain
		binary data for an image, references to other objects in the database,
		or other complex objects. In these cases I create a server-side
		method which acts as a proxy between XML-RPC serializing and the complex 
		object. This method will get the Member object and then enumerate it's
		properties and return XML-RPC friendly data. What I return would be
		a struct/hash/assoc.array with the Member property names as the keys and 
		basic objects as the values. A specific example would be to return a url 
		for an image rather than the binary data that is stored in the Member
		Object. Note: XML-RPC does support binary serialization via base64
		but in Flash 8 we cannot create anything with that data. However, in
		ActionScript 3 we will be able to.


	

Matt Shaw <xmlrpc@mattism.com>>