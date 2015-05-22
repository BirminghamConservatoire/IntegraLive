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



#include "platform_specifics.h"

#include <assert.h>

#include "interface_definition_loader.h"
#include "interface_definition.h"
#include "api/trace.h"
#include "api/guid_helper.h"
#include "api/string_helper.h"



/* 
 the following macros handle creation of structs within the loaded interface structure, and are
 to be used only by handle_element.  
*/


#define CREATE_CHILD_OBJECT( START_TAG, STORAGE_POINTER, Type )					\
	if( m_element_path == START_TAG )											\
	{																			\
		if( STORAGE_POINTER )													\
		{																		\
			INTEGRA_TRACE_ERROR << "multiple " START_TAG " tags";					\
			return CError::INPUT_ERROR;											\
		}																		\
		else																	\
		{																		\
			STORAGE_POINTER = new Type;											\
			return CError::SUCCESS;												\
		}																		\
	}	


#define CREATE_LIST_ENTRY( START_TAG, LIST, Type )								\
	if( m_element_path == START_TAG )											\
	{																			\
		Type *entry = new Type;													\
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
			INTEGRA_TRACE_ERROR << "duplicate" << element_value;					\
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




namespace integra_internal
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
			INTEGRA_TRACE_ERROR << "unable to read file";
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
			INTEGRA_TRACE_ERROR << "sanity check failed";
			cleanup();
			return NULL;
		}

		m_interface_definition->propagate_defaults();

		INTEGRA_TRACE_VERBOSE << "Loaded ok: " << m_interface_definition->get_interface_info().get_name();
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
			"InterfaceDeclaration.InterfaceInfo.Name", 
			m_interface_definition->m_interface_info->m_name );

		READ_MEMBER( 
			"InterfaceDeclaration.InterfaceInfo.Label", 
			m_interface_definition->m_interface_info->m_label );

		READ_MEMBER( 
			"InterfaceDeclaration.InterfaceInfo.Description", 
			m_interface_definition->m_interface_info->m_description );

		READ_SET_CONTENT( 
			"InterfaceDeclaration.InterfaceInfo.Tags.Tag", 
			m_interface_definition->m_interface_info->m_tags );

		READ_MEMBER( 
			"InterfaceDeclaration.InterfaceInfo.ImplementedInLibIntegra", 
			m_interface_definition->m_interface_info->m_implemented_in_libintegra );

		READ_MEMBER( 
			"InterfaceDeclaration.InterfaceInfo.Author", 
			m_interface_definition->m_interface_info->m_author );

		READ_MEMBER( 
			"InterfaceDeclaration.InterfaceInfo.CreatedDate", 
			m_interface_definition->m_interface_info->m_created_date );

		READ_MEMBER( 
			"InterfaceDeclaration.InterfaceInfo.ModifiedDate", 
			m_interface_definition->m_interface_info->m_modified_date );


		/* endpoint info */
		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.Name", 
			current_endpoint().m_name );

		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.Label", 
			current_endpoint().m_label );

		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.Description", 
			current_endpoint().m_description );

		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.Type", 
			current_endpoint().m_type );

		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.ControlType", 
			current_endpoint().m_control_info->m_type );

		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.StateType", 
			current_endpoint().m_control_info->m_state_info->m_type );

		READ_VALUE( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Constraint.Range.Minimum",
			current_endpoint().m_control_info->m_state_info->m_constraint->m_value_range->m_minimum,
			get_range_type() );

		READ_VALUE( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Constraint.Range.Maximum",
			current_endpoint().m_control_info->m_state_info->m_constraint->m_value_range->m_maximum,
			get_range_type() );

		READ_VALUE_SET_CONTENT( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Constraint.AllowedStates.State",
			current_endpoint().m_control_info->m_state_info->m_constraint->m_allowed_states,
			get_state_type() );
	
		READ_VALUE( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Default",
			current_endpoint().m_control_info->m_state_info->m_default_value,
			get_state_type() );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Scale.ScaleType",
			current_endpoint().m_control_info->m_state_info->m_value_scale->m_type );

		READ_VALUE( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.StateLabels.Label.State",
			m_last_state_label_value,
			get_state_type() );

		READ_MEMBER( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.StateLabels.Label.Text",
			m_last_state_label_key );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.IsInputFile",
			current_endpoint().m_control_info->m_state_info->m_is_input_file );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.IsSavedToFile",
			current_endpoint().m_control_info->m_state_info->m_is_saved_to_file );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.CanBeSource",
			current_endpoint().m_control_info->m_can_be_source );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.CanBeTarget",
			current_endpoint().m_control_info->m_can_be_target );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.IsSentToHost",
			current_endpoint().m_control_info->m_is_sent_to_host );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.StreamInfo.StreamType",
			current_endpoint().m_stream_info->m_type );

		READ_MEMBER(
			"InterfaceDeclaration.EndpointInfo.Endpoint.StreamInfo.StreamDirection",
			current_endpoint().m_stream_info->m_direction );


		/* widget info */

		READ_MEMBER( 
			"InterfaceDeclaration.WidgetInfo.Widget.WidgetType",
			current_widget().m_type );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.Label",
			current_widget().m_label );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.Position.X",
			current_widget().m_position->m_x );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.Position.Y",
			current_widget().m_position->m_y );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.Position.Width",
			current_widget().m_position->m_width );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.Position.Height",
			current_widget().m_position->m_height );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.AttributeMappings.AttributeMapping.WidgetAttribute",
			m_last_widget_key );

		READ_MEMBER(
			"InterfaceDeclaration.WidgetInfo.Widget.AttributeMappings.AttributeMapping.Endpoint",
			m_last_widget_value );

		/* implementation info */

		READ_MEMBER( 
			"InterfaceDeclaration.ImplementationInfo.PatchName",
			m_interface_definition->m_implementation_info->m_patch_name );

		INTEGRA_TRACE_ERROR << "unhandled element: " << m_element_path << " for module: " << m_interface_definition->m_interface_info->m_name;
	
		return CError::SUCCESS;

	}


	CError CInterfaceDefinitionLoader::handle_element()
	{
		assert( m_interface_definition && !m_element_path.empty() );

		/* handle child objects */
		CREATE_CHILD_OBJECT( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo", 
			current_endpoint().m_control_info,
			CControlInfo );

		CREATE_CHILD_OBJECT( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo", 
			current_endpoint().m_control_info->m_state_info, 
			CStateInfo );

		CREATE_CHILD_OBJECT( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.StreamInfo", 
			current_endpoint().m_stream_info, 
			CStreamInfo );

		CREATE_CHILD_OBJECT( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Constraint.Range", 
			current_endpoint().m_control_info->m_state_info->m_constraint->m_value_range, 
			CValueRange );

		CREATE_CHILD_OBJECT( 
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Constraint.AllowedStates", 
			current_endpoint().m_control_info->m_state_info->m_constraint->m_allowed_states, 
			value_set );

		CREATE_CHILD_OBJECT(
			"InterfaceDeclaration.EndpointInfo.Endpoint.ControlInfo.StateInfo.Scale",
			current_endpoint().m_control_info->m_state_info->m_value_scale,
			CValueScale );

		CREATE_CHILD_OBJECT( 
			"InterfaceDeclaration.ImplementationInfo", 
			m_interface_definition->m_implementation_info, 
			CImplementationInfo );

		/* handle list entries */
		CREATE_LIST_ENTRY( 
			"InterfaceDeclaration.EndpointInfo.Endpoint", 
			m_interface_definition->m_endpoint_definitions, 
			CEndpointDefinition );

		CREATE_LIST_ENTRY( 
			"InterfaceDeclaration.WidgetInfo.Widget", 
			m_interface_definition->m_widget_definitions, 
			CWidgetDefinition );

		return CError::SUCCESS;
	}


	CError CInterfaceDefinitionLoader::handle_element_attributes()
	{
		CError error = CError::SUCCESS;

		assert( m_interface_definition && m_reader && !m_element_path.empty() );

		if( m_element_path == "InterfaceDeclaration" )
		{
			char *module_guid_attribute = ( char * ) xmlTextReaderGetAttribute( m_reader, BAD_CAST "moduleGuid" );
			if( module_guid_attribute )
			{
				if( CGuidHelper::string_to_guid( module_guid_attribute, m_interface_definition->m_module_guid ) != CError::SUCCESS )
				{
					INTEGRA_TRACE_ERROR << "Couldn't parse guid: " << module_guid_attribute;
					error = CError::INPUT_ERROR;
				}

				xmlFree( module_guid_attribute );
			}
			else
			{
				INTEGRA_TRACE_ERROR << "InterfaceDeclaration lacks moduleGuid attribute";
				error = CError::INPUT_ERROR;
			}

			char *origin_guid_attribute = ( char * ) xmlTextReaderGetAttribute( m_reader, BAD_CAST "originGuid" );
			if( origin_guid_attribute )
			{
				if( CGuidHelper::string_to_guid( origin_guid_attribute, m_interface_definition->m_origin_guid ) != CError::SUCCESS )
				{
					INTEGRA_TRACE_ERROR << "Couldn't parse guid: " << origin_guid_attribute;
					error = CError::INPUT_ERROR;
				}

				xmlFree( origin_guid_attribute );
			}
			else
			{
				INTEGRA_TRACE_ERROR << "InterfaceDeclaration lacks originGuid attribute";
				error = CError::INPUT_ERROR;
			}
		}

		return error;
	}


	void CInterfaceDefinitionLoader::store_map_entries()
	{
		if( m_last_state_label_value && !m_last_state_label_key.empty() )
		{
			current_endpoint().m_control_info->m_state_info->m_state_labels[ m_last_state_label_key ] = m_last_state_label_value;
			m_last_state_label_key.clear();
			m_last_state_label_value = NULL;
		}

		if( !m_last_widget_key.empty() && !m_last_widget_value.empty() )
		{
			current_widget().m_attribute_mappings[ m_last_widget_key ] = m_last_widget_value;
			m_last_widget_key.clear();
			m_last_widget_value.clear();
		}
	}


	void CInterfaceDefinitionLoader::push_element_name( const string &element )
	{
		if( !m_element_path.empty() )
		{
			m_element_path += '.';
		}

		m_element_path += element;
	}


	void CInterfaceDefinitionLoader::pop_element_name()
	{
		size_t last_dot = m_element_path.find_last_of( '.' );
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

		return current_endpoint().m_control_info->m_state_info->m_type;
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
			const IEndpointDefinition &endpoint_definition = **i;

			if( endpoint_definition.get_name().empty() )	
			{
				return CError::INPUT_ERROR;
			}

			switch( endpoint_definition.get_type() )
			{
				case CEndpointDefinition::CONTROL:	
					{
						const IControlInfo *control_info = endpoint_definition.get_control_info();

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
			const IWidgetDefinition &widget_definition = **i;
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
		if( input == "false" )
		{
			output = false;
			return CError::SUCCESS;
		}

		if( input == "true" )
		{
			output = true;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid boolean: " << input;
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
		if( input == "control" )
		{
			output = CEndpointDefinition::CONTROL;
			return CError::SUCCESS;
		}

		if( input == "stream" )
		{
			output = CEndpointDefinition::STREAM;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid endpoint type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CControlInfo::control_type &output )
	{
		if( input == "state" )
		{
			output = CControlInfo::STATEFUL;
			return CError::SUCCESS;
		}

		if( input == "bang" )
		{
			output = CControlInfo::BANG;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid control type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CValue::type &output )
	{
		if( input == "float" )
		{
			output = CValue::FLOAT;
			return CError::SUCCESS;
		}

		if( input == "integer" )
		{
			output = CValue::INTEGER;
			return CError::SUCCESS;
		}

		if( input == "string" )
		{
			output = CValue::STRING;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid value type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CValueScale::scale_type &output )
	{
		if( input == "linear" )
		{
			output = CValueScale::LINEAR;
			return CError::SUCCESS;
		}

		if( input == "exponential" )
		{
			output = CValueScale::EXPONENTIAL;
			return CError::SUCCESS;
		}

		if( input == "decibel" )
		{
			output = CValueScale::DECIBEL;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid scale type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CStreamInfo::stream_type &output )
	{
		if( input == "audio" )
		{
			output = CStreamInfo::AUDIO;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid stream type: " << input;
		return CError::INPUT_ERROR;	
	}


	CError CInterfaceDefinitionLoader::converter( const string &input, CStreamInfo::stream_direction &output )
	{
		if( input == "input" )
		{
			output = CStreamInfo::INPUT;
			return CError::SUCCESS;
		}

		if( input == "output" )
		{
			output = CStreamInfo::OUTPUT;
			return CError::SUCCESS;
		}

		INTEGRA_TRACE_ERROR << "invalid stream direction: " << input;
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


	CEndpointDefinition &CInterfaceDefinitionLoader::current_endpoint()
	{
		assert( !m_interface_definition->m_endpoint_definitions.empty() );

		return CEndpointDefinition::downcast_writable( *m_interface_definition->m_endpoint_definitions.back() );
	}


	CWidgetDefinition &CInterfaceDefinitionLoader::current_widget()
	{
		assert( !m_interface_definition->m_widget_definitions.empty() );

		return CWidgetDefinition::downcast_writable( *m_interface_definition->m_widget_definitions.back() );
	}

}
