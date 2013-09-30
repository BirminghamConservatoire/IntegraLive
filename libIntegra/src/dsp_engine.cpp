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
#include "api/command.h"
#include "api/trace.h"

#include "PdBase.hpp"

#include <fstream>

#include "windows.h" //todo - remove - for Sleep()

using namespace integra_api;


namespace integra_internal
{
	const int CDspEngine::samples_per_buffer = 64;
	const int CDspEngine::max_channels = 64;

	const string CDspEngine::patch_file_name = "host_patch_file.pd";
	const string CDspEngine::host_patch_name = "integra-canvas";
	const string CDspEngine::patch_message_target = "pd-" + host_patch_name;

	const string CDspEngine::feedback_source = "integra";

	const int CDspEngine::module_x_margin = 10;
	const int CDspEngine::module_y_spacing = 50;



	CDspEngine::CDspEngine( CServer &server )
		:	m_server( server )
	{
		Sleep( 10000 );

		pthread_mutex_init( &m_mutex, NULL );

		m_input_channels = 2;
		m_output_channels = 2;
		m_sample_rate = 44100;

		m_next_patch_id = 0;

		create_host_patch();

		m_pd = new pd::PdBase;
		m_pd->init( m_input_channels, m_output_channels, m_sample_rate );
		m_pd->computeAudio( true );

		pd::Patch patch = m_pd->openPatch( patch_file_name, m_server.get_scratch_directory() );
		if( !patch.isValid() )
		{
			INTEGRA_TRACE_ERROR << "failed to load patch: " << get_patch_file_path();
		}

		m_pd->subscribe( feedback_source );


		//m_pd->subscribe( ";pd" );
		//m_pd->subscribe( ";test_patch.pd" );

        //m_pd->startMessage();
        //m_pd->addSymbol( patch_path + "test_output_before_connect.pd" );
        //m_pd->finishMessage( "pd-test_patch.pd", "saveto" );

		/* m_pd->startMessage();
        m_pd->addFloat( 0 );
        m_pd->addFloat( 0 );
        m_pd->addFloat( 1 );
        m_pd->addFloat( 0 );
        m_pd->finishMessage( patch_message_target, "connect" ); */

		/*
		//test connect message
		pd::List list;
		list << 0 << 0 << 1 << 0;
		m_pd->sendMessage( ";" + dollarZeroStr + "-instance", "connect", list );

		//test save message
		list.clear();
		list << "c:/test/" << "test_output.pd";
		m_pd->sendMessage( ";" + dollarZeroStr + "-instance", "saveto", list );
		*/

		m_initialised = true;
	}


	CDspEngine::~CDspEngine()
	{
		pthread_mutex_lock( &m_mutex );

		m_pd->clear();
		delete m_pd;

		delete_host_patch();

		pthread_mutex_unlock( &m_mutex );

		pthread_mutex_destroy( &m_mutex );
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
				m_pd->computeAudio( true );
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



	CError CDspEngine::add_module( internal_id id, const string &patch_path )
	{
		INTEGRA_TRACE_VERBOSE << "add module id " << id << " as " << patch_path;

		pthread_mutex_lock( &m_mutex );

        m_pd->startMessage();
		m_pd->addFloat( module_x_margin );
        m_pd->addFloat( ( m_next_patch_id + 1 ) * module_y_spacing );
        m_pd->addSymbol( patch_path );
		m_pd->addFloat( id );
        m_pd->finishMessage( patch_message_target, "obj" );

		m_map_id_to_patch_id[ id ] = m_next_patch_id;

		m_next_patch_id++;

		pthread_mutex_unlock( &m_mutex );

		return CError::SUCCESS;
	}


	CError CDspEngine::remove_module( internal_id id )
	{
		INTEGRA_TRACE_VERBOSE << "remove module id " << id;

		pthread_mutex_lock( &m_mutex );

		ostringstream find;
		find << "+" << id;

		m_pd->startMessage();
        m_pd->addSymbol( find.str() );
		m_pd->addFloat( 1 );
		m_pd->finishMessage( patch_message_target, "find" );

		m_pd->sendMessage( patch_message_target, "cut" );

		pthread_mutex_unlock( &m_mutex );

		return CError::SUCCESS;
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

		m_pd->startMessage();
        m_pd->addFloat( node.get_id() );
        m_pd->addSymbol( target.get_endpoint_definition().get_name() );

		const CValue *value = target.get_value();
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
			m_pd->addSymbol( "bang" );
		}

        m_pd->finishList( "integra-broadcast-receive" );

		pthread_mutex_unlock( &m_mutex );

		return CError::SUCCESS;
	}


	void CDspEngine::process_buffer( const float *input, float *output, int input_channels, int output_channels, int sample_rate )
	{
		memset( output, 0, samples_per_buffer * output_channels * sizeof( float ) );

		pthread_mutex_lock( &m_mutex );

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

		if( has_configuration_changed( input_channels, output_channels, sample_rate ) )
		{
			initialize_audio_configuration( input_channels, output_channels, sample_rate );
		}

		if( m_initialised )
		{
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

		handle_feedback();
	}


	/*void CDspEngine::test_libpd()
	{
		//test_libpd only implemented in windows!
		#ifdef _WINDOWS
			const string patch_name = "test_patch.pd";
			const string path_path = "C:/";
			const string output_file = "C:/IntegraLive.git/testout.wav";

			const int input_channels( 2 );
			const int output_channels( 2 );
			const int ticks_per_buffer( 1 );
			const int samples_per_tick( 64 );
			const int ticks_to_process( 10000 );
			const int sample_rate( 44100 );

			const int input_buffer_samples( samples_per_tick * input_channels * ticks_per_buffer );
			const int output_buffer_samples( samples_per_tick * output_channels * ticks_per_buffer );

			pd::PdBase *pd = new pd::PdBase;

			bool success = pd->init( input_channels, output_channels, sample_rate );

			pd::Patch patch = pd->openPatch( patch_name, path_path );
			bool is_valid = patch.isValid();

			pd->computeAudio( true );

			short *input_buffer = new short[ input_buffer_samples ];
			short *output_buffer = new short[ output_buffer_samples ];

			WAVEFORMATEX wave_format;
			wave_format.wFormatTag = WAVE_FORMAT_PCM;
			wave_format.nChannels = output_channels;
			wave_format.nSamplesPerSec = sample_rate;
			wave_format.wBitsPerSample = sizeof( short ) * 8;
			wave_format.nBlockAlign = wave_format.nChannels * wave_format.wBitsPerSample / 8;
			wave_format.nAvgBytesPerSec = wave_format.nSamplesPerSec * wave_format.nBlockAlign;
			wave_format.cbSize = 0;

			unsigned long subchunk2size = output_buffer_samples * ticks_to_process * sizeof( short );

			unsigned long chunk_size = 36 + subchunk2size;

			FILE *f;
			fopen_s( &f, output_file.c_str(), "wb" );
			fwrite( "RIFF", 1, 4, f );
			fwrite( &chunk_size, 4, 1, f );
			fwrite( "WAVE", 1, 4, f );
			fwrite( "fmt ", 1, 4, f );

			unsigned long subchunk1size = 16;
			fwrite( &subchunk1size, 4, 1, f );
			fwrite( &wave_format, sizeof( WAVEFORMATEX ) - sizeof( WORD ), 1, f );

			fwrite( "data", 1, 4, f );
			fwrite( &subchunk2size, 4, 1, f );


			for( int i = 0; i < ticks_to_process; i++ )
			{
				memset( input_buffer, 0, input_buffer_samples * sizeof( short ) );
				memset( output_buffer, 0, output_buffer_samples * sizeof( short ) );

				pd->processShort( ticks_per_buffer, input_buffer, output_buffer );

				fwrite( output_buffer, sizeof( short ), output_buffer_samples, f );
			}

			fclose( f );
	
			delete [] input_buffer;
			delete [] output_buffer;

			pd->closePatch( patch );
			pd->clear();
			delete pd;
		#endif
	}*/


	void CDspEngine::poll_for_messages()
	{
		while( m_pd->numMessages() > 0 ) 
		{
			pd::Message &message = m_pd->nextMessage();

			if( message.dest == feedback_source )
			{
				m_incoming_feedback.push_back( message );
			}

			switch( message.type )
			{
				case pd::NONE:
					break;

				case pd::PRINT:
					break;

					// events
				case pd::BANG:
				case pd::FLOAT:
				case pd::SYMBOL:
				case pd::LIST:
				case pd::MESSAGE:
					break;

					// midi
				case pd::NOTE_ON:
				case pd::CONTROL_CHANGE:
				case pd::PROGRAM_CHANGE:
				case pd::PITCH_BEND:
				case pd::AFTERTOUCH:
				case pd::POLY_AFTERTOUCH:
				case pd::BYTE:
					break;

				default:
					INTEGRA_TRACE_ERROR << "unhandled pd message type: " << message.type;
					break;
			}

		}
	}


	void CDspEngine::handle_feedback()
	{
		if( m_incoming_feedback.empty() )
		{
			return;
		}

		m_server.lock();

		for( pd_message_list::const_iterator i = m_incoming_feedback.begin(); i != m_incoming_feedback.end(); i++ )
		{
			const pd::Message &message = *i;

			if( message.type != pd::LIST )
			{
				INTEGRA_TRACE_ERROR << "unexpected message type: " << message.type;
				continue;
			}

			const pd::List &list = message.list;

			ISetCommand *command = make_set_command( list );
		
			if( command )
			{
				CError result = m_server.process_command( command, CCommandSource::MODULE_IMPLEMENTATION );
				if( result != CError::SUCCESS )
				{
					INTEGRA_TRACE_ERROR << "Error processing command: " << result.get_text();
				}
			}
			else
			{
				INTEGRA_TRACE_ERROR << "Couldn't process command";
			}
		}

		m_server.unlock();

		m_incoming_feedback.clear();
	}


	ISetCommand *CDspEngine::make_set_command( const pd::List &feedback_arguments ) const
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
		CValue *value = NULL;

		switch( control_info.get_type() )
		{
			case IControlInfo::BANG:
				value = NULL;
				break;

			case IControlInfo::STATEFUL:
				switch( control_info.get_state_info()->get_type() )
				{
					case CValue::INTEGER:
						if( feedback_arguments.isFloat( 3 ) )
						{
							value = new CIntegerValue( feedback_arguments.getFloat( 3 ) );
						}
						else
						{
							INTEGRA_TRACE_ERROR << "Unexpected message value type";
						}
						break;

					case CValue::FLOAT:
						if( feedback_arguments.isFloat( 3 ) )
						{
							value = new CFloatValue( feedback_arguments.getFloat( 3 ) );
						}
						else
						{
							INTEGRA_TRACE_ERROR << "Unexpected message value type";
						}
						break;

					case CValue::STRING:
						if( feedback_arguments.isSymbol( 3 ) )
						{
							value = new CStringValue( feedback_arguments.getSymbol( 3 ) );
						}
						else
						{
							INTEGRA_TRACE_ERROR << "Unexpected message value type";
						}
						break;

					default:
						INTEGRA_TRACE_ERROR << "unhandled value type: " << control_info.get_state_info()->get_type();
						return NULL;
				}

				break;

			default:
				INTEGRA_TRACE_ERROR << "unhandled control type: " << control_info.get_type();
				return NULL;
		}

		return ISetCommand::create( node_endpoint->get_path(), value );
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

}

