#!/usr/bin/python
"""Unit tests for the libIntegra XML-RPC interface"""
import Tkinter, tkFileDialog
import filecmp
import xmlrpclib
import unittest
import datetime
import base64
import os
import time

import thread


SLEEPTIME = 0
CWD = os.getcwd()
READ_FILE_PATH = CWD + '/test.ixd'
WRITE_FILE_PATH = CWD + '/test_new.ixd'
#READ_FILE_PATH = ''
#WRITE_FILE_PATH = ''

class TestSystemMethods(unittest.TestCase):
   """Test built-in xmlrpc-c 'system' methods"""

   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")

       self.signatures = {
           'system.listMethods':"[['array']]",
           'system.methodSignature':"[['array', 'string']]",
           'system.methodHelp':"[['string', 'string']]",
           'system.multicall':"[['array', 'array']]",
           'system.version':"[['struct']]",
           'system.shutdown':"[['int', 'string']]",
           'notify.stateindex':"[['struct']]",
           'notify.updates':"[['struct', 'int']]",
           'query.classlist':"[['struct']]",
           'query.classinfo':"[['struct', 'string']]",
           'query.attributes':"[['struct', 'string']]",
           'query.get':"[['struct', 'array']]",
           #'runscript':"[['struct', 'string']]",
           'query.nodelist':"[['struct', 'array']]",
           'command.set':"[['struct', 'array', 'string'],"\
                   " ['struct', 'array', 'int'],"\
                   " ['struct', 'array', 'double'],"\
                   " ['struct', 'array', 'base64']]",
           'command.new':"[['struct', 'string', 'string', 'array']]",
           'command.delete':"[['struct', 'array']]",
           'command.rename':"[['struct', 'array', 'string']]",
           'command.save':"[['struct', 'array', 'string']]",
           'command.load':"[['struct', 'string', 'array']]",
           'command.move':"[['struct', 'array', 'array']]",
       }

       self.help = {

           'system.listMethods':
           "Return an array of all available XML-RPC methods on this server.",

           'system.methodSignature':
           "Given the name of a method, return an array of legal signatures. Each signature is an array of strings.  The first item of each signature is the return type, and any others items are parameter types.",

           'system.methodHelp':
           "Given the name of a method, return a help string.",

           'system.multicall':
           "Process an array of calls, and return an array of results.  Calls should be structs of the form {'methodName': string, 'params': array}. Each result will either be a single-item array containg the result value, or a struct of the form {'faultCode': int, 'faultString': string}.  This is useful when you need to make lots of small calls without lots of round trips.",

           'system.shutdown':
           "Shut down the server.  Return code is always zero.",

           'system.version':
           "Return the current version of libIntegra\n\\return {'response':'system.version', 'version':<string>\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n",

           'notify.stateindex':
           "Return the current state index from the notification queue\n\\return {'response':'notify.stateindex', 'stateindex':<int>\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n",

           'notify.updates':
           "Return the contents of the notification queue after a given state index\n\param <int stateindex>\n\\return {'response':'notify.updates', 'updates':[{'stateindex':<int>, 'command':<string>, 'params':<array>}, ... ]\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n",

           'query.classlist':
           "Return a list of classes available for instantiation on the server\n\\return {'response':'query.classlist', 'classlist':<array>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n",

           'query.classinfo':
           "Return info about a class\n\param <string classname>\n\\return {'response':'query.classinfo', 'classname':<string>, 'classinfo':{'id':<int>, 'name':<string>, 'label':<string>, 'instantiable':<int 0-1>, 'core':<int 0-1>, 'system':<int 0-1>, 'description':<string>}}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n",

           'query.attributes':
           "Return a list of attribute definitions for a class\n\param <string classname>\n\\return {'response':'query.attributes', 'classname':<string>, 'attributes':[{'id':<int>, 'name':<string>, 'description':<string>, 'scope':<string>, 'type':<string>, 'minimum':<float>, 'maximum':<float>, 'undoable':<int 0-1>, 'unit':<string>, 'scale':<string>, 'control':<string>, 'controlgroup':<string>, 'controlattribute':<string>, 'default':<value>, 'legalvalues':[<value>, ...], 'valuelabels':[{'value':<value>, 'label':<label>}, ...]}, ... ]\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           #'runscript':
           #"Run a script\n\param <string script>\n\\return {'response':'runscript', 'data':<string return value>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'query.nodelist':
           "Return a list of nodes under the current node using depth-first recursion\n\param <array path>\n\\return {'response':'query.nodelist', 'nodelist':[{classname:<string>, path:<array>}, {classname:<string>, path:<array>}, ... ]}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'query.get':
           "Get the value of an attribute\n\param <array attribute path>\n\\return {'response':'query.get', 'path':<array>, 'value':<value>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'command.set':
           "Set the value of an attribute\n\param <array attribute path>\n\param <value value>\n\\return {'response':'command.set', 'path':<array>, 'value':<value>, 'stateindex':<int>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",


           'command.new':
           "Create a new instance of a class on the server\n\param <string class name>\n\param <string instance name>\n\param <array parent path>\n\\return {'response':'command.new', 'classname':<string>, 'instancename':<string>, 'parentpath':<array>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'command.delete':
           "Delete an instance of a class from the server\n\param <array path>\\return {'response':'command.delete', 'path':<array>\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'command.rename':
           "Rename an instance of a class on the server\n\param <array path>\n\param <string instance name>\n\\return {'response':'command.rename', 'instancepath':<array path>, 'name':<string name>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'command.save':
           "Save all nodes including and below a given node on the server to a path on the filesystem\n\param <array path>\n\param <string file path>\n\\return {'response':'command.save', 'instancepath':<array path>, 'filepath':<string path>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'command.load':
           "Load all nodes including and below a given node from the filesystem beneath the path given to the given node on the server\n\param <string file path>\n\param <array path>\n\\return {'response':'command.load', 'filepath':<string path>', 'parentpath':<array path>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

           'command.move':
           "Move an instance of a class on the server\n\param <array instance path>\n\param <array new instance parent path>\n\\return {'response':'command.move', 'instancepath':<array path>, 'parentpath':<array path>}\n\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n",

       }

   def testListMethods(self):
       rv = self.p.system.listMethods()
       self.assert_(rv)
       for method in self.signatures.keys():
           self.assert_(method in rv)

   def testMethodSignature(self):
       """Iterate over methods advertised by system.listMethods() and establish that method signature is valid

       """
       methods = self.p.system.listMethods()
       assert_ = self.assert_
       for method in methods:
           sig = self.p.system.methodSignature(method)
           print method
           print sig
           try:
               expected_sig = self.signatures[method]
           except KeyError:
               expected_sig = 'undef'
           #if str(sig) != expected_sig:
           #    print "SIG %s: %s" % (method, sig)
           #    print "EXPECTED SIG: %s" % expected_sig
           assert_(str(sig) == expected_sig)
#        print "len_methods: %d, expected: %d" % (len(methods), self.n_expected_methods)
       self.assert_(len(methods) == len(self.signatures))

   def testMethodHelp(self):
       """Iterate over methods advertised by system.listMethods() and establish that method help is valid

       """
       methods = self.p.system.listMethods()
       for method in methods:
           help = self.p.system.methodHelp(method)
           expected_help = self.help[method]
           #print "\nhelp: %s\nexpected: %s\n" % (help, expected_help)
           #if help != expected_help:
           #    print "\nhelp: %s\nexpected: %s\n" % (help, expected_help)
           self.assert_(help == expected_help)

   def testMulticall(self):
       load_params = ['', '', []]
       rv = self.p.system.multicall([
           {'methodName':'command.new', 'params':load_params},
           {'methodName':'command.delete', 'params':[[]]}
           ])
       self.assert_(rv)

   def tearDown(self):
       self.p = None

class TestAPI(unittest.TestCase):
   """Test that the Integra server API exists and that errors are
   returned when type-correct but invalid data is sent

   """

   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       now = datetime.datetime.now()
       now_iso8601 = now.strftime("%Y-%m-%d %H:%M:%S")
       self.dummy = {
               'array': [],
               'struct': {},
               'string': '',
               'int': 0,
               'double': 0.0,
               'base64': base64.b64encode(''),
               'boolean': False,
               'nil': None,
               'dateTime.iso8601': now_iso8601
               }

       self.fault_expected = [
               'system.methodSignature', 
               'system.methodHelp',
               'system.shutdown',
               'notify.updates',
               'notify.stateindex'
               ]

   def get_args(self, signature):
       args = []
       for el in signature:
           args.append(self.dummy[el])
       return args

   def testReturnValues(self):
       """Iterate over the methods advertised by the server and call them
       with valid data according to the advertised method signature.
       Succeed if the value returned by the method has the same type as that
       advertiesed in the method signature

       """
       assert_ = self.assert_
       methods = self.p.system.listMethods()

       for method in methods:
           print "calling", method
           if method == "notify.updates":
               continue
           signatures = self.p.system.methodSignature(method)
           for sig in signatures:
               expected_rv = self.dummy[sig[0]]
               expected_rv_type = type(expected_rv)
               args = self.get_args(sig[1:])
               assert_(hasattr(self.p, method))
               rv = None
               try:
                   rv = getattr(self.p, method)(*args)
               # FIX: check actual fault strings
               except xmlrpclib.Fault, err:
               #    print "** the method %s() returned a Fault object" % \
               #        str(method)
               #    print "Fault code: %d" % err.faultCode
               #    print "Fault string: %s" % err.faultString
                   if method in self.fault_expected:
                #       print "fault was expected"
                       rv = expected_rv
                   else:
                       print "unexpected fault"
               rv_type = type(rv)
               assert_(rv_type == expected_rv_type)

   def tearDown(self):
       self.p = None

class TestRootCRUD(unittest.TestCase):
   """Test module create, update, delete inside the root node"""

   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.set_value = 0.123456
       self.class_ = 'TapDelay'
       self.module = 'TapDelay1'
       self.attribute = 'delayTime'

   def new_in_root(self):
       path = []
       self.rv = self.p.command.new(self.class_, self.module, path)

   def set_in_root(self):
       path = [self.module, self.attribute]
       self.rv = self.p.command.set(path, self.set_value)

   def get_in_root(self):
       path = [self.module, self.attribute]
       self.rv = self.p.query.get(path)

   def delete_in_root(self):
       path = [self.module]
       self.rv = self.p.command.delete(path)

   def testNewInRoot(self):
       self.new_in_root()
       self.assert_(self.rv['response'] == 'command.new')

   def testSetInRoot(self):
       self.new_in_root()
       self.set_in_root()
       self.assert_(self.rv['response'] == 'command.set')

   def testGetInRoot(self):
       self.new_in_root()
       self.set_in_root()
       self.get_in_root()
       self.assert_(self.rv['response'] == 'query.get')
       #check the value we sent is the one we get back
       print self.rv['value']
       self.assert_(self.rv['value'] == self.set_value)

   def testDeleteInRoot(self):
       self.new_in_root()
       self.delete_in_root()
       self.assert_(self.rv['response'] == 'command.delete')

   def tearDown(self):
       path = [self.module]
       self.p.command.delete(path)
       self.p = None

class ThreadedClockMixin(object):
   """Functionality for starting a clock in a separate thread"""
   pass

class BlockCRUDMixin(object):
   """Functionality for nested CRUD"""

   def new_with_block(self, class_=None, module=None):
       if class_ != None:
           self.class_ = class_
       if module != None:
           self.module = module
       expected_response = 'command.new'
       path = [self.project, self.block, self.module]
       classes = [self.containerclass, self.containerclass, self.class_]

       command_calls = 0

       for i in range(len(path)):
           self.rv = self.p.command.new(classes[i], path[i], path[:i])
           command_calls += 1
           if self.rv['response'] != expected_response:
               break

       return command_calls

   def new_in_block(self, class_=None, module=None):
       if class_ != None:
           self.class_ = class_
       if module != None:
           self.module = module
       expected_response = 'command.new'
       path = [self.project, self.block]
       rv = self.p.command.new(self.class_, self.module, path)
       self.assert_(rv['response'] == expected_response)

   def set_in_block(self, module=None, attribute=None, value=None):
       if module != None:
           self.module = module
       if attribute != None:
           self.attribute = attribute
       if value != None:
           self.set_value = value
       path = [self.project, self.block, self.module, self.attribute]
       self.rv = self.p.command.set(path, self.set_value)

   def get_in_block(self, module=None, attribute=None):
       if module != None:
           self.module = module
       if attribute != None:
           self.attribute = attribute
       path = [self.project, self.block, self.module, self.attribute]
       self.rv = self.p.query.get(path)

   def delete_in_block(self, module=None):
       if module != None:
           self.module = module
       path = [self.project, self.block, self.module]
       self.rv = self.p.command.delete(path)

class TestBlockCRUD(unittest.TestCase, BlockCRUDMixin):
   """Test module create, update, delete inside a nested node"""

   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.set_value = 0.123456
       self.class_ = 'TapDelay'
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.attribute = 'delayTime'
       self.containerclass = 'Container'

   def testNewInBlock(self):
       self.new_with_block()
       self.assert_(self.rv['response'] == 'command.new')

   def testSetInBlock(self):
       self.new_with_block()
       self.set_in_block()
       self.assert_(self.rv['response'] == 'command.set')

   def testGetInBlock(self):
       self.new_with_block()
       self.set_in_block()
       self.get_in_block()
       self.assert_(self.rv['response'] == 'query.get')
       #check the value we sent is the one we get back
       self.assert_(self.rv['value'] == self.set_value)

   def testDeleteInBlock(self):
       self.new_with_block()
       self.delete_in_block()
       self.assert_(self.rv['response'] == 'command.delete')

   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)
       self.p = None

class TestGetSet(unittest.TestCase, BlockCRUDMixin):
   """Test that get and set do the right thing in unexpected cases"""

   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.set_value = 0.123456
       self.class_ = 'TapDelay'
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.attribute = 'delayTime'
       self.containerclass = 'Container'

   def testSetNonExistantAttribute(self):
       self.new_with_block() 
       path = [self.project, self.block, self.module, 'foobar']
       self.rv = self.p.command.set(path, self.set_value)
       self.delete_in_block()

   def testSetContainerAttribute(self):
       self.new_with_block() 
       path = [self.project, self.block, 'start']
       self.rv = self.p.command.set(path, 20)
       self.delete_in_block()

   def testSetConnectionUserData(self):
       self.new_with_block()
       self.new_in_block('DeepConnection', 'DeepConnection1')
       self.set_in_block('DeepConnection1', 'userData', 'sdfsfsdfs')
       self.get_in_block('DeepConnection1', 'userData')
       self.assert_(self.rv['value'] == 'sdfsfsdfs')

   def testSetGetDeepConnectionTarget(self):
       self.new_with_block()
       self.new_in_block('DeepConnection', 'DeepConnection1')
       self.set_in_block('DeepConnection1', 'sourcePath', 'DeepConnection1.')
       self.get_in_block('DeepConnection1', 'sourcePath')
       print self.rv['value']
       self.assert_(self.rv['value'] == 'DeepConnection1.')


   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)
       self.p = None

class TestGetSetMinimal(unittest.TestCase, BlockCRUDMixin):
   """Test that get and set do the right thing in unexpected cases"""

   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.set_value = 0.123456
       self.class_ = 'TapDelay'
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.attribute = 'delayTime'
       self.containerclass = 'Container'

#   def testSetNonExistantAttribute(self):
#       self.new_with_block() 
#       path = [self.project, self.block, self.module, 'foobar']
#       self.rv = self.p.command.set(path, self.set_value)
#       self.delete_in_block()

#   def testSetContainerAttribute(self):
#       self.new_with_block() 
#       path = [self.project, self.block, 'start']
#       self.rv = self.p.command.set(path, 20)
#       self.delete_in_block()

   def testSetConnectionUserData(self):
       self.new_with_block()
       #self.new_in_block('DeepConnection', 'DeepConnection1')
       #self.set_in_block('DeepConnection1', 'userData', 'sdfsfsdfs')
       #self.get_in_block('DeepConnection1', 'userData')
       #self.assert_(self.rv['value'] == 'sdfsfsdfs')

#   def testSetGetDeepConnectionTarget(self):
#       self.new_with_block()
#       self.new_in_block('DeepConnection', 'DeepConnection1')
#       self.set_in_block('DeepConnection1', 'sourcePath', 'DeepConnection1.')
#       self.get_in_block('DeepConnection1', 'sourcePath')
#       print self.rv['value']
#       self.assert_(self.rv['value'] == 'DeepConnection1.')


   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)
       self.p = None

class TestAttributes(unittest.TestCase):
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")

   def testOnClassList(self):
       rv = self.p.query.classlist()
       classlist = rv['classlist']

       for i in range(20):
           for class_ in classlist:
               rv = self.p.query.attributes(class_)
               self.assert_(rv['response'] == 'query.attributes')


class TestNodeList(unittest.TestCase):
   """Test that nodelist is correctly maintained"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.containerclass = 'Container'
       self.class_ = 'TapDelay'
       self.path = [self.project, self.block, self.module]
       self.classes = [self.containerclass, self.containerclass, self.class_]

   def newTree(self):
       for i in range(len(self.path)):
           self.p.command.new(self.classes[i], self.path[i], self.path[:i])

   def deleteTree(self):
       self.p.command.delete([self.path[0]])

   def testEmpty(self):
       rv = self.p.query.nodelist([])
       self.assert_(rv['response'] == 'query.nodelist')
       self.assert_(rv['nodelist'] == [])

   def testCallOnRoot(self):
       self.newTree()
       expected_nodelist = [{'classname': self.classes[n], 'path':self.path[:n+1]} for n,p in enumerate(self.path)]
       rv = self.p.query.nodelist([])
       #print "\n%s\nexpected: %s, \ngot: %s" % ('Root()', expected_nodelist, rv)
       self.assert_(str(rv['nodelist']) == str(expected_nodelist))
       self.deleteTree()
       rv = self.p.query.nodelist([])
       self.assert_(rv['nodelist'] == [])

   def testCallOnSubNode(self):
       self.newTree()
       expected_nodelist = [{'classname': self.classes[n], 'path':self.path[1:n+1]} for n,p in enumerate(self.path)]
       rv = self.p.query.nodelist(self.path[:1])
       #print "\n%s\nexpected: %s, \ngot: %s" % ('SubNode()', expected_nodelist, rv)
       self.assert_(str(rv['nodelist']) == str(expected_nodelist[1:]))
       self.deleteTree()
       rv = self.p.query.nodelist([])
       self.assert_(rv['nodelist'] == [])

class TestRenameMove(unittest.TestCase, BlockCRUDMixin):
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.containerclass = 'Container'
       self.class_ = 'TapDelay'
       self.new_name = 'FooBar'

   def testRenameModule(self):
       self.new_with_block()
       path = [self.project, self.block]
       self.p.command.rename(path + [self.module], self.new_name)
       nodelist = self.p.query.nodelist(path)
       got_name = nodelist['nodelist'][0]['path'][0]
       self.assert_(got_name == self.new_name)

   def testRenameBlock(self):
       self.new_with_block()
       path = [self.project]
       self.p.command.rename(path + [self.block], self.new_name)
       nodelist = self.p.query.nodelist([])
       got_path = nodelist['nodelist'][2]['path']
       expected_path = [self.project, self.new_name, self.module]
       for i, node in enumerate(got_path):
           self.assert_(expected_path[i] == node)

   def testRenameWithConnected(self):
       self.new_with_block()
       self.new_in_block('AudioOut', 'AudioOut1')
       self.new_in_block('Connection', 'Connection1')
       self.set_in_block('Connection1', 'sourceInstance', 'TapDelay1')
       self.set_in_block('Connection1', 'sourceAttribute', 'out1')
       self.set_in_block('Connection1', 'targetInstance', 'AudioOut1')
       self.set_in_block('Connection1', 'targetAttribute', 'in1')
       path = [self.project, self.block, 'AudioOut1']
       self.p.command.rename(path, 'FooBar')

   def testMove(self):
       self.new_with_block()
       self.block = 'Block2'
       self.new_with_block()
       self.p.command.move([self.project, 'Block1', self.module],
           [self.project, self.block])
       self.p.query.nodelist([])
       print self.rv


   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)
       self.p = None

class TestDisconnect(unittest.TestCase, BlockCRUDMixin):
   """Add modules in various configurations, disconnect and then remove them"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/", allow_none=True)
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.containerclass = 'Container'
       self.class_ = 'TapDelay'

   def testOneToOne(self): 
       self.new_with_block()
       self.new_in_block('AudioOut', 'AudioOut1')
       self.new_in_block('Connection', 'Connection1')
       #self.new_in_block('TapDelay', 'TapDelay1')
       self.set_in_block('Connection1', 'sourceInstance', 'TapDelay1')
       self.set_in_block('Connection1', 'sourceAttribute', 'out1')
       self.set_in_block('Connection1', 'targetInstance', 'AudioOut1')
       self.set_in_block('Connection1', 'targetAttribute', 'in1')
       self.set_value = None
       self.set_in_block('Connection1', 'targetAttribute', None)
       #self.p.delete_in_block('Connection1')
       #self.p.delete_in_block('TapDelay1')

   def testOneToMany(self):
       rv = True 
       self.assert_(rv)

   def testManyToOne(self):
       rv = True
       self.assert_(rv)

   def testManyToMany(self):
       rv = True
       self.assert_(rv)

   def testNonExistant(self):
       rv = True
       self.assert_(rv)

   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)
       self.p = None

class TestNotify(unittest.TestCase, BlockCRUDMixin):
   """Test notification mechanism"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.containerclass = 'Container'

   def _getUpdateInThread(self, value, *args):
       rv = self.p.notify.updates(value)
       self.assert_(str(rv['updates']) == """[{'classname': None, 'path': ['Project1', 'Block1', 'Clock1', 'tick'], 'instancename': None, 'commandname': 'set', 'value': 1.0}]""")
       self.delete_in_block()

   def testStateIndex(self):
       self.new_with_block('Clock', 'Clock1')
       initial_stateindex = self.p.notify.stateindex()['stateindex']
       # need to make sure we do sth. that changes server state
       self.set_in_block('Clock1', 'rate', 0)
       stateindex = self.p.notify.stateindex()['stateindex']
       self.assert_(stateindex == initial_stateindex + 1)

   def testUpdates(self):
       self.new_with_block('Clock', 'Clock1')
       stateindex = self.p.notify.stateindex()['stateindex']
       thread.start_new_thread(self._getUpdateInThread, (stateindex + 2,))
       self.set_in_block('Clock1', 'rate', 1)
       time.sleep(2)

   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)

class TestAttributeConnection(unittest.TestCase, BlockCRUDMixin):
   """Test connection between attributes"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.class_ = 'TapDelay'
       self.delay_time = .123
       self.containerclass = 'Container'

   def testBasic(self):
       self.new_with_block()
       self.new_in_block('TapDelay', 'TapDelay2')
       self.new_in_block('Connection', 'Connection1')
       self.set_in_block('Connection1', 'sourceInstance', 'TapDelay1')
       self.set_in_block('Connection1', 'sourceAttribute', 'delayTime')
       self.set_in_block('Connection1', 'targetInstance', 'TapDelay2')
       self.set_in_block('Connection1', 'targetAttribute', 'delayTime')
       self.set_in_block('TapDelay1', 'delayTime', self.delay_time)
       self.get_in_block('TapDelay1', 'delayTime')
       self.assert_(self.rv['value'] == self.delay_time)

   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)

class TestEnvelope(unittest.TestCase, BlockCRUDMixin):
   """Test Envelope class"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.containerclass = 'Container'

   def testBasic(self):
       self.new_with_block('Player', 'Player1')
       self.new_in_block('Envelope', 'Envelope1')
       envelope_path = [self.project, self.block, 'Envelope1']
       self.p.command.new('ControlPoint', 'ControlPoint1', envelope_path)
       self.p.command.new('ControlPoint', 'ControlPoint2', envelope_path)
       self.new_in_block('Connection', 'Connection1')
       self.new_in_block('Connection', 'Connection2')
       self.set_in_block('Connection1', 'sourceInstance', 'Player1')
       self.set_in_block('Connection1', 'sourceAttribute', 'tick')
       self.set_in_block('Connection1', 'targetInstance', 'Envelope1')
       self.set_in_block('Connection1', 'targetAttribute', 'currentTick')
       
       cp_path = envelope_path + ['ControlPoint1']
       self.p.command.set(cp_path + ['tick'], 0)
       self.p.command.set(cp_path + ['value'], 1.)
       cp_path = envelope_path + ['ControlPoint2']
       self.p.command.set(cp_path + ['tick'], 20)
       self.p.command.set(cp_path + ['value'], 10.)
       self.set_in_block('Envelope1', 'startTick', 0)
       self.set_in_block('Player1', 'tick', 10)
       self.get_in_block('Envelope1', 'currentValue')
       self.assert_(self.rv['value'] == 5.5)

   def tearDown(self):
       path = [self.project]
       #self.p.command.delete(path)



class TestLoadSave(unittest.TestCase, BlockCRUDMixin):
   """Test load and save"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.module = 'TapDelay1'
       self.class_ = 'TapDelay'
       self.containerclass = 'Container'
       self.myFormats = [('Integra eXtensible Data','*.ixd')]
       self.read_file_path = READ_FILE_PATH
       self.write_file_path = WRITE_FILE_PATH

   def testSave(self):
       """Save a file calling command.save() and compare it to test.ixd"""
       self.new_with_block()
       self.new_in_block(module='TapDelay2')
       self.rv = self.p.command.new('Container', 'Block2', ['Project1'])
       self.rv = self.p.command.new('TapDelay', 'TapDelay1', ['Project1', 'Block2'])
       if not self.write_file_path:
           root = Tkinter.Tk()
           root.withdraw()
           self.write_file_path = tkFileDialog.asksaveasfilename(parent=root,filetypes=self.myFormats ,title="Save file as...")

       try:
           os.remove(self.write_file_path)
       except:
           pass
       self.p.command.save(['Project1'], self.write_file_path)
       self.assert_(filecmp.cmp(self.read_file_path, self.write_file_path))

   def testLoadSave(self):
       """Load a file calling command.load(), save it and compare"""

       if not READ_FILE_PATH or not WRITE_FILE_PATH:
           root = Tkinter.Tk()
           root.withdraw()

       if not self.read_file_path:
           self.read_file_path = tkFileDialog.askopenfilename(parent=root,title='Open file')

       if not self.write_file_path:
           self.write_file_path = tkFileDialog.asksaveasfilename(parent=root,filetypes=self.myFormats ,title="Save file as...")

       self.p.command.load(self.read_file_path, [])
       try:
           os.remove(self.write_file_path)
       except:
           pass
       #os.remove(self.write_file_path)
       self.p.query.nodelist([])
       self.p.command.save(['Project1'], self.write_file_path)
       self.assert_(filecmp.cmp(self.read_file_path, self.write_file_path))

   def tearDown(self):
       path = [self.project]
       self.p.command.delete(path)


class TestScript2(unittest.TestCase, BlockCRUDMixin):
   """Test scripting interface"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.containerclass = 'Container'

   def testScriptBasic(self):
       """load a script that prints 'hello world'"""
       self.new_with_block('Script', 'Script1')
       #self.set_in_block('Script1', 'text', 'print "hello world"')
       self.set_in_block('Script1', 'text', 'func = loadfile("/home/kjetil/integralive/library/trunk/testing/xmlrpc/test.lua")\nfunc()\n')
       self.set_in_block('Script1', 'trigger', None)
       time.sleep(100000000)

   def tearDown(self):
       pass
       path = [self.project]
       self.p.command.delete(path)

class TestScript(unittest.TestCase, BlockCRUDMixin):
   """Test scripting interface"""
   def setUp(self):
       self.p = xmlrpclib.ServerProxy("http://localhost:8000/")
       self.project = 'Project1'
       self.block = 'Block1'
       self.containerclass = 'Container'

#   def testPlayer(self):
#       """temporary test to test the player"""
#       self.new_with_block('Player', 'Player1')
#       self.set_in_block('Player1', 'rate', 4)
#       self.set_in_block('Player1', 'tick', 1)
#       self.set_in_block('Player1', 'play', 1)
#       self.get_in_block('Player1', 'tick')
#       time1 = self.rv['value']
#       time.sleep(2)
#       self.get_in_block('Player1', 'tick')
#       time2 = self.rv['value']
#       self.set_in_block('Player1', 'play', 0)
#       self.assert_(time2 > time1)



   def testScriptBasic(self):
       """load a script that prints 'hello world'"""
       self.new_with_block('Script', 'Script1')
       #self.set_in_block('Script1', 'text', 'print "hello world"')
       self.set_in_block('Script1', 'text', 'func = loadfile("~/integralive/library/trunk/testing/xmlrpc/test.lua")\nfunc()\n')
       self.set_in_block('Script1', 'trigger', None)
       time.sleep(100000000)
       
   def testInstantiate(self):
       """load a TapDelay from script"""
       self.new_with_block('Script', 'Script1')
       self.set_in_block('Script1', 'text', 'TapDelay1 = new("TapDelay")')
       self.set_in_block('Script1', 'trigger', None)
       time.sleep(10)
       
   def testScript(self):
      self.testScriptBasic()

   def testScript_old(self):
       """load a script that gets triggered by a player, and adds .1 to the delayTime of a TapDelay every player tick"""
       # add script object
       self.new_with_block('Script', 'Script1')
       # add TapDelay
       self.new_in_block('TapDelay', 'TapDelay1')
       # add player
       self.new_in_block('Player', 'Player1')
       # connect Player1.tick to Script1.trigger
       self.new_in_block('Connection', 'Connection1')
       self.set_in_block('Connection1', 'sourcePath', 'Player1.tick')
       self.set_in_block('Connection1', 'targetPath', 'Script1.trigger')
       # set script text
       self.set_in_block('Script1', 'text', 'integra.set("TapDelay1","delayTime", .1)')
       # set the player rate
       self.set_in_block('Player1', 'rate', 4)
       # get delayTime
       self.get_in_block('TapDelay1', 'delayTime')
       dt1 = self.rv['value']
       # start player
       self.set_in_block('Player1', 'play', 1)
       # wait a second
       time.sleep(2)
       # stop player
       self.set_in_block('Player1', 'play', 0)
       # get new delayTime
       self.get_in_block('TapDelay1', 'delayTime')
       dt2 = self.rv['value']
       print dt1, dt2
       # assert the delayTime has increased
       self.assert_(dt2 > dt1)
       print "sleeping 100 seconds"
       time.sleep(100)

   def tearDown(self):
       pass
       path = [self.project]
       self.p.command.delete(path)


def suite():
   disconnect = unittest.TestLoader().loadTestsFromTestCase(TestDisconnect)
#    remove = unittest.TestLoader().loadTestsFromTestCase(TestRemove)
   root_crud = unittest.TestLoader().loadTestsFromTestCase(TestRootCRUD)

   block_crud           = unittest.TestLoader().loadTestsFromTestCase(TestBlockCRUD)
   api                  = unittest.TestLoader().loadTestsFromTestCase(TestAPI)
   system               = unittest.TestLoader().loadTestsFromTestCase(TestSystemMethods)
   nodelist             = unittest.TestLoader().loadTestsFromTestCase(TestNodeList)
   getset               = unittest.TestLoader().loadTestsFromTestCase(TestGetSet)
   attributes           = unittest.TestLoader().loadTestsFromTestCase(TestAttributes)
   move_rename          = unittest.TestLoader().loadTestsFromTestCase(TestRenameMove)
   notify               = unittest.TestLoader().loadTestsFromTestCase(TestNotify)
   attribute_connection = unittest.TestLoader().loadTestsFromTestCase(TestAttributeConnection)
   load_save            = unittest.TestLoader().loadTestsFromTestCase(TestLoadSave)
   script               = unittest.TestLoader().loadTestsFromTestCase(TestScript2)
   envelope             = unittest.TestLoader().loadTestsFromTestCase(TestEnvelope)


   #tests = [notify]
   #tests = [getset]
#   tests = [api, system, nodelist, block_crud, root_crud, getset, attributes, disconnect, move_rename]
#    tests = [api, system, nodelist, block_crud, root_crud, getset, attributes, disconnect, move_rename, notify, attribute_connection, load_save, script]
#   tests = [nodelist, block_crud, root_crud, getset, attributes, disconnect, move_rename, notify, attribute_connection, load_save, script]
#    tests = [attribute_connection]

   #tests = [script]

   #getset, attributes,
#   tests = [getset]
   #disconnect]
   #tests = [notify]
   #tests = [move_rename]
   #tests = [root_crud]
#    tests= [nodelist]
#    tests = [nodelist]
#    tests = [disconnect]
#    tests = [load_save]
#   tests = [envelope]
#   suite = unittest.TestSuite(tests)
   suite = unittest.TestSuite()

#   suite.addTest(TestScript("testScript"))
#   suite.addTest(TestScript("testInstantiate"))
#   suite.addTest(TestNodeList("testCallOnRoot"))

#    suite.addTest(TestRenameMove("testRenameWithConnected"))
#  suite.addTest(TestRootCRUD("testSetInRoot"))
#    suite.addTest(TestRootCRUD("testNewInRoot"))
#    suite.addTest(TestBlockCRUD("testSetInBlock"))
#    suite.addTest(TestBlockCRUD("testNewInBlock"))
#    suite.addTest(TestBlockCRUD("testDeleteInBlock"))
#    suite.addTest(TestBlockCRUD("testGetInBlock"))
#    suite.addTest(TestBlockCRUD("testDeleteInBlock"))
#    suite.addTest(TestDisconnect("testOneToOne"))
   suite.addTest(TestLoadSave("testLoadSave"))

   #suite.addTests(disconnect)
   return suite


if __name__ == '__main__':

   have_testoob = True
   try:
       import testoob
   except:
       have_testoob = False


   if have_testoob:
       testoob.main(defaultTest="suite", verbose=True)
   else:
       unittest.TextTestRunner(verbosity=2).run(suite())

