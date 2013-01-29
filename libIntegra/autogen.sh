#!/bin/sh

WANT_AUTOMAKE=1.6
export WANT_AUTOMAKE

case `uname -s` in
  Linux)
      LIBTOOLIZE=libtoolize
      ;;
  Darwin)
      LIBTOOLIZE=glibtoolize
      ;;
  *)  echo error: unrecognized OS
      exit 1
      ;;
esac

ACLOCALARGS='-I m4'
AUTOMAKE_REQ=1.6

# Automake version check from MusE
lessthan () {
  ver1="$1"
  ver2="$2"

  major1=$( echo $ver1 | sed "s/^\([0-9]*\)\..*/\1/");
  minor1=$( echo $ver1 | sed "s/^[^\.]*\.\([0-9]*\).*/\1/" );
  major2=$( echo $ver2 | sed "s/^\([0-9]*\)\..*/\1/");
  minor2=$( echo $ver2 | sed "s/^[^\.]*\.\([0-9]*\).*/\1/" );
  test "$major1" -lt "$major2" || test "$minor1" -lt "$minor2";
}

amver=$( automake --version | head -n 1 | sed "s/.* //" );
if lessthan $amver $AUTOMAKE_REQ ; then
    echo "you must have automake version >= $AUTOMAKE_REQ to proper bridge support"
    exit 1
fi

# Bootstrap!

    echo "=============== running" $LIBTOOLIZE " --force --copy" &&
    $LIBTOOLIZE --force --copy &&
    echo "=============== running aclocal" &&
    aclocal $ACLOCALARGS &&
    echo "=============== running autoheader" &&
    autoheader &&
    echo "=============== running automake -c --add-missing --foreign" &&
    automake -c --add-missing --foreign &&
    echo "=============== running autoconf" &&
    autoconf &&
    echo "=============== done"

