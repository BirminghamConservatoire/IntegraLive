
/* run the server with a dummy bridge */

#include "Integra/integra.h"
#include <unistd.h>

int main(void)
{
    const char *bridge_file = "integra_dummy_bridge.so";

    ntg_server_run(bridge_file, 8000, 8001);

    sleep(5);

    return 0;
}
