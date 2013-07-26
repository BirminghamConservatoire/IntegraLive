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


#include <pthread.h>
#include <semaphore.h>

#include "lo_ansi.h"
#include "id.h"
#include "trace.h"
#include "api/common_typedefs.h"


#ifdef DEFINE_GLOBALS
#define GLOBAL
#else
#define GLOBAL extern
#endif

/* global constants */
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

#define NTG_NODE_NAME_CHARACTER_SET "0123456789_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

namespace ntg_internal
{
	class CServer;
}

GLOBAL ntg_internal::CServer *server_;
GLOBAL void *bridge_handle;

GLOBAL ntg_internal::internal_id id_counter_; 

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
