
/* minimal xmlrpc server in separate thread */

#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>

#include <xmlrpc-c/base.h>
#include <xmlrpc-c/abyss.h>
#include <xmlrpc-c/server.h>
#include <xmlrpc-c/server_abyss.h>

TServer abyssServer;

pthread_mutex_t init_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  init_cond  = PTHREAD_COND_INITIALIZER;


void *xmlrpc_server_run(void *foo){

    xmlrpc_registry * registryP;
    xmlrpc_env env;
    int port = 8000;

    xmlrpc_env_init(&env);

    registryP = xmlrpc_registry_new(&env);

    ServerCreate(&abyssServer, "XmlRpcServer", port, NULL, NULL);

    xmlrpc_server_abyss_set_handlers2(&abyssServer, "/RPC2", registryP);

    ServerInit(&abyssServer);

    pthread_cond_signal(&init_cond);

    ServerRun(&abyssServer);

    ServerFree(&abyssServer);
    xmlrpc_registry_free(registryP);
    AbyssTerm();
    xmlrpc_env_clean(&env);

    fprintf(stderr, "server terminated...\n");
    pthread_exit(0);

}

int 
main(int           const argc, 
     const char ** const argv) {

    pthread_t xmlrpc_thread;
    pthread_create( &xmlrpc_thread, NULL, xmlrpc_server_run, NULL);

    pthread_mutex_lock(&init_mutex);
    pthread_cond_wait(&init_cond, &init_mutex);
    ServerTerminate(&abyssServer);
    pthread_mutex_unlock(&init_mutex);

    pthread_join(xmlrpc_thread, NULL);

    return 0;
}
