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


#ifndef INTEGRA_INTERFACE_DEFINITION_PRIVATE_H
#define INTEGRA_INTERFACE_DEFINITION_PRIVATE_H


#include "../externals/guiddef.h"
#include <time.h>

#include "api/common_typedefs.h"
#include "value.h"



namespace ntg_internal
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

	typedef std::list<CEndpointDefinition *> endpoint_definition_list;
	typedef std::list<CWidgetDefinition *> widget_definition_list;

	typedef std::unordered_map<GUID, CInterfaceDefinition *, ntg_api::GuidHash> map_guid_to_interface_definition;
	typedef std::unordered_map<ntg_api::string, CInterfaceDefinition *> map_string_to_interface_definition;


	class CInterfaceDefinition
	{
		friend class CInterfaceDefinitionLoader;

		public:

			CInterfaceDefinition();
			~CInterfaceDefinition();

			enum module_source
			{
				MODULE_SHIPPED_WITH_INTEGRA = 1,	
				MODULE_3RD_PARTY,
				MODULE_EMBEDDED,
				MODULE_IN_DEVELOPMENT 
			};

			/* queries */
			const GUID &get_module_guid() const { return m_module_guid; }
			const GUID &get_origin_guid() const { return m_origin_guid; }
			module_source get_module_source() const { return m_source; }
			const ntg_api::string &get_file_path() const { return m_file_path; }
			const CInterfaceInfo &get_interface_info() const { return *m_interface_info; }
			const endpoint_definition_list &get_endpoint_definitions() const { return m_endpoint_definitions; }
			const widget_definition_list &get_widget_definitions() const { return m_widget_definitions; }
			const CImplementationInfo *get_implementation_info() const { return m_implementation_info; }

			/* helpers */
			bool is_core_interface() const;
			bool is_named_core_interface( const ntg_api::string &name ) const;
			bool has_implementation() const;
			bool should_embed() const;

			/* setters */
			void set_module_source( module_source source ) { m_source = source; }
			void set_file_path( const ntg_api::string &file_path ) { m_file_path = file_path; }
			void set_implementation_checksum( unsigned int checksum );

	private:

			void propagate_defaults();

			GUID m_module_guid;
			GUID m_origin_guid;
			module_source m_source;
			ntg_api::string m_file_path;
			CInterfaceInfo *m_interface_info;
			endpoint_definition_list m_endpoint_definitions;
			widget_definition_list m_widget_definitions;
			CImplementationInfo *m_implementation_info;
	};


	class CInterfaceInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CInterfaceInfo();
			~CInterfaceInfo();

			const ntg_api::string &get_name() const { return m_name; }
			const ntg_api::string &get_label() const { return m_label; }
			const ntg_api::string &get_description() const { return m_description; }
			const ntg_api::string_set &get_tags() const { return m_tags; }
			bool get_implemented_in_libintegra() const { return m_implemented_in_libintegra; }
			const ntg_api::string &get_author() const { return m_author; }
			const struct tm &get_created_date() const { return m_created_date; }
			const struct tm &get_modified_date() const { return m_modified_date; }

			void propagate_defaults();

		private:

			ntg_api::string m_name;
			ntg_api::string m_label;
			ntg_api::string m_description;
			ntg_api::string_set m_tags;
			bool m_implemented_in_libintegra;
			ntg_api::string m_author;
			struct tm m_created_date;
			struct tm m_modified_date;
	};


	//todo - remove LIBINTEGRA_API from here - temporary measure to make the bridge compile */
	class LIBINTEGRA_API CEndpointDefinition
	{
		friend class CInterfaceDefinitionLoader;

		public:

			CEndpointDefinition();
			~CEndpointDefinition();

			enum endpoint_type
			{
			    CONTROL = 1,
				STREAM
			};

			const ntg_api::string &get_name() const { return m_name; }
			const ntg_api::string &get_label() const { return m_label; }
			const ntg_api::string &get_description() const { return m_description; }
			endpoint_type get_type() const { return m_type; }
			const CControlInfo *get_control_info() const { return m_control_info; }
			const CStreamInfo *get_stream_info() const { return m_stream_info; }

			/* helpers */
			bool should_send_to_host() const;
			bool is_input_file() const;
			bool should_load_from_ixd( ntg_api::CValue::type loaded_type ) const;
			bool is_audio_stream() const;

			void propagate_defaults();

		private:

			ntg_api::string m_name;
			ntg_api::string m_label;
			ntg_api::string m_description;
			endpoint_type m_type;
			CControlInfo *m_control_info;
			CStreamInfo *m_stream_info;
	};


	class CControlInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CControlInfo();
			~CControlInfo();

			enum control_type
			{
				STATEFUL = 1,
				BANG
			};

			control_type get_type() const { return m_type; }
			const CStateInfo *get_state_info() const { return m_state_info; }
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


	class CStateInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CStateInfo();
			~CStateInfo();

			ntg_api::CValue::type get_type() const { return m_type; }
			const CConstraint &get_constraint() const { return *m_constraint; }
			const ntg_api::CValue &get_default_value() const { return *m_default_value; }
			const CValueScale *get_value_scale() const { return m_value_scale; }
			const ntg_api::value_map &get_state_labels() const { return m_state_labels; }
			bool get_is_saved_to_file() const { return m_is_saved_to_file; }
			bool get_is_input_file() const { return m_is_input_file; }

		private:
			ntg_api::CValue::type m_type;
			CConstraint *m_constraint;
			ntg_api::CValue *m_default_value;
			CValueScale *m_value_scale;
			ntg_api::value_map m_state_labels;
			bool m_is_saved_to_file;
			bool m_is_input_file;
	};


	class CConstraint
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CConstraint();
			~CConstraint();

			const CValueRange *get_value_range() const { return m_value_range; }
			const ntg_api::value_set *get_allowed_states() const { return m_allowed_states; }

		private:
			CValueRange *m_value_range;
			ntg_api::value_set *m_allowed_states;
	};


	class CValueRange
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CValueRange();
			~CValueRange();

			const ntg_api::CValue &get_minimum() const { return *m_minimum; }
			const ntg_api::CValue &get_maximum() const { return *m_maximum; }

		private:

			ntg_api::CValue *m_minimum;
			ntg_api::CValue *m_maximum;
	};


	class CValueScale
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CValueScale();
			~CValueScale();

			enum scale_type
			{
				LINEAR = 1,
				EXPONENTIAL,
				DECIBEL
			};

			scale_type get_scale_type() const { return m_type; }
			int get_exponent_root() const { return m_exponent_root; }

		private:
			scale_type m_type;
			int m_exponent_root;
	};


	class CStreamInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CStreamInfo();
			~CStreamInfo();

			enum stream_type
			{
				AUDIO = 1
			};

			enum stream_direction
			{
				INPUT = 1,
				OUTPUT
			};

			stream_type get_type() const { return m_type; }
			stream_direction get_direction() const { return m_direction; }
		private:
			
			stream_type m_type;
			stream_direction m_direction;
	};


	class CWidgetDefinition
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CWidgetDefinition();
			~CWidgetDefinition();

			const ntg_api::string &get_type() const { return m_type; }
			const ntg_api::string &get_label() const { return m_label; }
			const CWidgetPosition &get_position() const { return *m_position; }
			const ntg_api::string_map &get_attribute_mappings() const { return m_attribute_mappings; }

		private:
			ntg_api::string m_type;
			ntg_api::string m_label;
			CWidgetPosition *m_position;
			ntg_api::string_map m_attribute_mappings;
	};


	class CWidgetPosition
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


	class CImplementationInfo
	{
		friend class CInterfaceDefinitionLoader;

		public:
			CImplementationInfo();
			~CImplementationInfo();

			const ntg_api::string &get_patch_name() const { return m_patch_name; }
			unsigned int get_checksum() const { return m_checksum; }

			void set_checksum( unsigned int checksum ) { m_checksum = checksum; }

		private:

			ntg_api::string m_patch_name;
			unsigned int m_checksum;
	};

}


#endif

