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

#ifndef INTEGRA_HASHTABLE_PRIVATE_H
#define INTEGRA_HASHTABLE_PRIVATE_H

#ifdef __cplusplus
extern "C" {
#endif

#include "../externals/guiddef.h"

#define NTG_HASHTABLE struct ntg_hash_node_ *

NTG_HASHTABLE *ntg_hashtable_new();
void ntg_hashtable_free( NTG_HASHTABLE *hashtable);

void ntg_hashtable_add_string_key( NTG_HASHTABLE *hashtable, const char *key, const void *value );
void ntg_hashtable_add_guid_key( NTG_HASHTABLE *hashtable, const GUID *key, const void *value );

void ntg_hashtable_remove_string_key( NTG_HASHTABLE *hashtable, const char *key );
void ntg_hashtable_remove_guid_key( NTG_HASHTABLE *hashtable, const GUID *key );

const void *ntg_hashtable_lookup_string( NTG_HASHTABLE *hashtable, const char *key );
const void *ntg_hashtable_lookup_guid( NTG_HASHTABLE *hashtable, const GUID *key );


#ifdef __cplusplus
}
#endif

#endif
