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

#include "platform_specifics.h"

#include "connection_logic.h"
#include "node.h"
#include "node_endpoint.h"
#include "interface_definition.h"
#include "api/trace.h"
#include "server.h"

#include <assert.h>

namespace integra_internal
{
	CConnectionLogic::CConnectionLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CConnectionLogic::~CConnectionLogic()
	{
	}

	
	void CConnectionLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();

		if( endpoint_name == endpoint_source_path )
		{
			source_path_handler( server, node_endpoint, previous_value, source );
			return;
		}

		if( endpoint_name == endpoint_target_path )
		{
			target_path_handler( server, node_endpoint, previous_value, source );
			return;
		}
	}


	void CConnectionLogic::handle_delete( CServer &server, CCommandSource source )
	{
		CLogic::handle_delete( server, source );

		/* remove in host if needed */ 
		const CNode &node = get_node();
		const CNode *connection_owner = CNode::downcast( node.get_parent() );

		const INodeEndpoint *source_path = node.get_node_endpoint( endpoint_source_path );
		const INodeEndpoint *target_path = node.get_node_endpoint( endpoint_target_path );
		assert( source_path && target_path );

		const INodeEndpoint *source_endpoint = server.find_node_endpoint( *source_path->get_value(), connection_owner );
		const INodeEndpoint *target_endpoint = server.find_node_endpoint( *target_path->get_value(), connection_owner );
	
		if( source_endpoint && source_endpoint->get_endpoint_definition().is_audio_stream() && source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
		{
			if( target_endpoint && target_endpoint->get_endpoint_definition().is_audio_stream() && target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
			{
				/* remove connection in host */
				connect_audio_in_host( server, *source_endpoint, *target_endpoint, false );
			}
		}
	}


	void CConnectionLogic::source_path_handler( CServer &server, const CNodeEndpoint &endpoint, const CValue *previous_value, CCommandSource source )
	{
		/* remove and/or add in host if needed */ 

		if( source == CCommandSource::SYSTEM )
		{
			/* the connection source changed due to the connected endpoint being moved or renamed - no need to do anything in the host */
			return;
		}

		const CNode &connection_node = *CNode::downcast( &endpoint.get_node() );
		const CNode *connection_owner = CNode::downcast( connection_node.get_parent() );

		const INodeEndpoint *source_path = connection_node.get_node_endpoint( endpoint_source_path );
		const INodeEndpoint *target_path = connection_node.get_node_endpoint( endpoint_target_path );
		assert( source_path && target_path );

		const INodeEndpoint *old_source_endpoint = server.find_node_endpoint( *previous_value, connection_owner );
		const INodeEndpoint *new_source_endpoint = server.find_node_endpoint( *source_path->get_value(), connection_owner );
		const INodeEndpoint *target_endpoint = server.find_node_endpoint( *target_path->get_value(), connection_owner );

		if( new_source_endpoint && new_source_endpoint->get_endpoint_definition().get_type() == CEndpointDefinition::CONTROL && !new_source_endpoint->get_endpoint_definition().get_control_info()->get_can_be_source() )
		{
			INTEGRA_TRACE_ERROR << "Setting connection source to an endpoint which should not be a connection source!";
		}

		if( !target_endpoint || !target_endpoint->get_endpoint_definition().is_audio_stream() )
		{
			/* early exit - wasn't an audio connection before and still isn't */
			return;
		}

		if( target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() != CStreamInfo::INPUT )
		{
			/* early exit - target isn't an input */
			return;
		}

		if( old_source_endpoint && old_source_endpoint->get_endpoint_definition().is_audio_stream() )
		{
			if( old_source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
			{
				/* remove previous connection in host */
				connect_audio_in_host( server, *old_source_endpoint, *target_endpoint, false );
			}
		}

		if( new_source_endpoint && new_source_endpoint->get_endpoint_definition().is_audio_stream() )
		{
			if( new_source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::OUTPUT )
			{
				/* create new connection in host */
				connect_audio_in_host( server, *new_source_endpoint, *target_endpoint, true );
			}
		}
	}


	void CConnectionLogic::target_path_handler( CServer &server, const CNodeEndpoint &endpoint, const CValue *previous_value, CCommandSource source )
	{
		/* remove and/or add in host if needed */ 

		if( source == CCommandSource::SYSTEM )
		{
			/* the connection target changed due to the connected endpoint being moved or renamed - no need to do anything in the host */
			return;
		}

		const CNode &connection_node = *CNode::downcast( &endpoint.get_node() );
		const CNode *connection_owner = CNode::downcast( connection_node.get_parent() );

		const INodeEndpoint *source_path = connection_node.get_node_endpoint( endpoint_source_path );
		const INodeEndpoint *target_path = connection_node.get_node_endpoint( endpoint_target_path );
		assert( source_path && target_path );

		const INodeEndpoint *source_endpoint = server.find_node_endpoint( *source_path->get_value(), connection_owner );
		const INodeEndpoint *old_target_endpoint = server.find_node_endpoint( *previous_value, connection_owner );
		const INodeEndpoint *new_target_endpoint = server.find_node_endpoint( *target_path->get_value(), connection_owner );

		if( new_target_endpoint && new_target_endpoint->get_endpoint_definition().get_type() == CEndpointDefinition::CONTROL && !new_target_endpoint->get_endpoint_definition().get_control_info()->get_can_be_target() )
		{
			INTEGRA_TRACE_ERROR << "Setting connection target to an endpoint which should not be a connection target!";
		}


		if( !source_endpoint || !source_endpoint->get_endpoint_definition().is_audio_stream() )
		{
			/* early exit - wasn't an audio connection before and still isn't */
			return;
		}

		if( source_endpoint->get_endpoint_definition().get_stream_info()->get_direction() != CStreamInfo::OUTPUT )
		{
			/* early exit - source isn't an output */
			return;
		}

		if( old_target_endpoint && old_target_endpoint->get_endpoint_definition().is_audio_stream() )
		{
			if( old_target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
			{
				/* remove previous connection in host */
				connect_audio_in_host( server, *source_endpoint, *old_target_endpoint, false );
			}
		}

		if( new_target_endpoint && new_target_endpoint->get_endpoint_definition().is_audio_stream() )
		{
			if( new_target_endpoint->get_endpoint_definition().get_stream_info()->get_direction() == CStreamInfo::INPUT )
			{
				/* create new connection in host */
				connect_audio_in_host( server, *source_endpoint, *new_target_endpoint, true );
			}
		}
	}
}