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

#include "dsp_engine.h"
#include "interface_definition.h"
#include "file_helper.h"
#include "server.h"
#include "midi_engine.h"
#include "api/command.h"
#include "api/trace.h"

#include "PdBase.hpp"

#include <fstream>
#include <iostream>


using namespace integra_api;


namespace integra_internal
{
	const int CDspEngine::samples_per_buffer = 64;
	const int CDspEngine::max_audio_channels = 64;

	const string CDspEngine::patch_file_name = "host_patch_file.pd";
	const string CDspEngine::host_patch_name = "integra-canvas";
	const string CDspEngine::patch_message_target = "pd-" + host_patch_name;

	const string CDspEngine::feedback_source = "integra";
	const string CDspEngine::broadcast_symbol = "integra-broadcast-receive";
	const string CDspEngine::bang = "bang";

	const int CDspEngine::module_x_margin = 10;
	const int CDspEngine::module_y_spacing = 50;

	const string CDspEngine::trace_start_tag = "<libpd>";
	const string CDspEngine::trace_end_tag = "</libpd>";

	const string CDspEngine::init_message = "init";
	const string CDspEngine::fini_message = "fini";
	const string CDspEngine::ping_message = "ping";


	CDspEngine::CDspEngine( CServer &server )
		:	m_server( server )
	{
		pthread_mutex_init( &m_mutex, NULL );

		m_input_channels = 2;
		m_output_channels = 2;
		m_sample_rate = 44100;

		m_unanswered_pings = 0;

		m_next_module_y_slot = 1;

		create_host_patch();

		m_message_queue = new CThreadedQueue<pd::Message>( *this );

		m_pd = new pd::PdBase;

		m_pd->init( m_input_channels, m_output_channels, m_sample_rate );

		setup_libpd();

		pd::Patch patch = m_pd->openPatch( patch_file_name, m_server.get_scratch_directory() );
		if( !patch.isValid() )
		{
			INTEGRA_TRACE_ERROR << "failed to load patch: " << get_patch_file_path();
		}

		register_externals();

		memset( m_channel_pressures, 0, midi_channels * sizeof( int ) );
		memset( m_pitchbends, 0, midi_channels * sizeof( int ) );


		m_initialised = true;
	}


	CDspEngine::~CDspEngine()
	{
		pthread_mutex_lock( &m_mutex );

		m_pd->clear();
		delete m_pd;

		delete m_message_queue;

		for( set_command_list::iterator i = m_set_commands.begin(); i != m_set_commands.end(); i++ )
		{
			delete *i;
		}

		delete_host_patch();

		pthread_mutex_unlock( &m_mutex );

		pthread_mutex_destroy( &m_mutex );
	}


	void CDspEngine::register_externals()
	{
		bonk_tilde_setup();
		expr_setup();
		fiddle_tilde_setup();
		lrshift_tilde_setup();
		partconv_tilde_setup();
		freeverb_tilde_setup();
		soundfile_info_setup();
		fsplay_tilde_setup();
	}


	string CDspEngine::get_patch_file_path() const
	{
		return m_server.get_scratch_directory() + patch_file_name;
	}


	void CDspEngine::create_host_patch()
	{
		std::ofstream host_patch_file;
		host_patch_file.open( get_patch_file_path(), std::ios_base::out | std::ios_base::trunc );
		if( host_patch_file.fail() )
		{
			INTEGRA_TRACE_ERROR << "Failed to open host patch " << get_patch_file_path();
			return;
		}

		host_patch_file << "#N canvas 250 50 800 600 10;" << std::endl;
		host_patch_file << "#N canvas 10 30 400 400 integra-canvas 0;" << std::endl;
		host_patch_file << "#X restore 30 20 pd integra-canvas;" << std::endl;

		host_patch_file.close();
	}


	void CDspEngine::delete_host_patch()
	{
		CFileHelper::delete_file( get_patch_file_path() );
	}


	bool CDspEngine::has_configuration_changed( int input_channels, int output_channels, int sample_rate ) const
	{
		if( input_channels != m_input_channels ) return true;
		if( output_channels != m_output_channels ) return true;
		if( sample_rate != m_sample_rate ) return true;

		return false;
	}


	bool CDspEngine::is_configuration_valid() const
	{
		if( m_input_channels < 0 ) return false;
		if( m_output_channels < 0 ) return false;

		if( m_input_channels == 0 && m_output_channels == 0 ) return false;

		if( m_sample_rate <= 0 ) return false;

		return true;
	}


	void CDspEngine::initialize_audio_configuration( int input_channels, int output_channels, int sample_rate )
	{
		m_input_channels = input_channels;
		m_output_channels = output_channels;
		m_sample_rate = sample_rate;

		if( is_configuration_valid() )
		{
			m_initialised = m_pd->init( m_input_channels, m_output_channels, m_sample_rate );
			if( m_initialised )
			{
				setup_libpd();
			}
			else
			{
				INTEGRA_TRACE_ERROR << "failed to initialize pd configuration";
			}
		}
		else
		{
			INTEGRA_TRACE_ERROR << "invalid configuration!";

			m_initialised = false;
		}
	}


	void CDspEngine::setup_libpd()
	{
		m_pd->computeAudio( true );
		m_pd->subscribe( feedback_source );
	}


	void CDspEngine::dump_patch_to_file( const string &path )
	{
		if( CFileHelper::file_exists( path ) )
		{
			CFileHelper::delete_file( path );
		}
		
		string filename = CFileHelper::extract_filename_from_path( path );
		string directory = CFileHelper::extract_directory_from_path( path );

		pthread_mutex_lock( &m_mutex );

        m_pd->startMessage();
        m_pd->addSymbol( filename );
        m_pd->addSymbol( directory );
        m_pd->finishMessage( "pd-" + patch_file_name, "savetofile" );

		pthread_mutex_unlock( &m_mutex );
	}


	void CDspEngine::ping_all_modules()
	{
		pthread_mutex_lock( &m_mutex );

		m_unanswered_pings = 0;

		INTEGRA_TRACE_PROGRESS << "Pinging all dsp modules...";

		int modules_pinged = ping_modules( m_server.get_nodes() );

		if( m_unanswered_pings == 0 )
		{
			INTEGRA_TRACE_PROGRESS << "Pinged " << modules_pinged << " modules.  All modules responded ok";
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Pinged " << modules_pinged << " modules.  " << m_unanswered_pings << "failed to respond";
		}

		pthread_mutex_unlock( &m_mutex );
	}


	int CDspEngine::ping_modules( const node_map &nodes )
	{
		int modules_pinged = 0;

		for( node_map::const_iterator i = nodes.begin(); i != nodes.end(); i++ )
		{
			const CNode &node = *CNode::downcast( i->second );

			const CInterfaceDefinition &interfaceDefinition = CInterfaceDefinition::downcast( node.get_interface_definition() );
			if( interfaceDefinition.has_implementation() )
			{
				send_ping( node );
				modules_pinged++;
			}

			modules_pinged += ping_modules( node.get_children() );
		}

		return modules_pinged;
	}


	void CDspEngine::send_ping( const CNode &node )
	{
		INTEGRA_TRACE_PROGRESS << "Pinging " << node.get_interface_definition().get_interface_info().get_name() << " (" << node.get_path().get_string() << ")";
 
		m_pd->startMessage();
		m_pd->addFloat( node.get_id() );
		m_pd->addSymbol( ping_message );
		m_pd->addSymbol( bang );
		m_pd->finishList( broadcast_symbol );

		int previous_unanswered_pings( m_unanswered_pings );

		m_unanswered_pings++;

		poll_for_messages();

		bool ping_was_answered = ( m_unanswered_pings == previous_unanswered_pings );

		if( ping_was_answered )
		{
			INTEGRA_TRACE_PROGRESS << "Ping response received";
		}
		else
		{
			INTEGRA_TRACE_ERROR << "NO PING RESPONSE!";
		}
	}

	
	CError CDspEngine::add_module( internal_id id, const string &patch_path )
	{
		INTEGRA_TRACE_VERBOSE << "add module id " << id << " as " << patch_path;

		pthread_mutex_lock( &m_mutex );

        m_pd->startMessage();
		m_pd->addFloat( module_x_margin );
        m_pd->addFloat( m_next_module_y_slot * module_y_spacing );
        m_pd->addSymbol( patch_path );
		m_pd->addFloat( id );
        m_pd->finishMessage( patch_message_target, "obj" );

		m_next_module_y_slot ++;

		m_map_id_to_patch_id[ id ] = m_map_id_to_patch_id.size();

		test_map_sanity();

		//send 'init' message
		m_pd->startMessage();
        m_pd->addFloat( id );
        m_pd->addSymbol( init_message );
		m_pd->addSymbol( bang );
        m_pd->finishList( broadcast_symbol );

		pthread_mutex_unlock( &m_mutex );

		return CError::SUCCESS;
	}


	CError CDspEngine::remove_module( internal_id id )
	{
		INTEGRA_TRACE_VERBOSE << "remove module id " << id;

		pthread_mutex_lock( &m_mutex );

		//send 'fini' message
		m_pd->startMessage();
        m_pd->addFloat( id );
        m_pd->addSymbol( fini_message );
		m_pd->addSymbol( bang );
        m_pd->finishList( broadcast_symbol );

		//do the magic to select and delete the module
		ostringstream find;
		find << "+" << id;

		m_pd->startMessage();
        m_pd->addSymbol( find.str() );
		m_pd->addFloat( 1 );
		m_pd->finishMessage( patch_message_target, "find" );

		m_pd->sendMessage( patch_message_target, "cut" );

		int patch_id = get_patch_id( id );
		m_map_id_to_patch_id.erase( id );

		for( int_map::iterator i = m_map_id_to_patch_id.begin(); i != m_map_id_to_patch_id.end(); i++ )
		{
			if( i->second > patch_id )
			{
				i->second --;
			}
		}

		test_map_sanity();

		pthread_mutex_unlock( &m_mutex );

		return CError::SUCCESS;
	}


	void CDspEngine::test_map_sanity()
	{
		//m_map_id_to_patch_id should contain all values from 0 .. m_map_id_to_patch_id.size()-1, with no duplicates

		int_set values;

		for( int_map::const_iterator i = m_map_id_to_patch_id.begin(); i != m_map_id_to_patch_id.end(); i++ )
		{
			int value = i->second;
			if( value < 0 || value >= m_map_id_to_patch_id.size() )
			{
				INTEGRA_TRACE_ERROR << "map sanity check failed - value " << value << "is out of range";
			}

			if( values.count( value ) != 0 )
			{
				INTEGRA_TRACE_ERROR << "map sanity check failed - duplicate value " << value;
			}

			values.insert( value );
		}
	}


	CError CDspEngine::connect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target )
	{
		INTEGRA_TRACE_VERBOSE << "connect " << source.get_path().get_string() << " to " << target.get_path().get_string();

		return connect_or_disconnect( source, target, "connect" );
	}


	CError CDspEngine::disconnect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target )
	{
		INTEGRA_TRACE_VERBOSE << "disconnect " << source.get_path().get_string() << " from " << target.get_path().get_string();

		return connect_or_disconnect( source, target, "disconnect" );
	}


	CError CDspEngine::connect_or_disconnect( const CNodeEndpoint &source, const CNodeEndpoint &target, const string &command )
	{
		CError result;

		pthread_mutex_lock( &m_mutex );

		int source_patch_id = get_patch_id( CNode::downcast( source.get_node() ).get_id() );
		int target_patch_id = get_patch_id( CNode::downcast( target.get_node() ).get_id() );

		if( source_patch_id < 0 || target_patch_id < 0 )
		{
			INTEGRA_TRACE_ERROR << "failed to get a patch id - can't " << command;
		}
		else
		{
			int source_connection_index = get_stream_connection_index( source );
			int target_connection_index = get_stream_connection_index( target );

			if( source_connection_index < 0 || target_connection_index < 0 )
			{
				INTEGRA_TRACE_ERROR << "failed to get a connection index - can't " << command;
				result = CError::FAILED;
			}
			else
			{
				m_pd->startMessage();
				m_pd->addFloat( source_patch_id );
				m_pd->addFloat( source_connection_index );
				m_pd->addFloat( target_patch_id );
				m_pd->addFloat( target_connection_index );
				m_pd->finishMessage( patch_message_target, command ); 

				result = CError::SUCCESS;
			}
		}

		pthread_mutex_unlock( &m_mutex );

		return result;
	}


	CError CDspEngine::send_value( const CNodeEndpoint &target )
	{
		INTEGRA_TRACE_VERBOSE << "send value to " << target.get_path().get_string();

		pthread_mutex_lock( &m_mutex );

		const CNode &node = CNode::downcast( target.get_node() );
		const CValue *value = target.get_value();

		m_pd->startMessage();
		m_pd->addFloat( node.get_id() );
		m_pd->addSymbol( target.get_endpoint_definition().get_name() );

		if( value )
		{
			switch( value->get_type() )
			{
				case CValue::STRING:
					m_pd->addSymbol( ( const string & ) *value );
					break;

				case CValue::INTEGER:
					m_pd->addFloat( ( int ) *value );
					break;

				case CValue::FLOAT:
					m_pd->addFloat( ( float ) *value );
					break;

				default:
					INTEGRA_TRACE_ERROR << "unhandled value type";
					break;
			}
		}
		else
		{
			m_pd->addSymbol( bang );
		}

		m_pd->finishList( broadcast_symbol );

		pthread_mutex_unlock( &m_mutex );

		return CError::SUCCESS;
	}


	void CDspEngine::process_buffer( const float *input, float *output, int input_channels, int output_channels, int sample_rate )
	{
		memset( output, 0, samples_per_buffer * output_channels * sizeof( float ) );

		//NOISE GENERATOR
		
		/*for( int i = 0; i < output_channels * samples_per_buffer; i++ )
		{
			output[ i ] = float( ( rand() % 200 ) - 100 ) * 0.001f;
		}*/

		//THRU
		/*for( int i = 0; i < samples_per_buffer; i++ )
		{
			float input_mix( 0 );
			if( input_channels > 0 )
			{
				for( int j = 0; j < input_channels; j++ )
				{
					input_mix += input[ i * input_channels + j ];
				}
				input_mix /= input_channels;
			}

			for( int j = 0; j < output_channels; j++ )
			{
				output[ i * output_channels + j ] = input_mix;
			}
		}*/

		pthread_mutex_lock( &m_mutex );

		if( has_configuration_changed( input_channels, output_channels, sample_rate ) )
		{
			initialize_audio_configuration( input_channels, output_channels, sample_rate );
		}

		if( m_initialised )
		{
			handle_midi_input();

			/* pd needs a writable input pointer, although presumably does not write to it */
			float *input_writable = ( float * ) input;

			m_pd->processFloat( 1, input_writable, output );
		}
		else
		{
			memset( output, 0, output_channels * samples_per_buffer * sizeof( float ) );
		}

		poll_for_messages();

		pthread_mutex_unlock( &m_mutex );
	}


	void CDspEngine::poll_for_messages()
	{
		pd_message_list queue_messages;

		while( m_pd->numMessages() > 0 ) 
		{
			pd::Message &message = m_pd->nextMessage();

			if( handle_immediate_message( message ) )
			{
				continue;
			}
			else
			{
				queue_messages.push_back( message );
			}
		}

		if( !queue_messages.empty() )
		{
			m_message_queue->push( queue_messages );
		}
	}


	//returns true if message has been handled immediately
	bool CDspEngine::handle_immediate_message( const pd::Message &message )
	{
		if( is_ping_result( message ) ) 
		{
			m_unanswered_pings--;
			return true;
		}

		return false;
	}


	bool CDspEngine::is_ping_result( const pd::Message &message ) const
	{
		if( message.type != pd::LIST )
		{
			return false;
		}

		const pd::List &list = message.list;

		if( list.len() != 3 ) return false;
		if( !list.isSymbol( 0 ) || list.getSymbol( 0 ) != "" ) return false;
		if( !list.isSymbol( 1 ) || list.getSymbol( 1 ) != ping_message ) return false;
		if( !list.isSymbol( 2 ) || list.getSymbol( 2 ) != "OK" ) return false;

		return true;
	}


	void CDspEngine::handle_queue_items( const pd_message_list &messages )
	{
		if( !m_server.lock() )
		{
			return;
		}

		for( pd_message_list::const_iterator i = messages.begin(); i != messages.end(); i++ )
		{
			const pd::Message &message = *i;
			if( message.dest == feedback_source )
			{
				assert( message.type == pd::LIST );

				ISetCommand *command = build_set_command( message.list );
				if( command )
				{
					merge_set_command( command );
				}
				continue;
			}
			else
			{
				switch( message.type )
				{
					case pd::PRINT:
						std::cout << trace_start_tag << message.symbol << trace_end_tag;
						break;

					case pd::NONE:

						// events
					case pd::LIST:
					case pd::BANG:
					case pd::FLOAT:
					case pd::SYMBOL:
					case pd::MESSAGE:

						// midi
					case pd::NOTE_ON:
					case pd::CONTROL_CHANGE:
					case pd::PROGRAM_CHANGE:
					case pd::PITCH_BEND:
					case pd::AFTERTOUCH:
					case pd::POLY_AFTERTOUCH:
					case pd::BYTE:

					default:
						INTEGRA_TRACE_ERROR << "unhandled pd message type: " << message.type;
						break;
				}
			}
		}

		for( set_command_list::iterator i = m_set_commands.begin(); i != m_set_commands.end(); i++ )
		{
			CError result = m_server.process_command( *i, CCommandSource::MODULE_IMPLEMENTATION );
			if( result != CError::SUCCESS )
			{
				INTEGRA_TRACE_ERROR << "Error processing command: " << result.get_text();
			}
		}

		m_set_commands.clear();

		m_server.unlock();
	}


	ISetCommand *CDspEngine::build_set_command( const pd::List &feedback_arguments ) const
	{
		if( feedback_arguments.len() != 4 || !feedback_arguments.isFloat( 0 ) || !feedback_arguments.isSymbol( 1 ) || !feedback_arguments.isSymbol( 2 ) || feedback_arguments.getSymbol( 2 ) != "scalar" )
		{
			INTEGRA_TRACE_ERROR << "unexpected message list structure " << feedback_arguments.toString();
			return NULL;
		}

		internal_id id = feedback_arguments.getFloat( 0 );
		const CNode *node = m_server.find_node( id );
		if( !node )
		{
			INTEGRA_TRACE_ERROR << "Couldn't find node with id " << id;
			return NULL;
		}

		string endpoint_name = feedback_arguments.getSymbol( 1 );
		const INodeEndpoint *node_endpoint = node->get_node_endpoint( endpoint_name );
		if( !node_endpoint )
		{
			INTEGRA_TRACE_ERROR << "Couldn't find endpoint " << endpoint_name;
			return NULL;
		}

		const IEndpointDefinition &endpoint_definition = node_endpoint->get_endpoint_definition();
		if( endpoint_definition.get_type() != IEndpointDefinition::CONTROL )
		{
			INTEGRA_TRACE_ERROR << "Endpoint isn't a control " << endpoint_name;
			return NULL;
		}

		const IControlInfo &control_info = *endpoint_definition.get_control_info();

		switch( control_info.get_type() )
		{
			case IControlInfo::BANG:
				return ISetCommand::create( node_endpoint->get_path() );

			case IControlInfo::STATEFUL:
				switch( control_info.get_state_info()->get_type() )
				{
					case CValue::INTEGER:
						if( feedback_arguments.isFloat( 3 ) )
						{
							CIntegerValue value( feedback_arguments.getFloat( 3 ) );
							return ISetCommand::create( node_endpoint->get_path(), value );
						}

						INTEGRA_TRACE_ERROR << "Unexpected message value type";
						return NULL;

					case CValue::FLOAT:
						if( feedback_arguments.isFloat( 3 ) )
						{
							CFloatValue value( feedback_arguments.getFloat( 3 ) );
							return ISetCommand::create( node_endpoint->get_path(), value );
						}

						INTEGRA_TRACE_ERROR << "Unexpected message value type";
						return NULL;

					case CValue::STRING:
						if( feedback_arguments.isSymbol( 3 ) )
						{
							CStringValue value( feedback_arguments.getSymbol( 3 ) );
							return ISetCommand::create( node_endpoint->get_path(), value );
						}

						INTEGRA_TRACE_ERROR << "Unexpected message value type";
						return NULL;

					default:
						INTEGRA_TRACE_ERROR << "unhandled value type: " << control_info.get_state_info()->get_type();
						return NULL;
				}

				break;

			default:
				INTEGRA_TRACE_ERROR << "unhandled control type: " << control_info.get_type();
				return NULL;
		}
	}


	void CDspEngine::merge_set_command( ISetCommand *command )
	{
		for( set_command_list::iterator i = m_set_commands.begin(); i != m_set_commands.end(); i++ )
		{
			ISetCommand *previous_command = *i;
			if( previous_command ->get_endpoint_path() == command->get_endpoint_path() )
			{
				delete previous_command;
				m_set_commands.erase( i );
				break;
			}

		}
		m_set_commands.push_back( command );
	}


	int CDspEngine::get_patch_id( internal_id id ) const
	{
		int_map::const_iterator lookup = m_map_id_to_patch_id.find( id );
		if( lookup == m_map_id_to_patch_id.end() )
		{
			INTEGRA_TRACE_ERROR << "Can't find patch id from internal id " << id;
			return -1;
		}

		return lookup->second;
	}


	int CDspEngine::get_stream_connection_index( const CNodeEndpoint &node_endpoint ) const
	{
		const IEndpointDefinition &endpoint_definition = node_endpoint.get_endpoint_definition();
		if( !endpoint_definition.is_audio_stream() )
		{
			INTEGRA_TRACE_ERROR << "can't get stream connection index for non-audio stream!";
			return -1;
		}

		const IInterfaceDefinition &interface_definition = node_endpoint.get_node().get_interface_definition();
		endpoint_definition_list endpoint_definitions = interface_definition.get_endpoint_definitions();

		bool found( false );
		int index = 0;

		for( endpoint_definition_list::const_iterator i = endpoint_definitions.begin(); i != endpoint_definitions.end(); i++ )
		{
			const IEndpointDefinition *prior_endpoint = *i;
		
			if( prior_endpoint == &endpoint_definition )
			{
				found = true;
				break;
			}

			if( !prior_endpoint->is_audio_stream() ) 
			{
				continue;
			}

			const IStreamInfo *prior_stream = prior_endpoint->get_stream_info();
			const IStreamInfo *my_stream = endpoint_definition.get_stream_info();

			if( prior_stream->get_type() == my_stream->get_type() && prior_stream->get_direction() == my_stream->get_direction() )
			{
				index ++;
			}
		}

		if( !found )
		{
			/* endpoint not found! */
			INTEGRA_TRACE_ERROR << "can't get stream connection index - endpoint not found in sibling list!";
			return -1;
		}

		return index;
	}


	void CDspEngine::handle_midi_input()
	{
		IMidiEngine &midi_engine = m_server.get_midi_engine();

		unsigned int *midi_messages = NULL;
		int number_of_midi_messages = 0;

		CError midi_result = midi_engine.get_incoming_midi_messages( midi_messages, number_of_midi_messages );
		if( midi_result != CError::SUCCESS )
		{
			INTEGRA_TRACE_ERROR << "Error getting incoming midi messages: " << midi_result;
			return;
		}

		if( number_of_midi_messages == 0 )
		{
			/*
			 early exit
			*/

			return;
		}

		/* 
		 clear caches
		*/

		memset( m_channel_pressures, 0xFF, midi_channels * sizeof( int ) );
		memset( m_pitchbends, 0xFF, midi_channels * sizeof( int ) );
		for( int i = 0; i < midi_channels; i++ )
		{
			m_poly_pressures[ i ].clear();
			m_control_changes[ i ].clear();
		}

		/* 
		 iterate through midi messages
		 send note on/off and program change immediately
		 store key pressure, control change, pitchbend in caches so that duplicates are not sent per frame
		*/

		for( int i = 0; i < number_of_midi_messages; i++ )
		{
			unsigned int message = midi_messages[ i ];

			unsigned int status_nibble = ( message & 0xF0 ) >> 4;
			unsigned int channel_nibble = message & 0xF;
			unsigned int value1 = ( message & 0xFF00 ) >> 8;
			unsigned int value2 = ( message & 0xFF0000 ) >> 16;

			assert( status_nibble >= 0 && status_nibble << 0xF );

			if( status_nibble < 0x8 )
			{
				INTEGRA_TRACE_ERROR << "Unexpected status nibble - should begin with 1: " << std::hex << message;
				continue;
			}

			if( value1 >= 0x80 )
			{
				INTEGRA_TRACE_ERROR << "Unexpected value 1 - should begin with 0: " << std::hex << message;
				continue;
			}

			if( value2 >= 0x80 )
			{
				INTEGRA_TRACE_ERROR << "Unexpected value 2 - should begin with 0: " << std::hex << message;
				continue;
			}

			switch( status_nibble )
			{
				case 0x8:	/* note off */
					m_pd->sendNoteOn( channel_nibble, value1, 0 );
					break;							

				case 0x9:	/* note on */
					m_pd->sendNoteOn( channel_nibble, value1, value2 );
					break;

				case 0xA:	/* polyphonic key pressure */
					m_poly_pressures[ channel_nibble ][ value1 ] = value2; 
					break;

				case 0xB:	/* control change */
					m_control_changes[ channel_nibble ][ value1 ] = value2;
					break;

				case 0xC:	/* program change */
					m_pd->sendProgramChange( channel_nibble, value1 );
					break;

				case 0xD:	/* channel pressure */
					m_channel_pressures[ channel_nibble ] = value1;
					break;

				case 0xE:	/* pitchbend */
					m_pitchbends[ channel_nibble ] = value1 | ( value2 << 7 );
					break;

				case 0xF:
					INTEGRA_TRACE_ERROR << "Unexpected system common / realtime message: " << std::hex << message;
					break;
			}
		}

		/* 
		 iterate through cached key pressure, control change and pitchbend
		*/

		for( int channel = 0; channel < midi_channels; channel++ )
		{
			const int_map &poly_pressures = m_poly_pressures[ channel ];
			for( int_map::const_iterator i = poly_pressures.begin(); i != poly_pressures.end(); i++ )
			{
				m_pd->sendPolyAftertouch( channel, i->first, i->second );
			}

			const int_map &control_changes = m_control_changes[ channel ];
			for( int_map::const_iterator i = control_changes.begin(); i != control_changes.end(); i++ )
			{
				m_pd->sendControlChange( channel, i->first, i->second );
			}

			int channel_pressure = m_channel_pressures[ channel ];
			if( channel_pressure >= 0 )
			{
				m_pd->sendAftertouch( channel, channel_pressure );
			}

			int pitchbend = m_pitchbends[ channel ];
			if( pitchbend >= 0 )
			{
				m_pd->sendPitchBend( channel, pitchbend );
			}
		}
	}
}

