 /* libIntegra multimedia module interface
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


#ifndef INTEGRA_AUDIO_SETTINGS_LOGIC_PRIVATE
#define INTEGRA_AUDIO_SETTINGS_LOGIC_PRIVATE

#include "logic.h"


namespace integra_internal
{
	class IAudioSettings;

	class CAudioSettingsLogic : public CLogic
	{
		public:
			CAudioSettingsLogic( const CNode &node );
			~CAudioSettingsLogic();

			void handle_new( CServer &server, CCommandSource source );
			void handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source );

		private:

			void update_all_fields( CServer &server );

			void update_string_field( CServer &server, const string &endpoint_name, const string &new_value );
			void update_integer_field( CServer &server, const string &endpoint_name, int new_value );

			static void update_all_fields_for_all_audio_settings_nodes( CServer &server );

			static string_vector int_vector_to_string_vector( const int_vector &input );

			typedef std::unordered_set<CAudioSettingsLogic *> audio_settings_logic_set;

			static audio_settings_logic_set s_all_audio_settings_logics;

			static const string endpoint_available_drivers;
			static const string endpoint_available_input_devices;
			static const string endpoint_available_output_devices;
			static const string endpoint_available_sample_rates;
			static const string endpoint_selected_driver;
			static const string endpoint_selected_input_device;
			static const string endpoint_selected_output_device;
			static const string endpoint_sample_rate;
			static const string endpoint_input_channels;
			static const string endpoint_output_channels;
			static const string endpoint_restore_defaults;
	};
}



#endif /*INTEGRA_AUDIO_SETTINGS_LOGIC_PRIVATE*/