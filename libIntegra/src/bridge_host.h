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

/** \file integra_bridge_host.h Integra bridge host functions */

/** \brief load an integra bridge 
 *
 * Searches for the named bridge and returns a pointer to its interface. 
 * If the function is unsuccessful, a NULL pointer is returned. 
 *
 * \param *so_name: the name of the binary shared object conaining the bridge 
 *
 * */

#ifndef INTEGRA_BRIDGE_HOST_PRIVATE_H
#define INTEGRA_BRIDGE_HOST_PRIVATE_H


#ifdef __cplusplus
extern "C" {
#endif

/** \brief function to load a bridge and return either a pointer to the bridge interface, or a NULL pointer */
void *ntg_bridge_load(const char *so_name);

#ifdef __cplusplus
}
#endif

#endif
