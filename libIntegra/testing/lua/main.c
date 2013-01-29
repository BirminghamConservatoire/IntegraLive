#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <Integra/integra_server.h>
#include <Integra/integra_lua_obsolete.h>

ntg_server *server;

void test_lua(void){
  ntg_lua_eval(server,
               NULL,
	       "print(\"start\")\n"
	       "load=integra.load(\"gakk\")\n"
	       //"print(load)\n"
	       "print(\"end\")"
	       );
}


int main(int const argc, const char ** const argv) {

    int port;

    if (argc-1 != 1) {
        fprintf(stderr, "You must specify 1 argument:  The TCP port number "
                "on which to listen for XML-RPC calls.  "
                "You specified %d.\n",  argc-1);
        exit(1);
    }
    
    port = atoi(argv[1]);

    //ntg_server_run("something",xmlport, oscport);
    server=ntg_server_new();

    test_lua();


    return 0;

}
