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

#include "trace.h"
#include "api/common_typedefs.h"


#ifdef DEFINE_GLOBALS
#define GLOBAL
#else
#define GLOBAL extern
#endif

#define NTG_NULL_GUID GUID( 0, 0, 0, { 0, 0, 0, 0, 0, 0, 0, 0 } )

/* global constants */
#define NTG_LONG_STRLEN    1024


namespace ntg_internal
{
	class CServer;
}

GLOBAL ntg_internal::CServer *server_;
GLOBAL void *bridge_handle;

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
