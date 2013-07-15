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

#ifndef INTEGRA_LIST_PRIVATE_H
#define INTEGRA_LIST_PRIVATE_H

namespace ntg_api
{
	class CPath;
}


typedef enum ntg_list_type_ {
    NTG_LIST_NODES,
	NTG_LIST_GUIDS
} ntg_list_type;

struct ntg_list_ {
    ntg_list_type type;
    void *elems;
    unsigned long n_elems;
};

#include "Integra/integra.h"

ntg_list *ntg_list_new(ntg_list_type);
void ntg_list_free(ntg_list *);

void ntg_list_push_node( ntg_list *list, const ntg_api::CPath &path );
void ntg_list_push_guid( ntg_list *list, const GUID *guid );


#endif

