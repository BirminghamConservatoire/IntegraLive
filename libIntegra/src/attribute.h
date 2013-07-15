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

#ifndef INTEGRA_ATTRIBUTE_PRIVATE_H
#define INTEGRA_ATTRIBUTE_PRIVATE_H


#ifndef NTG_ENDPOINT_TYPEDEF
typedef struct ntg_endpoint_ ntg_endpoint;
#define NTG_ENDPOINT_TYPEDEF
#endif

#include "Integra/integra_bridge.h"
#include "path.h"


/** \brief Linked list node for (node) attributes */
struct ntg_node_attribute_ {

    struct ntg_node_ *node;
	const ntg_endpoint *endpoint;
    struct ntg_node_attribute_ *next;

    ntg_value *value;
    ntg_api::CPath path;
};

/** \brief Create a new attribute */
ntg_node_attribute *ntg_node_attribute_new(void);

/** \brief Free an attribute */
ntg_error_code ntg_node_attribute_free(ntg_node_attribute *node_attribute);

/** \brief Insert an attribute into a list of attributes.  Insertion position determined by endpoint index */
ntg_node_attribute *ntg_node_attribute_insert_in_list(ntg_node_attribute * attribute_list,
											const ntg_endpoint *endpoint,
											const ntg_api::CPath &path,
											const ntg_value *value );



/** \brief Set the value of an attribute  */
void ntg_node_attribute_set_value(ntg_node_attribute *node, const ntg_value *value);

/** \brief Get the value of an attribute  */
const ntg_value *ntg_node_attribute_get_value(
        const ntg_node_attribute *list_node);

bool ntg_node_attribute_test_constraint( const ntg_node_attribute *attribute, const ntg_value *value);


/** \brief Free an attribute list */
void ntg_node_attributes_free(ntg_node_attribute *list_node);


/** \brief Send attribute value to module host */
void ntg_node_attribute_send_value(const ntg_node_attribute *attribute, ntg_bridge_interface *bridge);


#endif
