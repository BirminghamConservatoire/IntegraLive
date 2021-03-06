/** IntegraServer - console app to expose xmlrpc interface to libIntegra
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


#ifdef _WINDOWS
#pragma warning(disable : 4251)		//disable warnings about exported classes which use stl
#endif


#include <assert.h>
#include <xmlrpc-c/base.h>
#include "path.h"
#include "value.h"
#include "trace.h"


using namespace integra_api;



xmlrpc_value *ntg_xmlrpc_value_from_path( const CPath &path, xmlrpc_env *env)
{
    xmlrpc_value *xmlrpc_path, *path_item;

    xmlrpc_path = xmlrpc_array_new(env);

	for( int n = 0; n < path.get_number_of_elements(); n++) 
	{
        path_item = xmlrpc_string_new(env, path[n].c_str() );
        xmlrpc_array_append_item( env, xmlrpc_path, path_item );
        xmlrpc_DECREF(path_item);
    }

    return xmlrpc_path;
}


xmlrpc_value *ntg_xmlrpc_value_new( const CValue &value, xmlrpc_env *env )
{
	switch( value.get_type() ) 
	{
		case CValue::INTEGER:
			return xmlrpc_int_new( env, value );

		case CValue::FLOAT:
			return xmlrpc_double_new( env, value );

		case CValue::STRING:
			return xmlrpc_string_new(env, string( value ).c_str() );

		default:
			INTEGRA_TRACE_ERROR << "invalid value type";
			return NULL;
	}
}


CValue *ntg_xmlrpc_get_value( xmlrpc_env *env, xmlrpc_value *value_xmlrpc )
{
    int value_i;
    double value_d;
    float value_f;
    char *value_s;
	CValue *value = NULL;

    assert( env && value_xmlrpc );

    xmlrpc_type  value_type = xmlrpc_value_type( value_xmlrpc );

    switch (value_type) {
        case XMLRPC_TYPE_INT:
            xmlrpc_read_int(env, value_xmlrpc, &value_i);
            value = new CIntegerValue( value_i );
			break;

        case XMLRPC_TYPE_DOUBLE:
            xmlrpc_read_double(env, value_xmlrpc, &value_d);
            value_f = (float)value_d;
			value = new CFloatValue( value_f );
            break;

        case XMLRPC_TYPE_STRING:
            xmlrpc_read_string(env, value_xmlrpc, (const char **)&value_s);
			value = new CStringValue( value_s);
            free(value_s);
            break;

        case XMLRPC_TYPE_NIL:
            break;

        default:
            INTEGRA_TRACE_ERROR << "unhandled xmlrpc value type" << value_type;
            break;
    }

    return value;
}

