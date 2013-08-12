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

#include "interface_definition.h"
#include "trace.h"
#include "guid_helper.h"


namespace ntg_internal
{
	/************************************/
	/* INTERFACE DEFINITION             */
	/************************************/

	const string CInterfaceDefinition::core_tag = "core";


	CInterfaceDefinition::CInterfaceDefinition()
	{
		m_module_guid = CGuidHelper::null_guid;
		m_origin_guid = CGuidHelper::null_guid;
		m_interface_info = new CInterfaceInfo;
		m_implementation_info = NULL;
	}


	CInterfaceDefinition::~CInterfaceDefinition()
	{
		assert( m_interface_info );
		delete m_interface_info;
		
		for( endpoint_definition_list::iterator i = m_endpoint_definitions.begin(); i != m_endpoint_definitions.end(); i++ )
		{
			delete *i;
		}

		for( widget_definition_list::iterator i = m_widget_definitions.begin(); i != m_widget_definitions.end(); i++ )
		{
			delete *i;
		}

		if( m_implementation_info ) 
		{
			delete m_implementation_info;
		}
	}


	void CInterfaceDefinition::propagate_defaults()
	{
		assert( m_interface_info );
		m_interface_info->propagate_defaults();

		for( endpoint_definition_list::iterator i = m_endpoint_definitions.begin(); i != m_endpoint_definitions.end(); i++ )
		{
			( *i )->propagate_defaults();
		}
	}



	bool CInterfaceDefinition::is_core_interface() const
	{
		assert( m_interface_info );
		return ( m_interface_info->get_tags().count( core_tag ) > 0 );
	}


	bool CInterfaceDefinition::is_named_core_interface( const string &name ) const
	{
		if( is_core_interface() ) 
		{
			assert( m_interface_info );
			return( m_interface_info->get_name() == name );
		}
		else
		{
			return false;
		}

	}


	bool CInterfaceDefinition::has_implementation() const
	{
		if( m_implementation_info )
		{
			return !m_implementation_info->get_patch_name().empty();
		}

		return false;
	}


	bool CInterfaceDefinition::should_embed() const
	{
		assert( m_interface_info );
		return !m_interface_info->get_implemented_in_libintegra();
	}


	void CInterfaceDefinition::set_implementation_checksum( unsigned int checksum )
	{
		if( !m_implementation_info )
		{
			NTG_TRACE_ERROR << "Can't set checksum - no interface";
			return;
		}

		m_implementation_info->set_checksum( checksum );
	}


	/************************************/
	/* INTERFACE INFO                   */
	/************************************/

	CInterfaceInfo::CInterfaceInfo()
	{
		m_implemented_in_libintegra = false;
		memset( &m_created_date, 0, sizeof( struct tm ) );
		memset( &m_modified_date, 0, sizeof( struct tm ) );
	}


	CInterfaceInfo::~CInterfaceInfo()
	{
	}


	void CInterfaceInfo::propagate_defaults()
	{
		if( m_label.empty() )
		{
			m_label = m_name;
		}
	}


	/************************************/
	/* ENDPOINT DEFINITION	            */
	/************************************/

	CEndpointDefinition::CEndpointDefinition()
	{
		m_control_info = NULL;
		m_stream_info = NULL;
	}


	CEndpointDefinition::~CEndpointDefinition()
	{
		if( m_control_info ) 
		{
			delete m_control_info;
		}

		if( m_stream_info ) 
		{
			delete m_stream_info;
		}
	}



	bool CEndpointDefinition::should_send_to_host() const
	{
		if( m_type != CONTROL ) return false;

		return m_control_info->get_is_sent_to_host();
	}


	bool CEndpointDefinition::is_input_file() const
	{
		if( !m_control_info ) return false;
		if( !m_control_info->get_state_info() ) return false;

		return m_control_info->get_state_info()->get_is_input_file();
	}


	bool CEndpointDefinition::should_load_from_ixd( CValue::type loaded_type ) const
	{
		/* 
		Just because a value is in an ixd file, doesn't mean we want to load it.  
		The interface could've changed since ixd was written.
		*/

		if( m_type != CONTROL ) return false;
		if( m_control_info->get_type() != CControlInfo::STATEFUL ) return false;
		if( !m_control_info->get_state_info()->get_is_saved_to_file() ) return false;
		if( m_control_info->get_state_info()->get_type() != loaded_type ) return false;

		return true;
	}


	bool CEndpointDefinition::is_audio_stream() const
	{
		if( m_type != STREAM ) return false;

		return ( m_stream_info->get_type() == CStreamInfo::AUDIO );
	}


	void CEndpointDefinition::propagate_defaults()
	{
		if( m_label.empty() )
		{
			m_label = m_name;
		}
	}


	/************************************/
	/* CONTROL INFO                     */
	/************************************/


	CControlInfo::CControlInfo()
	{
		m_state_info = NULL;
		m_can_be_source = true;
		m_can_be_target = true;
		m_is_sent_to_host = true;
	}


	CControlInfo::~CControlInfo()
	{
		if( m_state_info )
		{
			delete m_state_info;
		}
	}


	/************************************/
	/* STATE INFO                       */
	/************************************/

	CStateInfo::CStateInfo()
	{
		m_constraint = new CConstraint;
		m_default_value = NULL;
		m_value_scale = NULL;
		m_is_saved_to_file = true;
		m_is_input_file = false;
	}


	CStateInfo::~CStateInfo()
	{
		assert( m_constraint );
		delete m_constraint;

		if( m_default_value )
		{
			delete m_default_value;
		}

		if( m_value_scale )
		{
			delete m_value_scale;
		}

		for( value_map::iterator i = m_state_labels.begin(); i != m_state_labels.end(); i++ )
		{
			delete i->second;
		}
	}


	/************************************/
	/* CONSTRAINT                       */
	/************************************/


	CConstraint::CConstraint()
	{
		m_value_range = NULL;
		m_allowed_states = NULL;
	}


	CConstraint::~CConstraint()
	{
		if( m_value_range )
		{
			delete m_value_range;
		}

		if( m_allowed_states )
		{
			for( value_set::iterator i = m_allowed_states->begin(); i != m_allowed_states->end(); i++ )
			{
				delete *i;
			}

			delete m_allowed_states;
		}
	}


	/************************************/
	/* VALUE RANGE                      */
	/************************************/


	CValueRange::CValueRange()
	{
		m_minimum = NULL;
		m_maximum = NULL;
	}


	CValueRange::~CValueRange()
	{
		if( m_minimum )
		{
			delete m_minimum;
		}

		if( m_maximum )
		{
			delete m_maximum;
		}
	}


	/************************************/
	/* VALUE SCALE                      */
	/************************************/

	CValueScale::CValueScale()
	{
		m_type = LINEAR;
		m_exponent_root = 1;
	}


	CValueScale::~CValueScale()
	{
	}


	/************************************/
	/* STREAM INFO                      */
	/************************************/

	CStreamInfo::CStreamInfo()
	{
		m_type = AUDIO;
		m_direction = INPUT;
	}
	
	
	CStreamInfo::~CStreamInfo()
	{
	}
	
	

	/************************************/
	/* WIDGET DEFINITION                */
	/************************************/
	
	CWidgetDefinition::CWidgetDefinition()
	{
		m_position = new CWidgetPosition;
	}


	CWidgetDefinition::~CWidgetDefinition()
	{
		assert( m_position );
		delete m_position;
	}


	/************************************/
	/* WIDGET POSITION                  */
	/************************************/


	CWidgetPosition::CWidgetPosition()
	{
		m_x = 0;
		m_y = 0;
		m_width = 0;
		m_height = 0;
	}


	CWidgetPosition::~CWidgetPosition()
	{
	}


	/************************************/
	/* IMPLEMENTATION INFO              */
	/************************************/
			
	CImplementationInfo::CImplementationInfo()
	{
	}


	CImplementationInfo::~CImplementationInfo()
	{
	}
}

