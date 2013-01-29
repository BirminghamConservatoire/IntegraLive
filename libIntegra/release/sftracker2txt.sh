#!/bin/sh
# simple/mvall
prog=`basename $0`
case $# in
0|1) echo 'Usage:' $prog '<input html filename> <output text filename>'; exit 1;;
esac


INFILE=$1
OUTFILE=$2

echo "Known Bugs" > $OUTFILE
echo "==========" >> $OUTFILE
echo "" >> $OUTFILE

cat $INFILE | grep google_ad_section | sed 's/<!-- google_ad_section_start -->/ - /g' | sed 's/<!-- google_ad_section_end -->//g' | sed 's/\t//g' | sed 's/    / /g' >> $OUTFILE
