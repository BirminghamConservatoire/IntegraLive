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
#include "server.h"
#include "globals.h"
#include "helper.h"
#include "interface.h"

using namespace ntg_api;


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
		delete node_attribute->value;
	}

    delete node_attribute;

    return NTG_NO_ERROR;
}


ntg_node_attribute *ntg_node_attribute_insert_in_list(	ntg_node_attribute *attribute_list,
											const ntg_endpoint *endpoint,
											const CPath &path,
											const CValue *value)
{
    ntg_node_attribute *new_node_attribute;
	ntg_node_attribute *attribute_iterator;

	assert( endpoint );

    new_node_attribute = ntg_node_attribute_new();
	new_node_attribute->endpoint = endpoint;

	if( value )
	{
		new_node_attribute->value = value->clone();
	}

    new_node_attribute->path = path;

	/* find correct insertion position in attribute list */

	if( !attribute_list || endpoint->endpoint_index < attribute_list->endpoint->endpoint_index )
	{
		new_node_attribute->next = attribute_list;
		return new_node_attribute;
	}
    
	for( attribute_iterator = attribute_list; attribute_iterator; attribute_iterator = attribute_iterator->next )
	{
		if( !attribute_iterator->next || endpoint->endpoint_index < attribute_iterator->next->endpoint->endpoint_index )
		{
			new_node_attribute->next = attribute_iterator->next;
			attribute_iterator->next = new_node_attribute;
			return attribute_list;
		}
	}

	assert( false );	/* failed to find insertion position */
	return NULL;	    
}


bool ntg_node_attribute_test_constraint( const ntg_node_attribute *attribute, const CValue &value )
{
	assert( attribute );

	const ntg_endpoint *endpoint = attribute->endpoint;
	if( !endpoint->control_info || !endpoint->control_info->state_info )
	{
		return false;
	}

	CValue::type endpoint_type = endpoint->control_info->state_info->type;

	if( value.get_type() != endpoint_type )
	{
		CValue *fixed_type = value.transmogrify( endpoint_type );

		bool test_result = ntg_node_attribute_test_constraint( attribute, *fixed_type );
		delete fixed_type;
		return test_result;
	}

	const ntg_constraint *constraint = &endpoint->control_info->state_info->constraint;

	const ntg_range *range = constraint->range;
	if( range )
	{
		switch( value.get_type() )
		{
			case CValue::STRING:
				{
					/* for strings, range constraint defines min/max length */
					const string &string_value = value;
					int string_length = string_value.length();
			
					if( string_length < ( int ) *range->minimum ) return false;
					if( string_length > ( int ) *range->maximum ) return false;

					return true;
				}

			case CValue::INTEGER:
				{
					/* for integers, range constraint defines min/max value */
					int int_value = value;

					if( int_value < ( int ) *range->minimum ) return false;
					if( int_value > ( int ) *range->maximum ) return false;

					return true;
				}

			case CValue::FLOAT:
				{
					/* for floats, range constraint defines min/max value */
					float float_value = value;

					if( float_value < ( float ) *range->minimum ) return false;
					if( float_value > ( float ) *range->maximum ) return false;

					return true;
				}

			default:
				NTG_TRACE_ERROR( "unhandled value type" );
				return false;
		}
	}
	else	/* allowed value constraint */
	{
		const ntg_allowed_state *allowed_state;
		for( allowed_state = constraint->allowed_states; allowed_state; allowed_state = allowed_state->next )
		{
			if( value.is_equal( *allowed_state->value ) ) 
			{
				return true;
			}
		}

		return false;	//not found
	}
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

