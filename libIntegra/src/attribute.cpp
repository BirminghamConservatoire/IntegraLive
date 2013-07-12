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

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

#include "attribute.h"
#include "memory.h"
#include "value.h"
#include "hashtable.h"
#include "server.h"
#include "globals.h"
#include "helper.h"
#include "interface.h"


ntg_node_attribute *ntg_node_attribute_new(void)
{
    ntg_node_attribute *attribute;
    attribute = new ntg_node_attribute;
	memset( attribute, 0, sizeof( ntg_node_attribute ) );

    return attribute;
}


ntg_error_code ntg_node_attribute_free(ntg_node_attribute *node_attribute)
{
    assert( node_attribute != NULL );

	if( node_attribute->value )
	{
		ntg_value_free( node_attribute->value );
	}

    assert(node_attribute->path);
    ntg_path_free(node_attribute->path);

    delete node_attribute;

    return NTG_NO_ERROR;
}


ntg_node_attribute *ntg_node_attribute_insert_in_list(	ntg_node_attribute *attribute_list,
											const ntg_endpoint *endpoint,
											const ntg_path *path,
											const ntg_value * value)
{
    ntg_node_attribute *new_node;
	ntg_node_attribute *attribute_iterator;

	assert( endpoint && path );

    new_node = ntg_node_attribute_new();
	new_node->endpoint = endpoint;
	if( value )
	{
		new_node->value = ntg_value_duplicate(value);
	}

    new_node->path = ntg_path_copy(path);

	/* find correct insertion position in attribute list */

	if( !attribute_list || endpoint->endpoint_index < attribute_list->endpoint->endpoint_index )
	{
		new_node->next = attribute_list;
		return new_node;
	}
    
	for( attribute_iterator = attribute_list; attribute_iterator; attribute_iterator = attribute_iterator->next )
	{
		if( !attribute_iterator->next || endpoint->endpoint_index < attribute_iterator->next->endpoint->endpoint_index )
		{
			new_node->next = attribute_iterator->next;
			attribute_iterator->next = new_node;
			return attribute_list;
		}
	}

	assert( false );	/* failed to find insertion position */
	return NULL;	    
}


void ntg_node_attribute_set_value(ntg_node_attribute * attribute,
                                  const ntg_value * value)
{

    assert(attribute->value);
    assert(value);

    ntg_value_copy(attribute->value, value);

}


bool ntg_node_attribute_test_constraint( const ntg_node_attribute *attribute, const ntg_value *value )
{
	const ntg_endpoint *endpoint;
	const ntg_constraint *constraint;
	const ntg_range *range;
	const ntg_allowed_state *allowed_state;

	int string_length;
	int int_value;
	float float_value;

	assert( attribute && value );

	if( value->type != attribute->value->type )
	{
		bool test_result;
		ntg_value *fixed_type = ntg_value_change_type( value, attribute->value->type );

		test_result = ntg_node_attribute_test_constraint( attribute, fixed_type );
		ntg_value_free( fixed_type );
		return test_result;
	}

	endpoint = attribute->endpoint;
	if( !endpoint->control_info || !endpoint->control_info->state_info )
	{
		return false;
	}

	constraint = &endpoint->control_info->state_info->constraint;

	range = constraint->range;
	if( range )
	{
		switch( value->type )
		{
			case NTG_STRING:
				/* for strings, range constraint defines min/max length */
				string_length = strlen( ntg_value_get_string( value ) );
			
				if( string_length < ntg_value_get_int( range->minimum ) ) return false;
				if( string_length > ntg_value_get_int( range->maximum ) ) return false;

				return true;

			case NTG_INTEGER:
				/* for integers, range constraint defines min/max value */
				int_value = ntg_value_get_int( value );

				if( int_value < ntg_value_get_int( range->minimum ) ) return false;
				if( int_value > ntg_value_get_int( range->maximum ) ) return false;

				return true;

			case NTG_FLOAT:
				/* for floats, range constraint defines min/max value */
				float_value = ntg_value_get_float( value );

				if( float_value < ntg_value_get_float( range->minimum ) ) return false;
				if( float_value > ntg_value_get_float( range->maximum ) ) return false;

				return true;

			default:
				NTG_TRACE_ERROR( "unhandled value type" );
				return false;
		}
	}
	else	/* allowed value constraint */
	{
		for( allowed_state = constraint->allowed_states; allowed_state; allowed_state = allowed_state->next )
		{
			if( ntg_value_compare( value, allowed_state->value ) == NTG_NO_ERROR )
			{
				return true;
			}
		}

		return false;	//not found
	}
}


const ntg_value *ntg_node_attribute_get_value( const ntg_node_attribute *attribute)
{

    return attribute->value;

}


void ntg_node_attributes_free(ntg_node_attribute *attribute_list)
{
    ntg_node_attribute *first, *next;

	if( !attribute_list ) return;

	first = attribute_list;

    do
	{
		next = attribute_list->next;;
		ntg_node_attribute_free( attribute_list );
		attribute_list = next;
    } 
	while( attribute_list != first );
}


void ntg_node_attribute_send_value(const ntg_node_attribute *attribute, ntg_bridge_interface *bridge)
{
	bridge->send_value(attribute);
}

