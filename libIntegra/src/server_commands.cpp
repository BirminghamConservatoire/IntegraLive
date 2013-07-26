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



command_status ntg_set_( CServer &server, ntg_command_source cmd_source, const CPath &path, const CValue *value )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

    NTG_COMMAND_STATUS_INIT;

	/* get node from path */
	CNodeEndpoint *node_endpoint = server.find_node_endpoint_writable( path.get_string() );
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

	if( cmd_source == NTG_SOURCE_HOST && !ntg_node_is_active( *node_endpoint->get_node() ) )
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


	if( server.get_reentrance_checker().push( node_endpoint, cmd_source ) )
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
	if( ntg_should_send_set_to_host( *node_endpoint, *node_endpoint->get_node()->get_interface(), cmd_source ) ) 
	{
		server.get_bridge()->send_value( node_endpoint );
    }

    if( error_code != NTG_NO_ERROR ) 
	{
        NTG_TRACE_ERROR("error setting attribute value");
        NTG_RETURN_COMMAND_STATUS;
    }

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_set( server.get_osc_client(), cmd_source, path, node_endpoint->get_value() );
    }

	server.get_reentrance_checker().pop();

    return command_status;
}


command_status ntg_new_( CServer &server, ntg_command_source cmd_source, const GUID *module_id, string node_name, const CPath &path )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

	NTG_COMMAND_STATUS_INIT;

    CNode *parent = server.find_node_writable( path );

    /* get interface */
	const ntg_interface *interface = server.get_module_manager().get_interface_by_module_id( *module_id );
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
	node_map &sibling_map = parent ? parent->get_children_writable() : server.get_nodes_writable();
    while( sibling_map.count( node_name ) > 0 ) 
	{
        NTG_TRACE_PROGRESS_WITH_STRING( "node name is in use; appending underscore", node_name.c_str() );

        node_name += "_";
	}

	if( !ntg_validate_node_name( node_name.c_str() ) )
	{
        NTG_TRACE_ERROR_WITH_STRING( "node name contains invalid characters", node_name.c_str() );
        NTG_RETURN_ERROR_CODE( NTG_FAILED );
	}

    CNode *node = new CNode;
	node->initialize( interface, node_name, parent );
	sibling_map[ node_name ] = node;
	server.get_state_table().add( *node );

	if( ntg_interface_has_implementation( interface ) )
	{
		/* load implementation in module host */
		string patch_path = server.get_module_manager().get_patch_path( *interface );
		if( patch_path.empty() )
		{
			NTG_TRACE_ERROR( "Failed to get implementation path - cannot load module in host" );
		}
		else
		{
			server.get_bridge()->module_load( node->get_id(), patch_path.c_str() );
		}
	}

    /* set attribute defaults */
	for( const ntg_endpoint *endpoint = interface->endpoint_list; endpoint; endpoint = endpoint->next )
	{
		if( endpoint->type != NTG_CONTROL || endpoint->control_info->type != NTG_STATE )
		{
			continue;
		}

		const CNodeEndpoint *node_endpoint = node->get_node_endpoint( endpoint->name );
        assert( node_endpoint );

		ntg_set_( server, NTG_SOURCE_INITIALIZATION, node_endpoint->get_path(), endpoint->control_info->state_info->default_value );
	}

    /* handle any system class logic */
	ntg_system_class_handle_new( server, *node, cmd_source );

    NTG_TRACE_VERBOSE_WITH_STRING( "Created node", node->get_name().c_str() );

	command_status.data = node;

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
	    ntg_osc_client_send_new( server.get_osc_client(), cmd_source, module_id, node_name.c_str(), node->get_parent_path() );
	}

    return command_status;
}


command_status ntg_delete_( CServer &server, ntg_command_source cmd_source, const CPath &path )
{
    command_status command_status;
    error_code error_code = NTG_NO_ERROR;

    NTG_COMMAND_STATUS_INIT;

	CNode *node = server.find_node_writable( path );
    if( !node ) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	/* delete children */
	node_map copy_of_children( node->get_children() );
	for( node_map::iterator i = copy_of_children.begin(); i != copy_of_children.end(); i++ )
	{
		CNode *child = i->second;
		ntg_delete_( server, cmd_source, child->get_path() );
	}

	/* system class logic */
	ntg_system_class_handle_delete( server, *node, cmd_source );

	/* state tables */
	server.get_state_table().remove( *node );

	/* remove in host */
	if( ntg_interface_has_implementation( node->get_interface() ) )
	{
		server.get_bridge()->module_remove( node->get_id() );
    }

	/* remove from owning container */
	server.get_sibling_set_writable( *node ).erase( node->get_name() );

	/* finally delete the node */
	delete node;

    NTG_RETURN_COMMAND_STATUS;
}


command_status ntg_unload_orphaned_embedded_modules_( CServer &server, ntg_command_source cmd_source )
{
	command_status command_status;
	error_code error_code = NTG_NO_ERROR;

	NTG_COMMAND_STATUS_INIT;

	guid_set orphaned_embedded_modules;
	server.get_module_manager().get_orphaned_embedded_modules( server.get_nodes(), orphaned_embedded_modules );

	server.get_module_manager_writable().unload_modules( orphaned_embedded_modules );

	NTG_RETURN_COMMAND_STATUS;
}


command_status ntg_install_module_( CServer &server, ntg_command_source cmd_source, const char *file_path )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

	assert( file_path );
	NTG_TRACE_PROGRESS( file_path );

	NTG_COMMAND_STATUS_INIT

	CModuleInstallResult *module_install_result = new CModuleInstallResult;

	error_code = server.get_module_manager_writable().install_module( file_path, *module_install_result );

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


command_status ntg_install_embedded_module_( CServer &server, ntg_command_source cmd_source, const GUID *module_id )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

	assert( module_id );
	NTG_TRACE_PROGRESS( "" );

	NTG_COMMAND_STATUS_INIT

	error_code = server.get_module_manager_writable().install_embedded_module( *module_id );

	NTG_RETURN_COMMAND_STATUS
}


command_status ntg_uninstall_module_( CServer &server, ntg_command_source cmd_source, const GUID *module_id )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

	assert( module_id );
	NTG_TRACE_PROGRESS( "" );

	NTG_COMMAND_STATUS_INIT

	CModuleUninstallResult *module_uninstall_result = new CModuleUninstallResult;

	error_code = server.get_module_manager_writable().uninstall_module( *module_id, *module_uninstall_result );

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


command_status ntg_load_module_in_development_( CServer &server, ntg_command_source cmd_source, const char *file_path )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

	assert( file_path );
	NTG_TRACE_PROGRESS( file_path );

	NTG_COMMAND_STATUS_INIT

	CLoadModuleInDevelopmentResult *result = new CLoadModuleInDevelopmentResult;

	error_code = server.get_module_manager_writable().load_module_in_development( file_path, *result );

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



command_status ntg_rename_(CServer &server, ntg_command_source cmd_source, const CPath &path, const char *name )
{
    error_code error_code = NTG_NO_ERROR;
    command_status command_status;

    assert( name );

    NTG_COMMAND_STATUS_INIT;

    CNode *node = server.find_node_writable( path );
    if( !node ) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	if( !ntg_validate_node_name( name ) )
	{
        NTG_TRACE_ERROR_WITH_STRING( "node name contains invalid characters", name );
        NTG_RETURN_ERROR_CODE( NTG_ERROR );
	}

	string new_name = name;

    /* First check if node name is already taken */
	node_map &sibling_set = server.get_sibling_set_writable( *node );
    while( sibling_set.count( new_name ) > 0 ) 
	{
        NTG_TRACE_PROGRESS_WITH_STRING( "node name is in use; appending underscore", new_name.c_str() );
		new_name += "_";
	}

	string previous_name = node->get_name();

    /* remove old state table entries for node and children */
	server.get_state_table().remove( *node );

    node->rename( new_name );

	sibling_set.erase( previous_name );
	sibling_set[ new_name ] = node;

    /* add new state table entries for node and children */
	server.get_state_table().add( *node );

	ntg_system_class_handle_rename( server, *node, previous_name.c_str(), cmd_source );

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_rename( server.get_osc_client(), cmd_source, path, new_name.c_str() );
	}

    NTG_RETURN_COMMAND_STATUS;
}

command_status ntg_move_( CServer &server, ntg_command_source cmd_source, const CPath &node_path, const CPath &new_parent_path )
{
    error_code      error_code = NTG_NO_ERROR;
    command_status  command_status;

    NTG_COMMAND_STATUS_INIT;

    CNode *node = server.find_node_writable( node_path );
    if( !node ) 
	{
		NTG_TRACE_ERROR_WITH_STRING( "unable to find node given by path", node_path.get_string().c_str() );
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

    /* remove old state table entries for node and children */
	server.get_state_table().remove( *node );

	node_map &old_sibling_set = server.get_sibling_set_writable( *node );
	old_sibling_set.erase( node->get_name() );

    CNode *new_parent = server.find_node_writable( new_parent_path );
	node_map &new_sibling_set = new_parent ? new_parent->get_children_writable() : server.get_nodes_writable();
	new_sibling_set[ node->get_name() ] = node;

	node->move( new_parent );

    /* add new state table entries for node and children */
	server.get_state_table().add( *node );

	ntg_system_class_handle_move( server, *node, node_path, cmd_source );

    if( ntg_should_send_to_client( cmd_source ) ) 
	{
		ntg_osc_client_send_move( server.get_osc_client(), cmd_source, node_path, new_parent_path );
	}

    NTG_RETURN_COMMAND_STATUS;
}


command_status ntg_load_( CServer &server, ntg_command_source cmd_source, const char *file_path, const CPath &path )
{
	command_status command_status;

    assert( file_path );

	NTG_COMMAND_STATUS_INIT

    const CNode *parent = server.find_node( path );

	command_status = ntg_file_load( file_path, parent, server.get_module_manager_writable() );

	return command_status;
}


const CValue *ntg_get_( CServer &server, const CPath &path )
{
	const CNodeEndpoint *node_endpoint = server.find_node_endpoint( path.get_string() );
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


error_code ntg_nodelist_( CServer &server, const CPath &path, path_list &results )
{
    const CNode *parent = server.find_node( path );
	const node_map &nodes = parent ? parent->get_children() : server.get_nodes();

	for( node_map::const_iterator i = nodes.begin(); i != nodes.end(); i++ )
	{
		const CNode *node = i->second;

		results.push_back( node->get_path() );

		ntg_nodelist_( server, node->get_path(), results );
	}

	return NTG_NO_ERROR;
}


command_status ntg_save_( CServer &server, const CPath &path, const char *file_path  )
{
    error_code error_code;
    command_status command_status;
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

    const CNode *node = server.find_node( path );
    if( !node ) 
	{
        NTG_RETURN_ERROR_CODE( NTG_PATH_ERROR );
    }

	file_path_with_suffix = ntg_ensure_filename_has_suffix( file_path, NTG_FILE_SUFFIX );

	error_code = ntg_file_save( file_path_with_suffix, *node, server.get_module_manager() );

	delete[] file_path_with_suffix;

    NTG_RETURN_COMMAND_STATUS;
}


void ntg_print_node_state( CServer &server, const node_map &nodes, int indentation)
{
	for( node_map::const_iterator i = nodes.begin(); i != nodes.end(); i++ )
	{
		const CNode *node = i->second;

        for( int i = 0; i < indentation; i++ )
		{
            printf("  |");
		}

		const ntg_interface *interface = node->get_interface();
		char *module_id_string = ntg_guid_to_string( &interface->module_guid );
		printf("  Node: \"%s\".\t module name: %s.\t module id: %s.\t Path: %s\n", node->get_name(), interface->info->name, module_id_string, node->get_path().get_string().c_str() );
		delete[] module_id_string;

		bool has_children = !node->get_children().empty();

		const node_endpoint_map &node_endpoints = node->get_node_endpoints();
		for( node_endpoint_map::const_iterator node_endpoint_iterator = node_endpoints.begin(); node_endpoint_iterator != node_endpoints.end(); node_endpoint_iterator++ )
		{
			const CNodeEndpoint *node_endpoint = node_endpoint_iterator->second;
			const CValue *value = node_endpoint->get_value();
			if( !value ) continue;

			for( int i = 0; i < indentation; i++ )
			{
				printf("  |");
			}

			printf( has_children ? "  |" : "   ");

			string value_string = value->get_as_string();

			printf("   -Attribute:  %s = %s\n", node_endpoint->get_endpoint()->name, value_string.c_str() );
		}
		
        if( has_children )
		{
			ntg_print_node_state( server, node->get_children(), indentation + 1 );
		}
    }
}



void ntg_print_state_()
{
	printf("Print State:\n");
	printf("***********:\n\n");
	ntg_print_node_state( *server_, server_->get_nodes(), 0 );
	fflush( stdout );
}
