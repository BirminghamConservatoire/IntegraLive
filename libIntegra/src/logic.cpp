 /* libIntegra modular audio framework
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

#include "container_logic.h"
#include "script_logic.h"
#include "scaler_logic.h"
#include "control_point_logic.h"
#include "envelope_logic.h"
#include "player_logic.h"
#include "scene_logic.h"
#include "connection_logic.h"
#include "audio_settings_logic.h"
#include "midi_settings_logic.h"

#include "dsp_engine.h"

#include "server.h"
#include "data_directory.h"
#include "module_manager.h"
#include "node.h"
#include "interface_definition.h"
#include "file_helper.h"

#include "api/guid_helper.h"
#include "api/trace.h"
#include "api/command.h"

#include "assert.h"


namespace integra_internal
{
	const string CLogic::module_container = "Container";
	const string CLogic::module_script = "Script";
	const string CLogic::module_scaler = "Scaler";
	const string CLogic::module_control_point = "ControlPoint";
	const string CLogic::module_envelope = "Envelope";
	const string CLogic::module_player = "Player";
	const string CLogic::module_scene = "Scene";
	const string CLogic::module_connection = "Connection";
	const string CLogic::module_audio_settings = "AudioSettings";
	const string CLogic::module_midi_settings = "MidiSettings";

	const string CLogic::endpoint_active = "active";
	const string CLogic::endpoint_data_directory = "dataDirectory";
	const string CLogic::endpoint_source_path = "sourcePath";
	const string CLogic::endpoint_target_path = "targetPath";


	CLogic::CLogic( const CNode &node )
		:	m_node( node )
	{
		m_connection_interface_guid = CGuidHelper::null_guid;
	}


	CLogic::~CLogic()
	{
	}


	CLogic *CLogic::create( const CNode &node )
	{
		const CInterfaceDefinition &interface_definition = CInterfaceDefinition::downcast( node.get_interface_definition() );

		if( interface_definition.is_named_core_interface( module_container ) )
		{
			return new CContainerLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_script ) )
		{
			return new CScriptLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_scaler ) )
		{
			return new CScalerLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_control_point ) )
		{
			return new CControlPointLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_envelope ) )
		{
			return new CEnvelopeLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_player ) )
		{
			return new CPlayerLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_scene ) )
		{
			return new CSceneLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_connection ) )
		{
			return new CConnectionLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_audio_settings ) )
		{
			return new CAudioSettingsLogic( node );
		}

		if( interface_definition.is_named_core_interface( module_midi_settings ) )
		{
			return new CMidiSettingsLogic( node );
		}

		/* 
		not a core module with specific logic class - create generic logic 
		*/

		return new CLogic( node );
	}

	
	void CLogic::handle_new( CServer &server, CCommandSource source )
	{
		/* add connections in host if needed */ 

		for( const INode *ancestor = &m_node; ancestor; ancestor = ancestor->get_parent() )
		{
			const node_map &siblings = server.get_siblings( *ancestor );
			for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
			{
				const INode *sibling = i->second;

				if( sibling != ancestor && CGuidHelper::guids_are_equal(sibling->get_interface_definition().get_module_guid(), get_connection_interface_guid( server ) ) )
				{
					/* found a connection which might target the new node */

					const INodeEndpoint *source_path = sibling->get_node_endpoint( endpoint_source_path );
					const INodeEndpoint *target_path = sibling->get_node_endpoint( endpoint_target_path );
					assert( source_path && target_path );

					const INodeEndpoint *source_endpoint = server.find_node_endpoint( CPath( *source_path->get_value() ), ancestor->get_parent() );
					const INodeEndpoint *target_endpoint = server.find_node_endpoint( CPath( *target_path->get_value() ), ancestor->get_parent() );
	
					if( source_endpoint && target_endpoint )
					{
						internal_id source_node_id = CNode::downcast( &source_endpoint->get_node() )->get_id();
						internal_id target_node_id = CNode::downcast( &target_endpoint->get_node() )->get_id();

						if( m_node.get_id() == source_node_id || m_node.get_id() == target_node_id )
						{
							if( source_endpoint->get_endpoint_definition().is_audio_stream() && source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
							{
								if( target_endpoint->get_endpoint_definition().is_audio_stream() && target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
								{
									/* create connection in host */
									connect_audio_in_host( server, *source_endpoint, *target_endpoint, true );
								}
							}
						}
					}
				}
			}
		}
	}


	void CLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		const CEndpointDefinition &endpoint_definition = CEndpointDefinition::downcast( node_endpoint.get_endpoint_definition() );
		const string &endpoint_name = endpoint_definition.get_name();
		if( source == CCommandSource::INITIALIZATION )
		{
			if( endpoint_name == endpoint_active )
			{
				const CInterfaceDefinition &interface_definition = CInterfaceDefinition::downcast( m_node.get_interface_definition() );

				if( !interface_definition.is_named_core_interface( module_container ) )
				{
					non_container_active_initializer( server );
				}
			}
		}

		if( endpoint_name == endpoint_data_directory )
		{
			data_directory_handler( server, node_endpoint, previous_value, source );
		}

		if( endpoint_definition.is_input_file() && should_copy_input_file( node_endpoint, source ) )
		{
			handle_input_file( server, node_endpoint );
		}

		switch( source )
		{
			case CCommandSource::INITIALIZATION:
			case CCommandSource::LOAD:
				break;

			default:
				handle_connections( server, m_node, node_endpoint );
		}
	}


	void CLogic::handle_rename( CServer &server, const string &previous_name, CCommandSource source )
	{
		update_connections_on_rename( server, m_node, previous_name, m_node.get_name() );

		update_on_path_change( server );
	}


	void CLogic::handle_move( CServer &server, const CPath &previous_path, CCommandSource source )
	{
		update_connections_on_move( server, m_node, previous_path, m_node.get_path() );

		update_on_path_change( server );
	}


	void CLogic::handle_delete( CServer &server, CCommandSource source )
	{
		/* no implementation currently needed */
	}


	bool CLogic::node_is_active() const
	{
		const INodeEndpoint *active_endpoint = m_node.get_node_endpoint( endpoint_active );
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


	bool CLogic::should_copy_input_file( const CNodeEndpoint &input_file, CCommandSource source ) const
	{
		if( !input_file.get_value() || input_file.get_value()->get_type() != CValue::STRING )
		{
			INTEGRA_TRACE_ERROR << "input file endpoint has no value, or value is not a string";
			return false;
		}

		switch( source )
		{
			case CCommandSource::CONNECTION:
			case CCommandSource::SCRIPT:
			case CCommandSource::PUBLIC_API:
				{
				/* these are the sources for which we want to copy the file to the data directory */

				/* but we only copy the file when a path is provided, otherwise we assume it is already in the data directory */
			
				const string &path = *input_file.get_value();
				return ( CFileHelper::extract_filename_from_path( path ) != path );
				}

			case CCommandSource::INITIALIZATION:
			case CCommandSource::LOAD:
			case CCommandSource::SYSTEM:
				return false;		/* these sources are not external set commands - do nothing */

			case CCommandSource::MODULE_IMPLEMENTATION:
				INTEGRA_TRACE_ERROR << "Module Implementation attempting to set input file endpoint!  Module Implementations should not do this";
				return false;		/* we don't expect input file to be set by host! */

			default:
				assert( false );	/* unhandled command source value */
				return false;
		}
	}


	bool CLogic::has_data_directory() const
	{
		return ( m_node.get_node_endpoint( endpoint_data_directory ) != NULL );
	}


	const string *CLogic::get_data_directory() const
	{
		const INodeEndpoint *data_directory = m_node.get_node_endpoint( endpoint_data_directory );
		if( !data_directory )
		{
			return NULL;
		}

		const CValue *value = data_directory->get_value();
		if( !value || value->get_type() != CValue::STRING ) 
		{
			INTEGRA_TRACE_ERROR << "data directory endpoint has no value or value is of unexpected type";
			return NULL;
		}

		const string &value_string = *value;
		return &value_string;	
	}


	bool CLogic::can_be_child_of( const CNode *candidate_parent ) const
	{
		/*
		 most modules can exist at top-level or as children of containers
		 module logics with other rules may override this method
		 */

		if( !candidate_parent )		
		{
			//can be top-level
			return true;
		}

		if( dynamic_cast<CContainerLogic *>( &candidate_parent->get_logic() ) )	
		{
			//can be inside container
			return true;
		}

		//can't be inside anything else
		return false;	
	}


	void CLogic::non_container_active_initializer( CServer &server )
	{
		/*
		sets 'active' endpoint to false if any ancestor's active endpoint is false
		*/

		const INodeEndpoint *active_endpoint = m_node.get_node_endpoint( endpoint_active );
		if( !active_endpoint )
		{
			return;
		}

		if( !are_all_ancestors_active() )
		{
			CIntegerValue value( 0 );
			server.process_command( ISetCommand::create( active_endpoint->get_path(), value ), CCommandSource::SYSTEM );
		}	
	}


	bool CLogic::are_all_ancestors_active() const
	{
		const INode *parent = m_node.get_parent();
		if( !parent )
		{
			return true;
		}

		const INodeEndpoint *parent_active = parent->get_node_endpoint( endpoint_active );
		if( parent_active && ( int ) *parent_active->get_value() == 0 )
		{
			return false;
		}

		return CNode::downcast( parent )->get_logic().are_all_ancestors_active();
	}


	void CLogic::data_directory_handler( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		switch( source )
		{
			case CCommandSource::INITIALIZATION:
				/* create and set data directory when the endpoint is initialized */
				{
				string data_directory = CDataDirectory::create_for_node( m_node, server );
				server.process_command( ISetCommand::create( node_endpoint.get_path(), CStringValue( data_directory ) ), CCommandSource::SYSTEM );
				}
				break;

			case CCommandSource::LOAD:
			case CCommandSource::SYSTEM:
				/* these sources are not external set commands - do nothing */
				break;	

			case CCommandSource::CONNECTION:
			case CCommandSource::SCRIPT:
			case CCommandSource::PUBLIC_API:
				/* external command is trying to reset the data directory - should delete the old one and create a new one */
				CDataDirectory::change( *previous_value, *node_endpoint.get_value() );
				break;		

			case CCommandSource::MODULE_IMPLEMENTATION:
				/* we don't expect data directory to be set by host! */
				INTEGRA_TRACE_ERROR << "Module Implementation is trying to set data directory!  Module Implementations should not try to do this!";
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
			INTEGRA_TRACE_ERROR << "can't handle input file - node doesn't have data directory";
			return;
		}

		string filename = CDataDirectory::copy_file_to_data_directory( input_file );
		if( !filename.empty() )
		{
			server.process_command( ISetCommand::create( input_file.get_path(), CStringValue( filename ) ), CCommandSource::SYSTEM );
		}
	}


	void CLogic::handle_connections( CServer &server, const CNode &search_node, const CNodeEndpoint &changed_endpoint )
	{
		const CNode *parent = CNode::downcast( search_node.get_parent() );

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
		const node_map &siblings = server.get_siblings( search_node );
		for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
		{
			const CNode *sibling = CNode::downcast( i->second );
			if( !CGuidHelper::guids_are_equal(sibling->get_interface_definition().get_module_guid(), get_connection_interface_guid( server ) ) )
			{
				/* not a connection */
				continue;
			}

			if( !sibling->get_logic().node_is_active() )
			{
				/* connection is not active */
				continue;
			}

			const INodeEndpoint *source_endpoint = sibling->get_node_endpoint( endpoint_source_path );
			assert( source_endpoint );

			const string &source_endpoint_value = *source_endpoint->get_value();
			if( source_endpoint_value == relative_endpoint_path )
			{
				if( changed_endpoint.get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL || !changed_endpoint.get_endpoint_definition().get_control_info()->get_can_be_source() )
				{
					INTEGRA_TRACE_ERROR << "aborting handling of connection from endpoint which cannot be a connection source";
					continue;
				}

				/* found a connection! */
				const INodeEndpoint *target_endpoint = sibling->get_node_endpoint( endpoint_target_path );
				assert( target_endpoint );

				const INodeEndpoint *destination_endpoint = server.find_node_endpoint( CPath( *target_endpoint->get_value() ), parent );

				if( destination_endpoint )
				{
					/* found a destination! */

					if( destination_endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL || !destination_endpoint->get_endpoint_definition().get_control_info()->get_can_be_target() )
					{
						INTEGRA_TRACE_ERROR << "aborting handling of connection to endpoint which cannot be a connection target";
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

					ISetCommand *command;

					if( converted_value )
					{
						command = ISetCommand::create( destination_endpoint->get_path(), *converted_value );
						delete converted_value;
					}
					else
					{
						command = ISetCommand::create( destination_endpoint->get_path() );
					}

					server.process_command( command, CCommandSource::CONNECTION );
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
				INTEGRA_TRACE_ERROR << "Value type mismatch whilst quantizing to allowed states";
				continue;
			}

			distance_to_current = value.get_distance( *allowed_state );

			if( first || distance_to_current < distance_to_nearest_allowed_state )
			{
				distance_to_nearest_allowed_state = distance_to_current;
				nearest_allowed_state = allowed_state;
				first = false;
			}
		}

		if( !nearest_allowed_state )
		{
			INTEGRA_TRACE_ERROR << "failed to quantize to allowed states - allowed states is empty";
			return;
		}

		assert( nearest_allowed_state->get_type() == value.get_type() );

		value = *nearest_allowed_state;
	}


	const GUID &CLogic::get_connection_interface_guid( CServer &server )
	{
		if( CGuidHelper::guids_are_equal(m_connection_interface_guid, CGuidHelper::null_guid) )
		{
			CModuleManager &module_manager = CModuleManager::downcast( server.get_module_manager() );

			const CInterfaceDefinition *connection_interface = module_manager.get_core_interface_by_name( module_connection );
			if( connection_interface )
			{
				m_connection_interface_guid = connection_interface->get_module_guid();
			}
			else
			{
				INTEGRA_TRACE_ERROR << "Failed to lookup connection interface";
			}
		}

		return m_connection_interface_guid;
	}


	CError CLogic::connect_audio_in_host( CServer &server, const INodeEndpoint &source, const INodeEndpoint &target, bool connect )
	{
		const CEndpointDefinition &source_endpoint_definition = CEndpointDefinition::downcast( source.get_endpoint_definition() );
		const CEndpointDefinition &target_endpoint_definition = CEndpointDefinition::downcast( target.get_endpoint_definition() );

		if( !source_endpoint_definition.is_audio_stream() || source_endpoint_definition.get_stream_info()->get_direction() != CStreamInfo::OUTPUT )
		{
			INTEGRA_TRACE_ERROR << "trying to make incorrect connection in host - source isn't an audio output";
			return CError::INPUT_ERROR;
		}

		if( !target_endpoint_definition.is_audio_stream() || target_endpoint_definition.get_stream_info()->get_direction() != CStreamInfo::INPUT )
		{
			INTEGRA_TRACE_ERROR << "trying to make incorrect connection in host - target isn't an audio output";
			return CError::INPUT_ERROR;
		}

		if( connect ) 
		{
			server.get_dsp_engine().connect_modules( CNodeEndpoint::downcast( source ), CNodeEndpoint::downcast( target ) );
		} 
		else 
		{
			server.get_dsp_engine().disconnect_modules( CNodeEndpoint::downcast( source ), CNodeEndpoint::downcast( target ) );
		}

		return CError::SUCCESS;
	}


	void CLogic::update_connection_path_on_rename( CServer &server, const CNodeEndpoint &connection_path, const string &previous_name, const string &new_name )
	{
		int previous_name_length;
		int old_connection_path_length;

		const string &old_connection_path = *connection_path.get_value();

		previous_name_length = previous_name.length();
		old_connection_path_length = old_connection_path.length();
		if( old_connection_path_length <= previous_name_length || previous_name != old_connection_path.substr( 0, previous_name_length ) )
		{
			/* connection path doesn't refer to the renamed object */
			return;
		}

		string path_after_renamed_node = old_connection_path.substr( previous_name_length );

		string new_connection_path = new_name + path_after_renamed_node;

		server.process_command( ISetCommand::create( connection_path.get_path(), CStringValue( new_connection_path ) ), CCommandSource::SYSTEM );
	}


	void CLogic::update_connections_on_rename( CServer &server, const CNode &search_node, const string &previous_name, const string &new_name )
	{
		const node_map &siblings = server.get_siblings( search_node );

		/* search amongst sibling nodes */
		for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
		{
			const INode *sibling = i->second;

			if( !CGuidHelper::guids_are_equal(sibling->get_interface_definition().get_module_guid(), get_connection_interface_guid( server ) ) )
			{
				/* current is not a connection */
				continue;
			}

			const CNodeEndpoint *source_endpoint = CNodeEndpoint::downcast( sibling->get_node_endpoint( endpoint_source_path ) );
			const CNodeEndpoint *target_endpoint = CNodeEndpoint::downcast( sibling->get_node_endpoint( endpoint_target_path ) );
			assert( source_endpoint && target_endpoint );

			update_connection_path_on_rename( server, *source_endpoint, previous_name, new_name );
			update_connection_path_on_rename( server, *target_endpoint, previous_name, new_name );
		}
	
		/* recurse up the tree */
		const CNode *parent = CNode::downcast( search_node.get_parent() );
		if( parent ) 
		{
			string previous_name_in_parent_scope = parent->get_name() + "." + previous_name;
			string new_name_in_parent_scope = parent->get_name() + "." + new_name;

			update_connections_on_rename( server, *parent, previous_name_in_parent_scope, new_name_in_parent_scope );
		}
	}


	void CLogic::update_connections_on_move( CServer &server, const CNode &search_node, const CPath &previous_path, const CPath &new_path )
	{
		const node_map &siblings = server.get_siblings( search_node );

		/* search amongst sibling nodes */
		for( node_map::const_iterator i = siblings.begin(); i != siblings.end(); i++ )
		{
			const INode *sibling = i->second;
			if( !CGuidHelper::guids_are_equal(sibling->get_interface_definition().get_module_guid(), get_connection_interface_guid( server ) ) )
			{
				/* current is not a connection */
				continue;
			}

			const CNodeEndpoint *source_endpoint = CNodeEndpoint::downcast( sibling->get_node_endpoint( endpoint_source_path ) );
			const CNodeEndpoint *target_endpoint = CNodeEndpoint::downcast( sibling->get_node_endpoint( endpoint_target_path ) );
			assert( source_endpoint && target_endpoint );

			update_connection_path_on_move( server, *source_endpoint, previous_path, new_path );
			update_connection_path_on_move( server, *target_endpoint, previous_path, new_path );
		}
	
		/* recurse up the tree */
		const CNode *parent = CNode::downcast( search_node.get_parent() );
		if( parent ) 
		{
			update_connections_on_move( server, *parent, previous_path, new_path );
		}
	}


	void CLogic::update_connection_path_on_move( CServer &server, const CNodeEndpoint &connection_path, const CPath &previous_path, const CPath &new_path )
	{
		int previous_path_length;
		int absolute_path_length;
		int characters_after_old_path;

		const CNode *parent = CNode::downcast( connection_path.get_node().get_parent() );
		const string &connection_path_string = *connection_path.get_value();

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

		const CPath &parent_path = connection_path.get_node().get_parent_path();
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

		server.process_command( ISetCommand::create( connection_path.get_path(), CStringValue( new_connection_path.str() ) ), CCommandSource::SYSTEM );
	}


	void CLogic::update_on_path_change( CServer &server )
	{
		const node_map &children = m_node.get_children();
		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			const CNode *child = CNode::downcast( i->second );
			child->get_logic().update_on_path_change( server );
		}
	}	
}
