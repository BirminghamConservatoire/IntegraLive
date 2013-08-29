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
#include "api/trace.h"

#include <assert.h>
#include <algorithm>	

#include <windows.h>		//todo - remove - for Sleep()


namespace integra_internal
{
	const string CPortAudioEngine::none = "none";


	CPortAudioEngine::CPortAudioEngine()
	{
		Sleep( 10000 );

		PaError error_code = Pa_Initialize();
		m_initialized_ok = ( error_code == paNoError );
		if( !m_initialized_ok )
		{
			INTEGRA_TRACE_ERROR << "PortAudio initialization error: " << Pa_GetErrorText( error_code );
			return;
		}

		update_available_apis();

		set_driver( none );
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

		if( lookup->second == m_selected_input_device )
		{
			/* reselecting existing device */
			return CError::SUCCESS;		
		}

		close_streams();

		m_selected_input_device = lookup->second;

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

		if( lookup->second == m_selected_output_device )
		{
			/* reselecting existing device */
			return CError::SUCCESS;		
		}

		close_streams();

		m_selected_output_device = lookup->second;

		open_streams();

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_sample_rate( int sample_rate )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_number_of_input_channels( int input_channels )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_number_of_output_channels( int output_channels )
	{
		if( !m_initialized_ok ) 
		{
			return CError::FAILED;
		}

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

		return api_info->name;
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

		return device_info->name;
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

		return device_info->name;
	}


	int CPortAudioEngine::get_sample_rate() const
	{
		return 44100;		//todo - implement
	}


	int CPortAudioEngine::get_number_of_input_channels() const
	{
		return 2;		//todo - implement
	}


	int CPortAudioEngine::get_number_of_output_channels() const
	{
		return 2;		//todo - implement
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

			m_available_apis[ api_info->name ] = api_info->type;
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
				m_available_input_devices[ device_info->name ] = i;
			}

			if( device_info->maxOutputChannels > 0 )
			{
				m_available_output_devices[ device_info->name ] = i;
			}
		}


	}


	void CPortAudioEngine::open_streams()
	{
		//todo - implement

	}


	void CPortAudioEngine::close_streams()
	{
		//todo - implement

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

}

 