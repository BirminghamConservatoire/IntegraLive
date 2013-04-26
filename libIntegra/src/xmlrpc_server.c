/** libIntegra multimedia module interface
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


#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <pthread.h>

#ifdef _WINDOWS
#include <winsock2.h>
#endif

#include <xmlrpc-c/base.h>
#include <xmlrpc-c/abyss.h>
#include <xmlrpc-c/server.h>
#include <xmlrpc-c/server_abyss.h>


#include "server.h"
#include "memory.h"
#include "value.h"
#include "path.h"
#include "globals.h"
#include "command.h"
#include "node.h"
#include "server_commands.h"
#include "xmlrpc_common.h"
#include "module_manager.h"
#include "interface.h"

#include "attribute.h"
#include "helper.h"
#include "list.h"

#define HELPSTR_VERSION "Return the current version of libIntegra\n\\return {'response':'system.version', 'version':<string>\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n"

#define HELPSTR_PRINTSTATE "Dump the entire node and attribute state to stdout for testing purposes\n\\return {'response':'system.printstate'\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n"

#define HELPSTR_INTERFACELIST "Return a list of ids of interfaces available for instantiation on the server\n\\return {'response':'query.interfacelist', 'interfacelist':<array>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n"

#define HELPSTR_INTERFACEINFO "Return interface info for a specified interface\n\\return {'response':'query.interfaceinfo', 'interfaceinfo':<struct>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n"

#define HELPSTR_ENDPOINTS "Return endpoints for a specified interface\n\\return {'response':'query.endpoints', 'endpoints':<array>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n"

#define HELPSTR_WIDGETS "Return widgets for a specified interface\n\\return {'response':'query.widgets', 'widgets':<array>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}}\n"

#define HELPSTR_NODELIST "Return a list of nodes under the current node using depth-first recursion\n\\param <array path>\n\\return {'response':'query.nodelist', 'nodelist':[{classname:<string>, path:<array>}, {classname:<string>, path:<array>}, ... ]}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_GET "Get the value of an attribute\n\\param <array attribute path>\n\\return {'response':'query.get', 'path':<array>, 'value':<value>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_SET "Set the value of an attribute\n\\param <array attribute path>\n\\param <value value>\n\\return {'response':'command.set', 'path':<array>, 'value':<value>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_NEW "Create a new node on the server\n\\param <string class name>\n\\param <string node name>\n\\param <array parent path>\n\\return {'response':'command.new', 'classname':<string>, 'instancename':<string>, 'parentpath':<array>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_DELETE "Delete a node from the server\n\\param <array path>\\return {'response':'command.delete', 'path':<array>\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_RENAME "Rename a node on the server\n\\param <array path>\n\\param <string node name>\n\\return {'response':'command.rename', 'instancepath':<array path>, 'name':<string name>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_SAVE "Save all nodes including and below a given node on the server to a path on the filesystem\n\\param <array path>\n\\param <string file path>\n\\return {'response':'command.save', 'nodepath':<array path>, 'filepath':<string path>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_LOAD "Load all nodes including and below a given node from the filesystem beneath the path given to the given node on the server\n\\param <string file path>\n\\param <array path>\n\\return {'response':'command.load', 'filepath':<string path>', 'parentpath':<array path>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_MOVE "Move a node on the server\n\\param <array node path>\n\\param <array new node parent path>\n\\return {'response':'command.move', 'instancepath':<array path>, 'parentpath':<array path>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_UNLOAD_ORPHANED_EMBEDDED "Remove orphaned embedded modules\n\\return {'response':'module.unloadorphanedembedded'}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_INSTALL_INTEGRA_MODULE_FILE "Install 3rd party module from integra-module file\n\\param <string module file path>\n\\return {'response':'module.installintegramodulefile', moduleid:<string>, waspreviouslyembedded:<boolean>}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_INSTALL_EMBEDDED_MODULE "Install embedded module\n\\param <string module guid>\n\\return {'response':'module.installembeddedmodule'}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define HELPSTR_UNINSTALL_MODULE "Uninstall 3rd party module\n\\param <string module guid>\n\\return {'response':'module.uninstallmodule, remainsasembedded:<boolean>'}\n\\error {'response':'error', 'errorcode':<int>, 'errortext':<string>}\n"

#define RESPONSE_LABEL      "response"
#define NTG_NULL_STRING     "None"

/*define maximum size for incoming xmlrpc (default is 500Kb and can be exceeded by large requests)*/
#define NTG_XMLRPC_SIZE_LIMIT 1024 * 1000 * 1000

static TServer abyssServer;
typedef void *(* ntg_server_callback_va)(ntg_server *, int, va_list);

/* run server command -- blocking version
 * call this if you want a return value -- e.g. to XMLRPC interface */
void *ntg_server_do_va(ntg_server_callback_va callback, const int argc, ...)
{
    void *rv;
    va_list argv;

    ntg_lock_server();

    va_start(argv, argc);
    rv = callback(server_, argc, argv);
    va_end(argv);

    ntg_unlock_server();

    return rv;
}

static xmlrpc_value *ntg_xmlrpc_error(xmlrpc_env * env,
        ntg_error_code error_code)
{

    xmlrpc_value *struct_, *xmlrpc_temp;
    const char *error_text;

    struct_ = xmlrpc_struct_new(env);
    error_text = ntg_error_text(error_code);

    xmlrpc_temp = xmlrpc_string_new(env, "error");
    if(xmlrpc_temp) {
        xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
        xmlrpc_DECREF(xmlrpc_temp);
    } else {
        NTG_TRACE_ERROR("getting xmlrpc RESPONSE_LABEL");
    }

    xmlrpc_temp = xmlrpc_int_new(env, error_code);
    if(xmlrpc_temp) {
        xmlrpc_struct_set_value(env, struct_, "errorcode", xmlrpc_temp);
        xmlrpc_DECREF(xmlrpc_temp);
    } else {
        NTG_TRACE_ERROR("getting xmlrpc errorcode");
    }

    xmlrpc_temp = xmlrpc_string_new(env, error_text);
    if(xmlrpc_temp) {
        xmlrpc_struct_set_value(env, struct_, "errortext", xmlrpc_temp);
        xmlrpc_DECREF(xmlrpc_temp);
    } else {
        NTG_TRACE_ERROR("getting xmlrpc errortext");
    }
    return struct_;

}

static ntg_path *ntg_xmlrpc_get_path(xmlrpc_env * env,
        xmlrpc_value * xmlrpc_path)
{

    int n;
    char *elem;
    int n_elems = 0;
    ntg_path *path;
    xmlrpc_value *xmlrpc_elem;

    path = ntg_path_new();
    n_elems = xmlrpc_array_size(env, xmlrpc_path);

    for (n = 0; n < n_elems; n++) {
        xmlrpc_array_read_item(env, xmlrpc_path, n, &xmlrpc_elem);
        xmlrpc_read_string(env, xmlrpc_elem, (const char **)&elem);
        xmlrpc_DECREF(xmlrpc_elem);
        ntg_path_append_element(path, elem);
        assert(elem != NULL);
        free(elem);
    }

    return path;

}


static void *ntg_xmlrpc_interfacelist_callback(ntg_server * server,
        const int argc, va_list argv)
{
    const ntg_list *module_id_list;
	int number_of_modules, i;
	GUID *module_ids;
	char *module_id_string;
    xmlrpc_value *array_ = NULL,
                 *array_item = NULL, *xmlrpc_name = NULL, *struct_ = NULL;
    xmlrpc_env *env;

    env = va_arg(argv, xmlrpc_env *);

	module_id_list = ntg_module_id_list( server->module_manager );
    number_of_modules = module_id_list->n_elems;
    module_ids = (GUID *)module_id_list->elems;

    array_ = xmlrpc_array_new(env);
    for( i = 0; i < number_of_modules; i++ ) 
	{
		module_id_string = ntg_guid_to_string( &module_ids[ i ] );
        array_item = xmlrpc_string_new( env, module_id_string );
        xmlrpc_array_append_item(env, array_, array_item);
        xmlrpc_DECREF(array_item);
		ntg_free( module_id_string );
    }

    if (env->fault_occurred)
        return NULL;


    struct_ = xmlrpc_struct_new(env);
    xmlrpc_name = xmlrpc_string_new(env, "query.interfacelist");

    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_name);
    xmlrpc_struct_set_value(env, struct_, "interfacelist", array_);

    xmlrpc_DECREF(xmlrpc_name);
    xmlrpc_DECREF(array_);

    return struct_;
}


static void *ntg_xmlrpc_interfaceinfo_callback(ntg_server * server,
        const int argc, va_list argv)
{
	xmlrpc_value *info_struct = NULL, *xmlrpc_temp = NULL, *xmlrpc_array = NULL, *struct_ = NULL;
    xmlrpc_env *env;
    char *module_id_string;
	char *origin_id_string;
	char *date_string;
    const ntg_interface *interface;
	const ntg_interface_info *info;
	const ntg_tag *tag;
	GUID guid;

    env = va_arg(argv, xmlrpc_env *);
    module_id_string = va_arg(argv, char *);

    if (env->fault_occurred)
	{
        return NULL;
	}

	if( ntg_string_to_guid( module_id_string, &guid ) != NTG_NO_ERROR ) 
	{
	    free(module_id_string);
		return ntg_xmlrpc_error(env, NTG_ERROR);
	}

	interface = ntg_get_interface_by_module_id( server->module_manager, &guid );
    if( !interface )	
	{
	    free(module_id_string);
		return ntg_xmlrpc_error(env, NTG_ERROR);
	}

	info = interface->info;

    info_struct = xmlrpc_struct_new(env);
    struct_ = xmlrpc_struct_new(env);

    xmlrpc_temp = xmlrpc_string_new(env, info->name );
    xmlrpc_struct_set_value(env, info_struct, "name", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	xmlrpc_temp = xmlrpc_string_new(env, info->label );
    xmlrpc_struct_set_value(env, info_struct, "label", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	xmlrpc_temp = xmlrpc_string_new(env, info->description ? info->description : "" );
    xmlrpc_struct_set_value(env, info_struct, "description", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	xmlrpc_array = xmlrpc_array_new(env);
	for( tag = info->tag_list; tag; tag = tag->next )
	{
		xmlrpc_temp = xmlrpc_string_new(env, tag->tag );
		xmlrpc_array_append_item( env, xmlrpc_array, xmlrpc_temp );
		xmlrpc_DECREF(xmlrpc_temp);
	}
	xmlrpc_struct_set_value(env, info_struct, "tags", xmlrpc_array );
	xmlrpc_DECREF(xmlrpc_array);

	xmlrpc_temp = xmlrpc_int_new(env, info->implemented_in_libintegra ? 1 : 0 );
    xmlrpc_struct_set_value(env, info_struct, "implementedinlibintegra", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	xmlrpc_temp = xmlrpc_string_new(env, info->author ? info->author : "" );
	xmlrpc_struct_set_value(env, info_struct, "author", xmlrpc_temp);
	xmlrpc_DECREF(xmlrpc_temp);

	date_string = ntg_date_to_string( &info->created_date );
	xmlrpc_temp = xmlrpc_string_new(env, date_string );
	xmlrpc_struct_set_value(env, info_struct, "createddate", xmlrpc_temp);
	xmlrpc_DECREF(xmlrpc_temp);
	ntg_free( date_string );

	date_string = ntg_date_to_string( &info->modified_date );
	xmlrpc_temp = xmlrpc_string_new(env, date_string );
	xmlrpc_struct_set_value(env, info_struct, "modifieddate", xmlrpc_temp);
	xmlrpc_DECREF(xmlrpc_temp);
	ntg_free( date_string );

	/* now package the built struct... */

    xmlrpc_temp = xmlrpc_string_new(env, "query.interfaceinfo");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, module_id_string);
    xmlrpc_struct_set_value(env, struct_, "moduleid", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	origin_id_string = ntg_guid_to_string( &interface->origin_guid );
    xmlrpc_temp = xmlrpc_string_new(env, origin_id_string);
    xmlrpc_struct_set_value(env, struct_, "originid", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);
	ntg_free( origin_id_string );

	switch( interface->module_source )
	{
		case NTG_MODULE_SHIPPED_WITH_INTEGRA:
			xmlrpc_temp = xmlrpc_string_new(env, "shippedwithintegra" );
			break;

		case NTG_MODULE_3RD_PARTY:
			xmlrpc_temp = xmlrpc_string_new(env, "thirdparty" );
			break;

		case NTG_MODULE_EMBEDDED:
			xmlrpc_temp = xmlrpc_string_new(env, "embedded" );
			break;

		default:
			assert( false );
			break;
	}

	xmlrpc_struct_set_value(env, struct_, "modulesource", xmlrpc_temp);
	xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "interfaceinfo", info_struct);
    xmlrpc_DECREF(info_struct);

    /* free out-of-place memory */
    free(module_id_string);

    return struct_;
}


static void *ntg_xmlrpc_endpoints_callback(ntg_server * server,
        const int argc, va_list argv)
{
	xmlrpc_value *xmlrpc_temp = NULL, *endpoints_array = NULL, *xmlrpc_endpoint = NULL, *struct_ = NULL;
	xmlrpc_value *xmlrpc_control_info = NULL, *xmlrpc_state_info = NULL, *xmlrpc_stream_info = NULL;
	xmlrpc_value *xmlrpc_constraint, *xmlrpc_range, *xmlrpc_scale, *xmlrpc_scale_exponent_root, *xmlrpc_allowed_states, *xmlrpc_state_labels = NULL, *xmlrpc_state_label = NULL;
    xmlrpc_env *env;
    char *module_id_string;
	GUID guid;
    const ntg_interface *interface;
	const ntg_endpoint *endpoint;
	const ntg_control_info *control_info;
	const ntg_state_info *state_info;
	const ntg_allowed_state *allowed_state;
	const ntg_state_label *state_label;
	const ntg_stream_info *stream_info;

    env = va_arg(argv, xmlrpc_env *);
    module_id_string = va_arg(argv, char *);

    if (env->fault_occurred)
	{
        return NULL;
	}

	if( ntg_string_to_guid( module_id_string, &guid ) != NTG_NO_ERROR ) 
	{
	    free(module_id_string);
		return ntg_xmlrpc_error(env, NTG_ERROR);
	}

	interface = ntg_get_interface_by_module_id( server->module_manager, &guid );
    if( !interface )	
	{
	    free(module_id_string);
		return ntg_xmlrpc_error(env, NTG_ERROR);
	}

    endpoints_array = xmlrpc_array_new(env);
    struct_ = xmlrpc_struct_new(env);

	for( endpoint = interface->endpoint_list; endpoint; endpoint = endpoint->next )
	{
		xmlrpc_endpoint = xmlrpc_struct_new( env );

		xmlrpc_temp = xmlrpc_string_new( env, endpoint->name );
		xmlrpc_struct_set_value(env, xmlrpc_endpoint, "name", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_temp = xmlrpc_string_new(env, endpoint->label ? endpoint->label : endpoint->name );
		xmlrpc_struct_set_value(env, xmlrpc_endpoint, "label", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_temp = xmlrpc_string_new(env, endpoint->description ? endpoint->description : "" );
		xmlrpc_struct_set_value(env, xmlrpc_endpoint, "description", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		switch( endpoint->type )
		{
			case NTG_CONTROL:
				xmlrpc_temp = xmlrpc_string_new(env, "control" );
				break;

			case NTG_STREAM:
				xmlrpc_temp = xmlrpc_string_new(env, "stream" );
				break;

			default:
				assert( false );
				continue;
		}

		xmlrpc_struct_set_value(env, xmlrpc_endpoint, "type", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		if( endpoint->control_info )
		{
			control_info = endpoint->control_info;
			xmlrpc_control_info = xmlrpc_struct_new( env );

			switch( control_info->type )
			{
				case NTG_STATE:
					xmlrpc_temp = xmlrpc_string_new(env, "state" );
					break;

				case NTG_BANG:
					xmlrpc_temp = xmlrpc_string_new(env, "bang" );
					break;

				default:
					assert( false );
					continue;
			}
			xmlrpc_struct_set_value(env, xmlrpc_control_info, "type", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			if( control_info->state_info )
			{
				xmlrpc_state_info = xmlrpc_struct_new( env );
				state_info = control_info->state_info;

				switch( state_info->type )
				{
					case NTG_INTEGER:
						xmlrpc_temp = xmlrpc_string_new(env, "integer" );
						break;

					case NTG_FLOAT:
						xmlrpc_temp = xmlrpc_string_new(env, "float" );
						break;

					case NTG_STRING:
						xmlrpc_temp = xmlrpc_string_new(env, "string" );
						break;

					default:
						assert( false );
						continue;
				}

				xmlrpc_struct_set_value(env, xmlrpc_state_info, "type", xmlrpc_temp);
				xmlrpc_DECREF(xmlrpc_temp);
				
				xmlrpc_constraint = xmlrpc_struct_new( env );

				if( state_info->constraint.range )
				{
					xmlrpc_range = xmlrpc_struct_new( env );

					xmlrpc_temp = ntg_xmlrpc_value_new( state_info->constraint.range->minimum, env );
					xmlrpc_struct_set_value( env, xmlrpc_range, "minimum", xmlrpc_temp);
					xmlrpc_DECREF(xmlrpc_temp);

					xmlrpc_temp = ntg_xmlrpc_value_new( state_info->constraint.range->maximum, env );
					xmlrpc_struct_set_value( env, xmlrpc_range, "maximum", xmlrpc_temp);
					xmlrpc_DECREF(xmlrpc_temp);

					xmlrpc_struct_set_value(env, xmlrpc_constraint, "range", xmlrpc_range);
					xmlrpc_DECREF(xmlrpc_range);
				}

				if( state_info->constraint.allowed_states )
				{
					xmlrpc_allowed_states = xmlrpc_array_new( env );

					for( allowed_state = state_info->constraint.allowed_states; allowed_state; allowed_state = allowed_state->next )
					{
						xmlrpc_temp = ntg_xmlrpc_value_new( allowed_state->value, env );
						xmlrpc_array_append_item( env, xmlrpc_allowed_states, xmlrpc_temp );
						xmlrpc_DECREF(xmlrpc_temp);
					}

					xmlrpc_struct_set_value(env, xmlrpc_constraint, "allowedstates", xmlrpc_allowed_states);
					xmlrpc_DECREF( xmlrpc_allowed_states );
				}

				xmlrpc_struct_set_value(env, xmlrpc_state_info, "constraint", xmlrpc_constraint );
				xmlrpc_DECREF(xmlrpc_constraint);

				if( !state_info->default_value || state_info->default_value->type != state_info->type )
				{
					ntg_value *morph;
					morph = ntg_value_new( state_info->type, NULL );
					
					NTG_TRACE_ERROR_WITH_STRING( "default value missing or of incorrect type", endpoint->name );
					xmlrpc_temp = ntg_xmlrpc_value_new( morph, env );
					ntg_value_free( morph );
				}
				else
				{
					xmlrpc_temp = ntg_xmlrpc_value_new( state_info->default_value, env );
				}
				xmlrpc_struct_set_value( env, xmlrpc_state_info, "defaultvalue", xmlrpc_temp );
				xmlrpc_DECREF(xmlrpc_temp);

				if( state_info->scale )
				{
					xmlrpc_scale = xmlrpc_struct_new( env );

					switch( state_info->scale->scale_type )
					{
						case NTG_LINEAR:
							xmlrpc_temp = xmlrpc_string_new(env, "linear" );
							xmlrpc_scale_exponent_root = NULL;
							break;

						case NTG_EXPONENTIAL:
							xmlrpc_temp = xmlrpc_string_new(env, "exponential" );
							xmlrpc_scale_exponent_root = xmlrpc_int_new( env, state_info->scale->exponent_root );
							break;

						case NTG_DECIBEL:
							xmlrpc_temp = xmlrpc_string_new(env, "decibel" );
							xmlrpc_scale_exponent_root = NULL;
							break;

						default:
							assert( false );
							continue;
					}

					xmlrpc_struct_set_value( env, xmlrpc_scale, "type", xmlrpc_temp );
					xmlrpc_DECREF( xmlrpc_temp );

					if( xmlrpc_scale_exponent_root )
					{
						xmlrpc_struct_set_value( env, xmlrpc_scale, "base", xmlrpc_scale_exponent_root );
						xmlrpc_DECREF( xmlrpc_scale_exponent_root );
					}

					xmlrpc_struct_set_value( env, xmlrpc_state_info, "scale", xmlrpc_scale );
				}

				xmlrpc_state_labels = xmlrpc_array_new( env );
				for( state_label = state_info->state_labels; state_label; state_label = state_label->next )
				{
					xmlrpc_state_label = xmlrpc_struct_new( env );

					xmlrpc_temp = ntg_xmlrpc_value_new( state_label->value, env );
					xmlrpc_struct_set_value( env, xmlrpc_state_label, "value", xmlrpc_temp );
					xmlrpc_DECREF(xmlrpc_temp);

					xmlrpc_temp = xmlrpc_string_new( env, state_label->text );
					xmlrpc_struct_set_value( env, xmlrpc_state_label, "text", xmlrpc_temp );
					xmlrpc_DECREF(xmlrpc_temp);

					xmlrpc_array_append_item( env, xmlrpc_state_labels, xmlrpc_state_label );
					xmlrpc_DECREF(xmlrpc_state_label);
				}

				xmlrpc_struct_set_value( env, xmlrpc_state_info, "statelabels", xmlrpc_state_labels );
				xmlrpc_DECREF(xmlrpc_state_labels);

				xmlrpc_temp = xmlrpc_int_new( env, state_info->is_input_file ? 1 : 0 );
				xmlrpc_struct_set_value( env, xmlrpc_state_info, "isinputfile", xmlrpc_temp );
				xmlrpc_DECREF(xmlrpc_temp);

				xmlrpc_temp = xmlrpc_int_new( env, state_info->is_saved_to_file ? 1 : 0 );
				xmlrpc_struct_set_value( env, xmlrpc_state_info, "issavedtofile", xmlrpc_temp );
				xmlrpc_DECREF(xmlrpc_temp);

				/* store built state info struct */
				xmlrpc_struct_set_value(env, xmlrpc_control_info, "stateinfo", xmlrpc_state_info);
				xmlrpc_DECREF(xmlrpc_state_info);
			}

			xmlrpc_temp = xmlrpc_int_new( env, endpoint->control_info->can_be_source ? 1 : 0 );
			xmlrpc_struct_set_value(env, xmlrpc_control_info, "canbesource", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			xmlrpc_temp = xmlrpc_int_new( env, endpoint->control_info->can_be_target ? 1 : 0 );
			xmlrpc_struct_set_value(env, xmlrpc_control_info, "canbetarget", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			xmlrpc_temp = xmlrpc_int_new( env, endpoint->control_info->is_sent_to_host ? 1 : 0 );
			xmlrpc_struct_set_value(env, xmlrpc_control_info, "issenttohost", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			/* store built control info struct */
			xmlrpc_struct_set_value(env, xmlrpc_endpoint, "controlinfo", xmlrpc_control_info);
			xmlrpc_DECREF(xmlrpc_control_info);
		}

		if( endpoint->stream_info )
		{
			xmlrpc_stream_info = xmlrpc_struct_new( env );
			stream_info = endpoint->stream_info;

			switch( stream_info->type )
			{
				case NTG_AUDIO_STREAM:
					xmlrpc_temp = xmlrpc_string_new(env, "audio" );
					break;

				default:
					assert( false );
					continue;
			}

			xmlrpc_struct_set_value(env, xmlrpc_stream_info, "type", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			switch( stream_info->direction )
			{
				case NTG_STREAM_INPUT:
					xmlrpc_temp = xmlrpc_string_new(env, "input" );
					break;

				case NTG_STREAM_OUTPUT:
					xmlrpc_temp = xmlrpc_string_new(env, "output" );
					break;

				default:
					assert( false );
					continue;
			}

			xmlrpc_struct_set_value(env, xmlrpc_stream_info, "direction", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			/* store built stream info struct */
			xmlrpc_struct_set_value(env, xmlrpc_endpoint, "streaminfo", xmlrpc_stream_info);
			xmlrpc_DECREF(xmlrpc_stream_info);
		}

		xmlrpc_array_append_item( env, endpoints_array, xmlrpc_endpoint );
		xmlrpc_DECREF(xmlrpc_endpoint);
	}

	/* now package the built struct... */

    xmlrpc_temp = xmlrpc_string_new(env, "query.endpoints");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, module_id_string);
    xmlrpc_struct_set_value(env, struct_, "moduleid", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "endpoints", endpoints_array);
    xmlrpc_DECREF(endpoints_array);

    /* free out-of-place memory */
    free(module_id_string);

	return struct_;
}


static void *ntg_xmlrpc_widgets_callback(ntg_server * server,
        const int argc, va_list argv)
{
	xmlrpc_value *xmlrpc_temp = NULL, *widgets_array = NULL, *xmlrpc_widget, *xmlrpc_position, *struct_ = NULL;
	xmlrpc_value *xmlrpc_mapping_list, *xmlrpc_mapping;
    xmlrpc_env *env;
    char *module_id_string;
    const ntg_interface *interface;
	const ntg_widget *widget;
	const ntg_widget_attribute_mapping *attribute_mapping;
	GUID guid;

    env = va_arg(argv, xmlrpc_env *);
    module_id_string = va_arg(argv, char *);

    if (env->fault_occurred)
	{
        return NULL;
	}

	if( ntg_string_to_guid( module_id_string, &guid ) != NTG_NO_ERROR ) 
	{
	    free(module_id_string);
		return ntg_xmlrpc_error(env, NTG_ERROR);
	}

	interface = ntg_get_interface_by_module_id( server->module_manager, &guid );
    if( !interface )	
	{
	    free(module_id_string);
		return ntg_xmlrpc_error(env, NTG_ERROR);
	}

    struct_ = xmlrpc_struct_new( env );

	widgets_array = xmlrpc_array_new( env );
	
	for( widget = interface->widget_list; widget; widget = widget->next )
	{
		xmlrpc_widget = xmlrpc_struct_new( env );

		xmlrpc_temp = xmlrpc_string_new( env, widget->type );
		xmlrpc_struct_set_value(env, xmlrpc_widget, "type", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_temp = xmlrpc_string_new( env, widget->label );
		xmlrpc_struct_set_value(env, xmlrpc_widget, "label", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_position = xmlrpc_struct_new( env );

		xmlrpc_temp = xmlrpc_double_new( env, widget->position.x );
		xmlrpc_struct_set_value(env, xmlrpc_position, "x", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_temp = xmlrpc_double_new( env, widget->position.y );
		xmlrpc_struct_set_value(env, xmlrpc_position, "y", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_temp = xmlrpc_double_new( env, widget->position.width );
		xmlrpc_struct_set_value(env, xmlrpc_position, "width", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_temp = xmlrpc_double_new( env, widget->position.height );
		xmlrpc_struct_set_value(env, xmlrpc_position, "height", xmlrpc_temp);
		xmlrpc_DECREF(xmlrpc_temp);

		xmlrpc_struct_set_value(env, xmlrpc_widget, "position", xmlrpc_position);
		xmlrpc_DECREF(xmlrpc_position);

		xmlrpc_mapping_list = xmlrpc_array_new( env );
		for( attribute_mapping = widget->mapping_list; attribute_mapping; attribute_mapping = attribute_mapping->next )
		{
			xmlrpc_mapping = xmlrpc_struct_new( env );

			xmlrpc_temp = xmlrpc_string_new( env, attribute_mapping->widget_attribute );
			xmlrpc_struct_set_value(env, xmlrpc_mapping, "widgetattribute", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			xmlrpc_temp = xmlrpc_string_new( env, attribute_mapping->endpoint );
			xmlrpc_struct_set_value(env, xmlrpc_mapping, "endpoint", xmlrpc_temp);
			xmlrpc_DECREF(xmlrpc_temp);

			xmlrpc_array_append_item( env, xmlrpc_mapping_list, xmlrpc_mapping );
			xmlrpc_DECREF( xmlrpc_mapping );
		}

		xmlrpc_struct_set_value(env, xmlrpc_widget, "mapping", xmlrpc_mapping_list);
		xmlrpc_DECREF( xmlrpc_mapping_list );

		xmlrpc_array_append_item( env, widgets_array, xmlrpc_widget );
		xmlrpc_DECREF( xmlrpc_widget );
	}

	/* now package the built struct... */

    xmlrpc_temp = xmlrpc_string_new(env, "query.widgets");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, module_id_string);
    xmlrpc_struct_set_value(env, struct_, "moduleid", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "widgets", widgets_array);
    xmlrpc_DECREF(widgets_array);

    /* free out-of-place memory */
    free(module_id_string);

    return struct_;
}


static void *ntg_xmlrpc_nodelist_callback(ntg_server * server,
        const int argc, va_list argv)
{

    xmlrpc_env *env;
    xmlrpc_value *xmlrpc_nodes = NULL,
                 *xmlrpc_path = NULL,
                 *xmlrpc_elem = NULL,
                 *xmlrpc_guid = NULL,
                 *xmlrpc_temp = NULL, *struct_ = NULL, *node_struct = NULL;
    ntg_list *nodelist = NULL;
    ntg_path *path     = NULL;
    ntg_node *node = NULL;
    ntg_node *root = NULL;
    int n, m;
    char *module_id_string = NULL;

    env = va_arg(argv, xmlrpc_env *);
    path = va_arg(argv, ntg_path *);

    xmlrpc_nodes = xmlrpc_array_new(env);
    struct_ = xmlrpc_struct_new(env);

    nodelist = ntg_nodelist_(server, path);

    if (nodelist == NULL) {
        return ntg_xmlrpc_error(env, NTG_FAILED);
    }

    /* each node is a ntg_path */

    for (n = 0; n < nodelist->n_elems; n++) {

        xmlrpc_path = xmlrpc_array_new(env);
        path = ((ntg_path **)nodelist->elems)[n];

        for (m = 0; m < path->n_elems; m++) {

            xmlrpc_elem = xmlrpc_string_new(env, path->elems[m]);

            xmlrpc_array_append_item(env, xmlrpc_path, xmlrpc_elem);
            xmlrpc_DECREF(xmlrpc_elem);

        }

        /* get the class id */
        root = ntg_server_get_root(server);
        /* FIX */
        node = ntg_node_find_by_path(path, root);
        if (node == NULL) {
            node =
                ntg_node_find_by_name_r(root, path->elems[path->n_elems - 1]);
        }
        if (node == NULL) {
            NTG_TRACE_ERROR("path not found: " );
            for (n = 0; n < path->n_elems; n++) {
                NTG_TRACE_ERROR(path->elems[n] );
            }
            return ntg_xmlrpc_error(env, NTG_FAILED);
        }

		module_id_string = ntg_guid_to_string( &node->interface->module_guid );

        /* construct the node struct and append to nodes array */
        node_struct = xmlrpc_struct_new(env);
        xmlrpc_guid = xmlrpc_string_new(env, module_id_string);
        xmlrpc_struct_set_value(env, node_struct, "guid", xmlrpc_guid);
        xmlrpc_DECREF(xmlrpc_guid);
        xmlrpc_struct_set_value(env, node_struct, "path", xmlrpc_path);
        xmlrpc_DECREF(xmlrpc_path);
        xmlrpc_array_append_item(env, xmlrpc_nodes, node_struct);
        xmlrpc_DECREF(node_struct);

        /* free out-of-place memory */
		ntg_free(module_id_string);

    }

    xmlrpc_temp = xmlrpc_string_new(env, "query.nodelist");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "nodelist", xmlrpc_nodes);
    xmlrpc_DECREF(xmlrpc_nodes);

    /* free out-of-place memory */
    ntg_list_free(nodelist);

    return struct_;

}

static void *ntg_xmlrpc_version_callback(ntg_server * server,
        const int argc, va_list argv)
{
    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;
    char version[ NTG_LONG_STRLEN ];

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);

    ntg_version(version, NTG_LONG_STRLEN);

    xmlrpc_temp = xmlrpc_string_new(env, "system.version");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, version);
    xmlrpc_struct_set_value(env, struct_, "version", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    return struct_;
}


static void *ntg_xmlrpc_print_state_callback(ntg_server * server,
        const int argc, va_list argv)
{
    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);

    ntg_print_state_();

    xmlrpc_temp = xmlrpc_string_new(env, "system.printstate");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    return struct_;
}


static void *ntg_xmlrpc_delete_callback(ntg_server * server, const int argc,
        va_list argv)
{


    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL, *xmlrpc_path = NULL;
    ntg_command_status command_status;
    ntg_error_code error_code;
    ntg_path *path;

    env = va_arg(argv, xmlrpc_env *);
    path = va_arg(argv, ntg_path *);

    struct_ = xmlrpc_struct_new(env);
    command_status = ntg_delete_(server, NTG_SOURCE_XMLRPC_API, path);
    error_code = command_status.error_code;

    if (error_code != NTG_NO_ERROR) {
        return ntg_xmlrpc_error(env, error_code);
    }

    xmlrpc_path = ntg_xmlrpc_value_from_path(path, env);

    xmlrpc_temp = xmlrpc_string_new(env, "command.delete");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "path", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);

    return struct_;

}

static void *ntg_xmlrpc_rename_callback(ntg_server * server, const int argc,
        va_list argv)
{

    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL, *xmlrpc_path = NULL;
    ntg_error_code error_code;
    ntg_command_status command_status;
    ntg_path *path;
    char *name;

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);
    path = va_arg(argv, ntg_path *);
    name = va_arg(argv, char *);

    command_status = ntg_rename_(server, NTG_SOURCE_XMLRPC_API, path, name);
    error_code = command_status.error_code;

    if (error_code != NTG_NO_ERROR) {
        return ntg_xmlrpc_error(env, error_code);
    }

    xmlrpc_path = ntg_xmlrpc_value_from_path(path, env);

    xmlrpc_temp = xmlrpc_string_new(env, "command.rename");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "instancepath", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);

    xmlrpc_temp = xmlrpc_string_new(env, name);
    xmlrpc_struct_set_value(env, struct_, "name", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    return struct_;

}

static void *ntg_xmlrpc_save_callback(ntg_server * server, const int argc,
        va_list argv)
{

    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL, *xmlrpc_path = NULL;
    ntg_error_code error_code;
    ntg_command_status command_status;
    ntg_path *path;
    char *file_path;

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);
    path = va_arg(argv, ntg_path *);
    file_path = va_arg(argv, char *);

    command_status = ntg_save_(server, path, file_path);
    error_code = command_status.error_code;

    if (error_code != NTG_NO_ERROR) {
        return ntg_xmlrpc_error(env, error_code);
    }

    xmlrpc_temp = xmlrpc_string_new(env, "command.save");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_path = ntg_xmlrpc_value_from_path(path, env);
    xmlrpc_struct_set_value(env, struct_, "instancepath", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);

    xmlrpc_temp = xmlrpc_string_new(env, file_path);
    xmlrpc_struct_set_value(env, struct_, "filepath", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    return struct_;

}

static void *ntg_xmlrpc_load_callback(ntg_server * server, const int argc,
        va_list argv)
{
    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL, *xmlrpc_path = NULL, *xmlrpc_array = NULL;
    ntg_error_code error_code;
    ntg_command_status command_status;
    ntg_path *path;
    char *file_path;
	ntg_list *embedded_module_ids;
	GUID *guids;
	int i;
	char *module_id_string;

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);
    file_path = va_arg(argv, char *);
    path = va_arg(argv, ntg_path *);

    command_status = ntg_load_(server, NTG_SOURCE_XMLRPC_API, file_path, path);
    error_code = command_status.error_code;

    if (error_code != NTG_NO_ERROR) {
        return ntg_xmlrpc_error(env, error_code);
    }


    xmlrpc_temp = xmlrpc_string_new(env, "command.load");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, file_path);
    xmlrpc_struct_set_value(env, struct_, "filepath", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_path = ntg_xmlrpc_value_from_path(path, env);
    xmlrpc_struct_set_value(env, struct_, "parentpath", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);


	embedded_module_ids = ( ntg_list * ) command_status.data;
    guids = ( GUID * ) embedded_module_ids->elems;

	xmlrpc_array = xmlrpc_array_new( env );
	for( i = 0; i < embedded_module_ids->n_elems; i++ ) 
	{
		module_id_string = ntg_guid_to_string( &guids[ i ] );
        xmlrpc_temp = xmlrpc_string_new( env, module_id_string );
        xmlrpc_array_append_item( env, xmlrpc_array, xmlrpc_temp);
        xmlrpc_DECREF( xmlrpc_temp );
		ntg_free( module_id_string );
    }

    xmlrpc_struct_set_value(env, struct_, "embeddedmodules", xmlrpc_array );

    xmlrpc_DECREF(xmlrpc_array);

	ntg_free( embedded_module_ids );

    return struct_;
}


static void *ntg_xmlrpc_move_callback(ntg_server * server, const int argc,
        va_list argv)
{

    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL,
                 *xmlrpc_node_path = NULL,
                 *xmlrpc_temp = NULL, *xmlrpc_parent_path = NULL;
    ntg_error_code error_code;
    ntg_command_status command_status;
    ntg_path *node_path, *parent_path;

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);
    node_path = va_arg(argv, ntg_path *);
    parent_path = va_arg(argv, ntg_path *);

    command_status = ntg_move_(server, NTG_SOURCE_XMLRPC_API, node_path,
            parent_path);
    error_code = command_status.error_code;

    if (error_code != NTG_NO_ERROR) {
        return ntg_xmlrpc_error(env, error_code);
    }

    xmlrpc_node_path = ntg_xmlrpc_value_from_path(node_path, env);
    xmlrpc_parent_path = ntg_xmlrpc_value_from_path(parent_path, env);

    xmlrpc_temp = xmlrpc_string_new(env, "command.move");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "instancepath", xmlrpc_node_path);
    xmlrpc_DECREF(xmlrpc_node_path);

    xmlrpc_struct_set_value(env, struct_, "parentpath", xmlrpc_parent_path);
    xmlrpc_DECREF(xmlrpc_parent_path);

    return struct_;

}


static void *ntg_xmlrpc_unload_orphaned_embedded_callback( ntg_server * server, const int argc,
        va_list argv)
{
    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;
    ntg_error_code error_code;
    ntg_command_status command_status;

    env = va_arg(argv, xmlrpc_env *);

    struct_ = xmlrpc_struct_new(env);

	command_status = ntg_unload_orphaned_embedded_modules_(server, NTG_SOURCE_XMLRPC_API);
    error_code = command_status.error_code;

    if (error_code != NTG_NO_ERROR) {
        return ntg_xmlrpc_error(env, error_code);
    }

    xmlrpc_temp = xmlrpc_string_new(env, "module.unloadorphanedembedded");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    return struct_;
}


static void *ntg_xmlrpc_install_module_callback( ntg_server * server, const int argc, va_list argv)
{
    char *file_path;
    char *module_id_string;
    ntg_command_status command_status;
    xmlrpc_env *env;
	ntg_module_install_result *result;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;

	assert( server );

    env = va_arg( argv, xmlrpc_env * );
    file_path = va_arg( argv, char * );

    struct_ = xmlrpc_struct_new(env);
    command_status = ntg_install_module_( server, NTG_SOURCE_XMLRPC_API, file_path );

	if( command_status.error_code != NTG_NO_ERROR )
	{
        free( file_path );
		return ntg_xmlrpc_error( env, command_status.error_code);
	}

	result = ( ntg_module_install_result * ) command_status.data;
	assert( result );

	module_id_string = ntg_guid_to_string( &result->module_id );

    xmlrpc_temp = xmlrpc_string_new(env, "module.installintegramodulefile");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, module_id_string );
    xmlrpc_struct_set_value(env, struct_, "moduleid", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	xmlrpc_temp = xmlrpc_bool_new(env, result->was_previously_embedded );
    xmlrpc_struct_set_value(env, struct_, "waspreviouslyembedded", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    /* free out-of-place memory */
	ntg_free( module_id_string );
	ntg_free( result );
    free( file_path );

    return struct_;
}


static void *ntg_xmlrpc_install_embedded_module_callback( ntg_server * server, const int argc, va_list argv)
{
    char *module_id_string;
	GUID module_id;
    ntg_command_status command_status;
    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;

	assert( server );

    env = va_arg( argv, xmlrpc_env * );
    module_id_string = va_arg( argv, char * );

	if( ntg_string_to_guid( module_id_string, &module_id ) != NTG_NO_ERROR )
	{
        free( module_id_string );
		return ntg_xmlrpc_error( env, NTG_ERROR );
	}

    free( module_id_string );

    command_status = ntg_install_embedded_module_( server, NTG_SOURCE_XMLRPC_API, &module_id );

	if( command_status.error_code != NTG_NO_ERROR )
	{
		return ntg_xmlrpc_error( env, command_status.error_code);
	}

    struct_ = xmlrpc_struct_new(env);
    xmlrpc_temp = xmlrpc_string_new(env, "module.installembeddedmodule");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    return struct_;
}


static void *ntg_xmlrpc_uninstall_module_callback( ntg_server * server, const int argc, va_list argv )
{
    char *module_id_string;
	GUID module_id;
    ntg_command_status command_status;
    xmlrpc_env *env;
	ntg_module_uninstall_result *result;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;

	assert( server );

    env = va_arg( argv, xmlrpc_env * );
    module_id_string = va_arg( argv, char * );

	if( ntg_string_to_guid( module_id_string, &module_id ) != NTG_NO_ERROR )
	{
        free( module_id_string );
		return ntg_xmlrpc_error( env, NTG_ERROR );
	}

    free( module_id_string );

    command_status = ntg_uninstall_module_( server, NTG_SOURCE_XMLRPC_API, &module_id );

	if( command_status.error_code != NTG_NO_ERROR )
	{
		return ntg_xmlrpc_error( env, command_status.error_code);
	}

	result = ( ntg_module_uninstall_result * ) command_status.data;

    struct_ = xmlrpc_struct_new(env);
    xmlrpc_temp = xmlrpc_string_new(env, "module.uninstallmodule");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

	xmlrpc_temp = xmlrpc_bool_new( env, result->remains_as_embedded );
    xmlrpc_struct_set_value( env, struct_, "remainsasembedded", xmlrpc_temp );
    xmlrpc_DECREF( xmlrpc_temp );

	/* free out-of-place memory */
	ntg_free( result );

    return struct_;
}


static void *ntg_xmlrpc_new_callback(ntg_server * server, const int argc,
        va_list argv)
{

    char *module_id_string, *node_name;
	GUID module_id;
    ntg_path *path;
    ntg_command_status command_status;
    ntg_node *node;
    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL, *xmlrpc_path = NULL;

    env = va_arg(argv, xmlrpc_env *);
    module_id_string = va_arg(argv, char *);
    node_name = va_arg(argv, char *);
    path = va_arg(argv, ntg_path *);

    assert(path->string != NULL);

	ntg_string_to_guid( module_id_string, &module_id );

    struct_ = xmlrpc_struct_new(env);
    command_status = ntg_new_(server, NTG_SOURCE_XMLRPC_API, &module_id, node_name, path);

    node = command_status.data;

    if (node == NULL) {
        /* free out-of-place memory */
        ntg_path_free(path);
        free(module_id_string);
        free(node_name);
        return ntg_xmlrpc_error(env, NTG_ERROR);
    }

    xmlrpc_temp = xmlrpc_string_new(env, "command.new");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, module_id_string);
    xmlrpc_struct_set_value(env, struct_, "moduleid", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_temp = xmlrpc_string_new(env, node->name);
    xmlrpc_struct_set_value(env, struct_, "instancename", xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_path = ntg_xmlrpc_value_from_path(path, env);
    xmlrpc_struct_set_value(env, struct_, "path", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);


    /* free out-of-place memory */
    ntg_path_free(path);
    free(module_id_string);
    free(node_name);


    return struct_;
}

static xmlrpc_value *ntg_xmlrpc_return_set(xmlrpc_env *env, 
        xmlrpc_value *xmlrpc_path,
        xmlrpc_value *value_xmlrpc)
{

    xmlrpc_value *struct_ = NULL, *xmlrpc_temp = NULL;

    struct_ = xmlrpc_struct_new(env);

    xmlrpc_temp = xmlrpc_string_new(env, "command.set");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_struct_set_value(env, struct_, "path", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);

	if( value_xmlrpc )
	{
		xmlrpc_struct_set_value(env, struct_, "value", value_xmlrpc);
	}

    return struct_;

}


static void *ntg_xmlrpc_get_callback(ntg_server * server, const int argc,
        va_list argv)
{

    xmlrpc_env *env;
    xmlrpc_value *struct_ = NULL;
    ntg_path *path;
    ntg_value *value = NULL;
    xmlrpc_value *value_xmlrpc = NULL, *xmlrpc_temp = NULL, *xmlrpc_path;

    env = va_arg(argv, xmlrpc_env *);
    path = va_arg(argv, ntg_path *);

    struct_ = xmlrpc_struct_new(env);

    NTG_TRACE_VERBOSE_WITH_STRING( "getting value", path->string);

    value = ntg_get_(server, path);

	if( value )
	{
		switch (value->type) 
		{
			case NTG_STRING:
				if (value->ctype.s) {
					value_xmlrpc = xmlrpc_string_new(env, value->ctype.s);
				} else {
					value_xmlrpc = xmlrpc_string_new(env, "");
				}
				break;
			case NTG_FLOAT:
				value_xmlrpc = xmlrpc_double_new(env, (double)value->ctype.f);
				break;
			case NTG_INTEGER:
				value_xmlrpc = xmlrpc_int_new(env, value->ctype.i);
				break;
			default:
				value_xmlrpc = xmlrpc_nil_new(env);
				NTG_TRACE_ERROR_WITH_INT("value set to nil due to unexpected value type", value->type);
		}
	}
	else
	{
		value_xmlrpc = xmlrpc_nil_new(env);
	}
 
    xmlrpc_temp = xmlrpc_string_new(env, "query.get");
    xmlrpc_struct_set_value(env, struct_, RESPONSE_LABEL, xmlrpc_temp);
    xmlrpc_DECREF(xmlrpc_temp);

    xmlrpc_path = ntg_xmlrpc_value_from_path(path, env);
    xmlrpc_struct_set_value(env, struct_, "path", xmlrpc_path);
    xmlrpc_DECREF(xmlrpc_path);

    xmlrpc_struct_set_value(env, struct_, "value", value_xmlrpc);
    xmlrpc_DECREF(value_xmlrpc);

    /* free out-of-place memory */
    ntg_path_free(path);

	if( value )
	{
		ntg_value_free(value);
	}

    return struct_;

}

static xmlrpc_value *ntg_xmlrpc_version(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    NTG_TRACE_VERBOSE("");

    return ntg_server_do_va(&ntg_xmlrpc_version_callback, 1, (void *)env);
}

static xmlrpc_value *ntg_xmlrpc_print_state(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    NTG_TRACE_VERBOSE("");

    return ntg_server_do_va(&ntg_xmlrpc_print_state_callback, 1, (void *)env);
}


static xmlrpc_value *ntg_xmlrpc_interfacelist(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    NTG_TRACE_VERBOSE("");

    return ntg_server_do_va(&ntg_xmlrpc_interfacelist_callback, 1, (void *)env);

}


static xmlrpc_value *ntg_xmlrpc_interfaceinfo(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    const char *name;
    size_t len;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(s#)", &name, &len);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_interfaceinfo_callback, 2, (void *)env, name);
}


static xmlrpc_value *ntg_xmlrpc_endpoints(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    const char *name;
    size_t len;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(s#)", &name, &len);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_endpoints_callback, 2, (void *)env, name);
}


static xmlrpc_value *ntg_xmlrpc_widgets(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    const char *name;
    size_t len;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(s#)", &name, &len);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_widgets_callback, 2, (void *)env, name);
}


static xmlrpc_value *ntg_xmlrpc_default(xmlrpc_env * const env,
        const char *const host,
        const char *const method_name,
        xmlrpc_value * const param_array,
        void *const user_data)
{
    NTG_TRACE_ERROR_WITH_STRING( "WARNING, unhandled method", method_name);

    return param_array;
}


static xmlrpc_value *ntg_xmlrpc_nodelist(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    ntg_path *path;
    xmlrpc_value *xmlrpc_path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(A)", &xmlrpc_path);

    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_nodelist_callback, 2, (void *)env, path);

}

static xmlrpc_value *ntg_xmlrpc_delete(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    ntg_path *path;
    xmlrpc_value *xmlrpc_path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(A)", &xmlrpc_path);
    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_delete_callback, 2, (void *)env, path);

}

static xmlrpc_value *ntg_xmlrpc_rename(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    ntg_path *path;
    xmlrpc_value *xmlrpc_path;
    const char *name;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(As)", &xmlrpc_path, &name);
    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_rename_callback, 3, (void *)env, path,
            name);

}

static xmlrpc_value *ntg_xmlrpc_save(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    ntg_path *path;
    xmlrpc_value *xmlrpc_path;
    const char *file_path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(As)", &xmlrpc_path, &file_path);
    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_save_callback, 3, (void *)env, path,
            file_path);
}

static xmlrpc_value *ntg_xmlrpc_load(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    ntg_path *path;
    xmlrpc_value *xmlrpc_path;
    const char *file_path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(sA)", &file_path, &xmlrpc_path);
    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_load_callback, 3,
            (void *)env, file_path, path);

}

static xmlrpc_value *ntg_xmlrpc_move(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    ntg_path *node_path, *parent_path;
    xmlrpc_value *xmlrpc_node_path, *xmlrpc_parent_path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(AA)", &xmlrpc_node_path,
            &xmlrpc_parent_path);

    node_path = ntg_xmlrpc_get_path(env, xmlrpc_node_path);
    parent_path = ntg_xmlrpc_get_path(env, xmlrpc_parent_path);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_move_callback, 3, (void *)env, node_path,
            parent_path);

}

static xmlrpc_value *ntg_xmlrpc_unload_orphaned_embedded(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    NTG_TRACE_VERBOSE("");

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_unload_orphaned_embedded_callback, 1, (void *)env);
}


static xmlrpc_value *ntg_xmlrpc_install_module_file(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    const char *file_name;
    size_t len;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(s#)", &file_name, &len);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_install_module_callback, 2, (void *)env, file_name );
}


static xmlrpc_value *ntg_xmlrpc_install_embedded_module(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    const char *module_id_string;
    size_t len;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(s#)", &module_id_string, &len);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_install_embedded_module_callback, 2, (void *)env, module_id_string );
}


static xmlrpc_value *ntg_xmlrpc_uninstall_module(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    const char *module_id_string;
    size_t len;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(s#)", &module_id_string, &len);

    if (env->fault_occurred)
        return NULL;

    return ntg_server_do_va(&ntg_xmlrpc_uninstall_module_callback, 2, (void *)env, module_id_string );
}


static xmlrpc_value *ntg_xmlrpc_new(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    const char *name, *node_name;
    ntg_path *path;
    xmlrpc_value *xmlrpc_path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(ssA)", &name, &node_name,
            &xmlrpc_path);

    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    xmlrpc_DECREF(xmlrpc_path);

    if (env->fault_occurred)
        return NULL;

    assert(path->string != NULL);

    return ntg_server_do_va(&ntg_xmlrpc_new_callback, 4, (void *)env, name,
            node_name, path);
}


static xmlrpc_value *ntg_xmlrpc_set(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{
    xmlrpc_value *xmlrpc_value_, *xmlrpc_path;
    xmlrpc_value *xmlrpc_rv;
    ntg_path *path;
    ntg_value *value;
	int number_of_elements;

    NTG_TRACE_VERBOSE("");

	number_of_elements = xmlrpc_array_size( env, paramArrayP );
	switch( number_of_elements )
	{
		case 1:
			xmlrpc_decompose_value(env, paramArrayP, "(A)", &xmlrpc_path );
			xmlrpc_value_ = NULL;
			value = NULL;
			break;

		case 2:
			xmlrpc_decompose_value(env, paramArrayP, "(AV)", &xmlrpc_path, &xmlrpc_value_ );
		    value = ntg_xmlrpc_get_value(env, xmlrpc_value_);
			break;

		default:
			NTG_TRACE_ERROR_WITH_INT( "incorrect number of parameters passed into xmlrpc command.set", number_of_elements );
			return NULL;
	}

    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    ntg_command_enqueue(NTG_SET, 3, NTG_SOURCE_XMLRPC_API, path, value );
    xmlrpc_rv = ntg_xmlrpc_return_set(env, xmlrpc_path, xmlrpc_value_);

	if( value )
	{
		ntg_value_free(value);
	}

    ntg_path_free(path);

    return xmlrpc_rv;
}

static xmlrpc_value *ntg_xmlrpc_get(xmlrpc_env * const env,
        xmlrpc_value * const paramArrayP,
        void *const userData)
{

    xmlrpc_value *xmlrpc_path;
    ntg_path *path;

    NTG_TRACE_VERBOSE("");

    xmlrpc_decompose_value(env, paramArrayP, "(A)", &xmlrpc_path);

    path = ntg_xmlrpc_get_path(env, xmlrpc_path);

    xmlrpc_DECREF(xmlrpc_path);

    return ntg_server_do_va(&ntg_xmlrpc_get_callback, 2, (void *)env, path);

}


void ntg_xmlrpc_shutdown( xmlrpc_env *const envP, 
        void *       const context,
        const char * const comment,
        void *       const callInfo)
{
    sem_post(SEM_SYSTEM_SHUTDOWN);
}


void *ntg_xmlrpc_server_run(void *portv)
{

    xmlrpc_registry *registryP;
    xmlrpc_env env;

    unsigned short*portp=(unsigned short*)portv;
    unsigned short port=*portp;
    ntg_free(portp);

    NTG_TRACE_PROGRESS_WITH_INT("Starting server on port", port);

    xmlrpc_env_init(&env);

    registryP = xmlrpc_registry_new(&env);

    xmlrpc_limit_set( XMLRPC_XML_SIZE_LIMIT_ID, NTG_XMLRPC_SIZE_LIMIT );

    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "system.version",
            &ntg_xmlrpc_version, NULL,
            "S:", HELPSTR_VERSION);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "system.printstate",
            &ntg_xmlrpc_print_state, NULL,
            "S:", HELPSTR_PRINTSTATE);
	xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "query.interfacelist",
            &ntg_xmlrpc_interfacelist, NULL, "S:",
            HELPSTR_INTERFACELIST);
	xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "query.interfaceinfo",
            &ntg_xmlrpc_interfaceinfo, NULL, "S:s",
            HELPSTR_INTERFACEINFO);
	xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "query.endpoints",
            &ntg_xmlrpc_endpoints, NULL, "S:s",
            HELPSTR_ENDPOINTS);
	xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "query.widgets",
            &ntg_xmlrpc_widgets, NULL, "S:s",
            HELPSTR_WIDGETS);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "query.nodelist",
            &ntg_xmlrpc_nodelist, NULL, "S:A",
            HELPSTR_NODELIST);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "query.get",
            &ntg_xmlrpc_get, NULL, "S:A",
            HELPSTR_GET);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.set",
            &ntg_xmlrpc_set, NULL,
            "S:As,S:Ai,S:Ad,S:A6", HELPSTR_SET);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.new",
            &ntg_xmlrpc_new, NULL, "S:ssA",
            HELPSTR_NEW);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.delete",
            &ntg_xmlrpc_delete, NULL, "S:A",
            HELPSTR_DELETE);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.rename",
            &ntg_xmlrpc_rename, NULL, "S:As",
            HELPSTR_RENAME);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.save",
            &ntg_xmlrpc_save, NULL, "S:As",
            HELPSTR_SAVE);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.load",
            &ntg_xmlrpc_load, NULL, "S:sA",
            HELPSTR_LOAD);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "command.move",
            &ntg_xmlrpc_move, NULL, "S:AA",
            HELPSTR_MOVE);

    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "module.unloadorphanedembedded",
            &ntg_xmlrpc_unload_orphaned_embedded, NULL, "S:",
            HELPSTR_UNLOAD_ORPHANED_EMBEDDED);
	xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "module.installintegramodulefile",
        &ntg_xmlrpc_install_module_file, NULL, "S:s",
        HELPSTR_INSTALL_INTEGRA_MODULE_FILE);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "module.installembeddedmodule",
        &ntg_xmlrpc_install_embedded_module, NULL, "S:s",
        HELPSTR_INSTALL_EMBEDDED_MODULE);
    xmlrpc_registry_add_method_w_doc(&env, registryP, NULL, "module.uninstallmodule",
        &ntg_xmlrpc_uninstall_module, NULL, "S:s",
        HELPSTR_UNINSTALL_MODULE);

    xmlrpc_registry_set_shutdown(registryP, ntg_xmlrpc_shutdown, NULL );

    xmlrpc_registry_set_default_method(&env, registryP, &ntg_xmlrpc_default,
            NULL);

    ServerCreate(&abyssServer, "XmlRpcServer", port, NULL, 
            NULL);

    xmlrpc_server_abyss_set_handlers2(&abyssServer, "/", registryP);

    ServerInit(&abyssServer);

    sem_post(SEM_ABYSS_INIT);

    /* This version processes commands concurrently */
#if 1
    ServerRun(&abyssServer);
#else
    while (true){
        ServerRunOnce(&abyssServer);
        /* This waits for the next connection, accepts it, reads the
           HTTP POST request, executes the indicated RPC, and closes
           the connection.
           */
    }
#endif

    ServerFree(&abyssServer);
    xmlrpc_registry_free(registryP);

    /* FIX: for now we support the old 'stable' version of xmlrpc-c */
    /* AbyssTerm(); */

    xmlrpc_env_clean(&env);

    NTG_TRACE_PROGRESS("XMLRPC server terminated");
    pthread_exit(0);

    return NULL;

}

void ntg_xmlrpc_server_terminate(void)
{
    /* make sure we don't try to terminate before abyssServer init */
    sem_wait(SEM_ABYSS_INIT);
    ServerTerminate(&abyssServer);
}
