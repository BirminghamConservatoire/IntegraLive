/* libIntegra multimedia module interface
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

#ifndef INTEGRA_GLOBALS_H
#define INTEGRA_GLOBALS_H


#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#include <pthread.h>
#include <semaphore.h>

#include "lo_ansi.h"
#include "id.h"
#include "memory.h"
#include "trace.h"


#ifdef DEFINE_GLOBALS
#define GLOBAL
#else
#define GLOBAL extern
#endif

/* global constants */
#define XML_ENCODING        "ISO-8859-1"
#define NTG_LEN_PATH_ATTR   10
#define NTG_LONG_STRLEN    1024

#define NTG_FILE_SUFFIX "integra"
#define NTG_MODULE_SUFFIX "integra-module"

/* 
 we use linux-style path separators for all builds, because windows can use the two interchangeably, 
 PD can't cope with windows separators at all, and zip files maintain the directionality of slashes 
 (if we used system-specific slashes in zip files, the files would not be platform-independant)
*/

#define NTG_PATH_SEPARATOR "/"

#define NTG_DATA_COPY_BUFFER_SIZE 16384

#define NTG_INTEGRA_DATA_DIRECTORY_NAME "integra_data" NTG_PATH_SEPARATOR
#define NTG_INTERNAL_IXD_FILE_NAME NTG_INTEGRA_DATA_DIRECTORY_NAME "nodes.ixd"
#define NTG_INTEGRA_IMPLEMENTATION_DIRECTORY_NAME NTG_INTEGRA_DATA_DIRECTORY_NAME "implementation" NTG_PATH_SEPARATOR


GLOBAL struct ntg_server_ *server_;
GLOBAL struct ntg_queue_ *command_queue_;
GLOBAL void *bridge_handle;

GLOBAL ntg_id id_counter_; 
GLOBAL pthread_t xmlrpc_thread;
GLOBAL pthread_t server_thread;
GLOBAL pthread_t signal_thread;
#ifndef _WINDOWS
GLOBAL sigset_t signal_sigset;
#endif
GLOBAL lo_server_thread osc_interface;

GLOBAL ntg_trace_category_bits trace_category_bits;
GLOBAL ntg_trace_options_bits trace_option_bits;


#ifdef __APPLE__
GLOBAL sem_t *sem_abyss_init;
GLOBAL sem_t *sem_system_shutdown;
#define SEM_ABYSS_INIT sem_abyss_init
#define SEM_SYSTEM_SHUTDOWN sem_system_shutdown
#else
GLOBAL sem_t sem_abyss_init;
GLOBAL sem_t sem_system_shutdown;
#define SEM_ABYSS_INIT &sem_abyss_init
#define SEM_SYSTEM_SHUTDOWN &sem_system_shutdown
#endif



#endif
