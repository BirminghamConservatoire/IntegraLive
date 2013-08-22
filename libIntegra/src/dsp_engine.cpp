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
#include "api/trace.h"

#ifdef _WINDOWS
#include "windows.h"	//for test_libpd()
#endif

#include "PdBase.hpp"

using namespace integra_api;


namespace integra_internal
{
	CDspEngine::CDspEngine()
	{
		test_libpd();
	}


	CDspEngine::~CDspEngine()
	{
	}


	CError CDspEngine::add_module( internal_id id, const string &patch_path )
	{
		INTEGRA_TRACE_PROGRESS << "add module id " << id << " as " << patch_path;

		//todo - implement

		return CError::SUCCESS;
	}


	CError CDspEngine::remove_module( internal_id id )
	{
		INTEGRA_TRACE_PROGRESS << "remove module id " << id;

		//todo - implement

		return CError::SUCCESS;
	}


	CError CDspEngine::connect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target )
	{
		INTEGRA_TRACE_PROGRESS << "connect " << source.get_path().get_string() << " to " << target.get_path().get_string();

		//todo - implement

		return CError::SUCCESS;
	}


	CError CDspEngine::disconnect_modules( const CNodeEndpoint &source, const CNodeEndpoint &target )
	{
		INTEGRA_TRACE_PROGRESS << "disconnect " << source.get_path().get_string() << " from " << target.get_path().get_string();

		//todo - implement

		return CError::SUCCESS;
	}


	CError CDspEngine::send_value( const CNodeEndpoint &target )
	{
		INTEGRA_TRACE_PROGRESS << "send value to " << target.get_path().get_string();

		//todo - implement

		return CError::SUCCESS;
	}


	void CDspEngine::test_libpd()
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
	}


	string CDspEngine::get_stream_connection_name( const IEndpointDefinition &endpoint_definition, const IInterfaceDefinition &interface_definition ) const
	{
		bool found( false );
		int index = 1;

		if( !endpoint_definition.is_audio_stream() )
		{
			INTEGRA_TRACE_ERROR << "can't get stream connection name for non-audio stream!";
			return string();
		}

		endpoint_definition_list endpoint_definitions = interface_definition.get_endpoint_definitions();
		for( endpoint_definition_list::const_iterator i = endpoint_definitions.begin(); i != endpoint_definitions.end(); i++ )
		{
			const IEndpointDefinition *prior_endpoint = *i;
		
			if( prior_endpoint == &endpoint_definition )
			{
				found = true;
				break;
			}

			if( prior_endpoint->is_audio_stream() ) 
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
			return false;
		}

		ostringstream stream;

		switch( endpoint_definition.get_stream_info()->get_direction() )
		{
			case CStreamInfo::INPUT:
				stream << "in";
				break;

			case CStreamInfo::OUTPUT:
				stream << "out";
				break;

			default:
				INTEGRA_TRACE_ERROR << "unhandled stream direction";
				return string();
		}

		stream << index;
		return stream.str();
	}

}

