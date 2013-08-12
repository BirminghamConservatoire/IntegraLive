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

#include <assert.h>

#include "interface_definition_loader.h"
#include "interface_definition.h"
#include "trace.h"
#include "string_helper.h"

#define INTERFACE					"InterfaceDeclaration"
#define INTERFACE_INFO				"InterfaceInfo"			
#define NAME						"Name"
#define LABEL						"Label"
#define DESCRIPTION					"Description"
#define TAGS						"Tags"
#define TAG							"Tag"
#define IMPLEMENTED_IN_LIBINTEGRA	"ImplementedInLibIntegra"
#define AUTHOR						"Author"
#define CREATED_DATE				"CreatedDate"
#define MODIFIED_DATE				"ModifiedDate"
#define ENDPOINT_INFO				"EndpointInfo"
#define ENDPOINT					"Endpoint"
#define TYPE						"Type"
#define CONTROL_INFO				"ControlInfo"
#define CONTROL_TYPE				"ControlType"
#define STATE_INFO					"StateInfo"
#define STATE_TYPE					"StateType"
#define CONSTRAINT					"Constraint"
#define RANGE						"Range"
#define MINIMUM						"Minimum"
#define MAXIMUM						"Maximum"
#define SCALE						"Scale"
#define SCALE_TYPE					"ScaleType"
#define BASE						"Base"
#define ALLOWED_STATES				"AllowedStates"
#define STATE						"State"
#define DEFAULT						"Default"
#define STATE_LABELS				"StateLabels"
#define LABEL						"Label"
#define TEXT						"Text"
#define IS_INPUT_FILE				"IsInputFile"
#define IS_SAVED_TO_FILE			"IsSavedToFile"
#define CAN_BE_SOURCE				"CanBeSource"
#define CAN_BE_TARGET				"CanBeTarget"
#define IS_SENT_TO_HOST				"IsSentToHost"
#define STREAM_INFO					"StreamInfo"
#define STREAM_TYPE					"StreamType"
#define STREAM_DIRECTION			"StreamDirection"
#define WIDGET_INFO					"WidgetInfo"
#define WIDGET						"Widget"
#define WIDGET_TYPE					"WidgetType"
#define POSITION					"Position"
#define X							"X"
#define Y							"Y"
#define WIDTH						"Width"
#define HEIGHT						"Height"
#define ATTRIBUTE_MAPPINGS			"AttributeMappings"
#define ATTRIBUTE_MAPPING			"AttributeMapping"
#define WIDGET_ATTRIBUTE			"WidgetAttribute"
#define IMPLEMENTATION_INFO			"ImplementationInfo"
#define PATCH_NAME					"PatchName"

#define STR_FALSE					"false"
#define STR_TRUE					"true"
#define STR_CONTROL					"control"
#define STR_STREAM					"stream"
#define STR_STATE					"state"
#define STR_BANG					"bang"
#define STR_FLOAT					"float"
#define STR_INTEGER					"integer"
#define STR_STRING					"string"
#define STR_LINEAR					"linear"
#define STR_EXPONENTIAL				"exponential"
#define STR_DECIBEL					"decibel"
#define STR_AUDIO					"audio"
#define STR_INPUT					"input"
#define STR_OUTPUT					"output"

#define ATTRIBUTE_MODULE_GUID		"moduleGuid"
#define ATTRIBUTE_ORIGIN_GUID		"originGuid"

#define DOT							"."


/* 
 the following macros handle creation of structs within the loaded interface structure, and are
 to be used only by handle_element.  
*/


#define CREATE_CHILD_OBJECT( START_TAG, STORAGE_POINTER, TYPE )					\
	if( m_element_path == START_TAG )											\
	{																			\
		if( STORAGE_POINTER )													\
		{																		\
			NTG_TRACE_ERROR << "multiple " START_TAG " tags";					\
			return CError::INPUT_ERROR;											\
		}																		\
		else																	\
		{																		\
			STORAGE_POINTER = new TYPE;											\
			return CError::SUCCESS;												\
		}																		\
	}	


#define CREATE_LIST_ENTRY( START_TAG, LIST, TYPE )								\
	if( m_element_path == START_TAG )											\
	{																			\
		TYPE *entry = new TYPE;													\
		LIST.push_back( entry );												\
		return CError::SUCCESS;													\
	}




/* 
 the following macros handle reading of xml properties into specified locations, and are 
 to be used only by handle_element_value.  
*/

#define READ_MEMBER( ELEMENT, STORAGE_LOCATION )								\
	if( m_element_path == ELEMENT )												\
	{																			\
		return( converter( element_value, STORAGE_LOCATION ) );					\
	}																						

#define READ_SET_CONTENT( ELEMENT, STORAGE_LOCATION )							\
	if( m_element_path == ELEMENT )												\
	{																			\
		if( STORAGE_LOCATION.count( element_value ) > 0 )						\
		{																		\
			NTG_TRACE_ERROR << "duplicate" << element_value;					\
			return CError::INPUT_ERROR;											\
		}																		\
		else																	\
		{																		\
			STORAGE_LOCATION.insert( element_value );							\
			return CError::SUCCESS;												\
		}																		\
	}

#define READ_VALUE( ELEMENT, STORAGE_LOCATION, VALUE_TYPE )						\
	if( m_element_path == ELEMENT )												\
	{																			\
		STORAGE_LOCATION = CValue::factory( VALUE_TYPE );						\
		STORAGE_LOCATION->set_from_string( element_value );						\
		return CError::SUCCESS;													\
	}


#define READ_VALUE_SET_CONTENT( ELEMENT, STORAGE_LOCATION, VALUE_TYPE )			\
	if( m_element_path == ELEMENT )												\
	{																			\
		CValue *value = CValue::factory( VALUE_TYPE );							\
		value->set_from_string( element_value );								\
		STORAGE_LOCATION->insert( value );										\
		return CError::SUCCESS;													\
	}




namespace ntg_internal
{
	CInterfaceDefinitionLoader::CInterfaceDefinitionLoader()
	{
		m_reader = NULL;
		m_interface_definition = NULL;
		m_last_state_label_value = NULL;
	}


	CInterfaceDefinitionLoader::~CInterfaceDefinitionLoader()
	{
		assert( !m_interface_definition && !m_reader && !m_last_state_label_value );
	}



	CInterfaceDefinition *CInterfaceDefinitionLoader::load( const unsigned char &buffer, unsigned int buffer_size )
	{
		assert( !m_interface_definition && !m_reader && m_element_path.empty() );

		m_interface_definition = new CInterfaceDefinition;

		xmlInitParser();

		m_reader = xmlReaderForMemory( (char *) &buffer, buffer_size, NULL, NULL, 0 );
		if( !m_reader )
		{
			NTG_TRACE_ERROR << "unable to read file";
			cleanup();
			return NULL;
		}

		int depth = -1;
		bool handled_element_content = false;
		char *inner_xml = NULL; 

		while( xmlTextReaderRead( m_reader ) )
		{
			switch( xmlTextReaderNodeType( m_reader ) )
			{
				case XML_READER_TYPE_TEXT:
					{
						char *element_value = ( char * ) xmlTextReaderValue( m_reader );
						if( handle_element_value( element_value ) != CError::SUCCESS )
						{
							xmlFree( element_value );
							cleanup();
							return NULL;
						}
						xmlFree( element_value );
						handled_element_content = true;

						store_map_entries();
					}
					break;

				case XML_READER_TYPE_ELEMENT:
					{
						const char *element_name = ( const char * ) xmlTextReaderConstName( m_reader );
						int new_depth = xmlTextReaderDepth( m_reader );

						while( depth >= new_depth )
						{
							pop_element_name();
							depth--;
						}

						if( depth < new_depth )
						{
							push_element_name( element_name );
							depth++;
						}

						assert( depth == new_depth );

						if( handle_element() != CError::SUCCESS )
						{
							cleanup();
							return NULL;
						}

						if( xmlTextReaderHasAttributes( m_reader ) )
						{
							if( handle_element_attributes() != CError::SUCCESS )
							{
								cleanup();
								return NULL;
							}
						}

						if( xmlTextReaderIsEmptyElement( m_reader ) )
						{
							handle_element_value( "" );
							handled_element_content = true;
						}
						else
						{
							handled_element_content = false;
							inner_xml = ( char * ) xmlTextReaderReadInnerXml( m_reader );
						}
					}

					break;

				case XML_READER_TYPE_END_ELEMENT:
					if( !handled_element_content && inner_xml )
					{
						handle_element_value( inner_xml );
					}
					if( inner_xml )
					{
						xmlFree( inner_xml );
						inner_xml = NULL;
					}
					handled_element_content = true;
					break;

				default:
					break;
			}
		}

		CError CError = do_sanity_check();
		if( CError != CError::SUCCESS )
		{
			NTG_TRACE_ERROR << "sanity check failed";
			cleanup();
			return NULL;
		}

		m_interface_definition->propagate_defaults();

		NTG_TRACE_VERBOSE << "Loaded ok: " << m_interface_definition->get_interface_info().get_name();
		CInterfaceDefinition *loaded_interface = m_interface_definition;
		m_interface_definition = NULL;
		cleanup();

		return loaded_interface;
	}


	CError CInterfaceDefinitionLoader::handle_element_value( const string &element_value )
	{
		assert( m_interface_definition && !m_element_path.empty() );

		/* interface info */
		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT NAME, 
			m_interface_definition->m_interface_info->m_name );

		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT LABEL, 
			m_interface_definition->m_interface_info->m_label );

		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT DESCRIPTION, 
			m_interface_definition->m_interface_info->m_description );

		READ_SET_CONTENT( 
			INTERFACE DOT INTERFACE_INFO DOT TAGS DOT TAG, 
			m_interface_definition->m_interface_info->m_tags );

		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT IMPLEMENTED_IN_LIBINTEGRA, 
			m_interface_definition->m_interface_info->m_implemented_in_libintegra );

		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT AUTHOR, 
			m_interface_definition->m_interface_info->m_author );

		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT CREATED_DATE, 
			m_interface_definition->m_interface_info->m_created_date );

		READ_MEMBER( 
			INTERFACE DOT INTERFACE_INFO DOT MODIFIED_DATE, 
			m_interface_definition->m_interface_info->m_modified_date );


		/* endpoint info */
		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT NAME, 
			m_interface_definition->m_endpoint_definitions.back()->m_name );

		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT LABEL, 
			m_interface_definition->m_endpoint_definitions.back()->m_label );

		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT DESCRIPTION, 
			m_interface_definition->m_endpoint_definitions.back()->m_description );

		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT TYPE, 
			m_interface_definition->m_endpoint_definitions.back()->m_type );

		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT CONTROL_TYPE, 
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_type );

		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT STATE_TYPE, 
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_type );

		READ_VALUE( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT CONSTRAINT DOT RANGE DOT MINIMUM,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_constraint->m_value_range->m_minimum,
			get_range_type() );

		READ_VALUE( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT CONSTRAINT DOT RANGE DOT MAXIMUM,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_constraint->m_value_range->m_maximum,
			get_range_type() );

		READ_VALUE_SET_CONTENT( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT CONSTRAINT DOT ALLOWED_STATES DOT STATE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_constraint->m_allowed_states,
			get_state_type() );
	
		READ_VALUE( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT DEFAULT,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_default_value,
			get_state_type() );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT SCALE DOT SCALE_TYPE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_value_scale->m_type );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT SCALE DOT BASE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_value_scale->m_exponent_root );

		READ_VALUE( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT STATE_LABELS DOT LABEL DOT STATE,
			m_last_state_label_value,
			get_state_type() );

		READ_MEMBER( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT STATE_LABELS DOT LABEL DOT TEXT,
			m_last_state_label_key );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT IS_INPUT_FILE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_is_input_file );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT IS_SAVED_TO_FILE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_is_saved_to_file );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT CAN_BE_SOURCE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_can_be_source );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT CAN_BE_TARGET,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_can_be_target );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT IS_SENT_TO_HOST,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_is_sent_to_host );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT STREAM_INFO DOT STREAM_TYPE,
			m_interface_definition->m_endpoint_definitions.back()->m_stream_info->m_type );

		READ_MEMBER(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT STREAM_INFO DOT STREAM_DIRECTION,
			m_interface_definition->m_endpoint_definitions.back()->m_stream_info->m_direction );


		/* widget info */

		READ_MEMBER( 
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT WIDGET_TYPE,
			m_interface_definition->m_widget_definitions.back()->m_type );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT LABEL,
			m_interface_definition->m_widget_definitions.back()->m_label );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT POSITION DOT X,
			m_interface_definition->m_widget_definitions.back()->m_position->m_x );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT POSITION DOT Y,
			m_interface_definition->m_widget_definitions.back()->m_position->m_y );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT POSITION DOT WIDTH,
			m_interface_definition->m_widget_definitions.back()->m_position->m_width );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT POSITION DOT HEIGHT,
			m_interface_definition->m_widget_definitions.back()->m_position->m_height );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT ATTRIBUTE_MAPPINGS DOT ATTRIBUTE_MAPPING DOT WIDGET_ATTRIBUTE,
			m_last_widget_key );

		READ_MEMBER(
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT ATTRIBUTE_MAPPINGS DOT ATTRIBUTE_MAPPING DOT ENDPOINT,
			m_last_widget_value );

		/* implementation info */

		READ_MEMBER( 
			INTERFACE DOT IMPLEMENTATION_INFO DOT PATCH_NAME,
			m_interface_definition->m_implementation_info->m_patch_name );

		NTG_TRACE_ERROR << "unhandled element: " << m_element_path;
	
		return CError::SUCCESS;

	}


	CError CInterfaceDefinitionLoader::handle_element()
	{
		assert( m_interface_definition && !m_element_path.empty() );

		/* handle child objects */
		CREATE_CHILD_OBJECT( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO, 
			m_interface_definition->m_endpoint_definitions.back()->m_control_info,
			CControlInfo );

		CREATE_CHILD_OBJECT( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO, 
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info, 
			CStateInfo );

		CREATE_CHILD_OBJECT( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT STREAM_INFO, 
			m_interface_definition->m_endpoint_definitions.back()->m_stream_info, 
			CStreamInfo );

		CREATE_CHILD_OBJECT( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT CONSTRAINT DOT RANGE, 
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_constraint->m_value_range, 
			CValueRange );

		CREATE_CHILD_OBJECT( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT CONSTRAINT DOT ALLOWED_STATES, 
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_constraint->m_allowed_states, 
			value_set );

		CREATE_CHILD_OBJECT(
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT SCALE,
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_value_scale,
			CValueScale );

		CREATE_CHILD_OBJECT( 
			INTERFACE DOT IMPLEMENTATION_INFO, 
			m_interface_definition->m_implementation_info, 
			CImplementationInfo );

		/* handle list entries */

		/*CREATE_LIST_ENTRY( 
			INTERFACE DOT INTERFACE_INFO DOT TAGS DOT TAG, 
			m_interface_definition->m_interface_m_interface_info->m_m_tags 
			ntg_tag );*/

		CREATE_LIST_ENTRY( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT, 
			m_interface_definition->m_endpoint_definitions, 
			CEndpointDefinition );

		/*CREATE_LIST_ENTRY( 
			INTERFACE DOT ENDPOINT_INFO DOT ENDPOINT DOT CONTROL_INFO DOT STATE_INFO DOT STATE_LABELS DOT LABEL, 
			m_interface_definition->endpoint_list->control_m_interface_info->m_state_m_interface_info->m_state_labels, 
			ntg_state_label );*/

		CREATE_LIST_ENTRY( 
			INTERFACE DOT WIDGET_INFO DOT WIDGET, 
			m_interface_definition->m_widget_definitions, 
			CWidgetDefinition );

		/*CREATE_LIST_ENTRY( 
			INTERFACE DOT WIDGET_INFO DOT WIDGET DOT ATTRIBUTE_MAPPINGS DOT ATTRIBUTE_MAPPING, 
			m_interface_definition->widget_list->mapping_list, 
			ntg_widget_attribute_mapping );*/

		return CError::SUCCESS;
	}


	CError CInterfaceDefinitionLoader::handle_element_attributes()
	{
		char *origin_guid_attribute = NULL;
		CError error = CError::SUCCESS;

		assert( m_interface_definition && m_reader && !m_element_path.empty() );

		if( m_element_path == INTERFACE )
		{
			char *module_guid_attribute = ( char * ) xmlTextReaderGetAttribute( m_reader, BAD_CAST ATTRIBUTE_MODULE_GUID );
			if( module_guid_attribute )
			{
				if( CStringHelper::string_to_guid( module_guid_attribute, m_interface_definition->m_module_guid ) != CError::SUCCESS )
				{
					NTG_TRACE_ERROR << "Couldn't parse guid: " << module_guid_attribute;
					error = CError::INPUT_ERROR;
				}

				xmlFree( module_guid_attribute );
			}
			else
			{
				NTG_TRACE_ERROR << INTERFACE " lacks " ATTRIBUTE_MODULE_GUID " attribute";
				error = CError::INPUT_ERROR;
			}

			char *origin_guid_attribute = ( char * ) xmlTextReaderGetAttribute( m_reader, BAD_CAST ATTRIBUTE_ORIGIN_GUID );
			if( origin_guid_attribute )
			{
				if( CStringHelper::string_to_guid( origin_guid_attribute, m_interface_definition->m_origin_guid ) != CError::SUCCESS )
				{
					NTG_TRACE_ERROR << "Couldn't parse guid: " << origin_guid_attribute;
					error = CError::INPUT_ERROR;
				}

				xmlFree( origin_guid_attribute );
			}
			else
			{
				NTG_TRACE_ERROR << INTERFACE " lacks " ATTRIBUTE_ORIGIN_GUID " attribute";
				error = CError::INPUT_ERROR;
			}
		}

		return error;
	}


	void CInterfaceDefinitionLoader::store_map_entries()
	{
		if( m_last_state_label_value && !m_last_state_label_key.empty() )
		{
			m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_state_labels[ m_last_state_label_key ] = m_last_state_label_value;
			m_last_state_label_key.clear();
			m_last_state_label_value = NULL;
		}

		if( !m_last_widget_key.empty() && !m_last_widget_value.empty() )
		{
			m_interface_definition->m_widget_definitions.back()->m_attribute_mappings[ m_last_widget_key ] = m_last_widget_value;
			m_last_widget_key.clear();
			m_last_widget_value.clear();
		}
	}


	void CInterfaceDefinitionLoader::push_element_name( const string &element )
	{
		if( !m_element_path.empty() )
		{
			m_element_path += DOT;
		}

		m_element_path += element;
	}


	void CInterfaceDefinitionLoader::pop_element_name()
	{
		size_t last_dot = m_element_path.find_last_of( DOT );
		if( last_dot == string::npos )
		{
			m_element_path.clear();
		}
		else
		{
			m_element_path = m_element_path.substr( 0, last_dot );
		}
	}


	CValue::type CInterfaceDefinitionLoader::get_range_type()
	{
		CValue::type type = get_state_type();

		if( type == CValue::STRING )
		{
			/* special case - strings have integer for their range - defines length limits */
			return CValue::INTEGER;
		}
		else
		{
			return type;
		}
	}


	CValue::type CInterfaceDefinitionLoader::get_state_type()
	{
		assert( m_interface_definition && !m_interface_definition->m_endpoint_definitions.empty() );

		return m_interface_definition->m_endpoint_definitions.back()->m_control_info->m_state_info->m_type;
	}


	CError CInterfaceDefinitionLoader::do_sanity_check()
	{
		if( !m_interface_definition )
		{
			return CError::INPUT_ERROR;
		}

		if( m_interface_definition->get_interface_info().get_name().empty() )
		{
			return CError::INPUT_ERROR;
		}

		const endpoint_definition_list &endpoint_definitions = m_interface_definition->get_endpoint_definitions();
		for( endpoint_definition_list::const_iterator i = endpoint_definitions.begin(); i != endpoint_definitions.end(); i++ )
		{
			const CEndpointDefinition &endpoint_definition = **i;

			if( endpoint_definition.get_name().empty() )	
			{
				return CError::INPUT_ERROR;
			}

			switch( endpoint_definition.get_type() )
			{
				case CEndpointDefinition::CONTROL:	
					{
						const CControlInfo *control_info = endpoint_definition.get_control_info();

						if( !control_info )
						{
							return CError::INPUT_ERROR;
						}

						switch( control_info->get_type() )
						{
							case CControlInfo::STATEFUL:
								if( !control_info->get_state_info() ) 
								{
									return CError::INPUT_ERROR;
								}
								break;

							case CControlInfo::BANG:
								break;

							default:
								return CError::INPUT_ERROR;
						}
					}
					break;

				case CEndpointDefinition::STREAM:
					if( !endpoint_definition.get_stream_info() ) 
					{
						return CError::INPUT_ERROR;
					}
					break;

				default:
					return CError::INPUT_ERROR;
			}
		}

		const widget_definition_list &widget_definitions = m_interface_definition->get_widget_definitions();

		for( widget_definition_list::const_iterator i = widget_definitions.begin(); i != widget_definitions.end(); i++ )
		{
			const CWidgetDefinition &widget_definition = **i;
			if( widget_definition.get_type().empty() || widget_definition.get_label().empty() )
			{
				return CError::INPUT_ERROR;
			}
		}

		return CError::SUCCESS;
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, string &output )
	{
		output = input;
		return CError::SUCCESS;
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, bool &output )
	{
		if( input == STR_FALSE )
		{
			output = false;
			return CError::SUCCESS;
		}

		if( input == STR_TRUE )
		{
			output = true;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid boolean: " << input;
		return CError::INPUT_ERROR;
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, int &output )
	{
		output = atoi( input.c_str() );
		return CError::SUCCESS;
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, float &output )
	{
		output = atof( input.c_str() );
		return CError::SUCCESS;
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CEndpointDefinition::endpoint_type &output )
	{
		if( input == STR_CONTROL )
		{
			output = CEndpointDefinition::CONTROL;
			return CError::SUCCESS;
		}

		if( input == STR_STREAM )
		{
			output = CEndpointDefinition::STREAM;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid endpoint type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CControlInfo::control_type &output )
	{
		if( input == STR_STATE )
		{
			output = CControlInfo::STATEFUL;
			return CError::SUCCESS;
		}

		if( input == STR_BANG )
		{
			output = CControlInfo::BANG;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid control type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CValue::type &output )
	{
		if( input == STR_FLOAT )
		{
			output = CValue::FLOAT;
			return CError::SUCCESS;
		}

		if( input == STR_INTEGER )
		{
			output = CValue::INTEGER;
			return CError::SUCCESS;
		}

		if( input == STR_STRING )
		{
			output = CValue::STRING;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid value type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CValueScale::scale_type &output )
	{
		if( input == STR_LINEAR )
		{
			output = CValueScale::LINEAR;
			return CError::SUCCESS;
		}

		if( input == STR_EXPONENTIAL )
		{
			output = CValueScale::EXPONENTIAL;
			return CError::SUCCESS;
		}

		if( input == STR_DECIBEL )
		{
			output = CValueScale::DECIBEL;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid scale type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CStreamInfo::stream_type &output )
	{
		if( input == STR_AUDIO )
		{
			output = CStreamInfo::AUDIO;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid stream type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CStreamInfo::stream_direction &output )
	{
		if( input == STR_INPUT )
		{
			output = CStreamInfo::INPUT;
			return CError::SUCCESS;
		}

		if( input == STR_OUTPUT )
		{
			output = CStreamInfo::OUTPUT;
			return CError::SUCCESS;
		}

		NTG_TRACE_ERROR << "invalid stream direction: " << input;
		return CError::INPUT_ERROR;
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, struct tm &output )
	{
		return CStringHelper::string_to_date( input.c_str(), output );
	}


	void CInterfaceDefinitionLoader::cleanup()
	{
		if( m_reader )
		{
			xmlFreeTextReader( m_reader );
			m_reader = NULL;
		}

		if( m_interface_definition )
		{
			delete m_interface_definition;
			m_interface_definition = NULL;
		}

		if( m_last_state_label_value )
		{
			delete m_last_state_label_value;
			m_last_state_label_value = NULL;
		}

		m_element_path.clear();
	}

}