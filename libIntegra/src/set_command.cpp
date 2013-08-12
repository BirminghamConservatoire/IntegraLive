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

#include "set_command.h"
#include "server.h"
#include "interface_definition.h"
#include "reentrance_checker.h"
#include "logic.h"
#include "api/value.h"
#include "api/trace.h"

#include <assert.h>


namespace integra_api
{
	CSetCommandApi *CSetCommandApi::create( const CPath &endpoint_path, const CValue *value )
	{
		return new integra_internal::CSetCommand( endpoint_path, value );
	}
}


namespace integra_internal
{
	CSetCommand::CSetCommand( const CPath &endpoint_path, const CValue *value )
	{
		m_endpoint_path = endpoint_path;
		if( value )
		{
			m_value = value->clone();
		}
		else
		{
			m_value = NULL;
		}
	}


	CSetCommand::~CSetCommand()
	{
		if( m_value )
		{
			delete m_value;
		}
	}


	CError CSetCommand::execute( CServer &server, CCommandSource source, CCommandResult *result )
	{
		/* get node endpoint from path */
		CNodeEndpoint *node_endpoint = server.find_node_endpoint_writable( m_endpoint_path.get_string() );
		if( node_endpoint == NULL) 
		{
			INTEGRA_TRACE_ERROR << "endpoint not found: " << m_endpoint_path.get_string();
			return CError::PATH_ERROR;
		}

		const CEndpointDefinition &endpoint_definition = node_endpoint->get_endpoint_definition();

		switch( endpoint_definition.get_type() )
		{
			case CEndpointDefinition::STREAM:
				INTEGRA_TRACE_ERROR << "can't call set for a stream attribute: " << m_endpoint_path.get_string();
				return CError::TYPE_ERROR ;

			case CEndpointDefinition::CONTROL:
				switch( endpoint_definition.get_control_info()->get_type() )
				{
					case CControlInfo::STATEFUL:
					{
						if( !m_value )
						{
							INTEGRA_TRACE_ERROR << "called set without a value for a stateful endpoint: " << m_endpoint_path.get_string();
							return CError::TYPE_ERROR;
						}

						CValue::type value_type = m_value->get_type();
						CValue::type endpoint_type = endpoint_definition.get_control_info()->get_state_info()->get_type();

						/* test that new value is of correct type */
						if( value_type != endpoint_type )
						{
							/* we allow passing integers to float attributes and vice-versa, but no other mismatched types */
							if( ( value_type != CValue::INTEGER && m_value->get_type() != CValue::FLOAT ) || ( endpoint_type != CValue::INTEGER && endpoint_type != CValue::FLOAT ) )
							{
								INTEGRA_TRACE_ERROR << "called set with incorrect value type: " << m_endpoint_path.get_string();
								return CError::TYPE_ERROR;
							}
						} 

						break;
					}

					case CControlInfo::BANG:
						if( m_value )
						{
							INTEGRA_TRACE_ERROR << "called set with a value for a stateless endpoint: " << m_endpoint_path.get_string();
							return CError::TYPE_ERROR;
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

		if( source == CCommandSource::HOST && !node_endpoint->get_node().get_logic().node_is_active() )
		{
			return CError::SUCCESS;
		}

		/* test constraint */
		if( m_value )
		{
			if( !node_endpoint->test_constraint( *m_value ) )
			{
				INTEGRA_TRACE_ERROR << "attempting to set value which doesn't conform to constraint - aborting set command: " << m_endpoint_path.get_string();
				return CError::CONSTRAINT_ERROR;
			}
		}


		if( server.get_reentrance_checker().push( node_endpoint, source ) )
		{
			INTEGRA_TRACE_ERROR << "detected reentry - aborting set command: " << m_endpoint_path.get_string();
			return CError::REENTRANCE_ERROR;
		}

		CValue *previous_value( NULL );
		if( node_endpoint->get_value() )
		{
			previous_value = node_endpoint->get_value()->clone();
		}

		/* set the attribute value */
		if( m_value )
		{
			assert( node_endpoint->get_value() );
			m_value->convert( *node_endpoint->get_value_writable() );
		}

		
		/* handle any system class logic */
		node_endpoint->get_node().get_logic().handle_set( server, *node_endpoint, previous_value, source );

		if( previous_value )
		{
			delete previous_value;
		}

		server.get_reentrance_checker().pop();

		/* send the attribute value to the host if needed */
		if( should_send_to_host( *node_endpoint, node_endpoint->get_node().get_interface_definition(), source ) ) 
		{
			server.get_bridge()->send_value( node_endpoint );
		}

		if( ntg_should_send_to_client( source ) ) 
		{
			ntg_osc_client_send_set( server.get_osc_client(), source, m_endpoint_path, node_endpoint->get_value() );
		}

		return CError::SUCCESS;
	}


	bool CSetCommand::should_send_to_host( const CNodeEndpoint &endpoint, const CInterfaceDefinition &interface_definition, CCommandSource source ) const
	{
		switch( source )
		{
			case CCommandSource::HOST:
				return false;	/* don't send to host if came from host */

			case CCommandSource::LOAD:
				return false;	/* don't send to host when handling load - handled in a second phase */

			default:
				break;		
		}

		if( endpoint.get_endpoint_definition().is_input_file() && endpoint.get_node().get_logic().should_copy_input_file( endpoint, source ) )
		{
			return false;
		}

		if( !interface_definition.has_implementation() )
		{
			return false;
		}

		if( !endpoint.get_endpoint_definition().should_send_to_host() )
		{
			return false;
		}

		return true;
	}


}

