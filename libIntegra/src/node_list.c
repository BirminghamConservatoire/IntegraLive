/** libIntegra multimedia module interface
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


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "platform_specifics.h"

#include <assert.h>

#include "node_list.h"
#include "memory.h"


ntg_node_list *ntg_node_list_push( ntg_node_list *node_list, const ntg_node *node )
{
	ntg_node_list *new_node_list_entry;

	assert( node );

	new_node_list_entry = ntg_malloc( sizeof( ntg_node_list ) );
	new_node_list_entry->node = node;
	new_node_list_entry->next = node_list;

	return new_node_list_entry;
}


void ntg_node_list_free( ntg_node_list *node_list )
{
	ntg_node_list *entry_to_free;

	while( node_list )
	{
		entry_to_free = node_list;
		node_list = node_list->next;
		ntg_free( entry_to_free );
	}
}