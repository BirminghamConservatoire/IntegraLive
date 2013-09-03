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

#include "portaudio_engine.h"
#include "dsp_engine.h"
#include "api/trace.h"
#include "api/string_helper.h"

#include <assert.h>
#include <algorithm>	

#include <windows.h>		//todo - remove - for Sleep()


namespace integra_internal
{
	const string CPortAudioEngine::none = "none";


	CPortAudioEngine::CPortAudioEngine()
	{
		Sleep( 10000 );

		m_selected_api = api_none();
		m_selected_input_device = paNoDevice;
		m_selected_output_device = paNoDevice;

		m_number_of_input_channels = 0;
		m_number_of_output_channels = 0;

		m_sample_rate = 0;

		m_input_stream = NULL;
		m_output_stream = NULL;
		m_duplex_stream = NULL;

		PaError error_code = Pa_Initialize();
		m_initialized_ok = ( error_code == paNoError );
		if( !m_initialized_ok )
		{
			INTEGRA_TRACE_ERROR << "PortAudio initialization error: " << Pa_GetErrorText( error_code );
			return;
		}

		update_available_apis();

		set_driver( none );

		INTEGRA_TRACE_PROGRESS << "Created PortAudio engine";
	}


	CPortAudioEngine::~CPortAudioEngine()
	{
		if( !m_initialized_ok ) 
		{
			return;
		}

		close_streams();

		PaError error_code = Pa_Terminate();
		if( error_code != paNoError )
		{
			INTEGRA_TRACE_ERROR << "PortAudio termination error: " << Pa_GetErrorText( error_code );
		}

		INTEGRA_TRACE_PROGRESS << "Destroyed PortAudio engine";
	}


	CError CPortAudioEngine::set_driver( const string &driver )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		api_map::const_iterator lookup = m_available_apis.find( driver );
		if( lookup == m_available_apis.end() )
		{
			return CError::INPUT_ERROR;
		}

		if( lookup->second == m_selected_api )
		{
			/* reselecting existing driver */
			return CError::SUCCESS;		
		}

		close_streams();

		m_selected_api = lookup->second;

		m_selected_input_device = paNoDevice;
		m_selected_output_device = paNoDevice;

		m_number_of_input_channels = 0;
		m_number_of_output_channels = 0;

		update_available_devices();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_input_device( const string &input_device )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		device_map::const_iterator lookup = m_available_input_devices.find( input_device );
		if( lookup == m_available_input_devices.end() )
		{
			return CError::INPUT_ERROR;
		}

		PaDeviceIndex new_input_device = lookup->second;

		if( new_input_device == m_selected_input_device )
		{
			/* reselecting existing device */
			return CError::SUCCESS;		
		}

		close_streams();

		m_selected_input_device = new_input_device;
		m_number_of_input_channels = 0;

		open_streams();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_output_device( const string &output_device )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		device_map::const_iterator lookup = m_available_output_devices.find( output_device );
		if( lookup == m_available_output_devices.end() )
		{
			return CError::INPUT_ERROR;
		}

		PaDeviceIndex new_output_device = lookup->second;

		if( new_output_device == m_selected_output_device )
		{
			/* reselecting existing device */
			return CError::SUCCESS;		
		}

		close_streams();

		m_selected_output_device = new_output_device;
		m_number_of_output_channels = 0;

		open_streams();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_sample_rate( int sample_rate )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_streams();

		m_sample_rate = sample_rate;

		open_streams();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_number_of_input_channels( int input_channels )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_streams();

		m_number_of_input_channels = input_channels;

		open_streams();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_number_of_output_channels( int output_channels )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_streams();

		m_number_of_output_channels = output_channels;

		open_streams();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::restore_defaults()
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		return CError::SUCCESS;
	}


	string_vector CPortAudioEngine::get_available_drivers() const
	{
		string_vector drivers;

		for( api_map::const_iterator i = m_available_apis.begin(); i != m_available_apis.end(); i++ )
		{
			drivers.push_back( i->first );
		}

		std::sort( drivers.begin(), drivers.end(), CCompareApiNames( m_available_apis ) );

		return drivers;
	}


	string_vector CPortAudioEngine::get_available_input_devices() const
	{
		return get_available_devices( m_available_input_devices );
	}


	string_vector CPortAudioEngine::get_available_output_devices() const
	{
		return get_available_devices( m_available_output_devices );
	}


	string_vector CPortAudioEngine::get_available_devices( const device_map &device_map ) const
	{
		string_vector devices;

		for( device_map::const_iterator i = device_map.begin(); i != device_map.end(); i++ )
		{
			devices.push_back( i->first );
		}

		std::sort( devices.begin(), devices.end(), CCompareDeviceNames( device_map ) );

		return devices;
	}


	string CPortAudioEngine::get_selected_driver() const
	{
		if( m_selected_api == api_none() )
		{
			return none;
		}

		const PaHostApiInfo *api_info = Pa_GetHostApiInfo( get_selected_api_index() );
		if( !api_info )
		{
			INTEGRA_TRACE_ERROR << "can't get api info";
			return none;
		}

		return CStringHelper::trim( api_info->name );
	}


	string CPortAudioEngine::get_selected_input_device() const
	{
		if( m_selected_input_device == paNoDevice )
		{
			return none;
		}

		const PaDeviceInfo *device_info = Pa_GetDeviceInfo( m_selected_input_device );
		if( !device_info )
		{
			INTEGRA_TRACE_ERROR << "can't get device info";
			return none;
		}

		return CStringHelper::trim( device_info->name );
	}


	string CPortAudioEngine::get_selected_output_device() const
	{
		if( m_selected_output_device == paNoDevice )
		{
			return none;
		}

		const PaDeviceInfo *device_info = Pa_GetDeviceInfo( m_selected_output_device );
		if( !device_info )
		{
			INTEGRA_TRACE_ERROR << "can't get device info";
			return none;
		}

		return CStringHelper::trim( device_info->name );
	}


	int CPortAudioEngine::get_sample_rate() const
	{
		return m_sample_rate;
	}


	int CPortAudioEngine::get_number_of_input_channels() const
	{
		return m_number_of_input_channels;
	}


	int CPortAudioEngine::get_number_of_output_channels() const
	{
		return m_number_of_output_channels;
	}


	void CPortAudioEngine::update_available_apis()
	{
		assert( m_initialized_ok );

		m_available_apis.clear();

		m_available_apis[ none ] = api_none();

		PaHostApiIndex api_count = Pa_GetHostApiCount();
		if( api_count < 0 )
		{
			INTEGRA_TRACE_ERROR << "Error getting api count: " << Pa_GetErrorText( api_count );
			return;
		}

		for( PaHostApiIndex i = 0; i < api_count; i++ )
		{
			const PaHostApiInfo *api_info = Pa_GetHostApiInfo( i );
			if( !api_info )
			{
				INTEGRA_TRACE_ERROR << "Pa_GetHostApiInfo returned NULL";
				continue;
			}

			m_available_apis[ CStringHelper::trim( api_info->name ) ] = api_info->type;
		}
	}


	void CPortAudioEngine::update_available_devices()
	{
		assert( m_initialized_ok );

		m_available_input_devices.clear();
		m_available_output_devices.clear();

		m_available_input_devices[ none ] = paNoDevice;
		m_available_output_devices[ none ] = paNoDevice;

		int numberOfDevices = Pa_GetDeviceCount();
		if( numberOfDevices < 0 )
		{
			INTEGRA_TRACE_ERROR << "Error in Pa_GetDeviceCount: " << Pa_GetErrorText( numberOfDevices );
			return;
		}

		int api_index = get_selected_api_index();

		for( PaDeviceIndex i = 0; i < numberOfDevices; i++ )
		{
			const PaDeviceInfo *device_info = Pa_GetDeviceInfo( i );
			if( !device_info )
			{
				INTEGRA_TRACE_ERROR << "Error in Pa_GetDeviceInfo";
				continue;
			}

			if( device_info->hostApi != api_index ) 
			{
				continue;
			}

			if( device_info->maxInputChannels > 0 )
			{
				m_available_input_devices[ CStringHelper::trim( device_info->name ) ] = i;
			}

			if( device_info->maxOutputChannels > 0 )
			{
				m_available_output_devices[ CStringHelper::trim( device_info->name ) ] = i;
			}
		}
	}


	void CPortAudioEngine::open_streams()
	{
		#ifdef _WINDOWS
			CoInitialize( NULL );
		#endif

		if( m_selected_input_device != paNoDevice )
		{
			if( m_selected_output_device == m_selected_input_device )
			{
				//open duplex stream
				PaStreamParameters input_parameters, output_parameters;
				initialize_stream_parameters( input_parameters, m_selected_input_device, false );
				initialize_stream_parameters( output_parameters, m_selected_output_device, true );

				PaError supported = Pa_IsFormatSupported( &input_parameters, &output_parameters, m_sample_rate );
				if( supported != paFormatIsSupported )
				{
					m_sample_rate = get_default_sample_rate( m_selected_input_device );
				}

				PaError result = Pa_OpenStream( &m_duplex_stream, &input_parameters, &output_parameters, m_sample_rate, CDspEngine::samples_per_buffer, paNoFlag, duplex_callback, this );
				if( result == paNoError )
				{
					result = Pa_StartStream( m_duplex_stream );
					if( result == paNoError )
					{
						INTEGRA_TRACE_PROGRESS << "Started Duplex Audio Stream";
					}
					else
					{
						INTEGRA_TRACE_ERROR << "Error starting duplex stream: " << Pa_GetErrorText( result );
						m_selected_input_device = paNoDevice;
						m_selected_output_device = paNoDevice;
					}
				}
				else
				{
					INTEGRA_TRACE_ERROR << "Error opening duplex stream: " << Pa_GetErrorText( result );
					m_selected_input_device = paNoDevice;
					m_selected_output_device = paNoDevice;
				}
			}
			else
			{
				//open input stream
				PaStreamParameters input_parameters;
				initialize_stream_parameters( input_parameters, m_selected_input_device, false );

				PaError supported = Pa_IsFormatSupported( &input_parameters, NULL, m_sample_rate );
				if( supported != paFormatIsSupported )
				{
					m_sample_rate = get_default_sample_rate( m_selected_input_device );
				}

				PaError result = Pa_OpenStream( &m_input_stream, &input_parameters, NULL, m_sample_rate, CDspEngine::samples_per_buffer, paNoFlag, input_callback, this );
				if( result == paNoError )
				{
					result = Pa_StartStream( m_input_stream );
					if( result == paNoError )
					{
						INTEGRA_TRACE_PROGRESS << "Started Audio Input Stream";
					}
					else
					{
						INTEGRA_TRACE_ERROR << "Error starting input stream: " << Pa_GetErrorText( result );
						m_selected_input_device = paNoDevice;
					}
				}
				else
				{
					INTEGRA_TRACE_ERROR << "Error opening input stream: " << Pa_GetErrorText( result );
					m_selected_input_device = paNoDevice;
				}
			}
		}

		if( m_selected_output_device != paNoDevice && m_selected_output_device != m_selected_input_device )
		{
			//open output stream
			PaStreamParameters output_parameters;
			initialize_stream_parameters( output_parameters, m_selected_output_device, true );

			PaError supported = Pa_IsFormatSupported( NULL, &output_parameters, m_sample_rate );
			if( supported != paFormatIsSupported )
			{
				m_sample_rate = get_default_sample_rate( m_selected_output_device );
			}

			PaError result = Pa_OpenStream( &m_output_stream, NULL, &output_parameters, m_sample_rate, CDspEngine::samples_per_buffer, paNoFlag, output_callback, this );
			if( result == paNoError )
			{
				result = Pa_StartStream( m_output_stream );
				if( result == paNoError )
				{
					INTEGRA_TRACE_PROGRESS << "Started Audio Output Stream";

					/*if( m_selected_input_device != paNoDevice )
					{
						m_ring_buffer = new CRingBuffer;
					}*/
				}
				else
				{
					INTEGRA_TRACE_ERROR << "Error starting output stream: " << Pa_GetErrorText( result );
					m_selected_output_device = paNoDevice;
				}
			}
			else
			{
				INTEGRA_TRACE_ERROR << "Error opening output stream: " << Pa_GetErrorText( result );
				m_selected_output_device = paNoDevice;
			}
		}	

		#ifdef _WINDOWS
			CoUninitialize();
		#endif
	}


	void CPortAudioEngine::close_streams()
	{
		if( m_input_stream ) 
		{
			Pa_CloseStream( m_input_stream );
			m_input_stream = NULL;

			INTEGRA_TRACE_PROGRESS << "Closed input stream";
		}

		if( m_output_stream ) 
		{
			Pa_CloseStream( m_output_stream );
			m_output_stream = NULL;

			INTEGRA_TRACE_PROGRESS << "Closed output stream";
		}

		if( m_duplex_stream ) 
		{
			Pa_CloseStream( m_duplex_stream );
			m_duplex_stream = NULL;

			INTEGRA_TRACE_PROGRESS << "Closed duplex stream";
		}
	}


	void CPortAudioEngine::initialize_stream_parameters( PaStreamParameters &parameters, int device_index, bool is_output )
	{
		assert( m_initialized_ok );

		const PaDeviceInfo *info = Pa_GetDeviceInfo( device_index );
		assert( info );

		int &number_of_channels = is_output ? m_number_of_output_channels : m_number_of_input_channels;
		const int &max_number_of_channels = is_output ? info->maxOutputChannels : info->maxInputChannels;

		if( number_of_channels <= 0 )
		{
			number_of_channels = max_number_of_channels;
		}
		else
		{
			number_of_channels = MIN( number_of_channels, max_number_of_channels );
		}

		parameters.device = device_index;
		parameters.channelCount = number_of_channels;
		parameters.sampleFormat = paFloat32;
	
		parameters.suggestedLatency = is_output ? info->defaultLowOutputLatency : info->defaultLowInputLatency;

		parameters.hostApiSpecificStreamInfo = NULL;
	}


	int CPortAudioEngine::get_default_sample_rate( int device_index ) const
	{
		assert( m_initialized_ok );

		const PaDeviceInfo *info = Pa_GetDeviceInfo( device_index );
		assert( info );

		return info->defaultSampleRate;
	}


	void CPortAudioEngine::input_handler( const void *input_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags )
	{
		if( status_flags & paInputUnderflow )
		{
			INTEGRA_TRACE_ERROR << "input underflow";
		}

		if( status_flags & paInputOverflow )
		{
			INTEGRA_TRACE_ERROR << "input overflow";
		}

		/*if( dlg->m_outputDeviceIndex >= 0 )
		{
			ASSERT( dlg->m_ringBuffer );
			dlg->m_ringBuffer->write( ( const SAMPLE * ) inputBuffer, framesPerBuffer * NUMBER_OF_CHANNELS );
		}
		else
		{
			dlg->doSomeProcessing( ( const SAMPLE * ) inputBuffer, NULL, framesPerBuffer );
		}*/
	}


	void CPortAudioEngine::output_handler( void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags )
	{
		if( status_flags & paOutputUnderflow )
		{
			INTEGRA_TRACE_ERROR << "output underflow";
		}

		if( status_flags & paOutputOverflow )
		{
			INTEGRA_TRACE_ERROR << "output overflow";
		}

		static float theta[ 32 ];

		float *output = ( float * ) output_buffer;
		for( int i = 0; i < frames_per_buffer; i++ )
		{
			for( int channel = 0; channel < m_number_of_output_channels; channel++ )
			{
				float value = sin( theta[ channel ] );
				output[ i * m_number_of_output_channels + channel ] = value;

				theta[ channel ] += 0.05 * ( channel + 1 );
				if( theta[ channel ] >= 6.283185307179586476925286766559 )
				{
					theta[ channel ] -= 6.283185307179586476925286766559;
				}
			}
		}

		//ensure process buffer exists and is large enough
		/*int sizeNeeded = framesPerBuffer * NUMBER_OF_CHANNELS;
		if( dlg->m_processBuffer ) 
		{
			if( dlg->m_processBufferSize < sizeNeeded )
			{
				delete[] dlg->m_processBuffer;
				dlg->m_processBuffer = new float[ sizeNeeded ];
				dlg->m_processBufferSize = sizeNeeded;
			}
		}
		else
		{
			dlg->m_processBuffer = new float[ sizeNeeded ];
			dlg->m_processBufferSize = sizeNeeded;
		}

		if( dlg->m_ringBuffer )
		{
			dlg->m_ringBuffer->read( dlg->m_processBuffer, framesPerBuffer * NUMBER_OF_CHANNELS );
		}

		dlg->doSomeProcessing( dlg->m_processBuffer, ( SAMPLE * ) outputBuffer, framesPerBuffer );

		return paContinue;*/
	}


	void CPortAudioEngine::duplex_handler( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags )
	{
		if( status_flags & paInputUnderflow )
		{
			INTEGRA_TRACE_ERROR << "input underflow";
		}

		if( status_flags & paInputOverflow )
		{
			INTEGRA_TRACE_ERROR << "input overflow";
		}

		if( status_flags & paOutputUnderflow )
		{
			INTEGRA_TRACE_ERROR << "output underflow";
		}

		if( status_flags & paOutputOverflow )
		{
			INTEGRA_TRACE_ERROR << "output overflow";
		}

		//todo

		static float theta[ 32 ];

		float *output = ( float * ) output_buffer;
		for( int i = 0; i < frames_per_buffer; i++ )
		{
			for( int channel = 0; channel < m_number_of_output_channels; channel++ )
			{
				float value = sin( theta[ channel ] );
				output[ i * m_number_of_output_channels + channel ] = value;

				theta[ channel ] += 0.08 * ( channel + 1 );
				if( theta[ channel ] >= 6.283185307179586476925286766559 )
				{
					theta[ channel ] -= 6.283185307179586476925286766559;
				}
			}
		}
	}


	PaHostApiTypeId CPortAudioEngine::api_none() const
	{
		return ( PaHostApiTypeId ) -1;
	}


	PaHostApiIndex CPortAudioEngine::get_selected_api_index() const
	{
		if( m_selected_api == api_none() ) 
		{
			return -1;
		}

		PaHostApiIndex api_index = Pa_HostApiTypeIdToHostApiIndex( m_selected_api );
		if( api_index >= 0 )
		{
			return api_index;
		}

		INTEGRA_TRACE_ERROR << "Error interpreting api id: " << Pa_GetErrorText( api_index );
		return -1;
	}


	CPortAudioEngine::CCompareApiNames::CCompareApiNames( const api_map &context )
		:	m_context( context )
	{
	}


	bool CPortAudioEngine::CCompareApiNames::operator()( const string &api_name_1, const string &api_name_2 ) const
	{
		api_map::const_iterator lookup1 = m_context.find( api_name_1 );
		api_map::const_iterator lookup2 = m_context.find( api_name_2 );
		if( lookup1 == m_context.end() || lookup2 == m_context.end() )
		{
			INTEGRA_TRACE_ERROR << "no api id for one of these api names: " << api_name_1 << api_name_2;
			return false;
		}

		return lookup1->second < lookup2->second;
	}


	CPortAudioEngine::CCompareDeviceNames::CCompareDeviceNames( const device_map &context )
		:	m_context( context )
	{
	}


	bool CPortAudioEngine::CCompareDeviceNames::operator()( const string &device_name_1, const string &device_name_2 ) const
	{
		device_map::const_iterator lookup1 = m_context.find( device_name_1 );
		device_map::const_iterator lookup2 = m_context.find( device_name_2 );
		if( lookup1 == m_context.end() || lookup2 == m_context.end() )
		{
			INTEGRA_TRACE_ERROR << "no device id for one of these api names: " << device_name_1 << device_name_2;
			return false;
		}

		return lookup1->second < lookup2->second;
	}


	static int input_callback( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags, void *user_data )
	{
		CPortAudioEngine *port_audio_engine = ( CPortAudioEngine * ) user_data;
		assert( port_audio_engine );

		port_audio_engine->input_handler( input_buffer, frames_per_buffer, time_info, status_flags );
		return paContinue;
	}


	static int output_callback( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags, void *user_data )
	{
		CPortAudioEngine *port_audio_engine = ( CPortAudioEngine * ) user_data;
		assert( port_audio_engine );

		port_audio_engine->output_handler( output_buffer, frames_per_buffer, time_info, status_flags );
		return paContinue;
	}


	static int duplex_callback( const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags status_flags, void *user_data )
	{
		CPortAudioEngine *port_audio_engine = ( CPortAudioEngine * ) user_data;
		assert( port_audio_engine );

		port_audio_engine->duplex_handler( input_buffer, output_buffer, frames_per_buffer, time_info, status_flags );
		return paContinue;
	}
}

 