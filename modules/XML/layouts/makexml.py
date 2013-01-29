
f = open("MIDI.xml", 'w')

lines = []
lines.append('<controls>\n')
lines.append('\t<control id="channel" x="10" y="10" width="100" height="100"/>\n')

for i in range(128):
    lines.append('\t<control id="cc%d" x="%d" y="10" width="25" height="140" />\n' % (i, 125 + (i * 25)))

lines.append('</controls>\n')

f.writelines(lines)
f.close()
