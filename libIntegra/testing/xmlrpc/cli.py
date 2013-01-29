"""Convenience module to run XMLRPC CLI client under ipython"""

import xmlrpclib

class Server(object):
    def __init__(self):
        self._i = xmlrpclib.ServerProxy("http://localhost:8000/")

    def stateindex(self):
        return self._i.notify.stateindex()

    def updates(self, stateindex):
        return self._i.notify.update(stateindex)

    def classlist(self):
        return self._i.query.classlist()

    def classinfo(self, classname):
        return self._i.query.classinfo(classname)

    def attributes(self, classname):
        return self._i.query.attributes(classname)

    def get(self, attribpath):
        return self._i.query.get(attribpath)

    def nodelist(self, nodepath):
        return self._i.query.nodelist(nodepath)

    def set(self, attribpath, value):
        return self._i.command.set(attribpath, value)

    def new(self, classname, nodename, parentpath):
        return self._i.command.new(classname, nodename, parentpath)

    def delete(self, nodepath):
        return self._i.command.delete(nodepath)

    def rename(self, nodepath, newname):
        return self._i.command.rename(nodepath, newname)

    def save(self, nodepath, filepath):
        return self._i.command.save(nodepath, filepath)

    def load(self, filepath, nodepath):
        return self._i.command.load(filepath, nodepath)

    def move(self, nodepath, newparentpath):
        return self._i.command.move(nodepath, newparentpath)




