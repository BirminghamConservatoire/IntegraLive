AC_PREREQ(2.13)

m4_define(libIntegra_version, [ m4_esyscmd([cat ../FULLVERSION | tr -d '\n']) ]))

PACKAGE=libintegra

AC_INIT([libIntegra], [libIntegra_version], [dev@integralive.org])
AC_DEFINE(LIBINTEGRA_VERSION, libIntegra_version, [LibIntegra Version])
AM_INIT_AUTOMAKE([1.6])
AM_CONFIG_HEADER(config.h)
AC_PROG_CC
AM_PROG_CC_C_O
AC_CANONICAL_HOST
AC_PROG_LIBTOOL
AC_HEADER_ASSERT
AC_PROG_INSTALL
AC_ENABLE_STATIC(no)
AC_ENABLE_SHARED(yes)
AC_CHECK_HEADERS([stdlib.h stdio.h assert.h string.h])
AC_CHECK_FUNCS(getcwd)
AC_CONFIG_MACRO_DIR([m4])

libIntegra_LIBS=-lIntegra
AC_SUBST(libIntegra_LIBS)

AM_PATH_CHECK(,[have_check="yes"],
  AC_MSG_WARN([Check not found; cannot run unit tests!])
  [have_check="no"])
AM_CONDITIONAL(HAVE_CHECK, test x"$have_check" = "xyes")

# libtool version: current:revision:age
#
# If the library source code has changed at all since the last update, then
# increment revision (`c:r:a' becomes `c:r+1:a').
#
# If any interfaces have been added, removed, or changed since the last update,
# increment current, and set revision to 0.
#
# If any interfaces have been added since the last public release, then
# increment age.
#
# If any interfaces have been removed since the last public release, then set
# age to 0.
INTEGRA_SO_VERSION=0:0:0
dnl BASE_CFLAGS="-$(srcdir)/i -Wall -pedantic -ansi"
BASE_CFLAGS="-$(srcdir)/i -Wall"

# We have to specify optimisations like this becuase -fdefer-pop causes a program crash, and -fno-defer-pop isn't supported with O3 on OS X
# Note also -fdelayed-branch doesn't seem to be supported
O1_CFLAGS="-fguess-branch-probability -fcprop-registers -fif-conversion -fif-conversion2 -ftree-ccp -ftree-dce -ftree-dominator-opts -ftree-dse -ftree-ter -ftree-lrs -ftree-sra -ftree-copyrename -ftree-fre -ftree-ch -funit-at-a-time -fmerge-constants"
O2_CFLAGS="$O1_CFLAGS -fthread-jumps -fcrossjumping -foptimize-sibling-calls -fcse-follow-jumps -fcse-skip-blocks -fgcse -fgcse-lm -fexpensive-optimizations -frerun-cse-after-loop -fcaller-saves -fpeephole2 -fschedule-insns -fschedule-insns2 -fsched-interblock -fsched-spec -fregmove -fstrict-aliasing -fdelete-null-pointer-checks -freorder-blocks -freorder-functions -falign-functions -falign-jumps -falign-loops -falign-labels -ftree-pre"
O3_CFLAGS="$O2_CFLAGS -finline-functions -funswitch-loops -fgcse-after-reload"
#FAST_CFLAGS="$O3_CFLAGS -fomit-frame-pointer -fstrict-aliasing -momit-leaf-frame-pointer -fno-tree-pre -falign-loops"
FAST_CFLAGS="-O3"

CFLAGS="$BASE_CFLAGS"
LDFLAGS="$LDFLAGS" 

# --enable stuff

AC_ARG_ENABLE(osc_bridge, 
       [  --enable-osc_bridge    Compile the osc bridge],
       [case "${enableval}" in
	yes) osc_bridge=true ;;
	no)  osc_bridge=false ;;
	*) AC_MSG_ERROR(bad value ${enableval} for --enable-osc_bridge) ;;
    esac],[osc_bridge=false])

AC_ARG_ENABLE(server, 
       [  --enable-server        Compile the server executable],
       [case "${enableval}" in
	yes) server=true ;;
	no)  server=false ;;
	*) AC_MSG_ERROR(bad value ${enableval} for --enable-server) ;;
    esac],[server=false])

AC_ARG_ENABLE(cli_example,
       [  --enable-cli_example    Compile the command line interface],
       [case "${enableval}" in
	yes) cli_example=true ;;
	no)  cli_example=false ;;
	*) AC_MSG_ERROR(bad value ${enableval} for --enable-cli_example) ;;
    esac],[cli_example=false])

AC_ARG_ENABLE(dummy_bridge, 
       [  --enable-dummy_bridge    Compile the dummy bridge],
       [case "${enableval}" in
	yes) dummy_bridge=true ;;
	no)  dummy_bridge=false ;;
	*) AC_MSG_ERROR(bad value ${enableval} for --enable-dummy_bridge) ;;
    esac],[dummy_bridge=false])

AC_ARG_ENABLE(documentation, 
              [  --enable-documentation    Compile the documentation],
       [case "${enableval}" in
	yes) documentation=true ;;
	no)  documentation=false ;;
	*) AC_MSG_ERROR(bad value ${enableval} for --enable-documentation) ;;
    esac],[documentation=false])

# Check for Lua
CHECK_LUA([], AC_MSG_ERROR([you need lua >= 5.1]))
CFLAGS="$CFLAGS $LUA_CFLAGS -DBUILDPATH=`pwd`"

# Check for xmlrpc-c
OLD_LIBS=[$LIBS]
AC_CHECK_HEADERS([xmlrpc-c/base.h xmlrpc-c/server.h xmlrpc-c/server_abyss.h xmlrpc-c/abyss.h, xmlrpc-c/client.h], [xmlrpc_headers=yes], [xmlrpc_headers=no])
AC_CHECK_LIB([xmlrpc_util], [xmlrpc_millisecond_sleep], [LIB_XMLRPC_UTIL='-lxmlrpc_util'], [want_xmlrpc=no])
LIBS="$LIB_XMLRPC_UTIL $LIBS"
AC_CHECK_LIB([xmlrpc_abyss], [ServerRun], [want_xmlrpc=$xmlrpc_headers], [want_xmlrpc=no])

AC_MSG_CHECKING([for xmlrpc-c-config])
XMLRPC_CONFIG=`which xmlrpc-c-config 2>/dev/null`
if [ test ! -x "${XMLRPC_CONFIG}" ]
then
        want_xmlrpc=no
else
        want_xmlrpc=yes
fi
AC_MSG_RESULT($want_xmlrpc)

AM_CONDITIONAL([USE_XMLRPC], [test "x$want_xmlrpc" = "xyes"])

if test "x$want_xmlrpc" = "xyes"
then
        xmlrpc_LIBS="${xmlrpc_LIBS} `xmlrpc-c-config abyss-server --libs`"
        xmlrpc_libdir="`xmlrpc-c-config abyss-server --prefix`/lib"
        #xmlrpc_LIBS="$xmlrpc_libdir/libxmlrpc.a $xmlrpc_libdir/libxmlrpc_abyss.a $xmlrpc_libdir/libxmlrpc_server.a $xmlrpc_libdir/libxmlrpc_server_abyss.a $xmlrpc_libdir/libxmlrpc_util.a $xmlrpc_libdir/libxmlrpc_xmlparse.a $xmlrpc_libdir/libxmlrpc_xmltok.a"
        xmlrpc_client_LIBS=""
        AC_DEFINE(USE_XMLRPC, , [Compile XML-RPC interface])
else
	AC_MSG_ERROR(Error: missing libxmlrpc-c or incorrect version)
fi
LIBS="$OLD_LIBS"

# At least 1.16.6 is unstable. These are the versions I don't know if works. -Kjetil

illegal_xmlrpc_versions="
1.16.0
1.16.1
1.16.2
1.16.3
1.16.4
1.16.5
1.16.6
1.16.7
1.16.8
1.16.9
1.16.10
1.16.11
1.16.12
1.16.13
1.16.14
1.16.15
1.16.16
1.16.17
1.16.18
1.16.19
1.16.20
1.16.21
1.16.22
1.16.23
1.16.24
1.16.25
1.16.26
1.16.27
1.16.28
1.16.29
1.16.30
"

for v in $illegal_xmlrpc_versions;do
    if test `xmlrpc-c-config --version` = $v
    then
        AC_MSG_ERROR(Can not use a version of xmlrpc between 1.16.0 and 1.16.30. 1.16.31 or newer is fine, and 1.06.42 works as well.)
    fi
done


#-lxmlrpc_xmlparse 

AC_SUBST(xmlrpc_SRC)
AC_SUBST(xmlrpc_LIBS)
AC_SUBST(xmlrpc_LIBADD)
AC_SUBST(xmlrpc_client_LIBS)


AC_ARG_WITH(xml2-config,
[  --with-xml2-config=PATH Specify path to xml2-config.],,)

if test "$with_xml2_config" = "no" ; then
  AC_MSG_ERROR([LibXML2 support is a need to TinyOWS !])
fi

if test "`basename xx/$with_xml2_config`" = "xml2-config" ; then
  LIBXML2_CONFIG="$with_xml2_config"
  if ! test -f "$LIBXML2_CONFIG" -a -x "$LIBXML2_CONFIG" ; then
    AC_MSG_ERROR(['$LIBXML2_CONFIG' is not an executable.  Make sure you use --with-xml2-config=/path/to/xml2-config])
  fi
else
  AC_PATH_PROG(LIBXML2_CONFIG, xml2-config, no)
fi

if test "$LIBXML2_CONFIG" = "no" ; then
 AC_MSG_ERROR([couldn't find xml2-config, try using --with-xml2-config=PATH])
fi

XML2_VER=`$LIBXML2_CONFIG --version`
AC_MSG_RESULT([checking for libxml2 version... $XML2_VER])

xml2_vers=`$LIBXML2_CONFIG --version | awk 'BEGIN { FS = "."; } { printf "%d", ($1 * 1000 + $2) * 1000 + $3;}'`
if test "$xml2_vers" -lt 2006016 ; then
    AC_MSG_ERROR([You need at least libxml 2.6.16])
fi


xml2_SRC=`$LIBXML2_CONFIG --cflags`
xml2_LIBS=`$LIBXML2_CONFIG --libs`

CFLAGS="$CFLAGS $xml2_SRC"

AC_SUBST(xml2_SRC)
AC_SUBST(xml2_LIBS)

dnl --with stuff

AC_ARG_WITH(liblo_include_dir,
	[  --with-liblo-include-dir=path   liblo header path (default=/usr/include/lo) ],
	[
	liblo_include_dir="$withval"
	echo
	echo "liblo include dir is $withval"
	echo
	], [liblo_include_dir=false])

AC_ARG_WITH(pd_include_dir,
	[  --with-pd-include-dir=path   pd header path (default=/usr/include/) ],
	[
	pd_include_dir="$withval"
	echo
	echo "pd include dir is $withval"
	echo
	], [pd_include_dir=false])

dnl are we building the osc_bridge 
if [[ "$osc_bridge" = "true" ]] ; then
    AC_DEFINE([BUILD_OSC_BRIDGE], [1], [Build the OSC bridge])
fi

AM_CONDITIONAL(BUILD_OSC_BRIDGE, test "x${osc_bridge}" = 'xtrue')

dnl are we building the server 
if [[ "$server" = "true" ]] ; then
        AC_DEFINE([BUILD_SERVER], [1], [Build the server application])
fi

AM_CONDITIONAL(BUILD_SERVER, test "x${server}" = 'xtrue')

dnl liblo deps

AC_CHECK_LIB(lo, main, [ac_liblo="yes"], [ac_liblo="no"])
   if test "x$ac_liblo" = "xyes"; then
      AC_DEFINE(CONFIG_LIBLO, 1, [Define if liblo is available.])
      OSC_LIBS="-llo"
   else
      AC_MSG_ERROR([liblo library not found.])
      #AC_MSG_WARN([*** lo library not found.])
      #AC_MSG_WARN([*** OSC service support will be disabled.])
   fi

AC_SUBST(OSC_LIBS)

CFLAGS_TEMP="$CFLAGS"
CFLAGS="-I$liblo_include_dir"
AC_CHECK_HEADER(lo/lo.h, [ac_lo_h="yes"], [ac_lo_h="no"])
if test "x$ac_lo_h" = "xno"; then
	AC_MSG_ERROR([lo.h header file not found.])
fi
CFLAGS="$CFLAGS_TEMP"

AC_ARG_VAR([OSC_CFLAGS], [$OSC_CFLAGS], [C compiler flags for liblo])
AC_ARG_VAR([OSC_LIBS], [$OSC_LIBS], [C linker flags for liblo])

dnl are we building the dummy_bridge 
if [[ "$dummy_bridge" = "true" ]] ; then
    AC_DEFINE([BUILD_DUMMY_BRIDGE], [1], [Build the dummy bridge])
fi

AM_CONDITIONAL(BUILD_DUMMY_BRIDGE, test "x${dummy_bridge}" = 'xtrue')


if [[ "$documentation" = "true" ]] ; then

    AC_CHECK_PROG([DOXYGEN], [doxygen], [doc], [])
    AC_SUBST(DOXYGEN)
    AC_DEFINE([BUILD_DOCUMENTATION], [1], [Build the documentation])

    if test -z "$DOXYGEN"; then
        AC_MSG_ERROR([--enable-documentation specified but could not find doxygen binary])
    fi
fi


AM_CONDITIONAL(BUILD_DOCUMENTATION, test "x${documentation}" = 'xtrue')

# The install prefix is needed in integra_helper.c to establish
# default search paths for various files.
if [[ "x${prefix}" = xNONE ]]; then
   prefix=$ac_default_prefix
fi
AC_DEFINE_UNQUOTED(INSTALL_PREFIX,["${prefix}"],[Path to the install location])

dnl Enable debugging (yes)
AC_ARG_ENABLE(debug,
AS_HELP_STRING([--enable-debug],
               [enable debugging, default: no]),
[case "${enableval}" in
             yes) debug=true ;;
             no)  debug=false ;;
             *)   AC_MSG_ERROR([bad value ${enableval} for --enable-debug]) ;;
esac],
[debug=true])
if test "$debug" = "true"; then
   CFLAGS="$CFLAGS -g -ggdb -O0"
dnl AC_DEFINE(INTEGRA_DEBUG,1,[Define to enable debug])
else
    CFLAGS="$CFLAGS $FAST_CFLAGS -DNDEBUG"
fi
AM_CONDITIONAL(DEBUG, test x"$debug" = x"true")

dnl Enable profiling (no)
AC_ARG_ENABLE(profile,
  [  --enable-profile[[=value]]   compile with profiling flags [[default=no]]],
  with_profile="yes",
  with_profile="no")
if test "$with_profile" = "yes"; then
   CFLAGS="$CFLAGS -pg"
   LDFLAGS+="$LDFLAGS -pg"
   AC_DEFINE(INTEGRA_PROFILE,1,[Define to enable profiling])
fi

AC_ARG_ENABLE(Werror,
  [  --enable-Werror[[=value]]   compile with debug [[default=no]]],
  with_Werror="yes",
  with_Werror="no")
if test "$with_Werror" = "yes" ; then
   CFLAGS="$CFLAGS -Werror"
   AC_DEFINE(INTEGRA_WERROR,1,[Define to enable Werror])
fi

AC_CONFIG_FILES([doc/documentation.doxygen
				libIntegra.pc])

AC_OUTPUT([Makefile
	src/Makefile
	Integra/Makefile
	doc/Makefile
	testing/Makefile
	bridges/Makefile
	bridges/OSC/Makefile
	bridges/dummy/Makefile
	testing/check/Makefile
	server/Makefile
        ])

echo
echo "**************************************************************"
echo
echo "Building libIntegra version libIntegra_version Summary:"
echo

if test "$dummy_bridge" = "true"; then
  echo "dummy bridge:			   	   yes"
else
  echo "dummy bridge:		           	   no"
fi
if test "$osc_bridge" = "true"; then
  echo "osc bridge:			   	   yes"
else
  echo "osc bridge:		           	   no"
fi
if test "$server" = "true"; then
  echo "server application:			   yes"
else
  echo "server application:		           no"
fi
if test "$documentation" = "true"; then
  echo "documentation:			   	   yes"
else
  echo "documentation:		           	   no"
fi
if test "$debug" = "true"; then
  echo "debug build:			   	   yes"
else
  echo "debug build:		           	   no"
fi


  

echo
echo "**************************************************************"
echo
echo Configuration completed successfully. Type \'make\' to build ${PACKAGE}
echo


