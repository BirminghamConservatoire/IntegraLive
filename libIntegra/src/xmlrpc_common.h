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
_resolve * USA.
 */

#ifndef NTG_XMLRPC_COMMON_PRIVATE_H
#define NTG_XMLRPC_COMMON_PRIVATE_H

#include <xmlrpc-c/base.h>


xmlrpc_value *ntg_xmlrpc_value_new( const ntg_api::CValue &value, xmlrpc_env *env );
xmlrpc_value *ntg_xmlrpc_value_from_path( const ntg_api::CPath &path, xmlrpc_env *env );
ntg_api::CValue *ntg_xmlrpc_get_value( xmlrpc_env *env, xmlrpc_value *value_xmlrpc );


#endif

