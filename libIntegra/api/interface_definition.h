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

/** \file interface_definition.h
 *  \brief Defines classes relating to integra module interfaces
 *
 * For more information about integra module interfaces see 
 * http://www.integralive.org/tutorials/module-development-guide
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

	/**Linked list of endpoint definitions.  Used to represent each module's endpoint list */
	typedef std::list<IEndpointDefinition *> endpoint_definition_list;	

	/**Linked list of widget definitions.  Used to represent each module's widget definition list */
	typedef std::list<IWidgetDefinition *> widget_definition_list;		


	/** \class IInterfaceDefinition interface_definition.h "api/interface_definition.h"
	 *  \brief Top level container for an Integra Module interface 
	 */
	class INTEGRA_API IInterfaceDefinition
	{
		protected:
			IInterfaceDefinition() {}
		public:
			virtual ~IInterfaceDefinition() {}

			/** Enumeration of module sources */
			enum module_source
			{
				/** 
				 * \brief modules shipped with integra 
				 * These are the modules which were located in CServerStartupInfo::system_module_directory when 
				 * the session was started 
				 */
				MODULE_SHIPPED_WITH_INTEGRA = 1,	

				/** 
				 * \brief 3rd party modules
				 * These are the modules which are located in CServerStartupInfo::third_party_module_directory, 
				 * including ones installed by IModuleManager during the current session.
				 */
				MODULE_3RD_PARTY,					

				/** 
				 * \brief embedded modules
				 *
				 * These are the modules which were embedded in .integra files which have been loaded during the current session
				 * Embedded modules are only loaded if they aren't already in memory as 'shipped with integra' or '3rd party'
				 * Normally they remain in memory even if all instances are deleted, but embedded modules with no instances 
				 * can be unloaded via IModuleManager::unload_unused_embedded_modules
				 */
				MODULE_EMBEDDED,					

				/** 
				 * \brief in-development modules
				 *
				 * This functionality allows the special loading of modules which haven't been installed, to 
				 * facilitate a smooth workflow for module developers.  See IModuleManager::load_module_in_development
				 */

				MODULE_IN_DEVELOPMENT 
			};

			/** \brief get module's guid
			 * 
			 * Uniquely identifies each module, and each version of each module.  That is to say that different versions
			 * of the same module have different module guid.
			 * \returns the module's guid
			 */
			virtual const GUID &get_module_guid() const = 0;

			/** \brief get module 'origin' guid
			 * 
			 * Identifies the module's lineage.  Different versions of the same module have the same origin id.
			 * This allows upgrading from older to newer versions (or sidestepping in the case of divergent development histories)
			 * \returns the module's 'origin' guid
			 */
			virtual const GUID &get_origin_guid() const = 0;

			/** \brief get module's source
			 * 
			 * Module source is the reason a module is currently loaded - where it came from.  See #module_source for 
			 * possible values
			 * \returns the module's source
			 */
			virtual module_source get_module_source() const = 0;

			/** \brief get info about the module's interface
			 * 
			 * \returns an IInterfaceInfo 
			 */
			virtual const IInterfaceInfo &get_interface_info() const = 0;

			/** \brief get the module's list of endpoints
			 * 
			 * \returns the endpoints, in an ordered list
			 */
			virtual const endpoint_definition_list &get_endpoint_definitions() const = 0;

			/** \brief get the module's list of widgets
			 * 
			 * \returns the widget definitions, in an ordered list
			 */
			virtual const widget_definition_list &get_widget_definitions() const = 0;

			/** \brief get info about the module's implementation
			 * 
			 * \returns an IImplementationInfo 
			 */
			virtual const IImplementationInfo *get_implementation_info() const = 0;
	};


	/** \class IInterfaceInfo interface_definition.h "api/interface_definition.h"
	 *  \brief Information about an Integra Module interface 
	 */
	class INTEGRA_API IInterfaceInfo
	{
		protected:
			IInterfaceInfo() {}
		public:
			virtual ~IInterfaceInfo() {}

			/** \brief get interface's name
			 * Interface names are upper camel case, with no spaces
			 */
			virtual const string &get_name() const = 0;

			/** \brief get more human-readable version of interface's name, with spaces between words
			 */
			virtual const string &get_label() const = 0;

			/** \brief get interface description
			 * Interface descriptions can use markdown format (http://en.wikipedia.org/wiki/Markdown)
			 */
			virtual const string &get_description() const = 0;

			/** \brief get interface's set of tags
			 * Tags are used to describe the interface, so that guis can provide useful filtering
			 */
			virtual const string_set &get_tags() const = 0;

			/** \brief get name of module's author
			 */
			virtual const string &get_author() const = 0;

			/** \brief timestamp of when the module's origin id was generated
			 */
			virtual const struct tm &get_created_date() const = 0;

			/** \brief timestamp of when the module's module id was last regenerated (last modification)
			 */
			virtual const struct tm &get_modified_date() const = 0;
	};


	/** \class IEndpointDefinition interface_definition.h "api/interface_definition.h"
	 *  \brief Container for info about an Endpoint in an Integra Module interface 
	 */
	class INTEGRA_API IEndpointDefinition
	{
		protected:
			IEndpointDefinition() {}
		public:
			virtual ~IEndpointDefinition() {}

			/** Enumeration of endpoint types */
			enum endpoint_type
			{
				/**
				 * Controls are either stateful 'attributes' or stateless 'bangs' ie push-button type controls.
				 * They pass information to and from module implementations, at a rate no faster than once every
				 * DSP buffer (64 samples).  Control endpoints can be used to send information to DSP modules, 
				 * to received information from DSP modules, and are also used by non-dsp modules as the inputs
				 * and outputs of all implemented-in-libIntegra business logic.
				 */

			    CONTROL = 1,

				/**
				 * Streams are connections between DSP modules.  At present the only type of stream is audio stream.
				 * It is envisaged that potentially in future, other types of streams such as video or midi could be introduced
				 */

				STREAM
			};

			/** \brief get endpoint's name
			 * Endpoint names are upper camel case, with no spaces.  They are used to uniquely identify endpoints
			 *  within interfaces, so each endpoint name must be unique within it's interface.
			 */
			virtual const string &get_name() const = 0;

			/** \brief get more human-readable version of endpoint's name, with spaces between words 
			 */
			virtual const string &get_label() const = 0;

			/** \brief get endpoint description
			 * Endpoint descriptions can use markdown format (http://en.wikipedia.org/wiki/Markdown)
			 */
			virtual const string &get_description() const = 0;

			/** \brief get endpoint type
			 * See ::endpoint_type
			 */
			virtual endpoint_type get_type() const = 0;

			/** \brief get control info
			 * \return when endpoint type is #CONTROL, returns an IControlInfo, otherwise NULL
			 */
			virtual const IControlInfo *get_control_info() const = 0;

			/** \brief get stream info
			 * \return when endpoint type is #STREAM, returns an IStreamInfo, otherwise NULL
			 */
			virtual const IStreamInfo *get_stream_info() const = 0;

			/** \return true when endpoint type is an audio stream, otherwise false
			 */
			virtual bool is_audio_stream() const = 0;
	};


	/** \class IControlInfo interface_definition.h "api/interface_definition.h"
	 *  \brief Control-specific info about an Endpoint in an Integra Module interface 
	 */
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


	/** \class IStateInfo interface_definition.h "api/interface_definition.h"
	 *  \brief Stateful-control-specific info about an Endpoint in an Integra Module interface 
	 */
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


	/** \class IConstraint interface_definition.h "api/interface_definition.h"
	 *  \brief Definition of a stateful control's constraint
	 */
	class INTEGRA_API IConstraint
	{
		protected:
			IConstraint() {}
		public:
			virtual ~IConstraint() {}

			virtual const IValueRange *get_value_range() const = 0;
			virtual const value_set *get_allowed_states() const = 0;
	};


	/** \class IValueRange interface_definition.h "api/interface_definition.h"
	 *  \brief Definition of a value-range type constraint
	 */
	class INTEGRA_API IValueRange
	{
		protected:
			IValueRange() {}
		public:
			virtual ~IValueRange() {}

			virtual const CValue &get_minimum() const = 0;
			virtual const CValue &get_maximum() const = 0;
	};


	/** \class IValueScale interface_definition.h "api/interface_definition.h"
	 *  \brief Info about how numeric stateful controls should be scaled
	 */
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


	/** \class IStreamInfo interface_definition.h "api/interface_definition.h"
	 *  \brief Stream-specific info about an Endpoint in an Integra Module interface 
	 */
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


	/** \class IWidgetDefinition interface_definition.h "api/interface_definition.h"
	 *  \brief Definition of a widget in an Integra Module interface 
	 */
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


	/** \class IWidgetPosition interface_definition.h "api/interface_definition.h"
	 *  \brief Definition of a widget position
	 */
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


	/** \class IImplementationInfo interface_definition.h "api/interface_definition.h"
	 *  \brief Information about an Integra Module's implementation
	 */
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

