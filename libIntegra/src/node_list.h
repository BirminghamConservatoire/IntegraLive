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

#ifndef INTEGRA_NODE_LIST_H
#define INTEGRA_NODE_LIST_H

#include "node.h"



/** \struct ntg_node_list 
 * \brief Linked list of ntg_node pointers
 */
struct ntg_node_list_
{
    const ntg_node *node;
    struct ntg_node_list_ *next;

};


struct ntg_node_list_ *ntg_node_list_push( struct ntg_node_list_ *node_list, const ntg_node *node );
void ntg_node_list_free( struct ntg_node_list_ *node_list );

const ntg_node *ntg_node_list_get_tail( struct ntg_node_list_ *node_list );




#endif /*INTEGRA_NODE_LIST_H*/
