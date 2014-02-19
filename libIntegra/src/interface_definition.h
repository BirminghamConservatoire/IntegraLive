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



#ifndef INTEGRA_INTERFACE_DEFINITION_PRIVATE_H
#define INTEGRA_INTERFACE_DEFINITION_PRIVATE_H


#include <time.h>

#include "api/interface_definition.h"
#include "api/common_typedefs.h"
#include "api/guid_helper.h"
#include "api/value.h"


using namespace integra_api;


namespace integra_internal
{
	class CInterfaceDefinition;
	class CInterfaceInfo;
	class CImplementationInfo;
	class CEndpointDefinition;
	class CControlInfo;
	class CStateInfo;
	class CConstraint;
	class CValueRange;
	class CValueScale;
	class CStreamInfo;
	class CWidgetDefinition;
	class CWidgetPosition;

	class CInterfaceDefinition : public IInterfaceDefinition
	{
		friend class CInterfaceDefinitionLoader;

		public:

			CInterfaceDefinition();
			~CInterfaceDefinition();

			static const CInterfaceDefinition *downcast( const IInterfaceDefinition *interface_definition );
			static const CInterfaceDefinition &downcast( const IInterfaceDefinition &interface_definition );
			static CInterfaceDefinition &downcast_writable( IInterfaceDefinition &interface_definition );

			/* queries */
			const GUID &get_module_guid() const { return m_module_guid; }
			const GUID &get_origin_guid() const { return m_origin_guid; }
			module_source get_module_source() const { return m_source; }
			const string &get_file_path() const { return m_file_path; }
			const IInterfaceInfo &get_interface_info() const;
			const endpoint_definition_list &get_endpoint_definitions() const { return m_endpoint_definitions; }
			const widget_definition_list &get_widget_definitions() const { return m_widget_definitions; }
			const IImplementationInfo *get_implementation_info() const;

			/* helpers */
			bool is_core_interface() const;
			bool is_named_core_interface( const string &name ) const;
			bool has_implementation() const;
			bool should_embed() const;

			/* setters */
			void set_module_source( module_source source ) { m_source = source; }
			void set_file_path( const string &file_path ) { m_file_path = file_path; }
			void set_implementation_checksum( unsigned int checksum );

	private:

			void propagate_defaults();

			GUID m_module_guid;
			GUID m_origin_guid;
			module_source m_source;
			string m_file_path;
			CInterfaceInfo *m_interface_info;
			endpoint_definition_list m_endpoint_definitions;
			widget_definition_list m_widget_definitions;
			CImplementationInfo *m_implementation_info;

			const static string core_tag;
	};


	class CInterfaceInfo : public IInterfaceInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CInterfaceInfo();
			~CInterfaceInfo();

			static const CInterfaceInfo &downcast( const IInterfaceInfo &interface_info );

			const string &get_name() const { return m_name; }
			const string &get_label() const { return m_label; }
			const string &get_description() const { return m_description; }
			const string_set &get_tags() const { return m_tags; }
			bool get_implemented_in_libintegra() const { return m_implemented_in_libintegra; }
			const string &get_author() const { return m_author; }
			const struct tm &get_created_date() const { return m_created_date; }
			const struct tm &get_modified_date() const { return m_modified_date; }

			void propagate_defaults();

		private:

			string m_name;
			string m_label;
			string m_description;
			string_set m_tags;
			bool m_implemented_in_libintegra;
			string m_author;
			struct tm m_created_date;
			struct tm m_modified_date;
	};


	class CEndpointDefinition : public IEndpointDefinition
	{
		friend class CInterfaceDefinitionLoader;

		public:

			CEndpointDefinition();
			~CEndpointDefinition();

			static const CEndpointDefinition *downcast( const IEndpointDefinition *endpoint_definition );
			static const CEndpointDefinition &downcast( const IEndpointDefinition &endpoint_definition );
			static CEndpointDefinition &downcast_writable( IEndpointDefinition &endpoint_definition );

			const string &get_name() const { return m_name; }
			const string &get_label() const { return m_label; }
			const string &get_description() const { return m_description; }
			endpoint_type get_type() const { return m_type; }
			const IControlInfo *get_control_info() const;
			const IStreamInfo *get_stream_info() const;

			/* helpers */
			bool should_send_to_host() const;
			bool is_input_file() const;
			bool should_load_from_ixd( CValue::type loaded_type ) const;
			bool is_audio_stream() const;

			void propagate_defaults();

		private:

			string m_name;
			string m_label;
			string m_description;
			endpoint_type m_type;
			CControlInfo *m_control_info;
			CStreamInfo *m_stream_info;
	};


	class CControlInfo : public IControlInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CControlInfo();
			~CControlInfo();

			control_type get_type() const { return m_type; }
			const IStateInfo *get_state_info() const;
			bool get_can_be_source() const { return m_can_be_source; }
			bool get_can_be_target() const { return m_can_be_target; }
			bool get_is_sent_to_host() const { return m_is_sent_to_host; }

		private:

			control_type m_type;
			CStateInfo *m_state_info;
			bool m_can_be_source;
			bool m_can_be_target;
			bool m_is_sent_to_host;
	};


	class CStateInfo : public IStateInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CStateInfo();
			~CStateInfo();

			static const CStateInfo &downcast( const IStateInfo &state_info );

			CValue::type get_type() const { return m_type; }
			const IConstraint &get_constraint() const;
			const CValue &get_default_value() const { return *m_default_value; }
			const IValueScale *get_value_scale() const;
			const value_map &get_state_labels() const { return m_state_labels; }
			bool get_is_saved_to_file() const { return m_is_saved_to_file; }
			bool get_is_input_file() const { return m_is_input_file; }

			bool test_constraint( const CValue &value ) const;

		private:
			CValue::type m_type;
			CConstraint *m_constraint;
			CValue *m_default_value;
			CValueScale *m_value_scale;
			value_map m_state_labels;
			bool m_is_saved_to_file;
			bool m_is_input_file;
	};


	class CConstraint : public IConstraint
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CConstraint();
			~CConstraint();

			const IValueRange *get_value_range() const;
			const value_set *get_allowed_states() const { return m_allowed_states; }

		private:
			CValueRange *m_value_range;
			value_set *m_allowed_states;
	};


	class CValueRange : public IValueRange
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CValueRange();
			~CValueRange();

			const CValue &get_minimum() const { return *m_minimum; }
			const CValue &get_maximum() const { return *m_maximum; }

		private:

			CValue *m_minimum;
			CValue *m_maximum;
	};


	class CValueScale : public IValueScale
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CValueScale();
			~CValueScale();

			scale_type get_scale_type() const { return m_type; }

		private:
			scale_type m_type;
	};


	class CStreamInfo : public IStreamInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CStreamInfo();
			~CStreamInfo();

			stream_type get_type() const { return m_type; }
			stream_direction get_direction() const { return m_direction; }
		private:
			
			stream_type m_type;
			stream_direction m_direction;
	};


	class CWidgetDefinition : public IWidgetDefinition
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CWidgetDefinition();
			~CWidgetDefinition();

			static CWidgetDefinition &downcast_writable( IWidgetDefinition &widget_definition );

			const string &get_type() const { return m_type; }
			const string &get_label() const { return m_label; }
			const IWidgetPosition &get_position() const;
			const string_map &get_attribute_mappings() const { return m_attribute_mappings; }

		private:
			string m_type;
			string m_label;
			CWidgetPosition *m_position;
			string_map m_attribute_mappings;
	};


	class CWidgetPosition : public IWidgetPosition
	{
		friend class CInterfaceDefinitionLoader;

		public:	
			CWidgetPosition();
			~CWidgetPosition();
			
			float get_x() const { return m_x; }
			float get_y() const { return m_y; }
			float get_width() const { return m_width; }
			float get_height() const { return m_height; }

		private:
			float m_x;
			float m_y;
			float m_width;
			float m_height;
	};


	class CImplementationInfo : public IImplementationInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CImplementationInfo();
			~CImplementationInfo();

			static const CImplementationInfo *downcast( const IImplementationInfo *interface_definition );

			const string &get_patch_name() const { return m_patch_name; }
			unsigned int get_checksum() const { return m_checksum; }

			void set_checksum( unsigned int checksum ) { m_checksum = checksum; }

		private:

			string m_patch_name;
			unsigned int m_checksum;
	};

}


#endif

