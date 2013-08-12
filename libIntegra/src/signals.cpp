/** libIntegra multimedia module interface
 *
 * Copyright (C) 2007 Birmingham City University
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
 * USA.
 */

#ifndef _WINDOWS

#include "platform_specifics.h"

#include <signal.h>
#include <pthread.h>

#include "helper.h"
#include "globals.h"
#include "server.h"

void ntg_sig_block(sigset_t *sigset)
{
    sigemptyset(sigset);
    sigaddset(sigset, SIGHUP);
    sigaddset(sigset, SIGINT);
    sigaddset(sigset, SIGTERM);
    sigaddset(sigset, SIGQUIT);
    sigaddset(sigset, SIGPIPE);
    sigaddset(sigset, SIGUSR1);
    sigaddset(sigset, SIGUSR2);
    pthread_sigmask(SIG_BLOCK, sigset, 0);
}


void ntg_sig_unblock(sigset_t *sigset)
{
    pthread_sigmask(SIG_UNBLOCK, sigset, 0);
    sigemptyset(sigset);
}



void ntg_sig_handler(int signum) 
{
    NTG_TRACE_PROGRESS_WITH_INT("caught signal", signum);
    switch(signum) {
        case SIGINT:
        case SIGTERM:
        case SIGHUP:
        case SIGQUIT:
            sem_post(SEM_SYSTEM_SHUTDOWN);
            break;
            /* for now we only handle terminating sigs */

    }
    signal(signum, SIG_DFL);
    raise(signum); 
}

void *ntg_sighandler_thread(void *unused)
{
    int sig;

    sigset_t set;
    sigfillset(&set);

	NTG_TRACE_PROGRESS("started signal handler thread");
    while (1) {

		sigwait(&set, &sig);

		ntg_sig_handler(sig);
        NTG_TRACE_PROGRESS("exiting signal thread");
        pthread_exit(NULL);
        break;
    }

    return NULL;
}

void ntg_sig_setup(void)
{
    signal(SIGINT, ntg_sig_handler);
    signal(SIGTERM, ntg_sig_handler);
    signal(SIGHUP, ntg_sig_handler);
    signal(SIGQUIT, ntg_sig_handler);
    signal(SIGPIPE, SIG_IGN);
}


#endif		/*_WINDOWS*/
