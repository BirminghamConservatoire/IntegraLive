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
#include "path.h"
#include "trace.h"

using ntg_api::CPath;


ntg_list *ntg_list_new(ntg_list_type type)
{
    ntg_list *list = new ntg_list;

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

    delete list;
}

void ntg_list_free_as_nodelist(ntg_list *list)
{

    unsigned int i;

    for(i = 0; i < list->n_elems; ++i) 
	{
		delete (((CPath **)list->elems)[i]);
    }
    if(list->n_elems != 0) {
        delete[] list->elems;
        list->elems = NULL;
    }
    ntg_list_free_(list);
}

void ntg_list_free_as_guids(ntg_list *list)
{
	if( list->elems )
	{
		delete[] list->elems;
		list->elems   = NULL;
		list->n_elems = 0;
	}
	else
	{
		assert( list->n_elems == 0 );
	}   

    ntg_list_free_(list);
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
		case NTG_LIST_GUIDS:
			ntg_list_free_as_guids(list);
			break;
        default:
            NTG_TRACE_ERROR("invalid list type");
            break;
    }
}


void ntg_list_push_node( ntg_list *list, const CPath &path )
{
	assert( list );

	CPath **paths = new CPath *[ list->n_elems + 1 ];
	memcpy( paths, list->elems, list->n_elems * sizeof( CPath * ) );
	paths[ list->n_elems ] = new CPath( path );

	delete[] list->elems;
	list->elems = paths;
    list->n_elems++;
}


void ntg_list_push_guid( ntg_list *list, const GUID *guid )
{
	assert( list && guid );

	GUID *guids = new GUID[ list->n_elems + 1 ];
	memcpy( guids, list->elems, list->n_elems * sizeof( GUID ) );
	guids[ list->n_elems ] = *guid;

	delete[] list->elems;
	list->elems = guids;
    list->n_elems++;
}


