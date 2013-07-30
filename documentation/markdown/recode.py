#!/usr/bin/python
'''Recode the file at the path given by the first argument from Unicode to ASCII with escaped HTML entities'''

import sys
import os.path

try:
	fileToRecode = sys.argv[1]
except IndexError:
	print "usage: %s <path to input file>" % os.path.basename(sys.argv[0])
	exit(0)

try:
	fileHandle = file(fileToRecode, "r", 0)
	try:
		fileContent = fileHandle.read()
	finally:
		fileHandle.close()
except IOError:
	print "error: an error occurred reading", fileToRecode
	exit(0)
	
asciiContent = fileContent.decode('utf-8')
recodedContent = asciiContent.encode('ascii', 'xmlcharrefreplace')

print recodedContent
