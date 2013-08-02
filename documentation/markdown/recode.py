#!/usr/bin/python
'''Recode the file at the path given by the first argument from Unicode to ASCII with escaped HTML entities'''

import sys
import os.path

try:
	fileToRecode = sys.argv[1]
	try:
		fileHandle = file(fileToRecode, "r", 0)
	except IOError:
		print "error: an error occurred reading", fileToRecode
		exit(0)
except IndexError:
		if not sys.stdin.isatty():
			fileHandle = sys.stdin
		else:
			print "usage: %s <path to input file>" % os.path.basename(sys.argv[0])
			exit(0)

with fileHandle as fh:
	fileContent = fh.read()
	
asciiContent = fileContent.decode('utf-8')
recodedContent = asciiContent.encode('ascii', 'xmlcharrefreplace')

print recodedContent
