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


#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#include "platform_specifics.h"

#include <assert.h>
#include <math.h>
#include <float.h>
#include <string.h>

#include "system_class_handlers.h"
#include "player_handler.h"
#include "data_directory.h"
#include "system_class_literals.h"
#include "reentrance_checker.h"
#include "server_commands.h"
#include "command.h"
#include "memory.h"
#include "helper.h"
#include "module_manager.h"
#include "interface.h"
#include "list.h"
#include "value.h"
#include "trace.h"


/*
typedefs
*/

typedef void (*ntg_system_class_new_handler_function)(ntg_server *server, const ntg_node *node, ntg_command_source cmd_source);
typedef void (*ntg_system_class_set_handler_function)(ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source);
typedef void (*ntg_system_class_rename_handler_function)(ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source);
typedef void (*ntg_system_class_move_handler_function)(ntg_server *server, const ntg_node *node, const ntg_path *previous_path, ntg_command_source cmd_source);
typedef void (*ntg_system_class_delete_handler_function)(ntg_server *server, const ntg_node *node, ntg_command_source cmd_source);

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
The following methods are helpers used by the system class attribute handlers
*/


void ntg_envelope_update_value(ntg_server *server, const ntg_node *envelope_node)
{
	float previous_value, next_value;
	bool found_previous_tick = false, found_next_tick = false;
	int latest_previous_tick, earliest_next_tick;
	const ntg_node_attribute *start_tick_attribute, *current_tick_attribute, *current_value_attribute, *control_point_tick_attribute, *control_point_value_attribute, *control_point_curvature_attribute;
	int control_point_tick;
	float control_point_value;
	float previous_control_point_curvature;
	int envelope_start_tick;
	int envelope_current_tick;
	int tick_range;
	float interpolation;
	ntg_node *control_point_iterator;
	float output = 0;
	ntg_value *output_value;

	assert( server );
	assert( envelope_node );

	if( !ntg_node_is_active( envelope_node ) )
	{
		return;
	}

	current_value_attribute = ntg_find_attribute(envelope_node, NTG_ATTRIBUTE_CURRENT_VALUE);
	assert( current_value_attribute );

	/*
	lookup envelope current tick 
	*/

	current_tick_attribute = ntg_find_attribute(envelope_node, NTG_ATTRIBUTE_CURRENT_TICK);
	assert( current_tick_attribute );

	envelope_current_tick = ntg_value_get_int( current_tick_attribute->value );


	/*
	lookup and apply envelope start tick
	*/

	start_tick_attribute = ntg_find_attribute(envelope_node, NTG_ATTRIBUTE_START_TICK);
	assert( start_tick_attribute );
	envelope_start_tick = ntg_value_get_int( start_tick_attribute->value );

	envelope_current_tick -= envelope_start_tick;

	/*
	iterate over control points to find ticks and values of latest previous control point and earliest next control point
	*/

	control_point_iterator = envelope_node->nodes;
	while( control_point_iterator )
	{
		control_point_tick_attribute = ntg_find_attribute( control_point_iterator, NTG_ATTRIBUTE_TICK );
		control_point_value_attribute = ntg_find_attribute( control_point_iterator, NTG_ATTRIBUTE_VALUE );

		assert( control_point_tick_attribute );
		assert( control_point_value_attribute );

		control_point_tick = ntg_value_get_int( control_point_tick_attribute->value );
		control_point_value = ntg_value_get_float( control_point_value_attribute->value );

		if( control_point_tick <= envelope_current_tick && ( !found_previous_tick || control_point_tick > latest_previous_tick ) )
		{
			latest_previous_tick = control_point_tick;
			previous_value = control_point_value;

			control_point_curvature_attribute = ntg_find_attribute( control_point_iterator, NTG_ATTRIBUTE_CURVATURE );
			assert( control_point_curvature_attribute );

			previous_control_point_curvature = ntg_value_get_float( control_point_curvature_attribute->value );

			found_previous_tick = true;
		}

		if( control_point_tick > envelope_current_tick && ( !found_next_tick || control_point_tick < earliest_next_tick ) )
		{
			earliest_next_tick = control_point_tick;
			next_value = control_point_value;
			found_next_tick = true;
		}

		control_point_iterator = control_point_iterator->next;
		if( control_point_iterator == envelope_node->nodes )
		{
			break;
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
	output_value = ntg_value_new( NTG_FLOAT, &output );

	if( ntg_value_compare( current_value_attribute->value, output_value ) != NTG_NO_ERROR )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, current_value_attribute->path, output_value );
		ntg_value_free(output_value);
	}
}


bool ntg_node_are_all_ancestors_active( const ntg_node *node )
{
	const ntg_node_attribute *parent_active = NULL;

	assert( node );

	if( node->parent && !ntg_node_is_root( node->parent ) )
	{
		parent_active = ntg_find_attribute( node->parent, NTG_ATTRIBUTE_ACTIVE );
		assert( parent_active );

		if( ntg_value_get_int( parent_active->value ) == 0 )
		{
			return false;
		}
		else
		{
			return ntg_node_are_all_ancestors_active( node->parent );
		}
	}
	else
	{
		return true;
	}
}


void ntg_node_activate_tree(ntg_server *server, const ntg_node *node, bool activate, ntg_list *activated_nodes )
{
	/*
	sets 'active' attribute on any descendants that are not containers
	If any node in ancestor chain are not active, sets descendants to not active
	If all node in ancestor chain are active, sets descendants to active

	Additionally, the function pushes 'activated_nodes' - a list of pointers to 
	nodes which were activated by the function.
	The caller can use this list to perform additional logic
	*/

	const ntg_node_attribute *active_attribute = NULL;
	ntg_node *child = NULL;
	ntg_value *value = NULL;
	int value_i = 0;

	assert( server );
	assert( node );
	assert( activated_nodes );

	if( ntg_interface_is_core_name_match( node->interface, NTG_CLASS_CONTAINER ) )
	{
		/* if node is a container, update 'activate' according to it's active flag */
		active_attribute = ntg_find_attribute( node, NTG_ATTRIBUTE_ACTIVE );
		assert( active_attribute );
		activate &= ( ntg_value_get_int( active_attribute->value ) != 0 );
	}
	else
	{
		/* if node is not a container, update it's active flag (if it has one) according to 'activate' */
		active_attribute = ntg_find_attribute( node, NTG_ATTRIBUTE_ACTIVE );
		if( active_attribute )
		{
			value_i = activate ? 1 : 0;
			value = ntg_value_new( NTG_INTEGER, &value_i );

			if( ntg_value_compare( active_attribute->value, value ) != NTG_NO_ERROR )
			{
				ntg_set_( server, NTG_SOURCE_SYSTEM, active_attribute->path, value );

				if( activate )
				{
					ntg_list_push_node( activated_nodes, node->path );
				}
			}

			ntg_value_free( value );
		}
	}

	/* walk subtree */ 
	child = node->nodes;
	if( child )
	{
		do{
			ntg_node_activate_tree( server, child, activate, activated_nodes );

			child = child->next;

		} while(child != node->nodes);
	}
}


void ntg_container_active_handler( ntg_server *server, const ntg_node *node, bool active )
{
	const ntg_node *child = NULL;
	ntg_list *activated_nodes = ntg_list_new( NTG_LIST_NODES );
	int i;

	assert( server );
	assert( node );

	child = node->nodes;
	if( child )
	{
		do{
			ntg_node_activate_tree( server, child, active && ntg_node_are_all_ancestors_active( node ), activated_nodes );

			child = child->next;

		} while(child != node->nodes);
	}

	/* 
	Now we explicitly update some system classes which were activated by this operation.
	This needs to be done here, instead of via a normal set handler, in order to ensure that subsequent
	business logic happens after	everything else has become active
	*/

	for( i = 0; i < activated_nodes->n_elems; i++ )
	{
		const ntg_path *path = ( ( ntg_path ** ) activated_nodes->elems )[ i ];
		const ntg_node *activated_node = ntg_node_find_by_path( path, server->root );
		assert( activated_node );

		if( ntg_interface_is_core_name_match( activated_node->interface, NTG_CLASS_ENVELOPE ) )
		{
			ntg_envelope_update_value( server, activated_node );
		}

		if( ntg_interface_is_core_name_match( activated_node->interface, NTG_CLASS_PLAYER ) )
		{
			const ntg_node_attribute *player_tick = ntg_find_attribute( activated_node, NTG_ATTRIBUTE_TICK );
			assert( player_tick );

			ntg_set_( server, NTG_SOURCE_SYSTEM, player_tick->path, player_tick->value );
		}
	}

	ntg_list_free( activated_nodes );
}


void ntg_non_container_active_initializer( ntg_server *server, const ntg_node * node)
{
	/*
	sets 'active' attribute to false if node is leaf and any ancestor's active attribute is false
	*/

	const ntg_node_attribute *active_attribute = NULL;
	ntg_value *value = NULL;
	int value_i = 0;

	assert( server );
	assert( node );

	if( !node->nodes ) 
	{
		/* node is not a leaf */
		return;
	}
	
	active_attribute = ntg_find_attribute( node, NTG_ATTRIBUTE_ACTIVE );
	assert( active_attribute );

	if( !ntg_node_are_all_ancestors_active( node ) )
	{
		value = ntg_value_new( NTG_INTEGER, &value_i );
		ntg_set_( server, NTG_SOURCE_SYSTEM, active_attribute->path, value );
		ntg_value_free( value );
	}
}


void ntg_player_set_state(ntg_server *server, const ntg_node *player_node, int tick, int play, int loop, int start, int end )
{
	/*
	updates player state.  ignores tick when < 0
	*/

	const ntg_node_attribute *player_tick_attribute, *player_play_attribute, *player_loop_attribute, *player_start_attribute, *player_end_attribute;
	ntg_value *player_tick_value, *player_play_value, *player_loop_value, *player_start_value, *player_end_value;

	/* look up the player attributes to set */
	player_tick_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_TICK );
	player_play_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_PLAY );
	player_loop_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_LOOP );
	player_start_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_START );
	player_end_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_END );

	assert( player_tick_attribute && player_play_attribute && player_loop_attribute && player_start_attribute && player_end_attribute );

	/* create the new values */

	/* don't set tick unless >= 0.  Allows calling functions to skip setting tick */
	player_tick_value = ( tick >= 0 ) ? ntg_value_new( NTG_INTEGER, &tick ) : NULL;	
	player_play_value = ntg_value_new( NTG_INTEGER, &play );
	player_loop_value = ntg_value_new( NTG_INTEGER, &loop );
	player_start_value = ntg_value_new( NTG_INTEGER, &start );
	player_end_value = ntg_value_new( NTG_INTEGER, &end );

	/* 
	Set the new values.  
	Order is important here as the player will set play = false when loop == false and tick > end 
	We can prevent this from being a problem by setting tick after start & end, and setting play last
	*/

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_loop_attribute->path, player_loop_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_start_attribute->path, player_start_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_end_attribute->path, player_end_value );

	if( player_tick_value )
	{
		ntg_set_( server, NTG_SOURCE_SYSTEM, player_tick_attribute->path, player_tick_value );
	}

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_play_attribute->path, player_play_value );

	/* free the new values */

	if( player_tick_value )
	{
		ntg_value_free( player_tick_value );
	}

	ntg_value_free( player_play_value );
	ntg_value_free( player_loop_value );
	ntg_value_free( player_start_value );
	ntg_value_free( player_end_value );
}


bool ntg_scene_is_selected( const ntg_node *scene_node )
{
	ntg_node *player_node;
	const ntg_node_attribute *scene_attribute;

	player_node = scene_node->parent;
	scene_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_SCENE );
	assert( scene_attribute );

	return ( strcmp( ntg_value_get_string( scene_attribute->value ), scene_node->name ) == 0 );
}


void ntg_container_update_path_of_players( ntg_server *server, const ntg_node *node )
{
	ntg_node *node_iterator = NULL;

	node_iterator = node->nodes;
	if( !node_iterator )
	{
		return;
	}

	do
	{
		if( ntg_interface_is_core_name_match( node->interface, NTG_CLASS_CONTAINER ) )
		{
			/* recursively walk container tree */
			ntg_container_update_path_of_players( server, node_iterator );
		}
		else
		{
			if( ntg_interface_is_core_name_match( node->interface, NTG_CLASS_PLAYER ) )
			{
				ntg_player_handle_path_change( server, node_iterator );
			}
		}

		node_iterator = node_iterator->next;
	}
	while( node_iterator != node->nodes );
}


void ntg_quantize_to_allowed_states( ntg_value *value, const ntg_allowed_state *allowed_states )
{
	const ntg_allowed_state *iterator;
	const ntg_value *nearest_allowed_state = NULL;
	float distance_to_current = 0;
	float distance_to_nearest_allowed_state = 0;
	bool first = true;

	assert( allowed_states );

	for( iterator = allowed_states; iterator; iterator = iterator->next )
	{
		if( value->type != iterator->value->type )
		{
			NTG_TRACE_ERROR( "Value type mismatch whilst quantizing to allowed states" );
			continue;
		}

		distance_to_current = abs( ntg_value_get_difference( value, iterator->value ) );
		if( first )
		{
			distance_to_nearest_allowed_state = distance_to_current;
			nearest_allowed_state = iterator->value;
			first = false;
		}
		else
		{
			if( distance_to_current < distance_to_nearest_allowed_state )
			{
				distance_to_nearest_allowed_state = distance_to_current;
				nearest_allowed_state = iterator->value;
			}
		}
	}

	if( !nearest_allowed_state )
	{
		NTG_TRACE_ERROR( "failed to quantize to allowed states" );
	}

	assert( nearest_allowed_state->type == value->type );

	ntg_value_copy( value, nearest_allowed_state );
}


void ntg_handle_connections( ntg_server *server, const ntg_node *search_node, const ntg_node_attribute *changed_attribute )
{
    const ntg_node *current;
    const ntg_node *parent;
	const char *relative_attribute_path;
    const ntg_node_attribute *source_attribute, *target_attribute;
	const ntg_node_attribute *destination_attribute;
	ntg_value *converted_value;

	parent = search_node->parent;

    /* recurse up the tree first, so that higher-level connections are evaluated first */
    if( parent != ntg_server_get_root( server ) ) 
	{
        ntg_handle_connections( server, parent, changed_attribute );
    }

	/* build attribute path relative to search_node */
	relative_attribute_path = changed_attribute->path->string;
	if( parent != ntg_server_get_root( server ) )
	{
		relative_attribute_path += ( strlen( parent->path->string ) + 1 );
	}


    /* search amongst sibling nodes */
    for( current = search_node->next; current != search_node; current = current->next )
	{
		if( !ntg_guids_are_equal( &current->interface->module_guid, &server->system_class_data->connection_interface_guid ) ) 
		{
			/* current is not a connection */
            continue;
        }

		if( !ntg_node_is_active( current ) )
		{
			/* connection is not active */
			continue;
		}

		source_attribute = ntg_find_attribute( current, NTG_ATTRIBUTE_SOURCE_PATH );
		assert( source_attribute );

		if( strcmp( ntg_value_get_string( source_attribute->value ), relative_attribute_path ) == 0 )
		{
			if( changed_attribute->endpoint->type != NTG_CONTROL || !changed_attribute->endpoint->control_info->can_be_source )
			{
				NTG_TRACE_ERROR( "aborting handling of connection from endpoint which cannot be a connection source" );
				continue;
			}

			/* found a connection! */
			target_attribute = ntg_find_attribute( current, NTG_ATTRIBUTE_TARGET_PATH );
			assert( target_attribute );

			destination_attribute = ntg_server_resolve_relative_path( server, search_node->parent, ntg_value_get_string( target_attribute->value ) );

			if( destination_attribute )
			{
				/* found a destination! */

				if( destination_attribute->endpoint->type != NTG_CONTROL || !destination_attribute->endpoint->control_info->can_be_target )
				{
					NTG_TRACE_ERROR( "aborting handling of connection to endpoint which cannot be a connection target" );
					continue;
				}

				if( destination_attribute->endpoint->control_info->type == NTG_STATE )
				{
					if( changed_attribute->value )
					{
						converted_value = ntg_value_change_type( changed_attribute->value, destination_attribute->value->type );

						if( destination_attribute->endpoint->control_info->state_info->constraint.allowed_states )
						{
							/* if destination has set of allowed states, quantize to nearest allowed state */
							ntg_quantize_to_allowed_states( converted_value, destination_attribute->endpoint->control_info->state_info->constraint.allowed_states );
						}
					}
					else
					{
						/* if source is a bang, reset target to it's current value */
						converted_value = ntg_value_duplicate( destination_attribute->value );
					}
				}
				else
				{
					assert( destination_attribute->endpoint->control_info->type == NTG_BANG );
					converted_value = NULL;
				}

				ntg_set_( server, NTG_SOURCE_CONNECTION, destination_attribute->path, converted_value );

				if( converted_value )
				{
					ntg_value_free( converted_value );
				}
			}
		}
    }
}


void ntg_update_connection_path_on_rename( ntg_server *server, const ntg_node_attribute *connection_path, const char *previous_name, const char *new_name )
{
	const char *old_connection_path;
	int previous_name_length;
	int old_connection_path_length;

	const char *path_after_renamed_node;
	char *new_connection_path;
	ntg_value *new_value;

	old_connection_path = ntg_value_get_string( connection_path->value );

	previous_name_length = strlen( previous_name );
	old_connection_path_length = strlen( old_connection_path );
	if( old_connection_path_length <= previous_name_length || memcmp( old_connection_path, previous_name, previous_name_length ) != 0 )
	{
		/* connection path doesn't refer to the renamed object */
		return;
	}

	path_after_renamed_node = old_connection_path + previous_name_length;

	new_connection_path = new char[ strlen( new_name ) + strlen( path_after_renamed_node ) + 1 ];
	sprintf( new_connection_path, "%s%s", new_name, path_after_renamed_node );

	new_value = ntg_value_new( NTG_STRING, new_connection_path );

	ntg_set_( server, NTG_SOURCE_SYSTEM, connection_path->path, new_value );

	ntg_value_free( new_value );
	delete [] new_connection_path;
}


void ntg_update_connections_on_object_rename( ntg_server *server, const ntg_node *search_node, const char *previous_name, const char *new_name )
{
    const ntg_node *current;
	const ntg_node *parent;
	char *previous_name_in_parent_scope;
	char *new_name_in_parent_scope;
	const ntg_node_attribute *source_attribute, *target_attribute;

    /* search amongst sibling nodes */
    for( current = search_node->next; current != search_node; current = current->next )
	{
		if( !ntg_guids_are_equal( &current->interface->module_guid, &server->system_class_data->connection_interface_guid ) ) 
		{
			/* current is not a connection */
            continue;
        }

		source_attribute = ntg_find_attribute( current, NTG_ATTRIBUTE_SOURCE_PATH );
		target_attribute = ntg_find_attribute( current, NTG_ATTRIBUTE_TARGET_PATH );
		assert( source_attribute && target_attribute );

		ntg_update_connection_path_on_rename( server, source_attribute, previous_name, new_name );
		ntg_update_connection_path_on_rename( server, target_attribute, previous_name, new_name );
	}
	
    /* recurse up the tree */
	parent = search_node->parent;
    if( parent != ntg_server_get_root( server ) ) 
	{
		previous_name_in_parent_scope = new char[ strlen( parent->name ) + strlen( previous_name ) + 2 ];
		new_name_in_parent_scope = new char[ strlen( parent->name ) + strlen( new_name ) + 2 ];

		sprintf( previous_name_in_parent_scope, "%s.%s", parent->name, previous_name );
		sprintf( new_name_in_parent_scope, "%s.%s", parent->name, new_name );

        ntg_update_connections_on_object_rename( server, parent, previous_name_in_parent_scope, new_name_in_parent_scope );

		delete[] previous_name_in_parent_scope;
		delete[] new_name_in_parent_scope;
    }
}


void ntg_update_connection_path_on_move( ntg_server *server, const ntg_node_attribute *connection_path, const ntg_path *previous_path, const ntg_path *new_path )
{
	const char *connection_path_string;
	char *absolute_path;
	ntg_node *parent;
	int previous_path_length;
	int absolute_path_length;
	int characters_after_old_path;
	int i;
	ntg_path *new_relative_path;
	char *new_connection_path;
	ntg_value *new_connection_path_value;

	parent = connection_path->node->parent;
	connection_path_string = ntg_value_get_string( connection_path->value );

	absolute_path = new char[ strlen( parent->path->string ) + strlen( connection_path_string ) + 2 ];
	sprintf( absolute_path, "%s.%s", parent->path->string, connection_path_string );

	previous_path_length = strlen( previous_path->string );
	absolute_path_length = strlen( absolute_path );
	if( previous_path_length > absolute_path_length || memcmp( previous_path->string, absolute_path, previous_path_length ) != 0 )
	{
		/* connection_path isn't affected by this move */
		delete[] absolute_path;
		return;
	}

	for( i = 0; i < parent->path->n_elems; i++ )
	{
		if( i >= new_path->n_elems || strcmp( new_path->elems[ i ], parent->path->elems[ i ] ) != 0 )
		{
			/* new_path can't be targetted by this connection */
			delete[] absolute_path;
			return;
		}
	}

	new_relative_path = ntg_path_new();
	for( i = parent->path->n_elems; i < new_path->n_elems; i++ )
	{
		ntg_path_append_element( new_relative_path, new_path->elems[ i ] );
	}
	
	characters_after_old_path = absolute_path_length - previous_path_length;
	
	new_connection_path = new char[ strlen( new_relative_path->string ) + characters_after_old_path + 1 ];
	sprintf( new_connection_path, "%s%s", new_relative_path->string, absolute_path + previous_path_length );

	new_connection_path_value = ntg_value_new( NTG_STRING, new_connection_path );

	ntg_set_( server, NTG_SOURCE_SYSTEM, connection_path->path, new_connection_path_value );

	ntg_value_free( new_connection_path_value );
	ntg_path_free( new_relative_path );
	delete[] new_connection_path;
	delete[] absolute_path;
}


void ntg_update_connections_on_object_move( ntg_server *server, const ntg_node *search_node, const ntg_path *previous_path, const ntg_path *new_path )
{
    const ntg_node *current;
	const ntg_node *parent;
	const ntg_node_attribute *source_attribute, *target_attribute;

    /* search amongst sibling nodes */
    for( current = search_node->next; current != search_node; current = current->next )
	{
		if( !ntg_guids_are_equal( &current->interface->module_guid, &server->system_class_data->connection_interface_guid ) ) 
		{
			/* current is not a connection */
            continue;
        }

		source_attribute = ntg_find_attribute( current, NTG_ATTRIBUTE_SOURCE_PATH );
		target_attribute = ntg_find_attribute( current, NTG_ATTRIBUTE_TARGET_PATH );
		assert( source_attribute && target_attribute );

		ntg_update_connection_path_on_move( server, source_attribute, previous_path, new_path );
		ntg_update_connection_path_on_move( server, target_attribute, previous_path, new_path );
	}
	
    /* recurse up the tree */
	parent = search_node->parent;
    if( parent != ntg_server_get_root( server ) ) 
	{
        ntg_update_connections_on_object_move( server, parent, previous_path, new_path );
    }
}


bool ntg_should_copy_input_file( const ntg_value *value, ntg_command_source cmd_source )
{
	assert( value && value->type == NTG_STRING );

	switch( cmd_source )
	{
		case NTG_SOURCE_CONNECTION:
	    case NTG_SOURCE_SCRIPT:
	    case NTG_SOURCE_XMLRPC_API:
	    case NTG_SOURCE_OSC_API:
	    case NTG_SOURCE_C_API:
			/* these are the sources for which we want to copy the file to the data directory */

			/* but we only copy the file when a path is provided, otherwise we assume it is already in the data directory */
			
			return ( ntg_extract_filename_from_path( ntg_value_get_string( value ) ) != NULL );

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

void ntg_handle_input_file( ntg_server *server, const ntg_node_attribute *attribute, ntg_command_source cmd_source )
{
	const char *filename;
	ntg_value *filename_value;

	assert( server && attribute );
	assert( ntg_node_has_data_directory( attribute->node ) );

	filename = ntg_copy_file_to_data_directory( attribute );
	if( filename )
	{
		filename_value = ntg_value_new( NTG_STRING, filename );
		ntg_set_( server, NTG_SOURCE_SYSTEM, attribute->path, filename_value );
		ntg_value_free( filename_value );
	}
}


/*
The following methods are executed when server set commands occur

They must all conform the correct the method signature ntg_system_class_set_handler_function, 
*/


void ntg_generic_active_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	assert( attribute );

	if( ntg_interface_is_core_name_match( attribute->node->interface, NTG_CLASS_CONTAINER ) )
	{
		ntg_container_active_handler( server, attribute->node, ntg_value_get_int( attribute->value ) != 0 );
	}
	else
	{
		if( cmd_source == NTG_SOURCE_INITIALIZATION )
		{
			ntg_non_container_active_initializer( server, attribute->node );
		}
	}
}


void ntg_generic_data_directory_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	char *data_directory;
	ntg_value *data_directory_value;

	switch( cmd_source )
	{
		case NTG_SOURCE_INITIALIZATION:
			/* create and set data directory when the attribute is initialized */

			data_directory = ntg_node_data_directory_create( attribute->node, server );
			data_directory_value = ntg_value_new( NTG_STRING, data_directory );
			ntg_set_( server, NTG_SOURCE_SYSTEM, attribute->path, data_directory_value );
			ntg_value_free( data_directory_value );
			delete[] data_directory;
			break;

		case NTG_SOURCE_LOAD:
		case NTG_SOURCE_SYSTEM:
			/* these sources are not external set commands - do nothing */
			break;	

		case NTG_SOURCE_CONNECTION:
	    case NTG_SOURCE_SCRIPT:
	    case NTG_SOURCE_XMLRPC_API:
	    case NTG_SOURCE_OSC_API:
	    case NTG_SOURCE_C_API:
			/* external command is trying to reset the data directory - should delete the old one and create a new one */
			ntg_node_data_directory_change( ntg_value_get_string( previous_value ), ntg_value_get_string( attribute->value ) );
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


void ntg_script_trigger_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
    const ntg_node_attribute *text_attribute;
    const char *script = NULL;
	char *script_output = NULL;
	ntg_value *info_value;

    text_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_TEXT );
    assert(text_attribute);

    script = ntg_value_get_string(text_attribute->value);

    NTG_TRACE_VERBOSE_WITH_STRING("running script...", script);

    script_output = ntg_lua_eval( attribute->node->parent->path, script );
	if( script_output )
	{
		info_value = ntg_value_new( NTG_STRING, script_output );
		ntg_set_( server, NTG_SOURCE_SYSTEM, ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_INFO )->path, info_value );
		ntg_value_free( info_value );
		delete[] script_output;
	}

    NTG_TRACE_VERBOSE("script finished");
}


void ntg_scaler_in_value_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const ntg_node_attribute *in_range_min_attribute, *in_range_max_attribute, *out_range_min_attribute, *out_range_max_attribute, *out_value_attribute;
	const ntg_value *in_range_min_value, *in_range_max_value, *out_range_min_value, *out_range_max_value;
	float in_range_min, in_range_max, out_range_min, out_range_max;
	float in_range_total, out_range_total, scaled_value;
	ntg_value *out_value;

	if( !ntg_node_is_active( attribute->node ) )
	{
		return;
	}

	in_range_min_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_IN_RANGE_MIN);
	in_range_max_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_IN_RANGE_MAX);
	out_range_min_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_OUT_RANGE_MIN);
	out_range_max_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_OUT_RANGE_MAX);
	out_value_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_OUT_VALUE);
	assert( in_range_min_attribute && in_range_max_attribute && out_range_min_attribute && out_range_max_attribute && out_value_attribute);

	in_range_min_value = ntg_node_attribute_get_value( in_range_min_attribute );
	in_range_max_value = ntg_node_attribute_get_value( in_range_max_attribute );
	out_range_min_value = ntg_node_attribute_get_value( out_range_min_attribute );
	out_range_max_value = ntg_node_attribute_get_value( out_range_max_attribute );

	assert( attribute->value->type == NTG_FLOAT );
	assert( in_range_min_value && in_range_min_value->type == NTG_FLOAT );
	assert( in_range_max_value && in_range_max_value->type == NTG_FLOAT );
	assert( out_range_min_value && out_range_min_value->type == NTG_FLOAT );
	assert( out_range_max_value && out_range_max_value->type == NTG_FLOAT );

	in_range_min = ntg_value_get_float( in_range_min_value );
	in_range_max = ntg_value_get_float( in_range_max_value );
	out_range_min = ntg_value_get_float( out_range_min_value );
	out_range_max = ntg_value_get_float( out_range_max_value );

	in_range_total = in_range_max - in_range_min;
	out_range_total = out_range_max - out_range_min;

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
	scaled_value = ntg_value_get_float( attribute->value );
	scaled_value = MAX( scaled_value, MIN( in_range_min, in_range_max ) );
	scaled_value = MIN( scaled_value, MAX( in_range_min, in_range_max ) );

	/*perform linear interpolation*/
	scaled_value = ( scaled_value - in_range_min ) * out_range_total / in_range_total + out_range_min;

	/*store result*/
	out_value = ntg_value_new( NTG_FLOAT, &scaled_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, out_value_attribute->path, out_value );
	ntg_value_free(out_value);
}


void ntg_control_point_value_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_envelope_update_value(server, attribute->node->parent );
}


void ntg_control_point_tick_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_envelope_update_value(server, attribute->node->parent );
}


void ntg_envelope_start_tick_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_envelope_update_value(server, attribute->node );
}


void ntg_envelope_current_tick_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_envelope_update_value(server, attribute->node );
}


void ntg_player_active_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, attribute->node->id );
}


void ntg_player_play_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, attribute->node->id );
}


void ntg_player_tick_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	if( cmd_source != NTG_SOURCE_SYSTEM )
	{
		ntg_player_update(server, attribute->node->id );
	}
}


void ntg_player_loop_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, attribute->node->id );
}


void ntg_player_start_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, attribute->node->id );
}


void ntg_player_end_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	ntg_player_update(server, attribute->node->id );
}


void ntg_player_scene_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const char *scene_name;
	const ntg_node *scene_node;
	const ntg_node_attribute *scene_start_attribute, *scene_length_attribute, *scene_mode_attribute;
	const char *scene_mode;

	/* defaults for values to copy into the player.  The logic below updates these variables */

	int tick = -1;
	int play = 0;
	int loop = 0;
	int start = -1;
	int end = -1;

	/* handle scene selection */

	scene_name = ntg_value_get_string( attribute->value );

	scene_node = ntg_node_find_by_name( attribute->node, scene_name );
	if( !scene_node )	
	{
		if( strcmp( scene_name, "" ) != 0 )
		{
			NTG_TRACE_ERROR_WITH_STRING( "Player doesn't have scene", scene_name );
		}
	}
	else
	{
		scene_node = ntg_node_find_by_name( attribute->node, scene_name );
		if( !scene_node )
		{
			assert( false );
			return;
		}

		scene_start_attribute = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_START );
		scene_length_attribute = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_LENGTH );
		scene_mode_attribute = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_MODE );
		assert( scene_start_attribute && scene_length_attribute && scene_mode_attribute );

		scene_mode = ntg_value_get_string( scene_mode_attribute->value );
		assert( scene_mode );

		start = ntg_value_get_int( scene_start_attribute->value );
		end = start + ntg_value_get_int( scene_length_attribute->value );
		tick = start;

		if( strcmp( scene_mode, NTG_SCENE_MODE_PLAY ) == 0 )
		{
			play = 1;
		}
		else
		{
			if( strcmp( scene_mode, NTG_SCENE_MODE_LOOP ) == 0 )
			{
				play = 1;
				loop = 1;
			}
			else
			{
				assert( strcmp( scene_mode, NTG_SCENE_MODE_HOLD ) == 0 );
			}
		}
	}

	ntg_player_set_state( server, attribute->node, tick, play, loop, start, end );
}


void ntg_scene_activate_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const ntg_node *player_node;
	const ntg_node_attribute *player_scene_attribute;
	ntg_value *new_scene_value;
	
	player_node = attribute->node->parent;
	assert( player_node );

	player_scene_attribute = ntg_find_attribute( player_node, NTG_ATTRIBUTE_SCENE );
	assert( player_scene_attribute );

	new_scene_value = ntg_value_new( NTG_STRING, attribute->node->name );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_scene_attribute->path, new_scene_value ); 
	ntg_value_free( new_scene_value );
}


void ntg_scene_mode_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const ntg_node *scene_node;
	const ntg_node_attribute *scene_start_attribute, *scene_length_attribute;
	int tick, play, loop, start, end;
	const char *scene_mode;

	scene_node = attribute->node;

	if( !ntg_scene_is_selected( scene_node ) )
	{
		return;
	}

	scene_start_attribute = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_START );
	scene_length_attribute = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_LENGTH );
	assert( scene_start_attribute && scene_length_attribute );

	scene_mode = ntg_value_get_string( attribute->value );
	start = ntg_value_get_int( scene_start_attribute->value );
	end = start + ntg_value_get_int( scene_length_attribute->value );

	if( strcmp( scene_mode, NTG_SCENE_MODE_HOLD ) == 0 )
	{
		tick = start;
		play = 0;
		loop = 0;
	}
	else
	{
		if( strcmp( scene_mode, NTG_SCENE_MODE_LOOP ) == 0 )
		{
			loop = 1;
		}
		else
		{
			assert( strcmp( scene_mode, NTG_SCENE_MODE_PLAY ) == 0 );

			loop = 0;
		}

		tick = -1;
		play = 1;
	}

	ntg_player_set_state( server, scene_node->parent, tick, play, loop, start, end );
}


void ntg_scene_start_and_length_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const ntg_node *scene_node;
	const ntg_node_attribute *scene_start, *scene_length, *player_tick, *player_start, *player_end;
	ntg_value *player_start_value, *player_end_value;
	int start, end;

	scene_node = attribute->node;

	if( !ntg_scene_is_selected( scene_node ) )
	{
		return;
	}

	scene_start = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_START );
	scene_length = ntg_find_attribute( scene_node, NTG_ATTRIBUTE_LENGTH );
	player_tick = ntg_find_attribute( scene_node->parent, NTG_ATTRIBUTE_TICK );
	player_start = ntg_find_attribute( scene_node->parent, NTG_ATTRIBUTE_START );
	player_end = ntg_find_attribute( scene_node->parent, NTG_ATTRIBUTE_END );
	assert( scene_start && scene_length && player_tick && player_start && player_end );

	start = ntg_value_get_int( scene_start->value );
	end = start + ntg_value_get_int( scene_length->value );

	player_start_value = ntg_value_new( NTG_INTEGER, &start );
	player_end_value = ntg_value_new( NTG_INTEGER, &end );

	ntg_set_( server, NTG_SOURCE_SYSTEM, player_tick->path, player_start_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_start->path, player_start_value );
	ntg_set_( server, NTG_SOURCE_SYSTEM, player_end->path, player_end_value );
	
	ntg_value_free( player_start_value );
	ntg_value_free( player_end_value );
}


void ntg_player_next_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const ntg_node *selected_scene;
	const ntg_node *search_scene;
	const ntg_node_attribute *scene_attribute;
	const ntg_node_attribute *tick_attribute;
	const ntg_node_attribute *start_attribute;
	const char *selected_scene_name;
	const char *next_scene_name;
	ntg_value *new_scene_value;
	int player_tick;
	int best_scene_start;
	int search_scene_start;

	/* find selected scene start*/
	scene_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_SCENE );
	tick_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_TICK );
	assert( scene_attribute && tick_attribute );

	player_tick = ntg_value_get_int( tick_attribute->value );

	selected_scene_name = ntg_value_get_string( scene_attribute->value );
	if( strcmp( selected_scene_name, "" ) != 0 )
	{
		selected_scene = ntg_node_find_by_name( attribute->node, selected_scene_name );
		assert( selected_scene );

		start_attribute = ntg_find_attribute( selected_scene, NTG_ATTRIBUTE_START );
		assert( start_attribute );
	}
	else
	{
		selected_scene = NULL;
	}


	/* iterate through scenes looking for next scene */
	search_scene = attribute->node->nodes;
	next_scene_name = NULL;

	do
	{
		if( search_scene != selected_scene )
		{
			start_attribute = ntg_find_attribute( search_scene, NTG_ATTRIBUTE_START );
			assert( start_attribute );
			search_scene_start = ntg_value_get_int( start_attribute->value );

			if( search_scene_start >= player_tick )
			{
				if( !next_scene_name || search_scene_start < best_scene_start )
				{
					next_scene_name = search_scene->name;
					best_scene_start = search_scene_start;
				}
			}
		}

		search_scene = search_scene->next;
	}
	while( search_scene != attribute->node->nodes );

	if( next_scene_name )
	{
		new_scene_value = ntg_value_new( NTG_STRING, next_scene_name );
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_attribute->path, new_scene_value );
		ntg_value_free( new_scene_value );
	}
}


void ntg_player_prev_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	const ntg_node *selected_scene;
	const ntg_node *search_scene;
	const ntg_node_attribute *scene_attribute;
	const ntg_node_attribute *tick_attribute;
	const ntg_node_attribute *start_attribute;
	const char *selected_scene_name;
	const char *prev_scene_name;
	ntg_value *new_scene_value;
	int player_tick;
	int best_scene_start;
	int search_scene_start;

	/* find selected scene start*/
	scene_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_SCENE );
	tick_attribute = ntg_find_attribute( attribute->node, NTG_ATTRIBUTE_TICK );
	assert( scene_attribute && tick_attribute );

	player_tick = ntg_value_get_int( tick_attribute->value );

	selected_scene_name = ntg_value_get_string( scene_attribute->value );
	if( strcmp( selected_scene_name, "" ) != 0 )
	{
		selected_scene = ntg_node_find_by_name( attribute->node, selected_scene_name );
		assert( selected_scene );

		start_attribute = ntg_find_attribute( selected_scene, NTG_ATTRIBUTE_START );
		assert( start_attribute );
	}
	else
	{
		selected_scene = NULL;
	}


	/* iterate through scenes looking for next scene */
	search_scene = attribute->node->nodes;
	prev_scene_name = NULL;

	do
	{
		if( search_scene != selected_scene )
		{
			start_attribute = ntg_find_attribute( search_scene, NTG_ATTRIBUTE_START );
			assert( start_attribute );
			search_scene_start = ntg_value_get_int( start_attribute->value );

			if( search_scene_start < player_tick )
			{
				if( !prev_scene_name || search_scene_start > best_scene_start )
				{
					prev_scene_name = search_scene->name;
					best_scene_start = search_scene_start;
				}
			}
		}

		search_scene = search_scene->next;
	}
	while( search_scene != attribute->node->nodes );

	if( prev_scene_name )
	{
		new_scene_value = ntg_value_new( NTG_STRING, prev_scene_name );
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_attribute->path, new_scene_value );
		ntg_value_free( new_scene_value );
	}
}


void ntg_connection_source_path_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	/* remove and/or add in host if needed */ 

	const ntg_node *connection_node = NULL, *connection_owner = NULL;
	const ntg_node_attribute *source_path = NULL, *target_path = NULL;
	const ntg_node_attribute *old_source_attribute = NULL, *new_source_attribute = NULL, *target_attribute = NULL;

	assert( attribute );
	connection_node = attribute->node;
	assert( connection_node );
	connection_owner = connection_node->parent;
	assert( connection_owner );

	if( cmd_source == NTG_SOURCE_SYSTEM )
	{
		/* the connection source changed due to the connected attribute being moved or renamed - no need to do anything in the host */
		return;
	}

	source_path = ntg_find_attribute( connection_node, NTG_ATTRIBUTE_SOURCE_PATH );
	target_path = ntg_find_attribute( connection_node, NTG_ATTRIBUTE_TARGET_PATH );
	assert( source_path && target_path );

	old_source_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( previous_value ) );
	new_source_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( source_path->value ) );
	target_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( target_path->value ) );

	if( new_source_attribute && new_source_attribute->endpoint->type == NTG_CONTROL && !new_source_attribute->endpoint->control_info->can_be_source )
	{
		NTG_TRACE_ERROR( "Setting connection source to an endpoint which should not be a connection source!" );
	}

	if( !target_attribute || !ntg_endpoint_is_audio_stream( target_attribute->endpoint ) )
	{
		/* early exit - wasn't an audio connection before and still isn't */
		return;
	}

	if( target_attribute->endpoint->stream_info->direction != NTG_STREAM_INPUT )
	{
		/* early exit - target isn't an input */
		return;
	}

	if( old_source_attribute && ntg_endpoint_is_audio_stream( old_source_attribute->endpoint ) )
	{
		if( old_source_attribute->endpoint->stream_info->direction == NTG_STREAM_OUTPUT )
		{
			/* remove previous connection in host */
			ntg_server_connect_in_host( server, old_source_attribute, target_attribute, false );
		}
	}

	if( new_source_attribute && ntg_endpoint_is_audio_stream( new_source_attribute->endpoint ) )
	{
		if( new_source_attribute->endpoint->stream_info->direction == NTG_STREAM_OUTPUT )
		{
			/* create new connection in host */
			ntg_server_connect_in_host( server, new_source_attribute, target_attribute, true );
		}
	}
}


void ntg_connection_target_path_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	/* remove and/or add in host if needed */ 

	const ntg_node *connection_node = NULL, *connection_owner = NULL;
	const ntg_node_attribute *source_path = NULL, *target_path = NULL;
	const ntg_node_attribute *source_attribute = NULL, *old_target_attribute = NULL, *new_target_attribute = NULL;

	assert( attribute );
	connection_node = attribute->node;
	assert( connection_node );
	connection_owner = connection_node->parent;
	assert( connection_owner );

	if( cmd_source == NTG_SOURCE_SYSTEM )
	{
		/* the connection target changed due to the connected attribute being moved or renamed - no need to do anything in the host */
		return;
	}

	source_path = ntg_find_attribute( connection_node, NTG_ATTRIBUTE_SOURCE_PATH );
	target_path = ntg_find_attribute( connection_node, NTG_ATTRIBUTE_TARGET_PATH );
	assert( source_path && target_path );

	source_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( source_path->value ) );
	old_target_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( previous_value ) );
	new_target_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( target_path->value ) );

	if( new_target_attribute && new_target_attribute->endpoint->type == NTG_CONTROL && !new_target_attribute->endpoint->control_info->can_be_target )
	{
		NTG_TRACE_ERROR( "Setting connection target to an endpoint which should not be a connection target!" );
	}


	if( !source_attribute || !ntg_endpoint_is_audio_stream( source_attribute->endpoint ) )
	{
		/* early exit - wasn't an audio connection before and still isn't */
		return;
	}

	if( source_attribute->endpoint->stream_info->direction != NTG_STREAM_OUTPUT )
	{
		/* early exit - source isn't an output */
		return;
	}

	if( old_target_attribute && ntg_endpoint_is_audio_stream( old_target_attribute->endpoint ) )
	{
		if( old_target_attribute->endpoint->stream_info->direction == NTG_STREAM_INPUT )
		{
			/* remove previous connection in host */
			ntg_server_connect_in_host( server, source_attribute, old_target_attribute, false );
		}
	}

	if( new_target_attribute && ntg_endpoint_is_audio_stream( new_target_attribute->endpoint ) )
	{
		if( new_target_attribute->endpoint->stream_info->direction == NTG_STREAM_INPUT )
		{
			/* create new connection in host */
			ntg_server_connect_in_host( server, source_attribute, new_target_attribute, true );
		}
	}
}


void ntg_generic_set_handler( ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source )
{
	if( ntg_endpoint_is_input_file( attribute->endpoint ) && ntg_should_copy_input_file( attribute->value, cmd_source ) )
	{
		ntg_handle_input_file( server, attribute, cmd_source );
	}

	switch( cmd_source )
	{
		case NTG_SOURCE_INITIALIZATION:
		case NTG_SOURCE_LOAD:
			break;

		default:
			ntg_handle_connections( server, attribute->node, attribute );
	}
}


/*
The following methods are executed when server rename commands occur

They must all conform the correct the method signature ntg_system_class_rename_handler_function, 
*/


void ntg_container_rename_handler(ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_container_update_path_of_players( server, node );
}


void ntg_player_rename_handler( ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_player_handle_path_change( server, node );
}


void ntg_scene_rename_handler( ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source )
{
	/* if this is the selected scene, need to update the player's scene attribute */

	const ntg_node *player;
	const ntg_node_attribute *scene_attribute;
	ntg_value *scene_name;

	player = node->parent;
	assert( player );

	if( !ntg_interface_is_core_name_match( player->interface, NTG_CLASS_PLAYER ) )
	{
		NTG_TRACE_ERROR( "parent of renamed scene is not a player!" );
		return;
	}

	scene_attribute = ntg_find_attribute( player, NTG_ATTRIBUTE_SCENE );
	assert( scene_attribute );

	if( strcmp( ntg_value_get_string( scene_attribute->value ), previous_name ) == 0 )
	{
		scene_name = ntg_value_new( NTG_STRING, node->name );
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_attribute->path, scene_name );
		ntg_value_free( scene_name );
	}
}


void ntg_generic_rename_handler( ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_update_connections_on_object_rename( server, node, previous_name, node->name );
}



/*
The following methods are executed when server move commands occur

They must all conform the correct the method signature ntg_system_class_move_handler_function, 
*/


void ntg_container_move_handler( ntg_server *server, const ntg_node *node, const ntg_path *previous_path, ntg_command_source cmd_source )
{
	ntg_container_update_path_of_players( server, node );
}


void ntg_player_move_handler( ntg_server *server, const ntg_node *node, const ntg_path *previous_path, ntg_command_source cmd_source )
{
	ntg_player_handle_path_change( server, node );
}


void ntg_generic_move_handler( ntg_server *server, const ntg_node *node, const ntg_path *previous_path, ntg_command_source cmd_source )
{
	ntg_update_connections_on_object_move( server, node, previous_path, node->path );
}



/*
The following methods are executed when server new commands occur

They must all conform the correct the method signature ntg_system_class_new_handler_function, 
*/

void ntg_generic_new_handler( ntg_server *server, const ntg_node *new_node, ntg_command_source cmd_source )
{
	/* add connections in host if needed */ 

	const ntg_node *ancestor;
	const ntg_node *sibling;
	const ntg_node_attribute *source_path;
	const ntg_node_attribute *target_path;
	const ntg_node_attribute *source_attribute;
	const ntg_node_attribute *target_attribute;

	assert( server && new_node );

	for( ancestor = new_node; ancestor->parent != NULL; ancestor = ancestor->parent )
	{
		sibling = ancestor->parent->nodes;
		while( sibling )
		{
			if( sibling != ancestor && ntg_guids_are_equal( &sibling->interface->module_guid, &server->system_class_data->connection_interface_guid ) ) 
			{
				/* found a connection which might target the new node */

				source_path = ntg_find_attribute( sibling, NTG_ATTRIBUTE_SOURCE_PATH );
				target_path = ntg_find_attribute( sibling, NTG_ATTRIBUTE_TARGET_PATH );
				assert( source_path && target_path );

				source_attribute = ntg_server_resolve_relative_path( server, ancestor->parent, ntg_value_get_string( source_path->value ) );
				target_attribute = ntg_server_resolve_relative_path( server, ancestor->parent, ntg_value_get_string( target_path->value ) );
	
				if( source_attribute && target_attribute )
				{
					if( source_attribute->node == new_node || target_attribute->node == new_node )
					{
						if( ntg_endpoint_is_audio_stream( source_attribute->endpoint ) && source_attribute->endpoint->stream_info->direction == NTG_STREAM_OUTPUT )
						{
							if( ntg_endpoint_is_audio_stream( target_attribute->endpoint ) && target_attribute->endpoint->stream_info->direction == NTG_STREAM_INPUT )
							{
								/* create connection in host */
								ntg_server_connect_in_host( server, source_attribute, target_attribute, true );
							}
						}
					}
				}
			}

			sibling = sibling->next;
			if( sibling == ancestor->parent->nodes )
			{
				break;
			}
		}
	}
}

/*
The following methods are executed when server delete commands occur

They must all conform the correct the method signature ntg_system_class_delete_handler_function, 
*/


void ntg_container_delete_handler( ntg_server *server, const ntg_node *node, ntg_command_source cmd_source )
{
	/* recursively handle deletion of child nodes */

	ntg_node *node_iterator = NULL;

	node_iterator = node->nodes;
	if( !node_iterator )
	{
		return;
	}

	do
	{
		ntg_system_class_handle_delete( server, node_iterator, cmd_source );

		node_iterator = node_iterator->next;
	}
	while( node_iterator != node->nodes );
}


void ntg_player_delete_handler( ntg_server *server, const ntg_node *node, ntg_command_source cmd_source )
{
	ntg_player_handle_delete( server, node );
}


void ntg_scene_delete_handler( ntg_server *server, const ntg_node *node, ntg_command_source cmd_source )
{
	/* if this is the selected scene, need to clear the player's scene attribute */

	const ntg_node *player;
	const ntg_node_attribute *scene_attribute;
	ntg_value *empty_scene_name;

	player = node->parent;
	assert( player );

	if( !ntg_interface_is_core_name_match( player->interface, NTG_CLASS_PLAYER ) )
	{
		NTG_TRACE_ERROR( "parent of deleted scene is not a player!" );
		return;
	}

	scene_attribute = ntg_find_attribute( player, NTG_ATTRIBUTE_SCENE );
	assert( scene_attribute );

	if( strcmp( ntg_value_get_string( scene_attribute->value ), node->name ) == 0 )
	{
		empty_scene_name = ntg_value_new( NTG_STRING, "" );
		ntg_set_( server, NTG_SOURCE_SYSTEM, scene_attribute->path, empty_scene_name );
		ntg_value_free( empty_scene_name );
	}
}


void ntg_connection_delete_handler( ntg_server *server, const ntg_node *node, ntg_command_source cmd_source )
{
	/* remove in host if needed */ 

	const ntg_node *connection_owner = NULL;
	const ntg_node_attribute *source_path = NULL, *target_path = NULL;
	const ntg_node_attribute *source_attribute = NULL, *target_attribute = NULL;

	assert( node );
	connection_owner = node->parent;
	assert( connection_owner );

	source_path = ntg_find_attribute( node, NTG_ATTRIBUTE_SOURCE_PATH );
	target_path = ntg_find_attribute( node, NTG_ATTRIBUTE_TARGET_PATH );
	assert( source_path && target_path );

	source_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( source_path->value ) );
	target_attribute = ntg_server_resolve_relative_path( server, connection_owner, ntg_value_get_string( target_path->value ) );
	
	if( source_attribute && ntg_endpoint_is_audio_stream( source_attribute->endpoint ) && source_attribute->endpoint->stream_info->direction == NTG_STREAM_OUTPUT )
	{
		if( target_attribute && ntg_endpoint_is_audio_stream( target_attribute->endpoint ) && target_attribute->endpoint->stream_info->direction == NTG_STREAM_INPUT )
		{
			/* remove connection in host */
			ntg_server_connect_in_host( server, source_attribute, target_attribute, false );
		}
	}
}


/*
The following methods perform housekeeping and external interface for system class handlers
*/


void ntg_system_class_handlers_add( ntg_system_class_handler **list_head, const ntg_server *server, const char *class_name, const char *attribute_name, void * function )
{
	ntg_system_class_handler *handler = NULL;
	const ntg_interface *interface = NULL;

	assert( list_head );
	assert( server );
	assert( function );

	if( class_name )
	{
		interface = ntg_get_core_interface_by_name( server->module_manager, class_name );
		if( !interface )
		{
			NTG_TRACE_ERROR_WITH_STRING("failed to lookup into for core class", class_name);
			return;
		}

		if( !ntg_interface_is_core( interface ) )
		{
			NTG_TRACE_ERROR_WITH_STRING("attempt to add system class handler for non-core class", class_name);
			return;
		}

		assert( strcmp( class_name, interface->info->name ) == 0 );
	}
	else
	{
		interface = NULL;
	}
		
	handler = new ntg_system_class_handler;
	
	if( interface )
	{
		handler->module_guid = new GUID;
		*handler->module_guid = interface->module_guid;
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


ntg_system_class_handler *ntg_new_handlers_create( const ntg_server *server )
{
	ntg_system_class_handler *new_handlers = NULL;

	assert( server );

	NTG_TRACE_PROGRESS( "creating new handlers" );

	ntg_system_class_handlers_add( &new_handlers, server, NULL, NULL, ntg_generic_new_handler );

	return new_handlers;
}


ntg_system_class_handler *ntg_set_handlers_create(const ntg_server *server)
{
	ntg_system_class_handler *set_handlers = NULL;

	assert( server );

	NTG_TRACE_PROGRESS("creating set handlers");

	ntg_system_class_handlers_add( &set_handlers, server, NULL, NULL, ntg_generic_set_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NULL, NTG_ATTRIBUTE_ACTIVE, ntg_generic_active_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NULL, NTG_ATTRIBUTE_DATA_DIRECTORY, ntg_generic_data_directory_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCRIPT, NTG_ATTRIBUTE_TRIGGER, ntg_script_trigger_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCALER, NTG_ATTRIBUTE_IN_VALUE, ntg_scaler_in_value_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONTROL_POINT, NTG_ATTRIBUTE_TICK, ntg_control_point_tick_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONTROL_POINT, NTG_ATTRIBUTE_VALUE, ntg_control_point_value_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_ENVELOPE, NTG_ATTRIBUTE_START_TICK, ntg_envelope_start_tick_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_ENVELOPE, NTG_ATTRIBUTE_CURRENT_TICK, ntg_envelope_current_tick_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_ACTIVE, ntg_player_active_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_PLAY, ntg_player_play_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_TICK, ntg_player_tick_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_LOOP, ntg_player_loop_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_START, ntg_player_start_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_END, ntg_player_end_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_SCENE, ntg_player_scene_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_NEXT, ntg_player_next_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_PLAYER, NTG_ATTRIBUTE_PREV, ntg_player_prev_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ATTRIBUTE_ACTIVATE, ntg_scene_activate_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ATTRIBUTE_MODE, ntg_scene_mode_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ATTRIBUTE_START, ntg_scene_start_and_length_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_SCENE, NTG_ATTRIBUTE_LENGTH, ntg_scene_start_and_length_handler );

	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONNECTION, NTG_ATTRIBUTE_SOURCE_PATH, ntg_connection_source_path_handler );
	ntg_system_class_handlers_add( &set_handlers, server, NTG_CLASS_CONNECTION, NTG_ATTRIBUTE_TARGET_PATH, ntg_connection_target_path_handler );

	return set_handlers;
}


ntg_system_class_handler *ntg_rename_handlers_create(const ntg_server *server)
{
	ntg_system_class_handler *rename_handlers = NULL;

	assert( server );

	NTG_TRACE_PROGRESS("creating rename handlers");

	ntg_system_class_handlers_add( &rename_handlers, server, NTG_CLASS_CONTAINER, NULL, ntg_container_rename_handler );
	ntg_system_class_handlers_add( &rename_handlers, server, NTG_CLASS_PLAYER, NULL, ntg_player_rename_handler );
	ntg_system_class_handlers_add( &rename_handlers, server, NTG_CLASS_SCENE, NULL, ntg_scene_rename_handler );
	ntg_system_class_handlers_add( &rename_handlers, server, NULL, NULL, ntg_generic_rename_handler );

	return rename_handlers;
}


ntg_system_class_handler *ntg_move_handlers_create(const ntg_server *server)
{
	ntg_system_class_handler *move_handlers = NULL;

	assert( server );

	NTG_TRACE_PROGRESS("creating move handlers");

	ntg_system_class_handlers_add( &move_handlers, server, NTG_CLASS_CONTAINER, NULL, ntg_container_move_handler );
	ntg_system_class_handlers_add( &move_handlers, server, NTG_CLASS_PLAYER, NULL, ntg_player_move_handler );
	ntg_system_class_handlers_add( &move_handlers, server, NULL, NULL, ntg_generic_move_handler );

	return move_handlers;
}


ntg_system_class_handler *ntg_delete_handlers_create(const ntg_server *server)
{
	ntg_system_class_handler *delete_handlers = NULL;

	assert( server );

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


void ntg_system_class_handlers_initialize( ntg_server *server )
{
	const ntg_interface *connection_interface =  NULL;
	ntg_system_class_data *system_class_data = new ntg_system_class_data;

	system_class_data->new_handlers = ntg_new_handlers_create( server );
	system_class_data->set_handlers = ntg_set_handlers_create( server );
	system_class_data->rename_handlers = ntg_rename_handlers_create( server );
	system_class_data->move_handlers = ntg_move_handlers_create( server );
	system_class_data->delete_handlers = ntg_delete_handlers_create( server );

	connection_interface = ntg_get_core_interface_by_name( server->module_manager, NTG_CLASS_CONNECTION );
	if( connection_interface )
	{
		system_class_data->connection_interface_guid = connection_interface->module_guid;
	}
	else
	{
		NTG_TRACE_ERROR( "failed to look up class info for " NTG_CLASS_CONNECTION );
		ntg_guid_set_null( &system_class_data->connection_interface_guid );
	}

	server->system_class_data = system_class_data;

	ntg_player_initialize( server );

	ntg_reentrance_checker_initialize( server );
}


void ntg_system_class_handlers_shutdown( ntg_server *server )
{
	ntg_reentrance_checker_free( server );

	ntg_player_free( server );

	ntg_system_class_handlers_free( server->system_class_data->new_handlers );
	ntg_system_class_handlers_free( server->system_class_data->set_handlers );
	ntg_system_class_handlers_free( server->system_class_data->rename_handlers );
	ntg_system_class_handlers_free( server->system_class_data->move_handlers );
	ntg_system_class_handlers_free( server->system_class_data->delete_handlers );

	delete server->system_class_data;
}


void ntg_system_class_handle_new( ntg_server *server, const ntg_node *node, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_new_handler_function function = NULL;

	assert( server );
	assert( node );

	for( handler = server->system_class_data->new_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node->interface->module_guid ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_new_handler_function ) handler->function;
		function( server, node, cmd_source );
	}
}


void ntg_system_class_handle_set(ntg_server *server, const ntg_node_attribute *attribute, const ntg_value *previous_value, ntg_command_source cmd_source)
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_set_handler_function function = NULL;

	assert( server );
	assert( attribute );

	for( handler = server->system_class_data->set_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &attribute->node->interface->module_guid ) )
		{
			continue;
		}

		if( handler->attribute_name && attribute && strcmp( handler->attribute_name, attribute->endpoint->name ) != 0 )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_set_handler_function ) handler->function;
		function( server, attribute, previous_value, cmd_source );
	}
}


void ntg_system_class_handle_rename(ntg_server *server, const ntg_node *node, const char *previous_name, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_rename_handler_function function = NULL;

	assert( server );
	assert( node );

	for( handler = server->system_class_data->rename_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node->interface->module_guid ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_rename_handler_function ) handler->function;
		function( server, node, previous_name, cmd_source );
	}
}


void ntg_system_class_handle_move(ntg_server *server, const ntg_node *node, const ntg_path *previous_path, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_move_handler_function function = NULL;

	assert( server );
	assert( node );

	for( handler = server->system_class_data->move_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node->interface->module_guid ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_move_handler_function ) handler->function;
		function( server, node, previous_path, cmd_source );
	}
}


void ntg_system_class_handle_delete(ntg_server *server, const ntg_node *node, ntg_command_source cmd_source )
{
	ntg_system_class_handler *handler = NULL;
	ntg_system_class_delete_handler_function function = NULL;

	assert( server );
	assert( node );

	for( handler = server->system_class_data->delete_handlers; handler; handler = handler->next )
	{
		if( handler->module_guid && !ntg_guids_are_equal( handler->module_guid, &node->interface->module_guid ) )
		{
			continue;
		}

		assert( handler->function );
		function = ( ntg_system_class_delete_handler_function ) handler->function;
		function( server, node, cmd_source );
	}
}


bool ntg_node_is_active( const ntg_node *node )
{
	const ntg_node_attribute *active_attribute = ntg_find_attribute( node, NTG_ATTRIBUTE_ACTIVE );
	if( active_attribute )
	{
		return ( ntg_value_get_int( active_attribute->value ) != 0 );
	}
	else
	{
		return true;
	}
}


bool ntg_node_has_data_directory( const ntg_node *node )
{
	return ( ntg_find_attribute( node, NTG_ATTRIBUTE_DATA_DIRECTORY ) != NULL );
}


const char *ntg_node_get_data_directory( const ntg_node *node )
{
	const ntg_node_attribute *data_directory;

	assert( node );

	data_directory = ntg_find_attribute( node, NTG_ATTRIBUTE_DATA_DIRECTORY );
	if( !data_directory )
	{
		return NULL;
	}

	return ntg_value_get_string( data_directory->value );
}

