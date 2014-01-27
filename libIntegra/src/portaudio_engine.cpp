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

#include "portaudio_engine.h"
#include "dsp_engine.h"
#include "ring_buffer.h"
#include "api/trace.h"
#include "api/string_helper.h"

#include <assert.h>
#include <algorithm>	
#include <unistd.h>

#ifdef _WINDOWS
	#include <windows.h>	/* for CoInitialize, CoUninitialize, Sleep */
#endif


namespace integra_internal
{
	const string CPortAudioEngine::none = "none";

	const int CPortAudioEngine::potential_sample_rates[] = { 11025, 22050, 32000, 44100, 48000, 96000, 192000, 0 };

	const int CPortAudioEngine::ring_buffer_msecs = 2000;


	CPortAudioEngine::CPortAudioEngine()
	{
		m_selected_api = api_none();
		m_selected_input_device = paNoDevice;
		m_selected_output_device = paNoDevice;

		m_number_of_input_channels = 0;
		m_number_of_output_channels = 0;

		m_sample_rate = 0;

		m_input_stream = NULL;
		m_output_stream = NULL;
		m_duplex_stream = NULL;

		m_ring_buffer = new CRingBuffer;

		m_dummy_input_buffer = NULL;
		m_process_buffer = NULL;

		m_no_device_thread = NULL;
		sem_init( &m_stop_no_device_thread, 0, 0 );

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
		
		delete m_ring_buffer;

		assert( !m_dummy_input_buffer );
		assert( !m_process_buffer );

		assert( !m_no_device_thread );
		sem_destroy( &m_stop_no_device_thread );

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
		update_available_sample_rates();

		set_input_device_to_default();
		set_output_device_to_default();

		if( m_selected_api == api_none() )
		{
			start_no_device_thread();
		}

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

		if( new_input_device == paNoDevice && m_selected_output_device == m_selected_input_device )
		{
			/* deselecting duplex device */
			m_selected_output_device = paNoDevice;
		}

		m_selected_input_device = new_input_device;
		m_number_of_input_channels = 0;

		if( new_input_device != paNoDevice && m_available_output_devices.count( input_device ) > 0 )
		{
			/* selecting duplex device */
			m_selected_output_device = new_input_device;
			m_number_of_output_channels = 0;
		}

		open_streams();

		update_available_sample_rates();

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

		if( new_output_device == paNoDevice && m_selected_input_device == m_selected_output_device )
		{
			/* deselecting duplex device */
			m_selected_input_device = paNoDevice;
		}

		m_selected_output_device = new_output_device;
		m_number_of_output_channels = 0;

		if( new_output_device != paNoDevice && m_available_input_devices.count( output_device ) > 0 )
		{
			/* selecting duplex device */
			m_selected_input_device = new_output_device;
			m_number_of_input_channels = 0;
		}

		open_streams();

		update_available_sample_rates();

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

		if( m_selected_input_device == paNoDevice )
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

		if( m_selected_output_device == paNoDevice )
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

		PaHostApiIndex default_api_index = Pa_GetDefaultHostApi();
		if( default_api_index < 0 )
		{
			INTEGRA_TRACE_ERROR << "Failed to get default host api: " << Pa_GetErrorText( default_api_index );
			set_driver( none );
			return CError::FAILED;
		}

		const PaHostApiInfo *api_info = Pa_GetHostApiInfo( default_api_index );
		if( !api_info )
		{
			INTEGRA_TRACE_ERROR << "Failed to get default api info";
			set_driver( none );
			return CError::FAILED;
		}

		set_driver( api_info->name );

		set_input_device_to_default();
		set_output_device_to_default();

		set_sample_rate( 0 );

		return CError::SUCCESS;
	}


	void CPortAudioEngine::set_input_device_to_default()
	{
		if( m_selected_api == api_none() ) 
		{
			return;
		}

		const PaHostApiInfo *api_info = Pa_GetHostApiInfo( Pa_HostApiTypeIdToHostApiIndex( m_selected_api ) );
		if( !api_info )
		{
			INTEGRA_TRACE_ERROR << "Failed to get api info";
			return;
		}

		string default_input_device( none );

		if( api_info->defaultInputDevice != paNoDevice )
		{
			const PaDeviceInfo *input_device = Pa_GetDeviceInfo( api_info->defaultInputDevice );
			if( input_device )
			{
				default_input_device = input_device->name;
			}
			else
			{
				INTEGRA_TRACE_ERROR << "failed to get device info for default input device " << api_info->defaultInputDevice;
			}
		}

		set_input_device( default_input_device );
	}


	void CPortAudioEngine::set_output_device_to_default()
	{
		if( m_selected_api == api_none() ) 
		{
			return;
		}

		const PaHostApiInfo *api_info = Pa_GetHostApiInfo( Pa_HostApiTypeIdToHostApiIndex( m_selected_api ) );
		if( !api_info )
		{
			INTEGRA_TRACE_ERROR << "Failed to get api info";
			return;
		}

		string default_output_device( none );

		if( api_info->defaultOutputDevice != paNoDevice )
		{
			const PaDeviceInfo *output_device = Pa_GetDeviceInfo( api_info->defaultOutputDevice );
			if( output_device )
			{
				default_output_device = output_device->name;
			}
			else
			{
				INTEGRA_TRACE_ERROR << "failed to get device info for default input device " << api_info->defaultInputDevice;
			}
		}

		set_output_device( default_output_device );
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


	int_vector CPortAudioEngine::get_available_sample_rates() const
	{
		return m_available_sample_rates;
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


	void CPortAudioEngine::update_available_sample_rates()
	{
		m_available_sample_rates.clear();

		bool has_input = ( m_selected_input_device != paNoDevice );
		bool has_output = ( m_selected_output_device != paNoDevice );

		if( !has_input && !has_output )
		{
			return;
		}

		PaStreamParameters input_parameters, output_parameters;
		if( has_input )
		{
			initialize_stream_parameters( input_parameters, m_selected_input_device, false );
		}

		if( has_output )
		{
			initialize_stream_parameters( output_parameters, m_selected_output_device, true );
		}

		bool is_duplex = is_duplex_mode();

		for( int i = 0; true; i++ )
		{
			int potential_sample_rate = potential_sample_rates[ i ];
			if( !potential_sample_rate )
			{
				break;
			}

			if( is_duplex )
			{
				if( Pa_IsFormatSupported( &input_parameters, &output_parameters, potential_sample_rate ) != paFormatIsSupported )
				{
					continue;
				}
			}
			else
			{
				if( has_input )
				{
					if( Pa_IsFormatSupported( &input_parameters, NULL, potential_sample_rate ) != paFormatIsSupported )
					{
						continue;
					}
				}

				if( has_output )
				{
					if( Pa_IsFormatSupported( NULL, &output_parameters, potential_sample_rate ) != paFormatIsSupported )
					{
						continue;
					}
				}
			}
			
			m_available_sample_rates.push_back( potential_sample_rate );
		}
	}


	bool CPortAudioEngine::is_duplex_mode() const
	{
		return ( m_selected_output_device == m_selected_input_device && m_selected_output_device != paNoDevice );
	}


	void CPortAudioEngine::open_streams()
	{
		#ifdef _WINDOWS
			CoInitialize( NULL );
		#endif

		if( is_duplex_mode() )
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
					Pa_CloseStream( m_duplex_stream );

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
			if( m_selected_input_device != paNoDevice )
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
						Pa_CloseStream( m_input_stream );

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

			if( m_selected_output_device != paNoDevice )
			{
				//open output stream
				PaStreamParameters output_parameters;
				initialize_stream_parameters( output_parameters, m_selected_output_device, true );

				PaError supported = Pa_IsFormatSupported( NULL, &output_parameters, m_sample_rate );
				if( supported != paFormatIsSupported )
				{
					if( m_selected_input_device == paNoDevice )
					{
						m_sample_rate = get_default_sample_rate( m_selected_output_device );
					}
					else
					{
						INTEGRA_TRACE_ERROR << "Requested output device cannot use sample rate of input device - won't open";
					}
				}

				create_process_buffer();

				initialize_ring_buffer();

				PaError result = Pa_OpenStream( &m_output_stream, NULL, &output_parameters, m_sample_rate, CDspEngine::samples_per_buffer, paNoFlag, output_callback, this );
				if( result == paNoError )
				{
					result = Pa_StartStream( m_output_stream );
					if( result == paNoError )
					{
						INTEGRA_TRACE_PROGRESS << "Started Audio Output Stream";
					}
					else
					{
						Pa_CloseStream( m_output_stream );
					
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
		}

		if( !m_duplex_stream && !m_input_stream && !m_output_stream )
		{
			start_no_device_thread();
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

		if( m_no_device_thread )
		{
			stop_no_device_thread();
		}

		if( m_dummy_input_buffer )
		{
			delete [] m_dummy_input_buffer;
			m_dummy_input_buffer = NULL;
		}

		if( m_process_buffer )
		{
			delete [] m_process_buffer;
			m_process_buffer = NULL;
		}
	}


	void CPortAudioEngine::initialize_ring_buffer()
	{
		m_ring_buffer->set_number_of_channels( m_number_of_output_channels );
		m_ring_buffer->set_buffer_length( ring_buffer_msecs * m_sample_rate / 1000 );
		m_ring_buffer->clear();
	}


	void CPortAudioEngine::create_process_buffer()
	{
		assert( !m_process_buffer );
		m_process_buffer = new float[ CDspEngine::samples_per_buffer * m_number_of_output_channels ];
		memset( m_process_buffer, 0, CDspEngine::samples_per_buffer * m_number_of_output_channels * sizeof( float ) );
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
		
		const float *input = static_cast< const float * > ( input_buffer );

		if( m_process_buffer )
		{
			get_dsp_engine().process_buffer( input, m_process_buffer, m_number_of_input_channels, m_number_of_output_channels, m_sample_rate );
			m_ring_buffer->write( m_process_buffer, frames_per_buffer );
		}
		else
		{
			get_dsp_engine().process_buffer( input, NULL, m_number_of_input_channels, 0, m_sample_rate );
		}
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

		assert( frames_per_buffer == CDspEngine::samples_per_buffer );

		float *output = static_cast< float * > ( output_buffer );

		assert( m_process_buffer );

		if( m_input_stream )
		{
			m_ring_buffer->read( output, CDspEngine::samples_per_buffer );
		}
		else
		{
			if( !m_dummy_input_buffer )
			{
				m_dummy_input_buffer = new float[ CDspEngine::samples_per_buffer * m_number_of_input_channels ];
				memset( m_dummy_input_buffer, 0, CDspEngine::samples_per_buffer * m_number_of_input_channels * sizeof( float ) );
			}

			get_dsp_engine().process_buffer( m_dummy_input_buffer, output, m_number_of_input_channels, m_number_of_output_channels, m_sample_rate );
		}
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

		assert( frames_per_buffer == CDspEngine::samples_per_buffer );

		const float *input = static_cast< const float * >( input_buffer );
		float *output = static_cast< float * >( output_buffer );

		get_dsp_engine().process_buffer( input, output, m_number_of_input_channels, m_number_of_output_channels, m_sample_rate );
	}


	void CPortAudioEngine::start_no_device_thread()
	{
		assert( !m_no_device_thread );

		m_no_device_thread = new pthread_t;
		pthread_create( m_no_device_thread, NULL, no_device_thread, this );
	}


	void CPortAudioEngine::stop_no_device_thread()
	{
		assert( m_no_device_thread );

		sem_post( &m_stop_no_device_thread );
		pthread_join( *m_no_device_thread, NULL);
		delete m_no_device_thread;
		m_no_device_thread = NULL;
	}

		
	void CPortAudioEngine::run_no_device_thread()
	{
		/*
		 this thread runs whenever there is neither an input device nor an output device.  
		 it simply pumps silence through the dsp engine to ensure that midi is still polled and pd
		 logic eg VUs from generators etc still work
		*/

		const int number_of_channels = 2;
		const int sample_rate = 44100;
		const int buffers_per_cycle = 10;
		const int update_microseconds = 1000000 * CDspEngine::samples_per_buffer * buffers_per_cycle / sample_rate;

		float *in_buffer = new float[ CDspEngine::samples_per_buffer * number_of_channels ];
		float *out_buffer = new float[ CDspEngine::samples_per_buffer * number_of_channels ];
		memset( out_buffer, 0, CDspEngine::samples_per_buffer * number_of_channels * sizeof( float ) );

		while( sem_trywait( &m_stop_no_device_thread ) < 0 ) 
		{
			usleep( update_microseconds );

			for( int i = 0; i < buffers_per_cycle; i++ )
			{
				memset( in_buffer, 0, CDspEngine::samples_per_buffer * number_of_channels * sizeof( float ) );
				get_dsp_engine().process_buffer( in_buffer, out_buffer, number_of_channels, number_of_channels, sample_rate );
			}
		}

		delete[] in_buffer;
		delete[] out_buffer;
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


	static void *no_device_thread( void *context )
	{
		CPortAudioEngine *port_audio_engine = ( CPortAudioEngine * ) context;
		assert( port_audio_engine );
		
		port_audio_engine->run_no_device_thread();

		return NULL;
	}

}

 