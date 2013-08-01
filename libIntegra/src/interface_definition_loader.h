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


#ifndef INTEGRA_INTERFACE_DEFINITION_LOADER_PRIVATE_H
#define INTEGRA_INTERFACE_DEFINITION_LOADER_PRIVATE_H


#include "api/common_typedefs.h"
#include "value.h"
#include "error.h"
#include "interface_definition.h"

#include <libxml/xmlreader.h>


namespace ntg_internal
{
	class CInterfaceDefinitionLoader
	{
		public:
			CInterfaceDefinitionLoader();
			~CInterfaceDefinitionLoader();

			CInterfaceDefinition *load( const unsigned char &buffer, unsigned int buffer_size );

		private:

			ntg_api::error_code handle_element_value( const ntg_api::string &element_value );
			ntg_api::error_code handle_element();
			ntg_api::error_code handle_element_attributes();

			void store_map_entries();

			void push_element_name( const ntg_api::string &element );
			void pop_element_name();

			ntg_api::error_code do_sanity_check();

			void cleanup();

			ntg_api::error_code converter( const ntg_api::string &input, ntg_api::string &output );
			ntg_api::error_code converter( const ntg_api::string &input, bool &output );
			ntg_api::error_code converter( const ntg_api::string &input, int &output );
			ntg_api::error_code converter( const ntg_api::string &input, float &output );
			ntg_api::error_code converter( const ntg_api::string &input, CEndpointDefinition::endpoint_type &output );
			ntg_api::error_code converter( const ntg_api::string &input, CControlInfo::control_type &output );
			ntg_api::error_code converter( const ntg_api::string &input, ntg_api::CValue::type &output );
			ntg_api::error_code converter( const ntg_api::string &input, CValueScale::scale_type &output );
			ntg_api::error_code converter( const ntg_api::string &input, CStreamInfo::stream_type &output );
			ntg_api::error_code converter( const ntg_api::string &input, CStreamInfo::stream_direction &output );
			ntg_api::error_code converter( const ntg_api::string &input, struct tm &output );

			ntg_api::CValue::type get_state_type();
			ntg_api::CValue::type get_range_type();


			xmlTextReaderPtr m_reader;
			CInterfaceDefinition *m_interface_definition;
			ntg_api::string m_element_path;

			
			ntg_api::string m_last_state_label_key;
			ntg_api::CValue *m_last_state_label_value;

			ntg_api::string m_last_widget_key;
			ntg_api::string m_last_widget_value;

	};
}


#endif

