MAINTAINERCLEANFILES = Makefile.in lua_init.c lua_functions.c

common_SOURCES =  id.c \
                helper.c \
                MurmurHash2.c \
                hashtable.c \
                command.c \
                node.c \
                init.c \
                memory.c \
				queue.c \
                value.c \
                server.c \
				server_public.c \
				server_commands.c \
                xmlrpc_server.c \
                osc_client.c \
                xmlrpc_common.c \
                error.c \
                validate.c \
                path.c \
                bridge_host.c \
                attribute.c \
				signals.c \
				list.c \
				trace.c \
				osc.c \
				interface.c \
				module_manager.c \
				player_handler.c \
				reentrance_checker.c \
				system_class_handlers.c \
				data_directory.c \
				file_io.c \
				scratch_directory.c \
				platform_specifics.c \
				luascripting.c \
				node_list.c 

MINIZIP_DIR=../externals/minizip

minizip_SOURCES=$(MINIZIP_DIR)/unzip.c \
		$(MINIZIP_DIR)/ioapi.c \
		$(MINIZIP_DIR)/zip.c \
		$(MINIZIP_DIR)/mztools.c
minizip_CFLAGS=-Dunix -DUSE_FILE32API

if USE_XMLRPC
#xmlrpc_SOURCES = 
endif


SOURCES = $(common_SOURCES) $(osc_SOURCES) $(minizip_SOURCES)


lib_LTLIBRARIES = libIntegra.la
libIntegra_la_SOURCES = $(SOURCES)
libIntegra_la_CFLAGS = $(minizip_CFLAGS)
libIntegra_la_LDFLAGS = -export-dynamic -ldl -lz -headerpad_max_install_names
libIntegra_la_LIBADD = @xml2_LIBS@ @xmlrpc_LIBS@ @xmlrpc_client_LIBS@ @OSC_LIBS@ @LUA_LIBS@

