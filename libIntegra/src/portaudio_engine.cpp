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


namespace integra_internal
{
	CPortAudioEngine::CPortAudioEngine()
	{
		//todo - implement
	}


	CPortAudioEngine::~CPortAudioEngine()
	{
		//todo - implement
	}


	CError CPortAudioEngine::set_driver( const string &driver )
	{
		//todo - implement
		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_output_device( const string &output_device )
	{
		//todo - implement
		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_input_device( const string &input_device )
	{
		//todo - implement
		return CError::SUCCESS;
	}



	CError CPortAudioEngine::set_sample_rate( int sample_rate )
	{
		//todo - implement
		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_number_of_input_channels( int input_channels )
	{
		//todo - implement
		return CError::SUCCESS;
	}


	CError CPortAudioEngine::set_number_of_output_channels( int output_channels )
	{
		//todo - implement
		return CError::SUCCESS;
	}


	CError CPortAudioEngine::restore_defaults()
	{
		//todo - implement
		return CError::SUCCESS;
	}


	string_vector CPortAudioEngine::get_available_drivers() const
	{
		//todo - implement
		string_vector drivers;
		drivers.push_back( "none" );
		drivers.push_back( "driver 1" );
		drivers.push_back( "driver 2" );
		drivers.push_back( "driver 3" );
		return drivers;
	}


	string_vector CPortAudioEngine::get_available_input_devices() const
	{
		//todo - implement
		string_vector devices;
		devices.push_back( "none" );
		devices.push_back( "input device 1" );
		devices.push_back( "input device 2" );
		devices.push_back( "input device 3" );
		return devices;
	}


	string_vector CPortAudioEngine::get_available_output_devices() const
	{
		//todo - implement
		string_vector devices;
		devices.push_back( "none" );
		devices.push_back( "output device 1" );
		devices.push_back( "output device 2" );
		devices.push_back( "output device 3" );
		return devices;
	}


	string CPortAudioEngine::get_selected_driver() const
	{
		return "none";		//todo - implement
	}


	string CPortAudioEngine::get_selected_input_device() const
	{
		return "none";		//todo - implement
	}


	string CPortAudioEngine::get_selected_output_device() const
	{
		return "none";		//todo - implement
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
}

