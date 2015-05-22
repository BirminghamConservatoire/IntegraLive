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

#include "portmidi_engine.h"
#include "api/trace.h"
#include "api/string_helper.h"

#include <assert.h>
#include <algorithm>	


namespace integra_internal
{
	CPortMidiEngine::CPortMidiEngine()
	{
		m_input_event_buffer = new PmEvent[ CMidiInputBuffer::input_buffer_size ];

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

		close_input_devices();
		close_output_devices();

		delete [] m_input_event_buffer;

		PmError error = Pm_Terminate();

		if( error != pmNoError )
		{
			INTEGRA_TRACE_ERROR << "Failed to terminate PortMidi: " << Pm_GetErrorText( error );
		}

		pthread_mutex_destroy( &m_input_mutex );
		pthread_mutex_destroy( &m_output_mutex );

		INTEGRA_TRACE_PROGRESS << "Destroyed PortAudio engine";
	}


	CError CPortMidiEngine::set_input_devices( const string_vector &input_devices )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_input_devices();

		for( string_vector::const_iterator i = input_devices.begin(); i != input_devices.end(); i++ )
		{
			PmDeviceID device_id = get_device_id( m_available_input_devices, *i );
			open_input_device( device_id );
		}

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::set_output_devices( const string_vector &output_devices )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_output_devices();

		for( string_vector::const_iterator i = output_devices.begin(); i != output_devices.end(); i++ )
		{
			PmDeviceID device_id = get_device_id( m_available_output_devices, *i );

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

		close_input_devices();
		close_output_devices();

		set_input_devices_to_default();
		set_output_devices_to_default();

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::set_input_devices_to_default()
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_input_devices();
		open_input_device( Pm_GetDefaultInputDeviceID() );

		return CError::SUCCESS;
	}


	CError CPortMidiEngine::set_output_devices_to_default()
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		close_output_devices();
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


	string_vector CPortMidiEngine::get_active_input_devices() const
	{
		string_vector results;

		for( device_vector::const_iterator i = m_active_input_devices.begin(); i != m_active_input_devices.end(); i++ )
		{
			results.push_back( i->name );
		}

		return results;
	}


	string_vector CPortMidiEngine::get_active_output_devices() const
	{
		string_vector results;

		for( device_vector::const_iterator i = m_active_output_devices.begin(); i != m_active_output_devices.end(); i++ )
		{
			results.push_back( i->name );
		}

		return results;
	}


	void CPortMidiEngine::find_available_devices()
	{
		m_available_input_devices.clear();
		m_available_output_devices.clear();

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


	void CPortMidiEngine::close_input_devices()
	{
		pthread_mutex_lock( &m_input_mutex );

		for( device_vector::const_iterator i = m_active_input_devices.begin(); i != m_active_input_devices.end(); i++ )
		{
			PmError error = Pm_Close( i->stream );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error closing input stream: " << Pm_GetErrorText( error );
			}
		}

		m_active_input_devices.clear();

		pthread_mutex_unlock( &m_input_mutex );
	}


	void CPortMidiEngine::close_output_devices()
	{
		pthread_mutex_lock( &m_output_mutex );

		for( device_vector::const_iterator i = m_active_output_devices.begin(); i != m_active_output_devices.end(); i++ )
		{
			PmError error = Pm_Abort( i->stream );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error aborting output stream: " << Pm_GetErrorText( error );
			}

			error = Pm_Close( i->stream );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error closing output stream: " << Pm_GetErrorText( error );
			}
		}

		m_active_output_devices.clear();

		pthread_mutex_unlock( &m_output_mutex );
	}


	CError CPortMidiEngine::open_input_device( PmDeviceID device_id )
	{
		if( is_device_open( m_active_input_devices, device_id ) )
		{
			INTEGRA_TRACE_ERROR << "Device already open, ID: " << device_id;
			return CError::INPUT_ERROR;
		}

		if( m_available_input_devices.count( device_id ) == 0 )
		{
			INTEGRA_TRACE_ERROR << "Can't find device name, ID: " << device_id;
			return CError::INPUT_ERROR;
		}

		CError error( CError::SUCCESS );

		pthread_mutex_lock( &m_input_mutex );

		CMidiDevice device;
		device.id = device_id;
		device.name = m_available_input_devices.at( device_id );

		PmError result = Pm_OpenInput( &device.stream, device_id, NULL, CMidiInputBuffer::input_buffer_size, NULL, NULL );

		if( result == pmNoError )
		{
			m_active_input_devices.push_back( device );
			INTEGRA_TRACE_VERBOSE << "opened midi input device ID: " << device_id;

			/* filter everythomg except channel messages */
			Pm_SetFilter( device.stream, PM_FILT_REALTIME | PM_FILT_SYSTEMCOMMON );
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Failed to open midi input: " << Pm_GetErrorText( result );
			error = CError::FAILED;
		}

		pthread_mutex_unlock( &m_input_mutex );

		return error;
	}


	CError CPortMidiEngine::open_output_device( PmDeviceID device_id )
	{
		if( is_device_open( m_active_output_devices, device_id ) )
		{
			INTEGRA_TRACE_ERROR << "Device already open, ID: " << device_id;
			return CError::INPUT_ERROR;
		}

		if( m_available_output_devices.count( device_id ) == 0 )
		{
			INTEGRA_TRACE_ERROR << "Can't find device name, ID: " << device_id;
			return CError::INPUT_ERROR;
		}

		CError error( CError::SUCCESS );

		pthread_mutex_lock( &m_output_mutex );

		CMidiDevice device;
		device.id = device_id;
		device.name = m_available_output_devices.at( device_id );

		PmError result = Pm_OpenOutput( &device.stream, device_id, NULL, 0, NULL, NULL, 0 );

		if( result == pmNoError )
		{
			m_active_output_devices.push_back( device );
			INTEGRA_TRACE_VERBOSE << "opened midi output device ID: " << device_id;
		}
		else
		{
			INTEGRA_TRACE_ERROR << "Failed to open midi output: " << Pm_GetErrorText( result );
			error = CError::FAILED;
		}

		pthread_mutex_unlock( &m_output_mutex );

		return error;
	}


	bool CPortMidiEngine::is_device_open( const device_vector &devices, PmDeviceID device_id ) const
	{
		for( device_vector::const_iterator i = devices.begin(); i != devices.end(); i++ )
		{
			if( i->id == device_id ) 
			{
				return true;
			}
		}

		return false;
	}


	bool CPortMidiEngine::is_device_open( const device_vector &devices, const string &device_name ) const
	{
		for( device_vector::const_iterator i = devices.begin(); i != devices.end(); i++ )
		{
			if( i->name == device_name ) 
			{
				return true;
			}
		}

		return false;
	}


	CError CPortMidiEngine::poll_input( midi_input_buffer_array &input_buffers )
	{
		CError result = CError::SUCCESS;

		pthread_mutex_lock( &m_input_mutex );

		input_buffers.resize( m_active_input_devices.size() );

		for( int i = 0; i < m_active_input_devices.size(); i++ )
		{
			const CMidiDevice &midi_device = m_active_input_devices[ i ];
			CMidiInputBuffer &buffer = input_buffers[ i ];
			buffer.device_name = midi_device.name;
			buffer.number_of_messages = 0;

			PmError poll_result = Pm_Poll( midi_device.stream );
			if( poll_result != TRUE )
			{
				if( poll_result == FALSE )
				{
					continue;
				}
				else
				{
					INTEGRA_TRACE_ERROR << "Error polling for incoming midi: " << Pm_GetErrorText( poll_result );
					result = CError::FAILED;
					continue;
				}
			}

			int number_of_events = Pm_Read( midi_device.stream, m_input_event_buffer, CMidiInputBuffer::input_buffer_size );
			if( number_of_events < 0 )
			{
				INTEGRA_TRACE_ERROR << "Error reading midi input: " << Pm_GetErrorText( ( PmError ) number_of_events );
				result = CError::FAILED;
				continue;			
			}

			buffer.number_of_messages = number_of_events;

			for( int i = 0; i < number_of_events; i++ )
			{
				PmMessage &message = m_input_event_buffer[ i ].message;

				buffer.messages[ i ] = message;
			}
		}

		pthread_mutex_unlock( &m_input_mutex );

		return result;
	}


	CError CPortMidiEngine::send_midi_message( const string &device_name, unsigned int message )
	{
		CError result( CError::SUCCESS );

		pthread_mutex_lock( &m_output_mutex );

		bool found = false;

		for( device_vector::const_iterator i = m_active_output_devices.begin(); i != m_active_output_devices.end(); i++ )
		{
			if( i->name == device_name ) 
			{
				found = true;
				PmError error = Pm_WriteShort( i->stream, 0, message );
				if( error == pmNoError )
				{
					break;
				}
				else
				{
					INTEGRA_TRACE_ERROR << "Error sending midi output: " << Pm_GetErrorText( error );
					result = CError::FAILED;
					break;
				}
			}
		}

		if( !found )
		{
			//device not open / not found
			INTEGRA_TRACE_ERROR << "Can't send midi output to device: " << device_name << " as this device doesn't exist, or isn't open";
			result = CError::INPUT_ERROR;
		}

		pthread_mutex_unlock( &m_output_mutex );

		return result;
	}


	CError CPortMidiEngine::send_midi_message( int device_index, unsigned int message )
	{
		CError result( CError::SUCCESS );

		pthread_mutex_lock( &m_output_mutex );

		if( device_index >= 0 && device_index < m_active_output_devices.size() )
		{
			const CMidiDevice &device = m_active_output_devices[ device_index ];

			PmError error = Pm_WriteShort( device.stream, 0, message );
			if( error != pmNoError )
			{
				INTEGRA_TRACE_ERROR << "Error sending midi output: " << Pm_GetErrorText( error );
				result = CError::FAILED;
			}
		}
		else
		{
			//device index out of range
			INTEGRA_TRACE_ERROR << "Can't send midi output.  Device index " << device_index << " is out of range";
			result = CError::INPUT_ERROR;
		}

		pthread_mutex_unlock( &m_output_mutex );

		return result;
	}
}

 