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

#include "portmidi_engine.h"
#include "api/trace.h"
#include "api/string_helper.h"

#include <assert.h>
#include <algorithm>	


namespace integra_internal
{
	const string CPortMidiEngine::none = "none";
	const int CPortMidiEngine::input_buffer_size = 1024;

	CPortMidiEngine::CPortMidiEngine()
	{
		m_current_input_device_id = pmNoDevice;
		m_current_output_device_id = pmNoDevice;

		m_input_stream = NULL;
		m_output_stream = NULL;

		m_input_event_buffer = new PmEvent[ input_buffer_size ];
		m_input_message_buffer = new unsigned int[ input_buffer_size ];

		pthread_mutex_init( &m_input_mutex, NULL );
		pthread_mutex_init( &m_output_mutex, NULL );

		PmError error = Pm_Initialize();

		if( error != pmNoError )
		{
			INTEGRA_TRACE_ERROR << "Failed to initialize PortMidi: " << Pm_GetErrorText( error );
			m_initialized_ok = false;
			return;
		}

		find_available_devices();

		m_initialized_ok = true;

		INTEGRA_TRACE_PROGRESS << "Created PortMidi engine";
	}


	CPortMidiEngine::~CPortMidiEngine()
	{
		if( !m_initialized_ok ) 
		{
			return;
		}

		close_input_device();
		close_output_device();

		delete [] m_input_event_buffer;
		delete [] m_input_message_buffer;

		PmError error = Pm_Terminate();

		if( error != pmNoError )
		{
			INTEGRA_TRACE_ERROR << "Failed to terminate PortMidi: " << Pm_GetErrorText( error );
		}

		pthread_mutex_destroy( &m_input_mutex );
		pthread_mutex_destroy( &m_output_mutex );

		INTEGRA_TRACE_PROGRESS << "Destroyed PortAudio engine";
	}


	CError CPortMidiEngine::set_input_device( const string &input_device )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_input_device();

		PmDeviceID device_id = get_device_id( m_available_input_devices, input_device );

		if( device_id != pmNoDevice )
		{
			open_input_device( device_id );
		}

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::set_output_device( const string &output_device )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_output_device();

		PmDeviceID device_id = get_device_id( m_available_output_devices, output_device );

		if( device_id != pmNoDevice )
		{
			open_output_device( device_id );
		}

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::restore_defaults()
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_input_device();
		close_output_device();

		set_input_device_to_default();
		set_output_device_to_default();

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::set_input_device_to_default()
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		open_input_device( Pm_GetDefaultInputDeviceID() );

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::set_output_device_to_default()
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		open_output_device( Pm_GetDefaultOutputDeviceID() );

		return CError::SUCCESS;
	}


	string_vector CPortMidiEngine::get_available_input_devices() const
	{
		return device_map_to_string_vector( m_available_input_devices );
	}


	string_vector CPortMidiEngine::get_available_output_devices() const
	{
		return device_map_to_string_vector( m_available_output_devices );
	}


	string CPortMidiEngine::get_selected_input_device() const
	{
		if( m_current_input_device_id == pmNoDevice )
		{
			return none;
		}

		if( m_available_input_devices.count( m_current_input_device_id ) > 0 )
		{
			return m_available_input_devices.at( m_current_input_device_id );
		}

		INTEGRA_TRACE_ERROR << "can't find selected input device in map, device ID = " << m_current_input_device_id;
		return "";
	}


	string CPortMidiEngine::get_selected_output_device() const
	{
		if( m_current_output_device_id == pmNoDevice )
		{
			return none;
		}

		if( m_available_output_devices.count( m_current_output_device_id ) > 0 )
		{
			return m_available_output_devices.at( m_current_output_device_id );
		}

		INTEGRA_TRACE_ERROR << "can't find selected output device in map, device ID = " << m_current_output_device_id;
		return "";
	}


	void CPortMidiEngine::find_available_devices()
	{
		m_available_input_devices.clear();
		m_available_output_devices.clear();

		m_available_input_devices[ pmNoDevice ] = none;
		m_available_output_devices[ pmNoDevice ] = none;

		int number_of_devices = Pm_CountDevices();

		for( int device_id = 0; device_id < number_of_devices; device_id++ )
		{
			const PmDeviceInfo *device_info = Pm_GetDeviceInfo( device_id );
			if( !device_info )
			{
				INTEGRA_TRACE_ERROR << "Failed to get info for device id " << device_id;
				continue;
			}

			if( device_info->input )
			{
				m_available_input_devices[ device_id ] = CStringHelper::trim( device_info->name );
			}

			if( device_info->output )
			{
				m_available_output_devices[ device_id ] = CStringHelper::trim( device_info->name );
			}
		}
	}


	PmDeviceID CPortMidiEngine::get_device_id( const device_map &device_map, const string &device_name ) const
	{
		for( device_map::const_iterator i = device_map.begin(); i != device_map.end(); i++ )
		{
			if( i->second == device_name )
			{
				return i->first;
			}
		}

		INTEGRA_TRACE_ERROR << "Failed to find device " << device_name << " in device map";
		return pmNoDevice;
	}


	string_vector CPortMidiEngine::device_map_to_string_vector( const device_map &devices ) const
	{
		string_vector results;

		for( device_map::const_iterator i = devices.begin(); i != devices.end(); i++ )
		{
			results.push_back( i->second );
		}

		return results;
	}


	void CPortMidiEngine::close_input_device()
	{
		pthread_mutex_lock( &m_input_mutex );

		if( m_input_stream )
		{
			PmError error = Pm_Close( m_input_stream );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error closing input stream: " << Pm_GetErrorText( error );
			}

			m_input_stream = NULL;
			m_current_input_device_id = pmNoDevice;
		}
		else
		{
			assert( m_current_input_device_id == pmNoDevice );
		}

		pthread_mutex_unlock( &m_input_mutex );
	}


	void CPortMidiEngine::close_output_device()
	{
		pthread_mutex_lock( &m_output_mutex );

		if( m_output_stream )
		{
			PmError error = Pm_Abort( m_output_stream );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error aborting output stream: " << Pm_GetErrorText( error );
			}

			error = Pm_Close( m_output_stream );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error closing output stream: " << Pm_GetErrorText( error );
			}

			m_output_stream = NULL;
			m_current_output_device_id = pmNoDevice;
		}
		else
		{
			assert( m_current_output_device_id == pmNoDevice );
		}

		pthread_mutex_unlock( &m_output_mutex );
	}


	void CPortMidiEngine::open_input_device( PmDeviceID device_id )
	{
		pthread_mutex_lock( &m_input_mutex );

		assert( m_current_input_device_id == pmNoDevice && !m_input_stream );

		PmError result = Pm_OpenInput( &m_input_stream, device_id, NULL, input_buffer_size, NULL, NULL );

		if( result == pmNoError )
		{
			m_current_input_device_id = device_id;
			INTEGRA_TRACE_PROGRESS << "opened midi input device: " << get_selected_input_device();

			/* filter everythomg except channel messages */
			Pm_SetFilter( m_input_stream, PM_FILT_REALTIME | PM_FILT_SYSTEMCOMMON );
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Failed to open midi input: " << Pm_GetErrorText( result );
			m_input_stream = NULL;
		}

		pthread_mutex_unlock( &m_input_mutex );
	}


	void CPortMidiEngine::open_output_device( PmDeviceID device_id )
	{
		pthread_mutex_lock( &m_output_mutex );

		assert( m_current_output_device_id == pmNoDevice && !m_output_stream );

		PmError result = Pm_OpenOutput( &m_output_stream, device_id, NULL, 0, NULL, NULL, 0 );

		if( result == pmNoError )
		{
			m_current_output_device_id = device_id;
			INTEGRA_TRACE_PROGRESS << "opened midi output device: " << get_selected_output_device();
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Failed to open midi output: " << Pm_GetErrorText( result );
			m_output_stream = NULL;
		}

		pthread_mutex_unlock( &m_output_mutex );
	}


	CError CPortMidiEngine::get_incoming_midi_messages( unsigned int *&messages, int &number_of_messages )
	{
		pthread_mutex_lock( &m_input_mutex );

		CError result = get_incoming_midi_messages_inner( messages, number_of_messages );

		pthread_mutex_unlock( &m_input_mutex );

		return result;
	}


	CError CPortMidiEngine::get_incoming_midi_messages_inner( unsigned int *&messages, int &number_of_messages )
	{
		messages = m_input_message_buffer;
		number_of_messages = 0;

		if( !m_input_stream )
		{
			return CError::SUCCESS;
		}

		PmError poll_result = Pm_Poll( m_input_stream );
		if( poll_result != TRUE )
		{
			if( poll_result == FALSE )
			{
				return CError::SUCCESS;
			}
			else
			{
				INTEGRA_TRACE_ERROR << "Error polling for incoming midi: " << Pm_GetErrorText( poll_result );
				return CError::FAILED;
			}
		}

		int number_of_events = Pm_Read( m_input_stream, m_input_event_buffer, input_buffer_size );
		if( number_of_events < 0 )
		{
			INTEGRA_TRACE_ERROR << "Error reading midi input: " << Pm_GetErrorText( ( PmError ) number_of_events );
			return CError::FAILED;
		}

		number_of_messages = number_of_events;

		for( int i = 0; i < number_of_events; i++ )
		{
			PmMessage &message = m_input_event_buffer[ i ].message;

			messages[ i ] = message;
		}

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::send_midi_message( unsigned int message )
	{
		if( !m_output_stream )
		{
			return CError::SUCCESS;
		}

		PmError error = Pm_WriteShort( m_output_stream, 0, message );
		if( error != pmNoError )
		{
			INTEGRA_TRACE_ERROR << "Error sending midi output: " << Pm_GetErrorText( error );
			return CError::FAILED;
		}

		return CError::SUCCESS;
	}
}

 