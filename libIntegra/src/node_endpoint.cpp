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

#include <assert.h>

#include "node_endpoint.h"
#include "node.h"
#include "value.h"
#include "interface.h"
#include "trace.h"


using namespace ntg_api;


namespace ntg_internal
{
	CNodeEndpoint::CNodeEndpoint()
	{
		m_node = NULL;
		m_endpoint = NULL;
		m_value = NULL;
	}


	CNodeEndpoint::~CNodeEndpoint()
	{
		if( m_value ) 
		{
			delete m_value;
		}
	}

		
	void CNodeEndpoint::initialize( const struct ntg_node_ &node, const ntg_endpoint &endpoint )
	{
		m_node = &node;
		m_endpoint = &endpoint;

		if( m_value ) 
		{
			delete m_value;
			m_value = NULL;
		}

		if( endpoint.type == NTG_CONTROL && endpoint.control_info->type == NTG_STATE )
		{
			const ntg_state_info *state_info = endpoint.control_info->state_info;
			assert( state_info );

			m_value = CValue::factory( state_info->type );
		}

		update_path();
	}


	bool CNodeEndpoint::test_constraint( const ntg_api::CValue &value ) const
	{
		if( !m_endpoint->control_info || !m_endpoint->control_info->state_info )
		{
			return false;
		}

		CValue::type endpoint_type = m_endpoint->control_info->state_info->type;

		if( value.get_type() != endpoint_type )
		{
			CValue *fixed_type = value.transmogrify( endpoint_type );

			bool test_result = test_constraint( *fixed_type );
			delete fixed_type;
			return test_result;
		}

		const ntg_constraint *constraint = &m_endpoint->control_info->state_info->constraint;

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


	void CNodeEndpoint::update_path()
	{
		assert( m_node && m_endpoint );

		m_path = m_node->path;
		m_path.append_element( m_endpoint->name );
	}



}


