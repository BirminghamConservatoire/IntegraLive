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
				 * \brief Modules shipped with integra 
				 *
				 * These are the modules which were located in CServerStartupInfo::system_module_directory when 
				 * the session was started 
				 */
				MODULE_SHIPPED_WITH_INTEGRA = 1,	

				/** 
				 * \brief 3rd party modules
				 *
				 * These are the modules which are located in CServerStartupInfo::third_party_module_directory, 
				 * including ones installed by IModuleManager during the current session.
				 */
				MODULE_3RD_PARTY,					

				/** 
				 * \brief Embedded modules
				 *
				 * These are the modules which were embedded in .integra files which have been loaded during the current session
				 * Embedded modules are only loaded if they aren't already in memory as 'shipped with integra' or '3rd party'
				 * Normally they remain in memory even if all instances are deleted, but embedded modules with no instances 
				 * can be unloaded via IModuleManager::unload_unused_embedded_modules
				 */
				MODULE_EMBEDDED,					

				/** 
				 * \brief In-development modules
				 *
				 * This functionality allows the special loading of modules which haven't been installed, to 
				 * facilitate a smooth workflow for module developers.  See IModuleManager::load_module_in_development
				 */

				MODULE_IN_DEVELOPMENT 
			};

			/** \brief Get module's guid
			 * 
			 * Uniquely identifies each module, and each version of each module.  That is to say that different versions
			 * of the same module have different module guid.
			 * \returns the module's guid
			 */
			virtual const GUID &get_module_guid() const = 0;

			/** \brief Get module 'origin' guid
			 * 
			 * Identifies the module's lineage.  Different versions of the same module have the same origin id.
			 * This allows upgrading from older to newer versions (or sidestepping in the case of divergent development histories)
			 * \returns the module's 'origin' guid
			 */
			virtual const GUID &get_origin_guid() const = 0;

			/** \brief Get module's source
			 * 
			 * Module source is the reason a module is currently loaded - where it came from.  See #module_source for 
			 * possible values
			 * \returns the module's source
			 */
			virtual module_source get_module_source() const = 0;

			/** \brief Get info about the module's interface
			 * 
			 * \returns an IInterfaceInfo 
			 */
			virtual const IInterfaceInfo &get_interface_info() const = 0;

			/** \brief Get the module's list of endpoints
			 * 
			 * \returns the endpoints, in an ordered list
			 */
			virtual const endpoint_definition_list &get_endpoint_definitions() const = 0;

			/** \brief Get the module's list of widgets
			 * 
			 * \returns the widget definitions, in an ordered list
			 */
			virtual const widget_definition_list &get_widget_definitions() const = 0;

			/** \brief Get info about the module's implementation
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

			/** \brief Get interface's name
			 *
			 * Interface names are upper camel case, with no spaces
			 */
			virtual const string &get_name() const = 0;

			/** \brief Get more human-readable version of interface's name, with spaces between words
			 *
			 */
			virtual const string &get_label() const = 0;

			/** \brief Retrieve the interface's inbuilt documentation 
			 *
			 * Interface documentation can use markdown format (http://en.wikipedia.org/wiki/Markdown)
			 */
			virtual const string &get_description() const = 0;

			/** \brief Get interface's set of tags
			 *
			 * Tags are used to describe the interface, so that guis can provide useful filtering
			 */
			virtual const string_set &get_tags() const = 0;

			/** \brief Get name of module's author
			 */
			virtual const string &get_author() const = 0;

			/** \brief Timestamp of when the module's origin id was generated
			 */
			virtual const struct tm &get_created_date() const = 0;

			/** \brief Timestamp of when the module's module id was last regenerated (last modification)
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

			/** \brief Get endpoint's name
			 *
			 * Endpoint names are upper camel case, with no spaces.  They are used to uniquely identify endpoints
			 *  within interfaces, so each endpoint name must be unique within it's interface.
			 */
			virtual const string &get_name() const = 0;

			/** \brief Get more human-readable version of endpoint's name, with spaces between words 
			 */
			virtual const string &get_label() const = 0;

			/** \brief Retrieve the endpoint's inbuilt documentation 
			 *
			 * Endpoint documentation can use markdown format (http://en.wikipedia.org/wiki/Markdown)
			 */
			virtual const string &get_description() const = 0;

			/** \brief Get endpoint type
			 *
			 * See ::endpoint_type
			 */
			virtual endpoint_type get_type() const = 0;

			/** \brief Get control info
			 *
			 * \return when endpoint type is #CONTROL, returns an IControlInfo, otherwise NULL
			 */
			virtual const IControlInfo *get_control_info() const = 0;

			/** \brief Get stream info
			 *
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

			/** Enumeration of control types */
			enum control_type
			{
				/**
				 * Stateful controls represent values (integer, float or string)
				 */
				STATEFUL = 1,

				/**
				 * 'Bang' controls are stateless, akin to push-buttons
				 */
				BANG
			};

			/** \brief Get control type
			 *
			 * See ::control_type
			 */
			virtual control_type get_type() const = 0;

			/** \brief Get state info
			 *
			 * See IStateInfo
			 * \return an IStateInfo, or NULL if the control is of type 'bang'
			 */
			virtual const IStateInfo *get_state_info() const = 0;

			/** 
			 * A few controls are defined as not available to be used as the source for connections and scripts.
			 * For example, a connection's source and target paths cannot themselves be source for another (or the same) connection
			 * \return true if this control can be a source for connections and an input for scripts, otherwise false
			 */
			virtual bool get_can_be_source() const = 0;

			/** 
			 * A few controls are defined as not available to be used as the target for connections and scripts.
			 * For example, it makes no sense to set AudioIn.vu by a connection or script
			 * \return true if this control can be a source for connections and an input for scripts, otherwise false
			 */
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

			/** get type of value used to represent the endpoint's state */
			virtual CValue::type get_type() const = 0;

			/** get the constraint.  Defines which values are allowed */
			virtual const IConstraint &get_constraint() const = 0;

			/** get the default value */
			virtual const CValue &get_default_value() const = 0;

			/** how should the value be scaled? */
			virtual const IValueScale *get_value_scale() const = 0;

			/** \brief Get the state labels
			 *
			 * State labels are a set of 'special' values with strings assigned to them
			 * They could be used to provide specially labelled widgets.  For instance, a pan control might
			 * want to define the labels { -1:'L', 0:'C', 1:'R' }
			 */
			virtual const value_map &get_state_labels() const = 0;

			/** \brief Test whether a value adheres to constraint
			 \param value value to test
			 \return true if value's type matches type of this state, and value adheres to constraint
			*/
			virtual bool test_constraint( const CValue &value ) const = 0;
	};


	/** \class IConstraint interface_definition.h "api/interface_definition.h"
	 *  \brief Definition of a stateful control's constraint
	 *
	 * All stateful controls must have a constraint, and the constraint must be either a 
	 * range of values (min to max), or a set of allowed values (an enumeration).
	 */
	class INTEGRA_API IConstraint
	{
		protected:
			IConstraint() {}
		public:
			virtual ~IConstraint() {}

			/** \brief Get value range
			 *
			 * \return an IValueRange *, or NULL if this constraint uses an allowed-value set
			 */
			virtual const IValueRange *get_value_range() const = 0;

			/** \brief Get allowed states
			 *
			 * \return a value_set *, or NULL if this constraint uses a value range
			 */
			virtual const value_set *get_allowed_states() const = 0;
	};


	/** \class IValueRange interface_definition.h "api/interface_definition.h"
	 * \brief Definition of a value-range type constraint
	 *
	 * \note When this constraint applies to a stateful endpoint of type integer or float, 
	 * the minimum and maximum will be of matching type.
	 * When the constraint applies to a string, the minimum and maximum will be of type integer, 
	 * and will define the minimum and maximum permitted length for the string.
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
	 *
	 * Many types of controls have a linear relationship between value and perceptual linearity.
	 * For instance, for a filter sweep to sound like it is moving at a constant rate, the 
	 * filter's cutoff frequency must accelerate (or decelerate) exponentially.  In other words
	 * the desired relationship between a controller and it's value is in this case exponential.
	 */
	class INTEGRA_API IValueScale
	{
		protected:
			IValueScale() {}
		public:
			virtual ~IValueScale() {}

			/* enumeration of supported scale types */
			enum scale_type
			{
				/* no scaling - value should be directly proportional to input */
				LINEAR = 1,		

				/* value should be proportional to <constant root>^input */
				EXPONENTIAL,

				/* value should be proportional to 10*log10( input ) */
				DECIBEL
			};

			/** get scale type.  See ::scale_type */
			virtual scale_type get_scale_type() const = 0;
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

			/** 
			 * enumeration of stream types.  Note that at present there is only one type of stream.
			 * this enumeration is in anticipation of other types of stream, eg midi or video
			 */
			enum stream_type
			{
				AUDIO = 1	/** audio stream */
			};

			/** 
			 * enumeration of stream directions.  
			 */
			enum stream_direction
			{
				INPUT = 1,
				OUTPUT
			};

			/** get stream type.  See ::stream_type */
			virtual stream_type get_type() const = 0;

			/** get stream direction.  See ::stream_direction */
			virtual stream_direction get_direction() const = 0;
	};


	/** \class IWidgetDefinition interface_definition.h "api/interface_definition.h"
	 *  \brief Definition of a widget in an Integra Module interface 
	 *
	 * Widgets definitions provide hints to users of libIntegra about how user interfaces for integra modules
	 * could be laid out.  Although most widgets control a single endpoint, they can in some cases control 
	 * more than one endpoint, for multidimensional widgets.
	 */
	class INTEGRA_API IWidgetDefinition
	{
		protected:
			IWidgetDefinition() {}
		public:
			virtual ~IWidgetDefinition() {}

			/** \brief Get widget type
			 *
			 * Widget types are a hint to supporting guis about what sort of widget should be used.
			 * The set of supported widget types is defined in SDK\ModuleCreator\src\assets\ModuleCreator_config.xml
			 */
			virtual const string &get_type() const = 0;

			/** \brief Get widget label
			 *
			 * When the widget is mapped to a single control, the label will match the control's name
			 * When the widget is mapped to multiple labels, the label should provide a meaningful name for 
			 * the set of controls it is mapped to
			 */
			virtual const string &get_label() const = 0;

			/** \brief Get widget position
			 *
			 * Provides a hint as to how a module's widgets might be laid out
			 */
			virtual const IWidgetPosition &get_position() const = 0;

			/** \brief Get attribute mappings
			 *
			 * Example: if a module used an XYScratchPad widget to control a filter's Cutoff and Q endpoints,
			 * the attribute mapping would be { 'x' -> 'Cutoff', 'y' -> 'Q' }
			 * \r return a map of widget attribute names to endpoint names
			 */
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

			/** \brief Get implementation checksum
			 * This checksum is calculated as the widget implementation is loaded 
			 * It allows users to detect whether two modules different module IDs but matching origin IDs 
			 * (in other words, two different versions of the same module) have identical implementations or not
			 * \return 32bit checksum of module implementation
			 */
			virtual unsigned int get_checksum() const = 0;
	};
}


#endif

