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

#include <string.h>
#include <assert.h>

#include "helper.h"
#include "globals.h"
#include "command.h"
#include "server.h"
#include "path.h"
#include "memory.h"
#include "list.h"
#include "osc_client.h"
#include "system_class_handlers.h"
#include "reentrance_checker.h"
#include "data_directory.h"
#include "module_manager.h"
#include "file_io.h"
#include "interface.h"

#include "Integra/integra.h"


bool ntg_should_send_set_to_host( const ntg_server *server, const ntg_node_attribute *attribute, const ntg_interface *interface, ntg_command_source cmd_source )
{
    assert( attribute );
	assert( interface );

	switch( cmd_source )
	{
		case NTG_SOURCE_HOST:
			return false;	/* don't send to host if came from host */

		case NTG_SOURCE_LOAD:
			return false;	/* don't send to host when handling load - handled in a second phase */

		default:
			break;		
	}

	if( ntg_endpoint_is_input_file( attribute->endpoint ) && ntg_should_copy_input_file( cmd_source ) )
	{
		return false;
	}

	if( !ntg_interface_has_implementation( interface ) )
	{
		return false;
	}

	if( !ntg_endpoint_should_send_to_host( attribute->endpoint ) )
	{
		return false;
	}

	return true;
}


bool ntg_should_send_to_client( ntg_command_source cmd_source ) 
{
	switch( cmd_source )
	{
		case NTG_SOURCE_INITIALIZATION:
			/* don't send to client on initialization - client infers from known default values */
			return false;

		case NTG_SOURCE_LOAD:
			/* don't send to client on load - calls nodelist and get explicitly */
			return false;

		default:
			return true;
	}
}



ntg_command_status ntg_set_(ntg_server *server,
        ntg_command_source cmd_source,
        const ntg_path *path,
        const ntg_value *value)
{
    ntg_node *node = NULL;
    ntg_node *root = NULL;
    ntg_path *my_path = NULL;
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;
    ntg_node_attribute *attribute;
    char *attribute_name;
    ntg_bridge_interface *bridge = NULL;
	ntg_value *previous_value = NULL;

    assert(server != NULL);
    assert(path != NULL);

    NTG_COMMAND_STATUS_INIT;

    bridge = server->bridge;

	/* get node from path */
    root       = ntg_server_get_root(server);
    error_code = ntg_path_validate(path);

    if (error_code != NTG_NO_ERROR) {
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    if (path->n_elems <= 1) {
        NTG_TRACE_ERROR_WITH_INT("attribute has too few elements", 
                path->n_elems);
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    my_path = ntg_path_copy(path);
    attribute_name = ntg_path_pop_element(my_path);
    node = ntg_node_find_by_path(my_path, root);

    if (node == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("node not found; set request ignored",
                my_path->elems[my_path->n_elems - 1]);
        ntg_path_free(my_path);
        ntg_free(attribute_name);
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }
    ntg_path_free(my_path);

    attribute = ntg_node_attribute_find_by_name(node, attribute_name);
    if (attribute == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("attribute not found", attribute_name );
        ntg_free(attribute_name);
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }


	switch( attribute->endpoint->type )
	{
		case NTG_STREAM:
			NTG_TRACE_ERROR_WITH_STRING( "can't call set for a stream attribute!", attribute->path->string );
			NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );

		case NTG_CONTROL:
			switch( attribute->endpoint->control_info->type )
			{
				case NTG_STATE:
					if( !value )
					{
						NTG_TRACE_ERROR_WITH_STRING( "called set without a value for a stateful endpoint", attribute->path->string );
						NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );
					}

					/* test that new value is of correct type */
					if( value->type != attribute->endpoint->control_info->state_info->type )
					{
						/* we allow passing integers to float attributes and vice-versa, but no other mismatched types */
						if( ( value->type != NTG_INTEGER && value->type != NTG_FLOAT ) || ( attribute->endpoint->control_info->state_info->type != NTG_INTEGER && attribute->endpoint->control_info->state_info->type != NTG_FLOAT ) )
						{
							NTG_TRACE_ERROR_WITH_STRING( "called set with incorrect value type", attribute->path->string );
							NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );
						}
					} 

					break;

				case NTG_BANG:
					if( value )
					{
						NTG_TRACE_ERROR_WITH_STRING( "called set with a value for a stateless endpoint", attribute->path->string );
						NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );
					}
					break;

				default:
					assert( false );
					break;
			}
			break;

		default:
			assert( false );
			break;
	}

	if( cmd_source == NTG_SOURCE_HOST && !ntg_node_is_active( node ) )
	{
		return command_status;
	}

    /* test constraint */
	if( value )
	{
		if( !ntg_node_attribute_test_constraint( attribute, value ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "attempting to set value which doesn't conform to constraint - aborting set command", path->string );
			NTG_RETURN_ERROR_CODE( NTG_CONSTRAINT_ERROR );
		}
	}


	if( ntg_reentrance_push( server, attribute, cmd_source ) )
	{
		NTG_TRACE_ERROR_WITH_STRING("detected reentry - aborting set command", path->string );
		NTG_RETURN_ERROR_CODE( NTG_REENTRANCE_ERROR );
	}

	if( attribute->value )
	{
		previous_value = ntg_value_duplicate( attribute->value );
	}

    /* set the attribute value */
	if( value )
	{
		ntg_node_attribute_set_value( attribute, value );
	}

    /* handle any system class logic */
	ntg_system_class_handle_set( server, attribute, previous_value, cmd_source );

	if( previous_value )
	{
		ntg_value_free( previous_value );
	}

	ntg_free( attribute_name );

    /* send the attribute value to the host if needed */
	if( ntg_should_send_set_to_host( server, attribute, node->interface, cmd_source ) ) 
	{
        ntg_node_attribute_send_value(attribute, bridge);
    }

    if( error_code != NTG_NO_ERROR ) 
	{
        NTG_TRACE_ERROR("error setting attribute value");
        NTG_RETURN_COMMAND_STATUS;
    }

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_set(server->osc_client, cmd_source, path, attribute->value );
    }

	ntg_reentrance_pop( server, cmd_source );

    return command_status;
}


ntg_command_status ntg_new_(ntg_server *server,
        ntg_command_source cmd_source,
        const GUID *module_id,
        const char *node_name,
        const ntg_path *path)
{

    char *my_node_name = NULL;
    ntg_bridge_interface *bridge		= NULL;
	const ntg_interface *interface		= NULL;
	const ntg_endpoint *endpoint		= NULL;
    ntg_command_status command_status	= {NULL, 0};
    ntg_node_attribute *node_attribute	= NULL;
    ntg_node *root						= NULL;
    ntg_node *parent					= NULL;
    ntg_node *node						= NULL;
    ntg_value *value					= NULL;
	char *implementation_path			= NULL;

    if (path == NULL) {
        NTG_TRACE_ERROR("path is NULL, giving up...");
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    bridge = server->bridge;

    if (bridge == NULL) {
        NTG_TRACE_ERROR("there's no bridge. Aborting.");
        assert(0);
    }

    assert(path != NULL);
    assert(server != NULL);

    root = ntg_server_get_root((ntg_server *) server);
    parent = ntg_node_find_by_path(path, root);


    if (parent == NULL) {
        NTG_TRACE_ERROR("parent is NULL, returning NULL");
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }


    /* get interface */
	interface = ntg_get_interface_by_module_id( server->module_manager, module_id );
    if( !interface ) 
	{
        NTG_TRACE_ERROR("unable to find interface" );
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
    }

    /* if node name is NULL, create one */
    if( node_name )
	{
		my_node_name = ntg_strdup( node_name );
	}
	else
	{
		my_node_name = ntg_make_node_name( interface->info->name );
    }

    /* First check if node name is already taken */
    while( ntg_node_find_by_name( parent, my_node_name ) ) 
	{
        NTG_TRACE_PROGRESS_WITH_STRING("node name is in use; appending underscore", my_node_name);

        my_node_name = ntg_string_append(my_node_name, "_");
	}

    node = ntg_node_new();
    
    /* FIX: order is important here -- better to break into separate function */
    ntg_node_set_interface( node, interface );
    ntg_node_set_name(node, my_node_name);
    ntg_node_add(parent, node);
	ntg_node_add_attributes(node, interface->endpoint_list);
	ntg_node_add_to_statetable(node, server->state_table);

	if( ntg_interface_has_implementation( interface ) )
	{
		/* load implementation in module host */
		implementation_path = ntg_module_manager_get_patch_path( server->module_manager, interface );
		if( implementation_path )
		{
			bridge->module_load(node->id, implementation_path );
			ntg_free( implementation_path );
		}
		else
		{
			NTG_TRACE_ERROR( "Failed to get implementation path - cannot load module in host" );
		}
	}

    /* set attribute defaults */
	for( endpoint = interface->endpoint_list; endpoint; endpoint = endpoint->next )
	{
		if( endpoint->type != NTG_CONTROL || endpoint->control_info->type != NTG_STATE )
		{
			continue;
		}

        node_attribute = ntg_node_attribute_find_by_name( node, endpoint->name );
        assert( node_attribute );

		value = ntg_value_duplicate( endpoint->control_info->state_info->default_value );
		ntg_set_( server_, NTG_SOURCE_INITIALIZATION, node_attribute->path, value );
	    ntg_value_free(value);

	}

    NTG_TRACE_VERBOSE_WITH_STRING( "Created node", node->name );

	command_status.data = node;

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
	    ntg_osc_client_send_new(server->osc_client, cmd_source, module_id, my_node_name, parent->path);
	}

    ntg_free(my_node_name);

    return command_status;
}

ntg_command_status  ntg_delete_(ntg_server *server,
        ntg_command_source cmd_source,
        const ntg_path *path)
{
    ntg_bridge_interface *bridge;
    ntg_node *node, *root;
    ntg_command_status command_status;
    ntg_error_code error_code;

    NTG_COMMAND_STATUS_INIT;
    bridge = server->bridge;

    root = ntg_server_get_root(server);
    node = ntg_node_find_by_path(path, root);

    if (node == NULL) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	ntg_system_class_handle_delete( server, node, cmd_source );

	ntg_node_remove_from_statetable( node, server->state_table );

    error_code = ntg_server_node_delete(server, node);

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_delete(server->osc_client, cmd_source, path);
	}

    NTG_RETURN_COMMAND_STATUS;
}


ntg_command_status ntg_unload_orphaned_embedded_modules_( ntg_server *server, ntg_command_source cmd_source )
{
	ntg_list *orphaned_embedded_modules;
	ntg_command_status command_status;
	ntg_error_code error_code = NTG_NO_ERROR;

	assert( server );

	NTG_COMMAND_STATUS_INIT;

	orphaned_embedded_modules = ntg_module_manager_get_orphaned_embedded_modules( server->module_manager, server->root );

	if( orphaned_embedded_modules )
	{
		ntg_module_manager_unload_modules( server->module_manager, orphaned_embedded_modules );
		ntg_list_free( orphaned_embedded_modules );
	}

	NTG_RETURN_COMMAND_STATUS;
}


ntg_command_status ntg_rename_(ntg_server *server,
        ntg_command_source cmd_source,
        const ntg_path *path,
        const char *name)
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;
    ntg_node *node, *root;
	char *previous_name = NULL;

    assert( path );
    assert( name ) ;

    NTG_COMMAND_STATUS_INIT;

    root = ntg_server_get_root((ntg_server *) server);
    node = ntg_node_find_by_path(path, root);

    if (node == NULL) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	previous_name = ntg_strdup( node->name );

    /* remove old state table entries for node and children */
	ntg_node_remove_from_statetable( node, server->state_table );

    ntg_node_rename(node, name);

    /* add new state table entries for node and children */
	ntg_node_add_to_statetable( node, server->state_table );

	ntg_system_class_handle_rename( server, node, previous_name, cmd_source );

	ntg_free( previous_name );

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_rename(server->osc_client, cmd_source, path, name);
	}

    NTG_RETURN_COMMAND_STATUS;
}

ntg_command_status ntg_move_(ntg_server *server,
        ntg_command_source cmd_source,
        const ntg_path *node_path,
        const ntg_path *parent_path)
{
    ntg_error_code      error_code = NTG_NO_ERROR;
    ntg_command_status  command_status;
    ntg_node           *root;
    ntg_node           *node;
    ntg_node           *new_parent;
    ntg_node           *parent;

    NTG_COMMAND_STATUS_INIT;

    root = ntg_server_get_root(server);
    node = ntg_node_find_by_path(node_path, root);

    if (node==NULL) {
        NTG_TRACE_ERROR_WITH_STRING("unable to find node given by path", node->path->string);
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    parent = node->parent;
    /* check if we're at the beginning of the node list */
    if (parent->nodes == node) {
        if (node->next != node) {
            parent->nodes = node->next;
        } else {
            /* we're the only node in the list */
            parent->nodes = NULL;
        }
    }

    /* remove old state table entries for node and children */
	ntg_node_remove_from_statetable( node, server->state_table );

    ntg_node_unlink(node);
    new_parent = ntg_node_find_by_path(parent_path, root);

    if (new_parent == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("unable to find node given by path", parent_path->string);
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    /* add node to new parent */
    ntg_node_add(new_parent, node);

    /* update stored path */
    ntg_node_update_path(node);

    if (error_code != NTG_NO_ERROR) {
        NTG_TRACE_ERROR("failed to update vertices");
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
    }

    /* update child paths and vertices */
    ntg_node_update_children(node);

    /* add new state table entries for node and children */
	ntg_node_add_to_statetable( node, server->state_table );

	ntg_system_class_handle_move( server, node, node_path, cmd_source );

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_move(server->osc_client, cmd_source, node_path, parent_path);
	}

    NTG_RETURN_COMMAND_STATUS;
}


ntg_command_status ntg_load_(ntg_server * server,
        ntg_command_source cmd_source,
        const char *file_path,
        const ntg_path * path)
{
    ntg_node *node, *root;
	ntg_command_status command_status;

    assert(server != NULL);
    assert(file_path != NULL);
    assert(path != NULL);

	NTG_COMMAND_STATUS_INIT

    root = ntg_server_get_root(server);
    node = ntg_node_find_by_path( path, root);

    if( !node ) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	command_status = ntg_file_load( file_path, node, server->module_manager );

	return command_status;
}


const ntg_value *ntg_get_(ntg_server *server, const ntg_path * path)
{

    ntg_node_attribute *node_attribute = NULL;
    ntg_node           *node           = NULL;
    ntg_node           *root           = NULL;
    char               *attribute_name;
    ntg_error_code      error_code;

    error_code     = ntg_path_validate(path);

    if (error_code != NTG_NO_ERROR) {
        return NULL;
    }

    root           = ntg_server_get_root(server);

    {
        ntg_path *my_path = ntg_path_copy(path);

        /* get the attribute name */
        attribute_name = ntg_path_pop_element(my_path);
        node           = ntg_node_find_by_path(my_path, root);

        ntg_path_free(my_path);
    }

    if (node == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("node not found; get request ignored",
				path->elems[path->n_elems - 1]);
        ntg_free(attribute_name);
        return NULL;
    }

    node_attribute = ntg_node_attribute_find_by_name(node, attribute_name);

    if (node_attribute == NULL) {
        NTG_TRACE_ERROR_WITH_STRING("attribute not found; get request ignored",
                attribute_name);
        ntg_free(attribute_name);
        return NULL;
    }

    ntg_free(attribute_name);

    return ntg_value_duplicate(node_attribute->value);

}


const ntg_list *ntg_nodelist_(ntg_server *server, const ntg_path * path)
{
    ntg_node *parent   = NULL;
    ntg_node *root     = NULL;

    assert(path != NULL);
    assert(server != NULL);

    root = ntg_server_get_root( server );
    parent = ntg_node_find_by_path(path, root);

    if (parent == NULL) {
        NTG_TRACE_ERROR("parent is NULL, returning NULL");
        return NULL;
    }

    /* FIX: refactor into ntg_server_get_nodelist */
    if (parent->nodes == NULL) {
        return ntg_list_new(NTG_LIST_NODES);
    }

    return ntg_server_get_nodelist(server_, parent, NULL, NULL);
}

ntg_command_status ntg_save_(ntg_server *server, const ntg_path *path,
        const char *file_path)
{
    ntg_error_code error_code;
    ntg_command_status command_status;
    ntg_node *node, *root;
	char *file_path_with_suffix;

    NTG_COMMAND_STATUS_INIT;

    if (file_path == NULL) 
	{
        NTG_TRACE_ERROR("file path is NULL");
        NTG_RETURN_ERROR_CODE( NTG_ERROR );
    }
    else 
	{
        NTG_TRACE_PROGRESS_WITH_STRING("saving to", file_path);
    }

    root = ntg_server_get_root(server_);
    node = ntg_node_find_by_path(path, root);

    if( node==NULL ) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	file_path_with_suffix = ntg_ensure_filename_has_suffix( file_path, NTG_FILE_SUFFIX );

	error_code = ntg_file_save( file_path_with_suffix, node, server_->module_manager );

	ntg_free( file_path_with_suffix );

    NTG_RETURN_COMMAND_STATUS;
}


void ntg_print_state_()
{
	printf("Print State:\n");
	printf("***********:\n\n");
    print_node_state(server_,ntg_server_get_root(server_)->nodes,0);
	fflush( stdout );
}
