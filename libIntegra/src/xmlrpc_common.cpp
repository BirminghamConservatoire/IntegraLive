#include "platform_specifics.h"

#include <assert.h>
#include <xmlrpc-c/base.h>
#include "path.h"
#include "value.h"
#include "trace.h"


using ntg_api::CPath;



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


xmlrpc_value *ntg_xmlrpc_value_new(const ntg_value *value, xmlrpc_env *env)
{
	if( value )
	{
	    switch( ntg_value_get_type(value)) 
		{
			case NTG_INTEGER:
				return xmlrpc_int_new(env, ntg_value_get_int(value));
			case NTG_FLOAT:
				return xmlrpc_double_new(env, ntg_value_get_float(value));
			case NTG_STRING:
				return xmlrpc_string_new(env, ntg_value_get_string(value));
			default:
				NTG_TRACE_ERROR( "invalid value type" );
				return NULL;
		}
	}
	else
	{
		return xmlrpc_nil_new(env);
	}
}

ntg_value *ntg_xmlrpc_get_value (xmlrpc_env *env, xmlrpc_value *value_xmlrpc)
{
    ntg_value *value = NULL;
    int value_i;
    double value_d;
    float value_f;
    char *value_s          = NULL;
	xmlrpc_type value_type;

    assert(value_xmlrpc != NULL);

    value_type = xmlrpc_value_type(value_xmlrpc);

    switch (value_type) {
        case XMLRPC_TYPE_INT:
            xmlrpc_read_int(env, value_xmlrpc, &value_i);
            value = ntg_value_new(NTG_INTEGER, &value_i);
            break;

        case XMLRPC_TYPE_DOUBLE:
            xmlrpc_read_double(env, value_xmlrpc, &value_d);
            value_f = (float)value_d;
            value = ntg_value_new(NTG_FLOAT, &value_f);
            break;

        case XMLRPC_TYPE_STRING:
            xmlrpc_read_string(env, value_xmlrpc, (const char **)&value_s);
            value = ntg_value_new(NTG_STRING, value_s);
            free(value_s);
            break;

        case XMLRPC_TYPE_NIL:
            value = NULL;
            break;
        default:
            NTG_TRACE_ERROR_WITH_INT("unhandled xmlrpc value type", value_type);
            break;
    }

    return value;

}

