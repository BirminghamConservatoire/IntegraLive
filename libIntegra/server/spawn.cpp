/* *n*x-specific spawn implementation */

#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdarg.h>
#include <signal.h>
#include <spawn.h>

#include "spawn_.h"
#include "Integra/integra.h"

#ifndef _WINDOWS


static int spawnv_sync(const char *file, char *const argv[])
{
    NTG_TRACE_ERROR("not yet implemented");
    return -1;
}



static int spawnv_async(const char *file, char *const argv[])
{

    pid_t pid = fork();

    if (pid==0) /* first child */
    {
        execv(file, argv);
        exit(127);
    }
    else if (pid > 0) /* parent */
    {
        pid_t pid_parent = getpid();
        pid_t pid2 = fork();

        if (pid2 == 0) /* second child */
        {
            while(1)
            {
                if (getppid() != pid_parent) /* parent has died */
                {
                    /* kill first child */
                   kill( pid, SIGKILL );
                   exit(0);
                }
                sleep(1);
            }
        }
        return pid;
    }
    else
    {
        return pid;
    }
}

/*
int spawnl(const char *file, ...)
{
    va_list ap;
    int i, n;

    va_start(ap, file);
    for(n = 1; va_arg(ap, char *); n++)
        ;
    va_end(ap);
    {
        char *argv[n];

        va_start(ap, file);
        for(i = 0; i < n; i++)
            argv[i] = va_arg(ap, char *);
        va_end(ap);
        return spawnv(file, argv);
    }
}
*/
int spawnv(int mode, const char *file, char *const argv[])
{
    switch (mode) {
        case P_WAIT:
            return spawnv_sync(file, argv);
        case P_NOWAIT:
            return spawnv_async(file, argv);
        default:
            NTG_TRACE_ERROR_WITH_INT("mode not supported", mode);
            exit(EXIT_FAILURE);
    }
}


#endif
