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

#include "control_point_logic.h"
#include "envelope_logic.h"
#include "api/trace.h"
#include "server.h"
#include "node.h"
#include "node_endpoint.h"
#include "interface_definition.h"


namespace integra_internal
{
	const string CControlPointLogic::endpoint_tick = "tick";
	const string CControlPointLogic::endpoint_value = "value";
	const string CControlPointLogic::endpoint_curvature = "curvature";


	CControlPointLogic::CControlPointLogic( const CNode &node )
		:	CLogic( node )
	{
	}


	CControlPointLogic::~CControlPointLogic()
	{
	}

	
	void CControlPointLogic::handle_new( CServer &server, CCommandSource source )
	{
		CLogic::handle_new( server, source );

		update_envelope( server, CNode::downcast( get_node().get_parent() ) );
	}


	void CControlPointLogic::handle_set( CServer &server, const CNodeEndpoint &node_endpoint, const CValue *previous_value, CCommandSource source )
	{
		CLogic::handle_set( server, node_endpoint, previous_value, source );

		const string &endpoint_name = node_endpoint.get_endpoint_definition().get_name();
	
		if( endpoint_name == endpoint_value || endpoint_name == endpoint_tick )
		{
			update_envelope( server, CNode::downcast( get_node().get_parent() ) );
			return;
		}	
	}


	void CControlPointLogic::handle_move( CServer &server, const CPath &previous_path, CCommandSource source )
	{
		CLogic::handle_move( server, previous_path, source );

		/* let's handle the obscure case of moving a control point from one envelope to another! */

		/* update the previous envelope */
		CPath old_parent_path( previous_path );
		old_parent_path.pop_element();
		update_envelope( server, CNode::downcast( server.find_node( old_parent_path ) ) );

		/* update the new envelope */
		update_envelope( server, CNode::downcast( get_node().get_parent() ) );
	}


	void CControlPointLogic::handle_delete( CServer &server, CCommandSource source )
	{
		CLogic::handle_delete( server, source );

		update_envelope( server, CNode::downcast( get_node().get_parent() ), true );
	}


	void CControlPointLogic::update_envelope( CServer &server, const CNode *envelope_node, bool is_deleting )
	{
		if( !envelope_node )
		{
			INTEGRA_TRACE_ERROR << "Control point has no parent node!";
			return;
		}

		CEnvelopeLogic *envelope_logic = dynamic_cast< CEnvelopeLogic * > ( &envelope_node->get_logic() );
		if( !envelope_logic )
		{
			INTEGRA_TRACE_ERROR << "Control point is not inside an envelope!";
			return;
		}

		envelope_logic->update_value( server, is_deleting ? &get_node() : NULL );
	}


	bool CControlPointLogic::can_be_child_of( const CNode *candidate_parent ) const
	{
		/*
		 control points can only be children of envelopes
		 */

		if( !candidate_parent )		
		{
			//can't be top-level
			return false;
		}

		if( dynamic_cast<CEnvelopeLogic *>( &candidate_parent->get_logic() ) )	
		{
			//can be inside envelope
			return true;
		}

		//can't be inside anything else
		return false;
	}

}
