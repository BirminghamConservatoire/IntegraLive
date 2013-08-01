/** libIntegra multimedia module interface
 *
 * Copyright (C) 2012 Birmingham City University
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
#include <math.h>
#include <float.h>
#include <string.h>

#include "system_class_handlers.h"
#include "player_handler.h"
#include "data_directory.h"
#include "system_class_literals.h"
#include "server_commands.h"
#include "node_endpoint.h"
#include "helper.h"
#include "module_manager.h"
#include "interface_definition.h"
#include "value.h"
#include "trace.h"
#include "luascripting.h"
#include "file_helper.h"

using namespace ntg_api;
using namespace ntg_internal;

/*
typedefs
*/

typedef void (*ntg_system_class_new_handler_function)( CServer &server, const CNode &node, ntg_command_source cmd_source);
typedef void (*ntg_system_class_set_handler_function)( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source);
typedef void (*ntg_system_class_rename_handler_function)( CServer &server, const CNode &node, const char *previous_name, ntg_command_source cmd_source);
typedef void (*ntg_system_class_move_handler_function)( CServer &server, const CNode &node, const CPath &previous_path, ntg_command_source cmd_source);
typedef void (*ntg_system_class_delete_handler_function)( CServer &server, const CNode &node, ntg_command_source cmd_source);


typedef struct ntg_system_class_handler_ 
{
	/* module_guid can be null if the handler should apply to all classes */
	GUID *module_guid;

	/* attribute_name can be null if the handler is not for a set command, or if it should apply to all attributes */
	char *attribute_name;

	void *function;

	struct ntg_system_class_handler_ *next;

} ntg_system_class_handler;



/*
The following methods are helpers used by the system class endpoint handlers
*/


void ntg_envelope_update_value( CServer &server, const CNode &envelope_node )
{
	float previous_value, next_value;
	bool found_previous_tick = false, found_next_tick = false;
	int latest_previous_tick, earliest_next_tick;
	const CNodeEndpoint *start_tick_endpoint, *current_tick_endpoint, *current_value_endpoint, *control_point_tick_endpoint, *control_point_value_endpoint, *control_point_curvature_endpoint;
	int control_point_tick;
	float control_point_value;
	float previous_control_point_curvature;
	int envelope_start_tick;
	int envelope_current_tick;
	int tick_range;
	float interpolation;
	float output = 0;

	if( !ntg_node_is_active( envelope_node ) )
	{
		return;
	}

	current_value_endpoint = envelope_node.get_node_endpoint( NTG_ENDPOINT_CURRENT_VALUE);
	assert( current_value_endpoint );

	/*
	lookup envelope current tick 
	*/

	current_tick_endpoint = envelope_node.get_node_endpoint( NTG_ENDPOINT_CURRENT_TICK);
	assert( current_tick_endpoint );

	envelope_current_tick = *current_tick_endpoint->get_value();


	/*
	lookup and apply envelope start tick
	*/

	start_tick_endpoint = envelope_node.get_node_endpoint( NTG_ENDPOINT_START_TICK);
	assert( start_tick_endpoint );
	envelope_start_tick = *start_tick_endpoint->get_value();

	envelope_current_tick -= envelope_start_tick;

	/*
	iterate over control points to find ticks and values of latest previous control point and earliest next control point
	*/

	const node_map &control_points = envelope_node.get_children();
	for( node_map::const_iterator i = control_points.begin(); i != control_points.end(); i++ )
	{
		const CNode *control_point = i->second;
		control_point_tick_endpoint = control_point->get_node_endpoint( NTG_ENDPOINT_TICK );
		control_point_value_endpoint = control_point->get_node_endpoint( NTG_ENDPOINT_VALUE );

		assert( control_point_tick_endpoint );
		assert( control_point_value_endpoint );

		control_point_tick = *control_point_tick_endpoint->get_value();
		control_point_value = *control_point_value_endpoint->get_value();

		if( control_point_tick <= envelope_current_tick && ( !found_previous_tick || control_point_tick > latest_previous_tick ) )
		{
			latest_previous_tick = control_point_tick;
			previous_value = control_point_value;

			control_point_curvature_endpoint = control_point->get_node_endpoint( NTG_ENDPOINT_CURVATURE );
			assert( control_point_curvature_endpoint );

			previous_control_point_curvature = *control_point_curvature_endpoint->get_value();

			found_previous_tick = true;
		}

		if( control_point_tick > envelope_current_tick && ( !found_next_tick || control_point_tick < earliest_next_tick ) )
		{
			earliest_next_tick = control_point_tick;
			next_value = control_point_value;
			found_next_tick = true;
		}
	}

	/*
	find output value
	*/

	if( found_previous_tick )
	{
		if( found_next_tick )
		{
			/*
			between control points - perform interpolation
			*/
			tick_range = earliest_next_tick - latest_previous_tick;
			assert( tick_range > 0 );

			interpolation = (float) ( envelope_current_tick - latest_previous_tick ) / tick_range;

			/*
			apply curvature
			*/

			if( previous_control_point_curvature != 0 )
			{
				interpolation = pow( interpolation, pow( 2, -previous_control_point_curvature ) );
			}

			output = previous_value + interpolation * ( next_value - previous_value );
		}
		else
		{
			/*
			after last control point - use previous value
			*/
			output = previous_value;
		}
	}
	else
	{
		if( found_next_tick )
		{
			/*
			before first control point - use next value
			*/
			output = next_value;
		}
		else
		{
			/*
			no control points - can't find output value
			*/

			return;
		}
	}
	
	/*
	store output value if changed
	*/
	CFloatValue output_value( output );

	if( !current_value_endpoint->get_value()->is_equal( output_value ) )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, current_value_endpoint->get_path(), &output_value );
	}
}


bool ntg_node_are_all_ancestors_active( const CNode &node )
{
	const CNode *parent = node.get_parent();
	if( !parent )
	{
		return true;
	}

	const CNodeEndpoint *parent_active = parent->get_node_endpoint( NTG_ENDPOINT_ACTIVE );
	assert( parent_active );

	if( ( int ) *parent_active->get_value() == 0 )
	{
		return false;
	}
	else
	{
		return ntg_node_are_all_ancestors_active( *parent );
	}
}


void ntg_node_activate_tree(CServer &server, const CNode &node, bool activate, path_list &activated_nodes )
{
	/*
	sets 'active' endpoint on any descendants that are not containers
	If any node in ancestor chain are not active, sets descendants to not active
	If all node in ancestor chain are active, sets descendants to active

	Additionally, the function pushes 'activated_nodes' - a list of pointers to 
	nodes which were activated by the function.
	The caller can use this list to perform additional logic
	*/

	int value_i = 0;

	const CNodeEndpoint *active_endpoint = node.get_node_endpoint( NTG_ENDPOINT_ACTIVE );

	if( node.get_interface_definition().is_named_core_interface( NTG_CLASS_CONTAINER ) )
	{
		/* if node is a container, update 'activate' according to it's active flag */
		assert( active_endpoint );
		activate &= ( ( int ) *active_endpoint->get_value() != 0 );
	}
	else
	{
		/* if node is not a container, update it's active flag (if it has one) according to 'activate' */
		if( active_endpoint )
		{
			CIntegerValue value( activate ? 1 : 0 );

			if( !active_endpoint->get_value()->is_equal( value ) )
			{
				ntg_set_( server, NTG_SOURCE_SYSTEM, active_endpoint->get_path(), &value );

				if( activate )
				{
					activated_nodes.push_back( node.get_path() );
				}
			}
		}
	}

	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		ntg_node_activate_tree( server, *i->second, activate, activated_nodes );
	}
}


void ntg_container_active_handler( CServer &server, const CNode &node, bool active )
{
	path_list activated_nodes;

	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		ntg_node_activate_tree( server, *i->second, active && ntg_node_are_all_ancestors_active( node ), activated_nodes );
	}

	/* 
	Now we explicitly update some system classes which were activated by this operation.
	This needs to be done here, instead of via a normal set handler, in order to ensure that subsequent
	business logic happens after everything else has become active
	*/

	for( path_list::const_iterator i = activated_nodes.begin(); i != activated_nodes.end(); i++ )
	{
		const CPath &path = *i;
		const CNode *activated_node = server.find_node( path );
		assert( activated_node );

		if( activated_node->get_interface_definition().is_named_core_interface( NTG_CLASS_ENVELOPE ) )
		{
			ntg_envelope_update_value( server, *activated_node );
		}

		if( activated_node->get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
		{
			const CNodeEndpoint *player_tick = activated_node->get_node_endpoint( NTG_ENDPOINT_TICK );
			assert( player_tick );

			ntg_set_( server, NTG_SOURCE_SYSTEM, player_tick->get_path(), player_tick->get_value() );
		}
	}
}


void ntg_non_container_active_initializer( CServer &server, const CNode &node)
{
	/*
	sets 'active' endpoint to false if any ancestor's active endpoint is false
	*/

	const CNodeEndpoint *active_endpoint = node.get_node_endpoint( NTG_ENDPOINT_ACTIVE );
	if( !active_endpoint )
	{
		return;
	}

	if( !ntg_node_are_all_ancestors_active( node ) )
	{
		CIntegerValue value( 0 );
		ntg_set_( server, NTG_SOURCE_SYSTEM, active_endpoint->get_path(), &value );
	}
}


void ntg_player_set_state(CServer &server, const CNode &player_node, int tick, int play, int loop, int start, int end )
{
	/*
	updates player state.  ignores tick when < 0
	*/

	const CNodeEndpoint *player_tick_endpoint, *player_play_endpoint, *player_loop_endpoint, *player_start_endpoint, *player_end_endpoint;

	/* look up the player endpoints to set */
	player_tick_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_TICK );
	player_play_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_PLAY );
	player_loop_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_LOOP );
	player_start_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_START );
	player_end_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_END );

	assert( player_tick_endpoint && player_play_endpoint && player_loop_endpoint && player_start_endpoint && player_end_endpoint );

	/* 
	Set the new values.  
	Order is important here as the player will set play = false when loop == false and tick > end 
	We can prevent this from being a problem by setting tick after start & end, and setting play last
	*/

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_loop_endpoint->get_path(), &CIntegerValue( loop ) );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_start_endpoint->get_path(), &CIntegerValue( start ) );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_end_endpoint->get_path(), &CIntegerValue( play ) );

	/* don't set tick unless >= 0.  Allows calling functions to skip setting tick */
	if( tick >= 0 )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, player_tick_endpoint->get_path(), &CIntegerValue( tick ) );
	}

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_play_endpoint->get_path(), &CIntegerValue( play ) );
}


bool ntg_scene_is_selected( const CNode &scene_node )
{
	const CNode *player_node = scene_node.get_parent();
	if( !player_node || !player_node->get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
	{
		return false;
	}

	const CNodeEndpoint *scene_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_SCENE );
	assert( scene_endpoint );

	const string &scene = *scene_endpoint->get_value();

	return ( scene == scene_node.get_name() );
}


void ntg_container_update_path_of_players( CServer &server, const CNode &node )
{
	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		const CNode *child = i->second;

		if( node.get_interface_definition().is_named_core_interface( NTG_CLASS_CONTAINER ) )
		{
			/* recursively walk container tree */
			ntg_container_update_path_of_players( server, *child );
		}
		else
		{
			if( node.get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
			{
				ntg_player_handle_path_change( server, *child );
			}
		}
	}
}


void ntg_quantize_to_allowed_states( CValue &value, const value_set &allowed_states )
{
	const CValue *nearest_allowed_state = NULL;
	float distance_to_current = 0;
	float distance_to_nearest_allowed_state = 0;
	bool first = true;

	for( value_set::const_iterator i = allowed_states.begin(); i != allowed_states.end(); i++ )
	{
		const CValue *allowed_state = *i;
		if( value.get_type() != allowed_state->get_type() )
		{
			NTG_TRACE_ERROR( "Value type mismatch whilst quantizing to allowed states" );
			continue;
		}

		distance_to_current = abs( value.get_difference( *allowed_state ) );
		if( first || distance_to_current < distance_to_nearest_allowed_state )
		{
			distance_to_nearest_allowed_state = distance_to_current;
			nearest_allowed_state = allowed_state;
			first = false;
		}
	}

	if( !nearest_allowed_state )
	{
		NTG_TRACE_ERROR( "failed to quantize to allowed states - allowed states is empty" );
		return;
	}

	assert( nearest_allowed_state->get_type() == value.get_type() );

	value = *nearest_allowed_state;
}


void ntg_handle_connections( CServer &server, const CNode &search_node, const CNodeEndpoint *changed_endpoint )
{
	const CNode *parent = search_node.get_parent();

    /* recurse up the tree first, so that higher-level connections are evaluated first */
    if( parent ) 
	{
        ntg_handle_connections( server, *parent, changed_endpoint );
    }

	/* build endpoint path relative to search_node */
	string relative_endpoint_path = changed_endpoint->get_path().get_string();
	if( parent )
	{
		relative_endpoint_path = relative_endpoint_path.substr( parent->get_path().get_string().length() + 1 );
	}

    /* search amongst sibling nodes */
	const node_map &siblings = server.get_sibling_set( search_node );
	for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
	{
		const CNode *sibling = i->second;
		if( !ntg_guids_are_equal( &sibling->get_interface_definition().get_module_guid(), &server.get_system_class_data()->connection_interface_guid ) ) 
		{
			/* not a connection */
            continue;
        }

		if( !ntg_node_is_active( *sibling ) )
		{
			/* connection is not active */
			continue;
		}

		const CNodeEndpoint *source_endpoint = sibling->get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
		assert( source_endpoint );

		const string &source_endpoint_value = *source_endpoint->get_value();
		if( source_endpoint_value == relative_endpoint_path )
		{
			if( changed_endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL || !changed_endpoint->get_endpoint_definition().get_control_info()->get_can_be_source() )
			{
				NTG_TRACE_ERROR( "aborting handling of connection from endpoint which cannot be a connection source" );
				continue;
			}

			/* found a connection! */
			const CNodeEndpoint *target_endpoint = sibling->get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
			assert( target_endpoint );

			const CNodeEndpoint *destination_endpoint = server.find_node_endpoint( *target_endpoint->get_value(), parent );

			if( destination_endpoint )
			{
				/* found a destination! */

				if( destination_endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL || !destination_endpoint->get_endpoint_definition().get_control_info()->get_can_be_target() )
				{
					NTG_TRACE_ERROR( "aborting handling of connection to endpoint which cannot be a connection target" );
					continue;
				}

				CValue *converted_value;
				if( destination_endpoint->get_endpoint_definition().get_control_info()->get_type() == CControlInfo::STATEFUL )
				{
					if( changed_endpoint->get_value() )
					{
						converted_value = changed_endpoint->get_value()->transmogrify( destination_endpoint->get_value()->get_type() );

						const value_set *allowed_states = destination_endpoint->get_endpoint_definition().get_control_info()->get_state_info()->get_constraint().get_allowed_states();
						if( allowed_states )
						{
							/* if destination has set of allowed states, quantize to nearest allowed state */
							ntg_quantize_to_allowed_states( *converted_value, *allowed_states );
						}
					}
					else
					{
						/* if source is a bang, reset target to it's current value */
						converted_value = destination_endpoint->get_value()->clone();
					}
				}
				else
				{
					assert( destination_endpoint->get_endpoint_definition().get_control_info()->get_type() == CControlInfo::BANG );
					converted_value = NULL;
				}

				ntg_set_( server, NTG_SOURCE_CONNECTION, destination_endpoint->get_path(), converted_value );
				
				if( converted_value )
				{
					delete converted_value;
				}
			}
		}
    }
}


void ntg_update_connection_path_on_rename( CServer &server, const CNodeEndpoint *connection_path, const string &previous_name, const string &new_name )
{
	int previous_name_length;
	int old_connection_path_length;

	const string &old_connection_path = *connection_path->get_value();

	previous_name_length = previous_name.length();
	old_connection_path_length = old_connection_path.length();
	if( old_connection_path_length <= previous_name_length || previous_name != old_connection_path.substr( 0, previous_name_length ) )
	{
		/* connection path doesn't refer to the renamed object */
		return;
	}

	string path_after_renamed_node = old_connection_path.substr( previous_name_length );

	string new_connection_path = new_name + path_after_renamed_node;

	ntg_set_( server, NTG_SOURCE_SYSTEM, connection_path->get_path(), &CStringValue( new_connection_path ) );
}


void ntg_update_connections_on_object_rename( CServer &server, const CNode &search_node, const string &previous_name, const string &new_name )
{
	const node_map &siblings = server.get_sibling_set( search_node );

    /* search amongst sibling nodes */
	for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
	{
		const CNode *sibling = i->second;

		if( !ntg_guids_are_equal( &sibling->get_interface_definition().get_module_guid(), &server.get_system_class_data()->connection_interface_guid ) ) 
		{
			/* current is not a connection */
            continue;
        }

		const CNodeEndpoint *source_endpoint = sibling->get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
		const CNodeEndpoint *target_endpoint = sibling->get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
		assert( source_endpoint && target_endpoint );

		ntg_update_connection_path_on_rename( server, source_endpoint, previous_name, new_name );
		ntg_update_connection_path_on_rename( server, target_endpoint, previous_name, new_name );
	}
	
    /* recurse up the tree */
	const CNode *parent = search_node.get_parent();
    if( parent ) 
	{
		string previous_name_in_parent_scope = parent->get_name() + "." + previous_name;
		string new_name_in_parent_scope = parent->get_name() + "." + new_name;

        ntg_update_connections_on_object_rename( server, *parent, previous_name_in_parent_scope, new_name_in_parent_scope );
    }
}


void ntg_update_connection_path_on_move( CServer &server, const CNodeEndpoint *connection_path, const CPath &previous_path, const CPath &new_path )
{
	int previous_path_length;
	int absolute_path_length;
	int characters_after_old_path;

	const CNode *parent = connection_path->get_node().get_parent();
	const string &connection_path_string = *connection_path->get_value();

	ostringstream absolute_path_stream;
	if( parent )
	{
		absolute_path_stream << parent->get_path().get_string() << ".";
	}
	
	absolute_path_stream << connection_path_string;

	const string &absolute_path = absolute_path_stream.str();

	previous_path_length = previous_path.get_string().length();
	absolute_path_length = absolute_path.length();
	if( previous_path_length > absolute_path_length || previous_path.get_string() != absolute_path.substr( 0, previous_path_length ) )
	{
		/* connection_path isn't affected by this move */
		return;
	}

	const CPath &parent_path = connection_path->get_node().get_parent_path();
	for( int i = 0; i < parent_path.get_number_of_elements(); i++ )
	{
		if( i >= new_path.get_number_of_elements() || new_path[ i ] != parent_path[ i ] )
		{
			/* new_path can't be targetted by this connection */
			return;
		}
	}

	CPath new_relative_path;
	for( int i = parent_path.get_number_of_elements(); i < new_path.get_number_of_elements(); i++ )
	{
		new_relative_path.append_element( new_path[ i ] );
	}
	
	characters_after_old_path = absolute_path_length - previous_path_length;
	
	ostringstream new_connection_path;
	new_connection_path << new_relative_path.get_string() << absolute_path.substr( previous_path_length );

	ntg_set_( server, NTG_SOURCE_SYSTEM, connection_path->get_path(), &CStringValue( new_connection_path.str() ) );
}


void ntg_update_connections_on_object_move( CServer &server, const CNode &search_node, const CPath &previous_path, const CPath &new_path )
{
	const node_map &siblings = server.get_sibling_set( search_node );

    /* search amongst sibling nodes */
	for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
	{
		const CNode *sibling = i->second;
		if( !ntg_guids_are_equal( &sibling->get_interface_definition().get_module_guid(), &server.get_system_class_data()->connection_interface_guid ) ) 
		{
			/* current is not a connection */
            continue;
        }

		const CNodeEndpoint *source_endpoint = sibling->get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
		const CNodeEndpoint *target_endpoint = sibling->get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
		assert( source_endpoint && target_endpoint );

		ntg_update_connection_path_on_move( server, source_endpoint, previous_path, new_path );
		ntg_update_connection_path_on_move( server, target_endpoint, previous_path, new_path );
	}
	
    /* recurse up the tree */
	const CNode *parent = search_node.get_parent();
    if( parent ) 
	{
        ntg_update_connections_on_object_move( server, *parent, previous_path, new_path );
    }
}


error_code ntg_connect_in_host( CServer &server, const CNodeEndpoint &source, const CNodeEndpoint &target, bool connect )
{
	const CEndpointDefinition &source_endpoint_definition = source.get_endpoint_definition();
	const CEndpointDefinition &target_endpoint_definition = target.get_endpoint_definition();

	if( !source_endpoint_definition.is_audio_stream() || source_endpoint_definition.get_stream_info()->get_direction() != CStreamInfo::OUTPUT )
	{
		NTG_TRACE_ERROR( "trying to make incorrect connection in host - source isn't an audio output" );
		return NTG_ERROR;
	}

	if( !target_endpoint_definition.is_audio_stream() || target_endpoint_definition.get_stream_info()->get_direction() != CStreamInfo::INPUT )
	{
		NTG_TRACE_ERROR( "trying to make incorrect connection in host - target isn't an audio output" );
		return NTG_ERROR;
	}

    if( connect ) 
	{
        server.get_bridge()->module_connect( &source, &target );
    } 
	else 
	{
        server.get_bridge()->module_disconnect( &source, &target );
    }

    return NTG_NO_ERROR;
}


bool ntg_should_copy_input_file( const CValue &value, ntg_command_source cmd_source )
{
	assert( value.get_type() == CValue::STRING );

	switch( cmd_source )
	{
		case NTG_SOURCE_CONNECTION:
	    case NTG_SOURCE_SCRIPT:
	    case NTG_SOURCE_XMLRPC_API:
	    case NTG_SOURCE_C_API:
			{
			/* these are the sources for which we want to copy the file to the data directory */

			/* but we only copy the file when a path is provided, otherwise we assume it is already in the data directory */
			
			const string &path = value;
			return ( CFileHelper::extract_filename_from_path( path ) != path );
			}

		case NTG_SOURCE_INITIALIZATION:
		case NTG_SOURCE_LOAD:
		case NTG_SOURCE_SYSTEM:
			return false;		/* these sources are not external set commands - do nothing */

		case NTG_SOURCE_HOST:
			assert( false );
			return false;		/* we don't expect input file to be set by host! */

		default:
			assert( false );	/* unhandled command source value */
			return false;
	}
}


void ntg_handle_input_file( CServer &server, const CNodeEndpoint *endpoint, ntg_command_source cmd_source )
{
	assert( endpoint );
	assert( ntg_node_has_data_directory( endpoint->get_node() ) );

	string filename = CDataDirectory::copy_file_to_data_directory( *endpoint );
	if( !filename.empty() )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, endpoint->get_path(), &CStringValue( filename ) );
	}
}


/*
The following methods are executed when server set commands occur

They must all conform the correct the method signature ntg_system_class_set_handler_function, 
*/


void ntg_generic_active_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	assert( endpoint );

	if( endpoint->get_node().get_interface_definition().is_named_core_interface( NTG_CLASS_CONTAINER ) )
	{
		ntg_container_active_handler( server, endpoint->get_node(), ( int ) *endpoint->get_value() != 0 );
	}
	else
	{
		if( cmd_source == NTG_SOURCE_INITIALIZATION )
		{
			ntg_non_container_active_initializer( server, endpoint->get_node() );
		}
	}
}


void ntg_generic_data_directory_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	switch( cmd_source )
	{
		case NTG_SOURCE_INITIALIZATION:
			/* create and set data directory when the endpoint is initialized */
			{
			string data_directory = CDataDirectory::create_for_node( endpoint->get_node(), server );
			ntg_set_( server, NTG_SOURCE_SYSTEM, endpoint->get_path(), &CStringValue( data_directory ) );
			}
			break;

		case NTG_SOURCE_LOAD:
		case NTG_SOURCE_SYSTEM:
			/* these sources are not external set commands - do nothing */
			break;	

		case NTG_SOURCE_CONNECTION:
	    case NTG_SOURCE_SCRIPT:
	    case NTG_SOURCE_XMLRPC_API:
	    case NTG_SOURCE_C_API:
			/* external command is trying to reset the data directory - should delete the old one and create a new one */
			CDataDirectory::change( *previous_value, *endpoint->get_value() );
			break;		

		case NTG_SOURCE_HOST:
			/* we don't expect data directory to be set by host! */
			assert( false );
			break;				

		default:
			/* unhandled command source value */
			assert( false );	
			break;
	}
}


void ntg_script_trigger_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode &script_node = endpoint->get_node();

	const CNodeEndpoint *text_endpoint = script_node.get_node_endpoint( NTG_ENDPOINT_TEXT );
    assert( text_endpoint );

    const string &script = *text_endpoint->get_value();

    NTG_TRACE_VERBOSE_WITH_STRING( "running script...", script.c_str() );

	const CPath &parent_path = script_node.get_parent_path();
	
    char *script_output = ntg_lua_eval( parent_path, script.c_str() );
	if( script_output )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, script_node.get_node_endpoint( NTG_ENDPOINT_INFO )->get_path(), &CStringValue( script_output ) );
		delete[] script_output;
	}

    NTG_TRACE_VERBOSE("script finished");
}


void ntg_scaler_in_value_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode &scaler_node = endpoint->get_node();

	if( !ntg_node_is_active( scaler_node ) )
	{
		return;
	}

	const CNodeEndpoint *in_range_min_endpoint = scaler_node.get_node_endpoint( NTG_ENDPOINT_IN_RANGE_MIN );
	const CNodeEndpoint *in_range_max_endpoint = scaler_node.get_node_endpoint( NTG_ENDPOINT_IN_RANGE_MAX );
	const CNodeEndpoint *out_range_min_endpoint = scaler_node.get_node_endpoint( NTG_ENDPOINT_OUT_RANGE_MIN );
	const CNodeEndpoint *out_range_max_endpoint = scaler_node.get_node_endpoint( NTG_ENDPOINT_OUT_RANGE_MAX );
	const CNodeEndpoint *out_value_endpoint = scaler_node.get_node_endpoint( NTG_ENDPOINT_OUT_VALUE);
	assert( in_range_min_endpoint && in_range_max_endpoint && out_range_min_endpoint && out_range_max_endpoint && out_value_endpoint);

	assert( endpoint->get_value()->get_type() == CValue::FLOAT );
	assert( in_range_min_endpoint->get_value() && in_range_min_endpoint->get_value()->get_type() == CValue::FLOAT );
	assert( in_range_max_endpoint->get_value() && in_range_max_endpoint->get_value()->get_type() == CValue::FLOAT );
	assert( out_range_min_endpoint->get_value() && out_range_min_endpoint->get_value()->get_type() == CValue::FLOAT );
	assert( out_range_max_endpoint->get_value() && out_range_max_endpoint->get_value()->get_type() == CValue::FLOAT );

	float in_range_min = *in_range_min_endpoint->get_value();
	float in_range_max = *in_range_max_endpoint->get_value();
	float out_range_min = *out_range_min_endpoint->get_value();
	float out_range_max = *out_range_max_endpoint->get_value();

	float in_range_total = in_range_max - in_range_min;
	float out_range_total = out_range_max - out_range_min;

	if( fabs(in_range_total) < FLT_EPSILON)
	{
		/*
		Special case for input range ~= 0, to prevent division by zero errors or unusual behaviour arising from 
		floating point inaccuracy when dividing by a very tiny number.
		
		In this case setting the in_range_total to 1 will result in predictable and acceptable behaviour
		*/
		in_range_total = 1;
	}

	/*restrict to input range*/
	float scaled_value = *endpoint->get_value();
	scaled_value = MAX( scaled_value, MIN( in_range_min, in_range_max ) );
	scaled_value = MIN( scaled_value, MAX( in_range_min, in_range_max ) );

	/*perform linear interpolation*/
	scaled_value = ( scaled_value - in_range_min ) * out_range_total / in_range_total + out_range_min;

	/*store result*/
	ntg_set_( server, NTG_SOURCE_SYSTEM, out_value_endpoint->get_path(), &CFloatValue( scaled_value ) );
}


void ntg_control_point_value_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode *parent = endpoint->get_node().get_parent();
	if( !parent )
	{
		NTG_TRACE_ERROR( "control point with no parent" );
		return;
	}

	if( !parent->get_interface_definition().is_named_core_interface( NTG_CLASS_ENVELOPE ) )
	{
		NTG_TRACE_ERROR( "control point whose parent is not an envelope" );
		return;
	}

	ntg_envelope_update_value( server, *parent );
}


void ntg_control_point_tick_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode *parent =  endpoint->get_node().get_parent();
	if( !parent )
	{
		NTG_TRACE_ERROR( "control point with no parent" );
		return;
	}

	if( !parent->get_interface_definition().is_named_core_interface( NTG_CLASS_ENVELOPE ) )
	{ 
		NTG_TRACE_ERROR( "control point whose parent is not an envelope" );
		return;
	}

	ntg_envelope_update_value(server, *parent );
}


void ntg_envelope_start_tick_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_envelope_update_value(server, endpoint->get_node() );
}


void ntg_envelope_current_tick_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_envelope_update_value(server, endpoint->get_node() );
}


void ntg_player_active_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, endpoint->get_node().get_id() );
}


void ntg_player_play_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, endpoint->get_node().get_id() );
}


void ntg_player_tick_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	if( cmd_source != NTG_SOURCE_SYSTEM )
	{
		ntg_player_update(server, endpoint->get_node().get_id() );
	}
}


void ntg_player_loop_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, endpoint->get_node().get_id() );
}


void ntg_player_start_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, endpoint->get_node().get_id() );
}


void ntg_player_end_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, endpoint->get_node().get_id() );
}


void ntg_player_scene_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	/* defaults for values to copy into the player.  The logic below updates these variables */

	int tick = -1;
	int play = 0;
	int loop = 0;
	int start = -1;
	int end = -1;

	/* handle scene selection */

	string scene_name = *endpoint->get_value();

	const CNode *scene_node = endpoint->get_node().get_child( scene_name );
	if( !scene_node )	
	{
		if( !scene_name.empty() )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Player doesn't have scene", scene_name.c_str() );
		}
	}
	else
	{
		const CNodeEndpoint *scene_start_endpoint = scene_node->get_node_endpoint( NTG_ENDPOINT_START );
		const CNodeEndpoint *scene_length_endpoint = scene_node->get_node_endpoint( NTG_ENDPOINT_LENGTH );
		const CNodeEndpoint *scene_mode_endpoint = scene_node->get_node_endpoint( NTG_ENDPOINT_MODE );
		assert( scene_start_endpoint && scene_length_endpoint && scene_mode_endpoint );

		string scene_mode = *scene_mode_endpoint->get_value();

		start = *scene_start_endpoint->get_value();
		int length = *scene_length_endpoint->get_value();
		end = start + length;
		tick = start;

		if( scene_mode == NTG_SCENE_MODE_PLAY )
		{
			play = 1;
		}
		else
		{
			if( scene_mode == NTG_SCENE_MODE_LOOP )
			{
				play = 1;
				loop = 1;
			}
			else
			{
				assert( scene_mode == NTG_SCENE_MODE_HOLD );
			}
		}
	}

	ntg_player_set_state( server, endpoint->get_node(), tick, play, loop, start, end );
}


void ntg_scene_activate_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode *player_node = endpoint->get_node().get_parent();
	if( !player_node || !player_node->get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
	{
		NTG_TRACE_ERROR( "scene not inside player" );
		return;
	}

	const CNodeEndpoint *player_scene_endpoint = player_node->get_node_endpoint( NTG_ENDPOINT_SCENE );
	assert( player_scene_endpoint );

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_scene_endpoint->get_path(), &CStringValue( endpoint->get_node().get_name() ) ); 
}


void ntg_scene_mode_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode &scene_node = endpoint->get_node();

	if( !ntg_scene_is_selected( scene_node ) )
	{
		return;
	}

	const CNodeEndpoint *scene_start_endpoint = scene_node.get_node_endpoint( NTG_ENDPOINT_START );
	const CNodeEndpoint *scene_length_endpoint = scene_node.get_node_endpoint( NTG_ENDPOINT_LENGTH );
	assert( scene_start_endpoint && scene_length_endpoint );

	string scene_mode = *endpoint->get_value();
	int start = *scene_start_endpoint->get_value();
	int length = *scene_length_endpoint->get_value();
	int end = start + length;
	int tick = 0;
	int play = 0;
	int loop = 0;

	if( scene_mode == NTG_SCENE_MODE_HOLD )
	{
		tick = start;
		play = 0;
		loop = 0;
	}
	else
	{
		if( scene_mode == NTG_SCENE_MODE_LOOP )
		{
			loop = 1;
		}
		else
		{
			assert( scene_mode == NTG_SCENE_MODE_PLAY );

			loop = 0;
		}

		tick = -1;
		play = 1;
	}

	const CNode *player = scene_node.get_parent();
	if( !player || !player->get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
	{
		NTG_TRACE_ERROR( "scene not inside player" );
		return;
	}

	ntg_player_set_state( server, *player, tick, play, loop, start, end );
}


void ntg_scene_start_and_length_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode &scene_node = endpoint->get_node();

	if( !ntg_scene_is_selected( scene_node ) )
	{
		return;
	}

	const CNodeEndpoint *scene_start = scene_node.get_node_endpoint( NTG_ENDPOINT_START );
	const CNodeEndpoint *scene_length = scene_node.get_node_endpoint( NTG_ENDPOINT_LENGTH );
	const CNodeEndpoint *player_tick = scene_node.get_node_endpoint( NTG_ENDPOINT_TICK );
	const CNodeEndpoint *player_start = scene_node.get_node_endpoint( NTG_ENDPOINT_START );
	const CNodeEndpoint *player_end = scene_node.get_node_endpoint( NTG_ENDPOINT_END );
	assert( scene_start && scene_length && player_tick && player_start && player_end );

	int start = *scene_start->get_value();
	int length = *scene_length->get_value();
	int end = start + length;

	CIntegerValue player_start_value( start );
	CIntegerValue player_end_value( end );

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_tick->get_path(), &player_start_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_start->get_path(), &player_start_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_end->get_path(), &player_end_value );
}


void ntg_player_next_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode &player_node = endpoint->get_node();

	/* find selected scene start*/
	const CNodeEndpoint *scene_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_SCENE );
	const CNodeEndpoint *tick_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_TICK );
	assert( scene_endpoint && tick_endpoint );

	int player_tick = *tick_endpoint->get_value();
	
	const CNode *selected_scene = NULL;
	const CNodeEndpoint *scene_start_endpoint = NULL;

	const string &selected_scene_name = *scene_endpoint->get_value();

	if( !selected_scene_name.empty() )
	{
		selected_scene = player_node.get_child( selected_scene_name );
		if( selected_scene )
		{
			scene_start_endpoint = selected_scene->get_node_endpoint( NTG_ENDPOINT_START );
		}
	}

	/* iterate through scenes looking for next scene */
	const string *next_scene_name = NULL;
	int best_scene_start;
	int search_scene_start;

	const node_map &scenes = player_node.get_children();
	for( node_map::const_iterator i = scenes.begin(); i != scenes.end(); i++ )
	{
		const CNode *search_scene = i->second;
		if( !search_scene->get_interface_definition().is_named_core_interface( NTG_CLASS_SCENE ) )
		{
			NTG_TRACE_ERROR( "Object other than scene in player" );
			continue;
		}

		if( search_scene != selected_scene )
		{
			const CNodeEndpoint *start_endpoint = search_scene->get_node_endpoint( NTG_ENDPOINT_START );
			assert( start_endpoint );
			search_scene_start = *start_endpoint->get_value();

			if( search_scene_start >= player_tick )
			{
				if( !next_scene_name || search_scene_start < best_scene_start )
				{
					next_scene_name = &search_scene->get_name();
					best_scene_start = search_scene_start;
				}
			}
		}
	}

	if( next_scene_name )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_endpoint->get_path(), &CStringValue( *next_scene_name ) );
	}
}


void ntg_player_prev_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	const CNode &player_node = endpoint->get_node();

	/* find selected scene start*/
	const CNodeEndpoint *scene_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_SCENE );
	const CNodeEndpoint *tick_endpoint = player_node.get_node_endpoint( NTG_ENDPOINT_TICK );
	assert( scene_endpoint && tick_endpoint );

	int player_tick = *tick_endpoint->get_value();
	
	const CNode *selected_scene = NULL;
	const CNodeEndpoint *scene_start_endpoint = NULL;

	const string &selected_scene_name = *scene_endpoint->get_value();

	if( !selected_scene_name.empty() )
	{
		selected_scene = player_node.get_child( selected_scene_name );
		if( selected_scene )
		{
			scene_start_endpoint = selected_scene->get_node_endpoint( NTG_ENDPOINT_START );
		}
	}

	/* iterate through scenes looking for prev scene */
	const string *next_scene_name = NULL;
	int best_scene_start;
	int search_scene_start;

	const node_map &scenes = player_node.get_children();
	for( node_map::const_iterator i = scenes.begin(); i != scenes.end(); i++ )
	{
		const CNode *search_scene = i->second;
		if( !search_scene->get_interface_definition().is_named_core_interface( NTG_CLASS_SCENE ) )
		{
			NTG_TRACE_ERROR( "Object other than scene in player" );
			continue;
		}

		if( search_scene != selected_scene )
		{
			const CNodeEndpoint *start_endpoint = search_scene->get_node_endpoint( NTG_ENDPOINT_START );
			assert( start_endpoint );
			search_scene_start = *start_endpoint->get_value();

			if( search_scene_start < player_tick )
			{
				if( !next_scene_name || search_scene_start < best_scene_start )
				{
					next_scene_name = &search_scene->get_name();
					best_scene_start = search_scene_start;
				}
			}
		}
	}

	if( next_scene_name )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_endpoint->get_path(), &CStringValue( *next_scene_name ) );
	}
}


void ntg_connection_source_path_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	/* remove and/or add in host if needed */ 

	if( cmd_source == NTG_SOURCE_SYSTEM )
	{
		/* the connection source changed due to the connected endpoint being moved or renamed - no need to do anything in the host */
		return;
	}

	assert( endpoint );
	const CNode &connection_node = endpoint->get_node();
	const CNode *connection_owner = connection_node.get_parent();

	const CNodeEndpoint *source_path = connection_node.get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
	const CNodeEndpoint *target_path = connection_node.get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
	assert( source_path && target_path );

	const CNodeEndpoint *old_source_endpoint = server.find_node_endpoint( *previous_value, connection_owner );
	const CNodeEndpoint *new_source_endpoint = server.find_node_endpoint( *source_path->get_value(), connection_owner );
	const CNodeEndpoint *target_endpoint = server.find_node_endpoint( *target_path->get_value(), connection_owner );

	if( new_source_endpoint && new_source_endpoint->get_endpoint_definition().get_type() == CEndpointDefinition::CONTROL && !new_source_endpoint->get_endpoint_definition().get_control_info()->get_can_be_source() )
	{
		NTG_TRACE_ERROR( "Setting connection source to an endpoint which should not be a connection source!" );
	}

	if( !target_endpoint || !target_endpoint->get_endpoint_definition().is_audio_stream() )
	{
		/* early exit - wasn't an audio connection before and still isn't */
		return;
	}

	if( target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() != CStreamInfo::INPUT )
	{
		/* early exit - target isn't an input */
		return;
	}

	if( old_source_endpoint && old_source_endpoint->get_endpoint_definition().is_audio_stream() )
	{
		if( old_source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
		{
			/* remove previous connection in host */
			ntg_connect_in_host( server, *old_source_endpoint, *target_endpoint, false );
		}
	}

	if( new_source_endpoint && new_source_endpoint->get_endpoint_definition().is_audio_stream() )
	{
		if( new_source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
		{
			/* create new connection in host */
			ntg_connect_in_host( server, *new_source_endpoint, *target_endpoint, true );
		}
	}
}


void ntg_connection_target_path_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	/* remove and/or add in host if needed */ 

	if( cmd_source == NTG_SOURCE_SYSTEM )
	{
		/* the connection target changed due to the connected endpoint being moved or renamed - no need to do anything in the host */
		return;
	}

	assert( endpoint );
	const CNode &connection_node = endpoint->get_node();
	const CNode *connection_owner = connection_node.get_parent();

	const CNodeEndpoint *source_path = connection_node.get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
	const CNodeEndpoint *target_path = connection_node.get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
	assert( source_path && target_path );

	const CNodeEndpoint *source_endpoint = server.find_node_endpoint( *source_path->get_value(), connection_owner );
	const CNodeEndpoint *old_target_endpoint = server.find_node_endpoint( *previous_value, connection_owner );
	const CNodeEndpoint *new_target_endpoint = server.find_node_endpoint( *target_path->get_value(), connection_owner );

	if( new_target_endpoint && new_target_endpoint->get_endpoint_definition().get_type() == CEndpointDefinition::CONTROL && !new_target_endpoint->get_endpoint_definition().get_control_info()->get_can_be_target() )
	{
		NTG_TRACE_ERROR( "Setting connection target to an endpoint which should not be a connection target!" );
	}


	if( !source_endpoint || !source_endpoint->get_endpoint_definition().is_audio_stream() )
	{
		/* early exit - wasn't an audio connection before and still isn't */
		return;
	}

	if( source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() != CStreamInfo::OUTPUT )
	{
		/* early exit - source isn't an output */
		return;
	}

	if( old_target_endpoint && old_target_endpoint->get_endpoint_definition().is_audio_stream() )
	{
		if( old_target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
		{
			/* remove previous connection in host */
			ntg_connect_in_host( server, *source_endpoint, *old_target_endpoint, false );
		}
	}

	if( new_target_endpoint && new_target_endpoint->get_endpoint_definition().is_audio_stream() )
	{
		if( new_target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
		{
			/* create new connection in host */
			ntg_connect_in_host( server, *source_endpoint, *new_target_endpoint, true );
		}
	}
}


void ntg_generic_set_handler( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	if( endpoint->get_endpoint_definition().is_input_file() && ntg_should_copy_input_file( *endpoint->get_value(), cmd_source ) )
	{
		ntg_handle_input_file( server, endpoint, cmd_source );
	}

	switch( cmd_source )
	{
		case NTG_SOURCE_INITIALIZATION:
		case NTG_SOURCE_LOAD:
			break;

		default:
			ntg_handle_connections( server, endpoint->get_node(), endpoint );
	}
}


/*
The following methods are executed when server rename commands occur

They must all conform the correct the method signature ntg_system_class_rename_handler_function, 
*/


void ntg_container_rename_handler(CServer &server, const CNode &node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_container_update_path_of_players( server, node );
}


void ntg_player_rename_handler( CServer &server, const CNode &node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_player_handle_path_change( server, node );
}


void ntg_scene_rename_handler( CServer &server, const CNode &node, const char *previous_name, ntg_command_source cmd_source )
{
	/* if this is the selected scene, need to update the player's scene endpoint */

	const CNode *player = node.get_parent();
	if( !player || !player->get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
	{
		NTG_TRACE_ERROR( "scene not in a player" );
		return;
	}

	const CNodeEndpoint *scene_endpoint = player->get_node_endpoint( NTG_ENDPOINT_SCENE );
	assert( scene_endpoint );

	const string &scene_value = *scene_endpoint->get_value();
	if( scene_value == previous_name )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_endpoint->get_path(), &CStringValue( node.get_name() ) );
	}
}


void ntg_generic_rename_handler( CServer &server, const CNode &node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_update_connections_on_object_rename( server, node, previous_name, node.get_name() );
}



/*
The following methods are executed when server move commands occur

They must all conform the correct the method signature ntg_system_class_move_handler_function, 
*/


void ntg_container_move_handler( CServer &server, const CNode &node, const CPath &previous_path, ntg_command_source cmd_source )
{
	ntg_container_update_path_of_players( server, node );
}


void ntg_player_move_handler( CServer &server, const CNode &node, const CPath &previous_path, ntg_command_source cmd_source )
{
	ntg_player_handle_path_change( server, node );
}


void ntg_generic_move_handler( CServer &server, const CNode &node, const CPath &previous_path, ntg_command_source cmd_source )
{
	ntg_update_connections_on_object_move( server, node, previous_path, node.get_path() );
}



/*
The following methods are executed when server new commands occur

They must all conform the correct the method signature ntg_system_class_new_handler_function, 
*/

void ntg_generic_new_handler( CServer &server, const CNode &new_node, ntg_command_source cmd_source )
{
	/* add connections in host if needed */ 

	for( const CNode *ancestor = &new_node; ancestor; ancestor = ancestor->get_parent() )
	{
		const node_map &siblings = server.get_sibling_set( *ancestor );
		for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
		{
			const CNode *sibling = i->second;

			if( sibling != ancestor && ntg_guids_are_equal( &sibling->get_interface_definition().get_module_guid(), &server.get_system_class_data()->connection_interface_guid ) ) 
			{
				/* found a connection which might target the new node */

				const CNodeEndpoint *source_path = sibling->get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
				const CNodeEndpoint *target_path = sibling->get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
				assert( source_path && target_path );

				const CNodeEndpoint *source_endpoint = server.find_node_endpoint( *source_path->get_value(), ancestor->get_parent() );
				const CNodeEndpoint *target_endpoint = server.find_node_endpoint( *target_path->get_value(), ancestor->get_parent() );
	
				if( source_endpoint && target_endpoint )
				{
					if( source_endpoint->get_node().get_id() == new_node.get_id() || target_endpoint->get_node().get_id() == new_node.get_id() )
					{
						if( source_endpoint->get_endpoint_definition().is_audio_stream() && source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
						{
							if( target_endpoint->get_endpoint_definition().is_audio_stream() && target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
							{
								/* create connection in host */
								ntg_connect_in_host( server, *source_endpoint, *target_endpoint, true );
							}
						}
					}
				}
			}
		}
	}
}

/*
The following methods are executed when server delete commands occur

They must all conform the correct the method signature ntg_system_class_delete_handler_function, 
*/


void ntg_container_delete_handler( CServer &server, const CNode &node, ntg_command_source cmd_source )
{
	/* recursively handle deletion of child nodes */

	const node_map &children = node.get_children();
	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		ntg_system_class_handle_delete( server, *i->second, cmd_source );
	}
}


void ntg_player_delete_handler( CServer &server, const CNode &node, ntg_command_source cmd_source )
{
	ntg_player_handle_delete( server, node );
}


void ntg_scene_delete_handler( CServer &server, const CNode &node, ntg_command_source cmd_source )
{
	/* if this is the selected scene, need to clear the player's scene endpoint */

	const CNode *player = node.get_parent();;
	if( !player || !player->get_interface_definition().is_named_core_interface( NTG_CLASS_PLAYER ) )
	{
		NTG_TRACE_ERROR( "parent of deleted scene is not a player!" );
		return;
	}

	const CNodeEndpoint *scene_endpoint = player->get_node_endpoint( NTG_ENDPOINT_SCENE );
	assert( scene_endpoint );

	const string &scene_value = *scene_endpoint->get_value();
	if( scene_value == node.get_name() ) 
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_endpoint->get_path(), &CStringValue( "" ) );
	}
}


void ntg_connection_delete_handler( CServer &server, const CNode &node, ntg_command_source cmd_source )
{
	/* remove in host if needed */ 
	const CNode *connection_owner = node.get_parent();

	const CNodeEndpoint *source_path = node.get_node_endpoint( NTG_ENDPOINT_SOURCE_PATH );
	const CNodeEndpoint *target_path = node.get_node_endpoint( NTG_ENDPOINT_TARGET_PATH );
	assert( source_path && target_path );

	const CNodeEndpoint *source_endpoint = server.find_node_endpoint( *source_path->get_value(), connection_owner );
	const CNodeEndpoint *target_endpoint = server.find_node_endpoint( *target_path->get_value(), connection_owner );
	
	if( source_endpoint && source_endpoint->get_endpoint_definition().is_audio_stream() && source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
	{
		if( target_endpoint && target_endpoint->get_endpoint_definition().is_audio_stream() && target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
		{
			/* remove connection in host */
			ntg_connect_in_host( server, *source_endpoint, *target_endpoint, false );
		}
	}
}


/*
The following methods perform housekeeping and external interface for system class handlers
*/


void ntg_system_class_handlers_add( ntg_system_class_handler **list_head, const CServer &server, const char *class_name, const char *attribute_name, void * function )
{
	assert( list_head );
	assert( function );

	const CInterfaceDefinition *interface_definition = NULL;

	if( class_name )
	{
		interface_definition = server.get_module_manager().get_core_interface_by_name( class_name );
		if( !interface_definition )
		{
			NTG_TRACE_ERROR_WITH_STRING("failed to lookup into for core class", class_name);
			return;
		}

		if( !interface_definition->is_core_interface() )
		{
			NTG_TRACE_ERROR_WITH_STRING("attempt to add system class handler for non-core class", class_name);
			return;
		}

		assert( interface_definition->get_interface_info().get_name() == class_name );
	}
		
	ntg_system_class_handler *handler = new ntg_system_class_handler;
	
	if( interface_definition )
	{
		handler->module_guid = new GUID;
		*handler->module_guid = interface_definition->get_module_guid();
	}
	else
	{
		handler->module_guid = NULL;
	}

	if( attribute_name )
	{
		handler->attribute_name = ntg_strdup( attribute_name );
	}
	else
	{
		handler->attribute_name = NULL;
	}

	handler->function = function;

	handler->next = *list_head;

	*list_head = handler;
}


ntg_system_class_handler *ntg_new_handlers_create( const CServer &server )
{
	ntg_system_class_handler *new_handlers = NULL;

	NTG_TRACE_PROGRESS( "creating new handlers" );

	ntg_system_class_handlers_add( &new_handlers, server, NULL, NULL, ntg_generic_new_handler );

	return new_handlers;
}


ntg_system_class_handler *ntg_set_handlers_create( const CServer &server )
{
	ntg_system_class_handler *set_handlers = NULL;

	NTG_TRACE_PROGRESS("creating set handlers");

	ntg_system_class_handlers_add( &set_handlers, server, NULL, NULL, ntg_generic_set_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NULL, NTG_ENDPOINT_ACTIVE, ntg_generic_active_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NULL, NTG_ENDPOINT_DATA_DIRECTORY, ntg_generic_data_directory_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCRIPT, NTG_ENDPOINT_TRIGGER, ntg_script_trigger_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCALER, NTG_ENDPOINT_IN_VALUE, ntg_scaler_in_value_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONTROL_POINT, NTG_ENDPOINT_TICK, ntg_control_point_tick_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONTROL_POINT, NTG_ENDPOINT_VALUE, ntg_control_point_value_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_ENVELOPE, NTG_ENDPOINT_START_TICK, ntg_envelope_start_tick_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_ENVELOPE, NTG_ENDPOINT_CURRENT_TICK, ntg_envelope_current_tick_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_ACTIVE, ntg_player_active_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_PLAY, ntg_player_play_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_TICK, ntg_player_tick_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_LOOP, ntg_player_loop_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_START, ntg_player_start_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_END, ntg_player_end_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_SCENE, ntg_player_scene_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_NEXT, ntg_player_next_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ENDPOINT_PREV, ntg_player_prev_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ENDPOINT_ACTIVATE, ntg_scene_activate_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ENDPOINT_MODE, ntg_scene_mode_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ENDPOINT_START, ntg_scene_start_and_length_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ENDPOINT_LENGTH, ntg_scene_start_and_length_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONNECTION, NTG_ENDPOINT_SOURCE_PATH, ntg_connection_source_path_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONNECTION, NTG_ENDPOINT_TARGET_PATH, ntg_connection_target_path_handler );

	return set_handlers;
}


ntg_system_class_handler *ntg_rename_handlers_create( const CServer &server )
{
	ntg_system_class_handler *rename_handlers = NULL;

	NTG_TRACE_PROGRESS("creating rename handlers");

	ntg_system_class_handlers_add( &rename_handlers, server, NTG_CLASS_CONTAINER, NULL, ntg_container_rename_handler );
	ntg_system_class_handlers_add( &rename_handlers, server, NTG_CLASS_PLAYER, NULL, ntg_player_rename_handler );
	ntg_system_class_handlers_add( &rename_handlers, server, NTG_CLASS_SCENE, NULL, ntg_scene_rename_handler );
	ntg_system_class_handlers_add( &rename_handlers, server, NULL, NULL, ntg_generic_rename_handler );

	return rename_handlers;
}


ntg_system_class_handler *ntg_move_handlers_create( const CServer &server )
{
	ntg_system_class_handler *move_handlers = NULL;

	NTG_TRACE_PROGRESS("creating move handlers");

	ntg_system_class_handlers_add( &move_handlers, server, NTG_CLASS_CONTAINER, NULL, ntg_container_move_handler );
	ntg_system_class_handlers_add( &move_handlers, server, NTG_CLASS_PLAYER, NULL, ntg_player_move_handler );
	ntg_system_class_handlers_add( &move_handlers, server, NULL, NULL, ntg_generic_move_handler );

	return move_handlers;
}


ntg_system_class_handler *ntg_delete_handlers_create( const CServer &server )
{
	ntg_system_class_handler *delete_handlers = NULL;

	NTG_TRACE_PROGRESS("creating delete handlers");

	ntg_system_class_handlers_add( &delete_handlers, server, NTG_CLASS_PLAYER, NULL, ntg_player_delete_handler );
	ntg_system_class_handlers_add( &delete_handlers, server, NTG_CLASS_SCENE, NULL, ntg_scene_delete_handler );
	ntg_system_class_handlers_add( &delete_handlers, server, NTG_CLASS_CONTAINER, NULL, ntg_container_delete_handler );
	ntg_system_class_handlers_add( &delete_handlers, server, NTG_CLASS_CONNECTION, NULL, ntg_connection_delete_handler );

	return delete_handlers;
}


void ntg_system_class_handlers_free( ntg_system_class_handler *handlers )
{
	ntg_system_class_handler *next_handler = NULL;

    NTG_TRACE_PROGRESS("freeing system class handlers");

	while( handlers )
	{
		next_handler = handlers->next;

		if( handlers->module_guid )
		{
			delete handlers->module_guid;
		}

		if( handlers->attribute_name )
		{
			delete[] handlers->attribute_name;
		}

		delete handlers;

		handlers = next_handler;		
	}
}


void ntg_system_class_handlers_initialize( CServer &server )
{
	ntg_system_class_data *system_class_data = new ntg_system_class_data;

	system_class_data->new_handlers = ntg_new_handlers_create( server );
	system_class_data->set_handlers = ntg_set_handlers_create( server );
	system_class_data->rename_handlers = ntg_rename_handlers_create( server );
	system_class_data->move_handlers = ntg_move_handlers_create( server );
	system_class_data->delete_handlers = ntg_delete_handlers_create( server );

	const CInterfaceDefinition *connection_interface = server.get_module_manager().get_core_interface_by_name( NTG_CLASS_CONNECTION );
	if( connection_interface )
	{
		system_class_data->connection_interface_guid = connection_interface->get_module_guid();
	}
	else
	{
		NTG_TRACE_ERROR( "failed to look up class info for " NTG_CLASS_CONNECTION );
		ntg_guid_set_null( &system_class_data->connection_interface_guid );
	}

	server.set_system_class_data( system_class_data );

	ntg_player_initialize( server );
}


void ntg_system_class_handlers_shutdown( CServer &server )
{
	ntg_player_free( server );

	ntg_system_class_handlers_free( server.get_system_class_data()->new_handlers );
	ntg_system_class_handlers_free( server.get_system_class_data()->set_handlers );
	ntg_system_class_handlers_free( server.get_system_class_data()->rename_handlers );
	ntg_system_class_handlers_free( server.get_system_class_data()->move_handlers );
	ntg_system_class_handlers_free( server.get_system_class_data()->delete_handlers );

	delete server.get_system_class_data();
}


void ntg_system_class_handle_new( CServer &server, const CNode &node, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_new_handler_function function = NULL;

	for( handler = server.get_system_class_data()->new_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node.get_interface_definition().get_module_guid() ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_new_handler_function ) handler->function;
		function( server, node, cmd_source );
	}
}


void ntg_system_class_handle_set( CServer &server, const CNodeEndpoint *endpoint, const CValue *previous_value, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_set_handler_function function = NULL;

	for( handler = server.get_system_class_data()->set_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &endpoint->get_node().get_interface_definition().get_module_guid() ) )
		{
			continue;
		}

		if( handler->attribute_name && endpoint->get_endpoint_definition().get_name() != handler->attribute_name )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_set_handler_function ) handler->function;
		function( server, endpoint, previous_value, cmd_source );
	}
}


void ntg_system_class_handle_rename( CServer &server, const CNode &node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_rename_handler_function function = NULL;

	for( handler = server.get_system_class_data()->rename_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node.get_interface_definition().get_module_guid() ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_rename_handler_function ) handler->function;
		function( server, node, previous_name, cmd_source );
	}
}


void ntg_system_class_handle_move( CServer &server, const CNode &node, const CPath &previous_path, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_move_handler_function function = NULL;

	for( handler = server.get_system_class_data()->move_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node.get_interface_definition().get_module_guid() ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_move_handler_function ) handler->function;
		function( server, node, previous_path, cmd_source );
	}
}


void ntg_system_class_handle_delete( CServer &server, const CNode &node, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_delete_handler_function function = NULL;

	for( handler = server.get_system_class_data()->delete_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node.get_interface_definition().get_module_guid() ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_delete_handler_function ) handler->function;
		function( server, node, cmd_source );
	}
}


bool ntg_node_is_active( const CNode &node )
{
	const CNodeEndpoint *active_endpoint = node.get_node_endpoint( NTG_ENDPOINT_ACTIVE );
	if( active_endpoint )
	{
		int active = *active_endpoint->get_value();
		return ( active != 0 );
	}
	else
	{
		return true;
	}
}


bool ntg_node_has_data_directory( const CNode &node )
{
	return ( node.get_node_endpoint( NTG_ENDPOINT_DATA_DIRECTORY ) != NULL );
}


const string *ntg_node_get_data_directory( const CNode &node )
{
	const CNodeEndpoint *data_directory = node.get_node_endpoint( NTG_ENDPOINT_DATA_DIRECTORY );
	if( !data_directory )
	{
		return NULL;
	}

	const string &value = *data_directory->get_value();
	return &value;
}

