# coding: utf-8
import xml.etree.ElementTree as ET
import pprint
import sys
from sets import Set


if len(sys.argv) > 1:
    IXD_file = sys.argv[1]
else:
    print "Usage: %s <path to IXD>" % sys.argv[0]
    exit(1)


pp = pprint.PrettyPrinter(depth=6)
tree = ET.parse(IXD_file)
root = tree.getroot()
parent_map = dict((c, p) for p in root.getiterator() for c in p)
block_envelopes = []
blocks = []
trackMap = {}
envelopesWithoutValidConnections = []

# Find all BlockEnvelope instances
for object in root.iter('object'):
    name = object.get('name')
    # Assume all BlockEnvelope instances have a name beginning with BlockEnveope
    if name[:13] == "BlockEnvelope":
        block_envelopes.append(object)

# For each block envelope find the corresponding Connection under its parent
for envelope in block_envelopes:
    parent = parent_map[envelope]
    envelopeName = envelope.get('name')
    trackName = parent.get('name')
    # It would be great here if we could test if the parent is a Track, but since Tracks can be renamed the only thing we can do is check if the parent is a Container!

    expectedSourcePath = envelopeName + ".currentValue"

    # Find all Connections under the parent
    connections = parent.findall("./*[@moduleId='36c9c7c5-b954-0a12-84f2-ded0de687886']")
    sourcePathFound = False
    targetPathValid = False

    if not trackMap.has_key(trackName):
        trackMap[trackName] = {"targets":Set([]), "blocks":Set([])}

    # For each connection check if sourcePath and targetPath are valid for the given BlockEnvelope
    for connection in connections:
        sourcePath = connection.find("attribute[@name='sourcePath']").text
        targetPath = connection.find("attribute[@name='targetPath']").text
        trackMap[trackName]["targets"].add(targetPath[:targetPath.find(".")])

        for child in parent.findall("object"):
           nodeName = child.get("name")
           if nodeName.find("BlockEnvelope") == -1 and nodeName.find("Connection") == -1:
               trackMap[trackName]["blocks"].add(nodeName)

        if sourcePath == expectedSourcePath:
            sourcePathFound = True
            print "%s: found expected sourcePath %s" % (envelopeName, sourcePath)

            # Check that targetPath points to a valid Block.active

            # First check the path is of the form <instance>.<endpoint>
            dotLocation = targetPath.find(".")
            if targetPath.count(".") == 1 and dotLocation != 0 and dotLocation + 1 != len(targetPath):
               # Find the instance the targetPath points to
               targetName, targetEndpoint = targetPath.split(".")
               target = parent.find(".//*[@name='%s']" % targetName)
               if target is not None:
                   endpoint = target.find("attribute[@name='%s']" % targetEndpoint)
                   if endpoint is not None:
                       print "%s: connection targetPath connects to a valid endpoint" % envelopeName
                       targetPathValid = True
                   else:
                       print "%s: [ERROR] target endpoint not found for connection" % envelopeName
               else:
                   track = parent_map[connection]
                   print "%s: [ERROR] target node not found for connection %s" % (envelopeName, track.get('name') + "." + connection.get('name'))
                   print "%s: [ERROR] targetPath was set to %s" % (envelopeName, targetPath)
            else:
                print "%s: [ERROR] connection targetPath is of an invalid form"

    if not sourcePathFound:
        print "%s: [ERROR] no Connection with expected sourcePath %s" % (envelopeName, expectedSourcePath)

    if not sourcePathFound or not targetPathValid:
        envelopesWithoutValidConnections.append(parent.get('name') + "." + envelopeName)


print ""
print "Suspected erroneous nodes:"
pp.pprint(envelopesWithoutValidConnections)

for track in trackMap:
    blocks = trackMap[track]["blocks"]
    targets = trackMap[track]["targets"]
    blocks_no_connection = list(blocks - targets)
    connections_no_block = list(targets - blocks)

    if blocks_no_connection:
        print "%s: the following Blocks have no corresponding Connection targetPath: %s" % (track, blocks_no_connection)
    if connections_no_block:
        print "%s: the following Connection targetPaths have no corresponding Block: %s" % (track, connections_no_block)


for track in trackMap:
    trackMap[track]["blocks"] = list(trackMap[track]["blocks"])
    trackMap[track]["targets"] = list(trackMap[track]["targets"])

# print "Track map:"
# pp.pprint(trackMap)



