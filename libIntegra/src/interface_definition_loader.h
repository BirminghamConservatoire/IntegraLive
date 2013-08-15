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
#include "api/value.h"
#include "api/error.h"
#include "interface_definition.h"

#include <libxml/xmlreader.h>


namespace integra_internal
{
	class CInterfaceDefinitionLoader
	{
		public:
			CInterfaceDefinitionLoader();
			~CInterfaceDefinitionLoader();

			CInterfaceDefinition *load( const unsigned char &buffer, unsigned int buffer_size );

		private:

			CError handle_element_value( const string &element_value );
			CError handle_element();
			CError handle_element_attributes();

			CEndpointDefinition &current_endpoint();
			CWidgetDefinition &current_widget();


			void store_map_entries();

			void push_element_name( const string &element );
			void pop_element_name();

			CError do_sanity_check();

			void cleanup();

			CError converter( const string &input, string &output );
			CError converter( const string &input, bool &output );
			CError converter( const string &input, int &output );
			CError converter( const string &input, float &output );
			CError converter( const string &input, CEndpointDefinition::endpoint_type &output );
			CError converter( const string &input, CControlInfo::control_type &output );
			CError converter( const string &input, CValue::type &output );
			CError converter( const string &input, CValueScale::scale_type &output );
			CError converter( const string &input, CStreamInfo::stream_type &output );
			CError converter( const string &input, CStreamInfo::stream_direction &output );
			CError converter( const string &input, struct tm &output );

			CValue::type get_state_type();
			CValue::type get_range_type();


			xmlTextReaderPtr m_reader;
			CInterfaceDefinition *m_interface_definition;
			string m_element_path;

			
			string m_last_state_label_key;
			CValue *m_last_state_label_value;

			string m_last_widget_key;
			string m_last_widget_value;

	};
}


#endif

