 /* libIntegra multimedia module interface
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

#include "logic.h"
#include "node.h"
#include "interface_definition.h"
#include "trace.h"
#include "file_helper.h"
#include "assert.h"
#include "container_logic.h"
#include "script_logic.h"
#include "scaler_logic.h"
#include "control_point_logic.h"
#include "envelope_logic.h"
#include "player_logic.h"
#include "scene_logic.h"
#include "connection_logic.h"
#include "server.h"
#include "data_directory.h"
#include "module_manager.h"
#include "api/command_api.h"

using namespace ntg_api;


namespace ntg_internal
{
	const string CLogic::s_module_container = "Container";
	const string CLogic::s_module_script = "Script";
	const string CLogic::s_module_scaler = "Scaler";
	const string CLogic::s_module_control_point = "ControlPoint";
	const string CLogic::s_module_envelope = "Envelope";
	const string CLogic::s_module_player = "Player";
	const string CLogic::s_module_scene = "Scene";
	const string CLogic::s_module_connection = "Connection";

	const string CLogic::s_endpoint_active = "active";
	const string CLogic::s_endpoint_data_directory = "dataDirectory";
	const string CLogic::s_endpoint_source_path = "sourcePath";
	const string CLogic::s_endpoint_target_path = "targetPath";


	CLogic::CLogic( const CNode &node )
		:	m_node( node )
	{
		m_connection_interface_guid = NULL_GUID;
	}


	CLogic::~CLogic()
	{
	}


	CLogic *CLogic::create( const CNode &node )
	{
		const CInterfaceDefinition &interface_definition = node.get_interface_definition();

		if( interface_definition.is_named_core_interface( s_module_container ) )
		{
			return new CContainerLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_script ) )
		{
			return new CScriptLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_scaler ) )
		{
			return new CScalerLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_control_point ) )
		{
			return new CControlPointLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_envelope ) )
		{
			return new CEnvelopeLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_player ) )
		{
			return new CPlayerLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_scene ) )
		{
			return new CSceneLogic( node );
		}

		if( interface_definition.is_named_core_interface( s_module_connection ) )
		{
			return new CConnectionLogic( node );
		}

		/* 
		not a core module with specific logic class - create generic logic 
		*/

		return new CLogic( node );
	}

	
	void CLogic::handle_new( CServer &server, ntg_command_source source )
	{
	}

	void CLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, ntg_command_source source )
	{
		const CEndpointDefinition &endpoint_definition = node_endpoint.get_endpoint_definition();
		const string &endpoint_name = endpoint_definition.get_name();
		if( source == NTG_SOURCE_INITIALIZATION )
		{
			if( endpoint_name == s_endpoint_active )
			{
				if( !m_node.get_interface_definition().is_named_core_interface( s_module_container ) )
				{
					non_container_active_initializer( server );
				}
			}
		}

		if( endpoint_name == s_endpoint_data_directory )
		{
			data_directory_handler( server, node_endpoint, previous_value, source );
		}

		if( endpoint_definition.is_input_file() && should_copy_input_file( node_endpoint, source ) )
		{
			handle_input_file( server, node_endpoint );
		}

		switch( source )
		{
			case NTG_SOURCE_INITIALIZATION:
			case NTG_SOURCE_LOAD:
				break;

			default:
				handle_connections( server, m_node, node_endpoint );
		}
	}

	void CLogic::handle_rename( CServer &server, const string &previous_name, ntg_command_source source )
	{
	}

	void CLogic::handle_move( CServer &server, const CPath &previous_path, ntg_command_source source )
	{
	}

	void CLogic::handle_delete( CServer &server, ntg_command_source source )
	{
	}


	bool CLogic::node_is_active() const
	{
		const CNodeEndpoint *active_endpoint = m_node.get_node_endpoint( s_endpoint_active );
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


	bool CLogic::should_copy_input_file( const CNodeEndpoint &input_file, ntg_command_source source ) const
	{
		if( !input_file.get_value() || input_file.get_value()->get_type() != CValue::STRING )
		{
			NTG_TRACE_ERROR( "input file endpoint has no value, or value is not a string" );
			return false;
		}

		switch( source )
		{
			case NTG_SOURCE_CONNECTION:
			case NTG_SOURCE_SCRIPT:
			case NTG_SOURCE_XMLRPC_API:
			case NTG_SOURCE_C_API:
				{
				/* these are the sources for which we want to copy the file to the data directory */

				/* but we only copy the file when a path is provided, otherwise we assume it is already in the data directory */
			
				const string &path = *input_file.get_value();
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


	bool CLogic::has_data_directory() const
	{
		return ( m_node.get_node_endpoint( s_endpoint_data_directory ) != NULL );
	}


	const string *CLogic::get_data_directory() const
	{
		const CNodeEndpoint *data_directory = m_node.get_node_endpoint( s_endpoint_data_directory );
		if( !data_directory )
		{
			return NULL;
		}

		const CValue *value = data_directory->get_value();
		if( !value || value->get_type() != CValue::STRING ) 
		{
			NTG_TRACE_ERROR( "data directory endpoint has no value or value is of unexpected type" );
			return NULL;
		}

		const string &value_string = *value;
		return &value_string;	
	}


	void CLogic::non_container_active_initializer( CServer &server )
	{
		/*
		sets 'active' endpoint to false if any ancestor's active endpoint is false
		*/

		const CNodeEndpoint *active_endpoint = m_node.get_node_endpoint( s_endpoint_active );
		if( !active_endpoint )
		{
			return;
		}

		if( !are_all_ancestors_active() )
		{
			CIntegerValue value( 0 );
			server.process_command( CSetCommandApi::create( active_endpoint->get_path(), &value ), NTG_SOURCE_SYSTEM );
		}	
	}


	bool CLogic::are_all_ancestors_active() const
	{
		const CNode *parent = m_node.get_parent();
		if( !parent )
		{
			return true;
		}

		const CNodeEndpoint *parent_active = parent->get_node_endpoint( s_endpoint_active );
		if( parent_active && ( int ) *parent_active->get_value() == 0 )
		{
			return false;
		}

		return parent->get_logic().are_all_ancestors_active();
	}


	void CLogic::data_directory_handler( CServer &server, const CNodeEndpoint &node_endpoint, const ntg_api::CValue *previous_value, ntg_command_source source )
	{
		switch( source )
		{
			case NTG_SOURCE_INITIALIZATION:
				/* create and set data directory when the endpoint is initialized */
				{
				string data_directory = CDataDirectory::create_for_node( m_node, server );
				server.process_command( CSetCommandApi::create( node_endpoint.get_path(), &CStringValue( data_directory ) ), NTG_SOURCE_SYSTEM );
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
				CDataDirectory::change( *previous_value, *node_endpoint.get_value() );
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


	void CLogic::handle_input_file( CServer &server, const CNodeEndpoint &input_file )
	{
		if( !has_data_directory() )
		{
			NTG_TRACE_ERROR( "can't handle input file - node doesn't have data directory" );
			return;
		}

		string filename = CDataDirectory::copy_file_to_data_directory( input_file );
		if( !filename.empty() )
		{
			server.process_command( CSetCommandApi::create( input_file.get_path(), &CStringValue( filename ) ), NTG_SOURCE_SYSTEM );
		}
	}


	void CLogic::handle_connections( CServer &server, const CNode &search_node, const CNodeEndpoint &changed_endpoint )
	{
		const CNode *parent = search_node.get_parent();

		/* recurse up the tree first, so that higher-level connections are evaluated first */
		if( parent ) 
		{
			handle_connections( server, *parent, changed_endpoint );
		}

		/* build endpoint path relative to search_node */
		string relative_endpoint_path = changed_endpoint.get_path().get_string();
		if( parent )
		{
			relative_endpoint_path = relative_endpoint_path.substr( parent->get_path().get_string().length() + 1 );
		}

		/* search amongst sibling nodes */
		const node_map &siblings = server.get_sibling_set( search_node );
		for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
		{
			const CNode *sibling = i->second;
			if( sibling->get_interface_definition().get_module_guid() != get_connection_interface_guid( server ) ) 
			{
				/* not a connection */
				continue;
			}

			if( !sibling->get_logic().node_is_active() )
			{
				/* connection is not active */
				continue;
			}

			const CNodeEndpoint *source_endpoint = sibling->get_node_endpoint( s_endpoint_source_path );
			assert( source_endpoint );

			const string &source_endpoint_value = *source_endpoint->get_value();
			if( source_endpoint_value == relative_endpoint_path )
			{
				if( changed_endpoint.get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL || !changed_endpoint.get_endpoint_definition().get_control_info()->get_can_be_source() )
				{
					NTG_TRACE_ERROR( "aborting handling of connection from endpoint which cannot be a connection source" );
					continue;
				}

				/* found a connection! */
				const CNodeEndpoint *target_endpoint = sibling->get_node_endpoint( s_endpoint_target_path );
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
						if( changed_endpoint.get_value() )
						{
							converted_value = changed_endpoint.get_value()->transmogrify( destination_endpoint->get_value()->get_type() );

							const value_set *allowed_states = destination_endpoint->get_endpoint_definition().get_control_info()->get_state_info()->get_constraint().get_allowed_states();
							if( allowed_states )
							{
								/* if destination has set of allowed states, quantize to nearest allowed state */
								quantize_to_allowed_states( *converted_value, *allowed_states );
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

					server.process_command( CSetCommandApi::create( destination_endpoint->get_path(), converted_value ), NTG_SOURCE_CONNECTION );
				
					if( converted_value )
					{
						delete converted_value;
					}
				}
			}
		}
	}


	void CLogic::quantize_to_allowed_states( CValue &value, const value_set &allowed_states ) const
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


	const GUID &CLogic::get_connection_interface_guid( CServer &server )
	{
		if( m_connection_interface_guid == NULL_GUID )
		{
			const CInterfaceDefinition *connection_interface = server.get_module_manager().get_core_interface_by_name( s_module_connection );
			if( connection_interface )
			{
				m_connection_interface_guid = connection_interface->get_module_guid();
			}
			else
			{
				NTG_TRACE_ERROR( "Failed to lookup connection interface" );
			}
		}

		return m_connection_interface_guid;
	}
}
