LIBINTEGRA_DIR=/usr/local/lib

CFLAGS=-O0 -ggdb

all:
	$(CC) -L$(LIBINTEGRA_DIR) -lIntegra test_link_no_run.c -o test_link_no_run -lxmlrpc_client
	$(CC) -L$(LIBINTEGRA_DIR) -lIntegra test_run_server.c -o test_run_server `xml2-config --libs --cflags` -lxmlrpc_client
	$(CC) -L$(LIBINTEGRA_DIR) -lIntegra test_run_server_indefinite.c -o test_run_server_indefinite `xml2-config --libs --cflags` -lxmlrpc_client
	$(CC) $(CFLAGS) `xmlrpc-c-config abyss-server --libs --cflags` test_xmlrpc_runserver.c -o test_xmlrpc_runserver

