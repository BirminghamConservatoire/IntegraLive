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


#ifndef INTEGRA_INTERFACE_DEFINITION_API_H
#define INTEGRA_INTERFACE_DEFINITION_API_H


#include "../externals/guiddef.h"

#include "common_typedefs.h"
#include "guid_helper.h"
#include "value.h"

#include <list>

#include <time.h>

namespace integra_api
{
	class IInterfaceDefinition;
	class IInterfaceInfo;
	class IEndpointDefinition;
	class IControlInfo;
	class IStateInfo;
	class IConstraint;
	class IValueRange;
	class IValueScale;
	class IStreamInfo;
	class IWidgetDefinition;
	class IWidgetPosition;
	class IImplementationInfo;

	typedef std::list<IEndpointDefinition *> endpoint_definition_list;
	typedef std::list<IWidgetDefinition *> widget_definition_list;

	typedef std::unordered_map<GUID, IInterfaceDefinition *, GuidHash> map_guid_to_interface_definition;
	typedef std::unordered_map<string, IInterfaceDefinition *> map_string_to_interface_definition;


	class INTEGRA_API IInterfaceDefinition
	{
		protected:
			IInterfaceDefinition() {}
		public:
			virtual ~IInterfaceDefinition() {}

			enum module_source
			{
				MODULE_SHIPPED_WITH_INTEGRA = 1,	
				MODULE_3RD_PARTY,
				MODULE_EMBEDDED,
				MODULE_IN_DEVELOPMENT 
			};

			virtual const GUID &get_module_guid() const = 0;
			virtual const GUID &get_origin_guid() const = 0;
			virtual module_source get_module_source() const = 0;
			virtual const IInterfaceInfo &get_interface_info() const = 0;
			virtual const endpoint_definition_list &get_endpoint_definitions() const = 0;
			virtual const widget_definition_list &get_widget_definitions() const = 0;
			virtual const IImplementationInfo *get_implementation_info() const = 0;
	};


	class INTEGRA_API IInterfaceInfo
	{
		protected:
			IInterfaceInfo() {}
		public:
			virtual ~IInterfaceInfo() {}

			virtual const string &get_name() const = 0;
			virtual const string &get_label() const = 0;
			virtual const string &get_description() const = 0;
			virtual const string_set &get_tags() const = 0;
			virtual const string &get_author() const = 0;
			virtual const struct tm &get_created_date() const = 0;
			virtual const struct tm &get_modified_date() const = 0;
	};


	class INTEGRA_API IEndpointDefinition
	{
		protected:
			IEndpointDefinition() {}
		public:
			virtual ~IEndpointDefinition() {}

			enum endpoint_type
			{
			    CONTROL = 1,
				STREAM
			};

			virtual const string &get_name() const = 0;
			virtual const string &get_label() const = 0;
			virtual const string &get_description() const = 0;
			virtual endpoint_type get_type() const = 0;
			virtual const IControlInfo *get_control_info() const = 0;
			virtual const IStreamInfo *get_stream_info() const = 0;

			virtual bool is_audio_stream() const = 0;
	};


	class INTEGRA_API IControlInfo
	{
		protected:
			IControlInfo() {}
		public:
			virtual ~IControlInfo() {}

			enum control_type
			{
				STATEFUL = 1,
				BANG
			};

			virtual control_type get_type() const = 0;
			virtual const IStateInfo *get_state_info() const = 0;
			virtual bool get_can_be_source() const = 0;
			virtual bool get_can_be_target() const = 0;
	};


	class INTEGRA_API IStateInfo
	{
		protected:
			IStateInfo() {}
		public:
			virtual ~IStateInfo() {}

			virtual CValue::type get_type() const = 0;
			virtual const IConstraint &get_constraint() const = 0;
			virtual const CValue &get_default_value() const = 0;
			virtual const IValueScale *get_value_scale() const = 0;
			virtual const value_map &get_state_labels() const = 0;

			virtual bool test_constraint( const CValue &value ) const = 0;
	};


	class INTEGRA_API IConstraint
	{
		protected:
			IConstraint() {}
		public:
			virtual ~IConstraint() {}

			virtual const IValueRange *get_value_range() const = 0;
			virtual const value_set *get_allowed_states() const = 0;
	};


	class INTEGRA_API IValueRange
	{
		protected:
			IValueRange() {}
		public:
			virtual ~IValueRange() {}

			virtual const CValue &get_minimum() const = 0;
			virtual const CValue &get_maximum() const = 0;
	};


	class INTEGRA_API IValueScale
	{
		protected:
			IValueScale() {}
		public:
			virtual ~IValueScale() {}

			enum scale_type
			{
				LINEAR = 1,
				EXPONENTIAL,
				DECIBEL
			};

			virtual scale_type get_scale_type() const = 0;
			virtual int get_exponent_root() const = 0;
	};


	class INTEGRA_API IStreamInfo
	{
		protected:
			IStreamInfo() {}
		public:
			virtual ~IStreamInfo() {}

			enum stream_type
			{
				AUDIO = 1
			};

			enum stream_direction
			{
				INPUT = 1,
				OUTPUT
			};

			virtual stream_type get_type() const = 0;
			virtual stream_direction get_direction() const = 0;
	};


	class INTEGRA_API IWidgetDefinition
	{
		protected:
			IWidgetDefinition() {}
		public:
			virtual ~IWidgetDefinition() {}

			virtual const string &get_type() const = 0;
			virtual const string &get_label() const = 0;
			virtual const IWidgetPosition &get_position() const = 0;
			virtual const string_map &get_attribute_mappings() const = 0;
	};


	class INTEGRA_API IWidgetPosition
	{
		protected:
			IWidgetPosition() {}
		public:	
			virtual ~IWidgetPosition() {}

			virtual float get_x() const = 0;
			virtual float get_y() const = 0;
			virtual float get_width() const = 0;
			virtual float get_height() const = 0;
	};


	class INTEGRA_API IImplementationInfo
	{
		protected:
			IImplementationInfo() {}
		public:
			virtual ~IImplementationInfo() {}

			virtual unsigned int get_checksum() const = 0;
	};

}


#endif

