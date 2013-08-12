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
#include "interface_definition.h"
#include "trace.h"


namespace ntg_internal
{
	CNodeEndpoint::CNodeEndpoint()
	{
		m_node = NULL;
		m_endpoint_definition = NULL;
		m_value = NULL;
	}


	CNodeEndpoint::~CNodeEndpoint()
	{
		if( m_value ) 
		{
			delete m_value;
		}
	}

		
	void CNodeEndpoint::initialize( const CNode &node, const CEndpointDefinition &endpoint_definition )
	{
		m_node = &node;
		m_endpoint_definition = &endpoint_definition;

		if( m_value ) 
		{
			delete m_value;
			m_value = NULL;
		}

		if( endpoint_definition.get_type() == CEndpointDefinition::CONTROL && endpoint_definition.get_control_info()->get_type() == CControlInfo::STATEFUL )
		{
			const CStateInfo *state_info = endpoint_definition.get_control_info()->get_state_info();
			assert( state_info );

			m_value = CValue::factory( state_info->get_type() );
		}

		update_path();
	}


	bool CNodeEndpoint::test_constraint( const CValue &value ) const
	{
		const CControlInfo *control_info = m_endpoint_definition->get_control_info();
		if( !control_info ) 
		{
			NTG_TRACE_ERROR << "not a constrained type of endpoint";
			return false;
		}

		const CStateInfo *state_info = control_info->get_state_info();
		if( !state_info )
		{
			NTG_TRACE_ERROR << "not a constrained type of endpoint";
			return false;
		}

		CValue::type endpoint_type = state_info->get_type();

		if( value.get_type() != endpoint_type )
		{
			CValue *fixed_type = value.transmogrify( endpoint_type );

			bool test_result = test_constraint( *fixed_type );
			delete fixed_type;
			return test_result;
		}

		const CConstraint &constraint = state_info->get_constraint();

		const CValueRange *range = constraint.get_value_range();
		if( range )
		{
			switch( value.get_type() )
			{
				case CValue::STRING:
					{
						/* for strings, range constraint defines min/max length */
						const string &string_value = value;
						int string_length = string_value.length();
			
						if( string_length < ( int ) range->get_minimum() ) return false;
						if( string_length > ( int ) range->get_maximum() ) return false;

						return true;
					}

				case CValue::INTEGER:
					{
						/* for integers, range constraint defines min/max value */
						int int_value = value;

						if( int_value < ( int ) range->get_minimum() ) return false;
						if( int_value > ( int ) range->get_maximum() ) return false;

						return true;
					}

				case CValue::FLOAT:
					{
						/* for floats, range constraint defines min/max value */
						float float_value = value;

						if( float_value < ( float ) range->get_minimum() ) return false;
						if( float_value > ( float ) range->get_maximum() ) return false;

						return true;
					}

				default:
					NTG_TRACE_ERROR << "unhandled value type";
					return false;
			}
		}
		else	/* allowed value constraint */
		{
			const value_set *allowed_states = constraint.get_allowed_states();
			assert( allowed_states );
			for( value_set::const_iterator i = allowed_states->begin(); i != allowed_states->end(); i++ )
			{
				if( value.is_equal( **i ) ) 
				{
					return true;
				}
			}

			return false;	//not found
		}
	}


	void CNodeEndpoint::update_path()
	{
		assert( m_node && m_endpoint_definition );

		m_path = m_node->get_path();
		m_path.append_element( m_endpoint_definition->get_name() );
	}



}


