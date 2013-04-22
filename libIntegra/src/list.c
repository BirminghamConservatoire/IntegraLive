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

#include "platform_specifics.h"
#include <assert.h>

#include "list.h"
#include "memory.h"



ntg_list *ntg_list_new(ntg_list_type type)
{
    ntg_list *list = ntg_malloc(sizeof(ntg_list));

    list->type    = type;
    list->n_elems = 0;
    list->elems   = NULL;

    return list;
}


void ntg_list_free_(ntg_list *list)
{
	if( list == NULL || list->elems != NULL )
	{
		NTG_TRACE_ERROR( "invalid input" );
		assert( false );
		return;
	}

    ntg_free(list);
}

void ntg_list_free_as_attributes(ntg_list *list)
{
    ntg_free(list->elems);
    list->elems   = NULL;
    list->n_elems = 0;

    ntg_list_free_(list);
}


void ntg_list_free_as_nodelist(ntg_list *list)
{

    unsigned int i;

    for(i = 0; i < list->n_elems; ++i) {
        ntg_path_free(((ntg_path **)list->elems)[i]);
    }
    if(list->n_elems != 0) {
        ntg_free(list->elems);
        list->elems = NULL;
    }
    ntg_list_free_(list);
}

void ntg_list_free_as_guids(ntg_list *list)
{
	if( list->elems )
	{
		ntg_free(list->elems);
		list->elems   = NULL;
		list->n_elems = 0;
	}
	else
	{
		assert( list->n_elems == 0 );
	}   

    ntg_list_free_(list);
}

unsigned long ntg_list_get_n_elems(ntg_list *list)
{
    return list->n_elems;
}

void ntg_list_free(ntg_list *list)
{
    if(list == NULL) {
        NTG_TRACE_ERROR("invalid input");
        assert(false);
        return;
    }

    switch(list->type) {
        case NTG_LIST_NODES:
            ntg_list_free_as_nodelist(list);
            break;
        case NTG_LIST_ATTRIBUTES:
            ntg_list_free_as_attributes(list);
            break;
		case NTG_LIST_GUIDS:
			ntg_list_free_as_guids(list);
			break;
        default:
            NTG_TRACE_ERROR("invalid list type");
            break;
    }
}


void ntg_list_push_guid( ntg_list *list, const GUID *guid )
{
	GUID *guids;
	assert( list && guid );
	assert( list->type == NTG_LIST_GUIDS );

	list->elems = ntg_realloc( list->elems, ( list->n_elems + 1 ) * sizeof( GUID ) );

	guids = ( GUID * ) list->elems;
	guids[ list->n_elems ] = *guid;

	list->n_elems++;
}