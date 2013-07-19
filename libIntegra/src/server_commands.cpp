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
#include "server.h"
#include "path.h"
#include "osc_client.h"
#include "system_class_handlers.h"
#include "reentrance_checker.h"
#include "data_directory.h"
#include "module_manager.h"
#include "file_io.h"
#include "interface.h"

#include "Integra/integra.h"

using namespace ntg_api;
using namespace ntg_internal;



bool ntg_should_send_set_to_host( const CNodeEndpoint &endpoint, const ntg_interface &interface, ntg_command_source cmd_source )
{
	switch( cmd_source )
	{
		case NTG_SOURCE_HOST:
			return false;	/* don't send to host if came from host */

		case NTG_SOURCE_LOAD:
			return false;	/* don't send to host when handling load - handled in a second phase */

		default:
			break;		
	}

	if( ntg_endpoint_is_input_file( endpoint.get_endpoint() ) && ntg_should_copy_input_file( *endpoint.get_value(), cmd_source ) )
	{
		return false;
	}

	if( !ntg_interface_has_implementation( &interface ) )
	{
		return false;
	}

	if( !ntg_endpoint_should_send_to_host( endpoint.get_endpoint() ) )
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



ntg_command_status ntg_set_(ntg_server *server, ntg_command_source cmd_source, const CPath &path, const CValue *value )
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;

    assert( server );

    NTG_COMMAND_STATUS_INIT;

	/* get node from path */
	if( path.get_number_of_elements() <= 1) 
	{
		NTG_TRACE_ERROR_WITH_STRING("attribute has too few elements", path.get_string().c_str() );
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	CNodeEndpoint *node_endpoint = ntg_find_node_endpoint( path.get_string() );
    if( node_endpoint == NULL) 
	{
        NTG_TRACE_ERROR_WITH_STRING( "endpoint not found", path.get_string().c_str() );
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	const ntg_endpoint *endpoint = node_endpoint->get_endpoint();

	switch( endpoint->type )
	{
		case NTG_STREAM:
			NTG_TRACE_ERROR_WITH_STRING( "can't call set for a stream attribute!", path.get_string().c_str() );
			NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );

		case NTG_CONTROL:
			switch( endpoint->control_info->type )
			{
				case NTG_STATE:
					if( !value )
					{
						NTG_TRACE_ERROR_WITH_STRING( "called set without a value for a stateful endpoint", path.get_string().c_str() );
						NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );
					}

					/* test that new value is of correct type */
					if( value->get_type() != endpoint->control_info->state_info->type )
					{
						/* we allow passing integers to float attributes and vice-versa, but no other mismatched types */
						if( ( value->get_type() != CValue::INTEGER && value->get_type() != CValue::FLOAT ) || ( endpoint->control_info->state_info->type != CValue::INTEGER && endpoint->control_info->state_info->type != CValue::FLOAT ) )
						{
							NTG_TRACE_ERROR_WITH_STRING( "called set with incorrect value type", path.get_string().c_str() );
							NTG_RETURN_ERROR_CODE( NTG_TYPE_ERROR );
						}
					} 

					break;

				case NTG_BANG:
					if( value )
					{
						NTG_TRACE_ERROR_WITH_STRING( "called set with a value for a stateless endpoint", path.get_string().c_str() );
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

	if( cmd_source == NTG_SOURCE_HOST && !ntg_node_is_active( node_endpoint->get_node() ) )
	{
		return command_status;
	}

    /* test constraint */
	if( value )
	{
		if( !node_endpoint->test_constraint( *value ) )
		{
			NTG_TRACE_ERROR_WITH_STRING( "attempting to set value which doesn't conform to constraint - aborting set command", path.get_string().c_str() );
			NTG_RETURN_ERROR_CODE( NTG_CONSTRAINT_ERROR );
		}
	}


	if( ntg_reentrance_push( server, node_endpoint, cmd_source ) )
	{
		NTG_TRACE_ERROR_WITH_STRING( "detected reentry - aborting set command", path.get_string().c_str() );
		NTG_RETURN_ERROR_CODE( NTG_REENTRANCE_ERROR );
	}

	CValue *previous_value( NULL );
	if( node_endpoint->get_value() )
	{
		previous_value = node_endpoint->get_value()->clone();
	}

    /* set the attribute value */
	if( value )
	{
		assert( node_endpoint->get_value() );
		value->convert( *node_endpoint->get_value_writable() );
	}


    /* handle any system class logic */
	ntg_system_class_handle_set( server, node_endpoint, previous_value, cmd_source );

	if( previous_value )
	{
		delete previous_value;
	}

    /* send the attribute value to the host if needed */
	if( ntg_should_send_set_to_host( *node_endpoint, *node_endpoint->get_node()->interface, cmd_source ) ) 
	{
		server->bridge->send_value( node_endpoint );
    }

    if( error_code != NTG_NO_ERROR ) 
	{
        NTG_TRACE_ERROR("error setting attribute value");
        NTG_RETURN_COMMAND_STATUS;
    }

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_set( server->osc_client, cmd_source, path, node_endpoint->get_value() );
    }

	ntg_reentrance_pop( server, cmd_source );

    return command_status;
}


ntg_command_status ntg_new_(ntg_server *server, ntg_command_source cmd_source, const GUID *module_id, string node_name, const CPath &path )
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;

    assert( server );

    ntg_node *root = ntg_server_get_root( server );
    ntg_node *parent = ntg_node_find_by_path( path, root );

    if( !parent ) 
	{
        NTG_TRACE_ERROR( "parent is NULL, returning NULL" );
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    /* get interface */
	const ntg_interface *interface = ntg_get_interface_by_module_id( server->module_manager, module_id );
    if( !interface ) 
	{
        NTG_TRACE_ERROR( "unable to find interface" );
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
    }

    /* if node name is NULL, create one */
    if( node_name.empty() )
	{
		node_name = ntg_make_node_name( interface->info->name );
	}

    /* First check if node name is already taken */
    while( ntg_node_find_by_name( parent, node_name.c_str() ) ) 
	{
        NTG_TRACE_PROGRESS_WITH_STRING("node name is in use; appending underscore", node_name.c_str() );

        node_name += "_";
	}

	if( !ntg_validate_node_name( node_name.c_str() ) )
	{
        NTG_TRACE_ERROR_WITH_STRING( "node name contains invalid characters", node_name.c_str() );
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
	}

    ntg_node *node = ntg_node_new();
    
    /* FIX: order is important here -- better to break into separate function */
    ntg_node_set_interface( node, interface );
    ntg_node_set_name( node, node_name.c_str() );
    ntg_node_add( parent, node );
	ntg_node_add_node_endpoints( node, interface->endpoint_list );
	ntg_node_add_to_statetable( node, server->state_table );

	if( ntg_interface_has_implementation( interface ) )
	{
		/* load implementation in module host */
		char *implementation_path = ntg_module_manager_get_patch_path( server->module_manager, interface );
		if( implementation_path )
		{
			server->bridge->module_load( node->id, implementation_path );
			delete[] implementation_path;
		}
		else
		{
			NTG_TRACE_ERROR( "Failed to get implementation path - cannot load module in host" );
		}
	}

    /* set attribute defaults */
	for( const ntg_endpoint *endpoint = interface->endpoint_list; endpoint; endpoint = endpoint->next )
	{
		if( endpoint->type != NTG_CONTROL || endpoint->control_info->type != NTG_STATE )
		{
			continue;
		}

        const CNodeEndpoint *node_endpoint = ntg_find_node_endpoint( node, endpoint->name );
        assert( node_endpoint );

		ntg_set_( server_, NTG_SOURCE_INITIALIZATION, node_endpoint->get_path(), endpoint->control_info->state_info->default_value );
	}

    /* handle any system class logic */
	ntg_system_class_handle_new( server, node, cmd_source );


    NTG_TRACE_VERBOSE_WITH_STRING( "Created node", node->name );

	command_status.data = node;

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
	    ntg_osc_client_send_new( server->osc_client, cmd_source, module_id, node_name.c_str(), parent->path );
	}

    return command_status;
}


ntg_command_status ntg_delete_( ntg_server *server, ntg_command_source cmd_source, const CPath &path )
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
	ntg_command_status command_status;
	ntg_error_code error_code = NTG_NO_ERROR;

	assert( server );

	NTG_COMMAND_STATUS_INIT;

	guid_set orphaned_embedded_modules;
	ntg_module_manager_get_orphaned_embedded_modules( server->module_manager, *server->root, orphaned_embedded_modules );

	ntg_module_manager_unload_modules( server->module_manager, orphaned_embedded_modules );

	NTG_RETURN_COMMAND_STATUS;
}


ntg_command_status ntg_install_module_( ntg_server *server, ntg_command_source cmd_source, const char *file_path )
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;
	ntg_module_install_result *module_install_result;

	assert( server && file_path );
	NTG_TRACE_PROGRESS( file_path );

	NTG_COMMAND_STATUS_INIT

	module_install_result = new ntg_module_install_result;

	error_code = ntg_module_manager_install_module( server->module_manager, file_path, module_install_result );

	if( error_code == NTG_NO_ERROR )
	{
		command_status.data = module_install_result;
	}
	else
	{
		delete module_install_result;
	}

	NTG_RETURN_COMMAND_STATUS
}


ntg_command_status ntg_install_embedded_module_( ntg_server *server, ntg_command_source cmd_source, const GUID *module_id )
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;

	assert( server && module_id );
	NTG_TRACE_PROGRESS( "" );

	NTG_COMMAND_STATUS_INIT

	error_code = ntg_module_manager_install_embedded_module( server->module_manager, module_id );

	NTG_RETURN_COMMAND_STATUS
}


ntg_command_status ntg_uninstall_module_( ntg_server *server, ntg_command_source cmd_source, const GUID *module_id )
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;
	ntg_module_uninstall_result *module_uninstall_result;

	assert( server && module_id );
	NTG_TRACE_PROGRESS( "" );

	NTG_COMMAND_STATUS_INIT

	module_uninstall_result = new ntg_module_uninstall_result;
	memset( module_uninstall_result, 0, sizeof( ntg_module_uninstall_result ) );

	error_code = ntg_module_manager_uninstall_module( server->module_manager, module_id, module_uninstall_result );

	if( error_code == NTG_NO_ERROR )
	{
		command_status.data = module_uninstall_result;
	}
	else
	{
		delete module_uninstall_result;
	}

	NTG_RETURN_COMMAND_STATUS
}


ntg_command_status ntg_load_module_in_development_( ntg_server *server, ntg_command_source cmd_source, const char *file_path )
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;
	ntg_load_module_in_development_result *result;

	assert( server && file_path );
	NTG_TRACE_PROGRESS( file_path );

	NTG_COMMAND_STATUS_INIT

	result = new ntg_load_module_in_development_result;

	error_code = ntg_module_manager_load_module_in_development( server->module_manager, file_path, result );

	if( error_code == NTG_NO_ERROR )
	{
		command_status.data = result;
	}
	else
	{
		delete result;
	}

	NTG_RETURN_COMMAND_STATUS
}



ntg_command_status ntg_rename_(ntg_server *server, ntg_command_source cmd_source, const CPath &path, const char *name)
{
    ntg_error_code error_code = NTG_NO_ERROR;
    ntg_command_status command_status;
    ntg_node *node, *root;
	char *new_name = NULL;
	char *previous_name = NULL;

    assert( name ) ;

    NTG_COMMAND_STATUS_INIT;

    root = ntg_server_get_root((ntg_server *) server);
    node = ntg_node_find_by_path(path, root);

    if (node == NULL) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	new_name = ntg_strdup( name );

    /* First check if node name is already taken */
    while( ntg_node_sibling_find_by_name( node, new_name ) ) 
	{
        NTG_TRACE_PROGRESS_WITH_STRING("node name is in use; appending underscore", new_name);

        new_name = ntg_string_append(new_name, "_");
	}

	if( !ntg_validate_node_name( new_name ) )
	{
        NTG_TRACE_ERROR_WITH_STRING( "node name contains invalid characters", new_name );
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
	}

	previous_name = ntg_strdup( node->name );

    /* remove old state table entries for node and children */
	ntg_node_remove_from_statetable( node, server->state_table );

    ntg_node_rename(node, new_name);

    /* add new state table entries for node and children */
	ntg_node_add_to_statetable( node, server->state_table );

	ntg_system_class_handle_rename( server, node, previous_name, cmd_source );

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_rename(server->osc_client, cmd_source, path, new_name );
	}

	delete[] new_name;
	delete[] previous_name;

    NTG_RETURN_COMMAND_STATUS;
}

ntg_command_status ntg_move_(ntg_server *server, ntg_command_source cmd_source, const CPath &node_path, const CPath &parent_path )
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

    if( node==NULL ) 
	{
		NTG_TRACE_ERROR_WITH_STRING( "unable to find node given by path", node_path.get_string().c_str() );
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

    if (new_parent == NULL) 
	{
        NTG_TRACE_ERROR_WITH_STRING( "unable to find node given by path", parent_path.get_string().c_str() );
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    /* add node to new parent */
    ntg_node_add( new_parent, node );

    /* update stored path */
    ntg_node_update_path(node);

    if( error_code != NTG_NO_ERROR ) 
	{
        NTG_TRACE_ERROR("failed to update vertices");
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
    }

    /* update child paths and vertices */
    ntg_node_update_path( node );

    /* add new state table entries for node and children */
	ntg_node_add_to_statetable( node, server->state_table );

	ntg_system_class_handle_move( server, node, node_path, cmd_source );

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_move(server->osc_client, cmd_source, node_path, parent_path);
	}

    NTG_RETURN_COMMAND_STATUS;
}


ntg_command_status ntg_load_(ntg_server * server, ntg_command_source cmd_source, const char *file_path, const CPath &path )
{
    ntg_node *node, *root;
	ntg_command_status command_status;

    assert(server != NULL);
    assert(file_path != NULL);

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


const CValue *ntg_get_( ntg_server *server, const CPath &path )
{
	const CNodeEndpoint *node_endpoint = ntg_find_node_endpoint( path.get_string() );
    if( !node_endpoint ) 
	{
        NTG_TRACE_ERROR_WITH_STRING( "endpoint not found; get request ignored", path.get_string().c_str() );
        return NULL;
    }

	const CValue *value = node_endpoint->get_value();
	if( !value )
	{
		const ntg_endpoint *endpoint = node_endpoint->get_endpoint();
		assert( endpoint->type == NTG_STREAM || endpoint->control_info->type == NTG_BANG );
		return NULL;
	}

    return value;
}


ntg_error_code ntg_nodelist_(ntg_server *server, const CPath &path, path_list &results )
{
    assert( server );

    ntg_node *root = ntg_server_get_root( server );
    ntg_node *parent = ntg_node_find_by_path( path, root );

    if( !parent ) 
	{
        NTG_TRACE_ERROR("parent is NULL, returning NULL");
        return NTG_ERROR;
    }

    ntg_server_get_nodelist( server_, parent, results);
	return NTG_NO_ERROR;
}


ntg_command_status ntg_save_( ntg_server *server, const CPath &path, const char *file_path  )
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

	delete[] file_path_with_suffix;

    NTG_RETURN_COMMAND_STATUS;
}


void ntg_print_state_()
{
	printf("Print State:\n");
	printf("***********:\n\n");
    ntg_print_node_state(server_,ntg_server_get_root(server_)->nodes,0);
	fflush( stdout );
}