MAINTAINERCLEANFILES = Makefile.in configure depcomp compile config.guess ltmain.sh config.sub missing install-sh aclocal.m4 config.h.in config.h.in~ py-compile INSTALL m4/ltsugar.m4 m4/libtool.m4 m4/ltversion.m4 m4/lt~obsolete.m4 m4/ltoptions.m4 doc/Makefile.in doc/documentation.doxygen doc/Makefile

if BUILD_DOCUMENTATION
    DOCUMENTATION_DIR = @DOXYGEN@
endif

SUBDIRS = src Integra
SUBDIRS += $(DOCUMENTATION_DIR)
SUBDIRS += bridges server
SUBDIRS += testing
REPOBASEDIR = ..
MODULESDIR = modules
MODULESUFFIX = .integra-module
SCHEMADIR = data
COLLECTIONSCHEMA = CollectionSchema.xsd
MAPPINGFILE = id2guid.csv

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = libIntegra.pc

dist_pkgdata_DATA = $(SCHEMADIR)/$(COLLECTIONSCHEMA) $(SCHEMADIR)/$(MAPPINGFILE)
nobase_dist_pkgdata_DATA = $(MODULESDIR)/*

ACLOCAL_AMFLAGS = -I m4
BUILT_SOURCES = $(MODULESDIR)

EXTRA_DIST = \
	autogen.sh \
	README \
	src/*.h \
	src/lua_init.lua \
	src/gen_lua_init.py \
	src/atomic.c \
	doc/*.in


RUNCOMMAND=./server/.libs/integra_server -bridge=bridges/dummy/.libs/integra_dummy_bridge.so -xmlrpc_server_port=8000 -osc_server_port=8001 -osc_client_port=8002 -osc_client_url=127.0.0.1 -module_paths=modules -trace_progress=1

run:
	$(RUNCOMMAND)

run-debug:
	gdb --args $(RUNCOMMAND)

maintainer-clean-local:
	-rm -rf $(MODULESDIR)

clean-local:
	-rm -f $(MODULESDIR)/*

$(MODULESDIR):
	-mkdir -p $(MODULESDIR)
	-cp $(REPOBASEDIR)/$(MODULESDIR)/*MODULESUFFIX $(MODULESDIR)

dist-hook: 
#	find -E ./ -iregex '(.*DS_Store$|.*svn$)' | xargs rm -rf			

AUTOMAKE_OPTIONS = foreign
