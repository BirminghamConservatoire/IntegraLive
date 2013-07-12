/* libIntegra multimedia module interface
 *  
 * Copyright (C) 2012 Birmingham City University
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

#ifndef INTEGRA_REENTRANCE_CHECKER_H
#define INTEGRA_REENTRANCE_CHECKER_H

#include "server.h"



typedef struct ntg_reentrance_checker_state_ ntg_reentrance_checker_state;


void ntg_reentrance_checker_initialize( ntg_server *server );
void ntg_reentrance_checker_free( ntg_server *server );

/**\brief push reentrance stack, returns true if rentrance detected */
bool ntg_reentrance_push( ntg_server *server, ntg_node_attribute *attribute, ntg_command_source cmd_source );

/**\brief pop reentrance stack.  must be called once for every ntg_reentrance_push */
void ntg_reentrance_pop( ntg_server *server, ntg_command_source cmd_source );



#endif /*INTEGRA_REENTRANCE_CHECKER_H*/
