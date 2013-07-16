/** libIntegra multimedia module interface
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <assert.h>

#include <libxml/xmlreader.h>
#include <libxml/xmlwriter.h>

#include "memory.h"
#include "helper.h"
#include "value.h"
#include "path.h"
#include "globals.h"
#include "node.h"
#include "attribute.h"
#include "server.h"
#include "server_commands.h"
#include "module_manager.h"
#include "interface.h"

#define NTG_STR_INTEGRA_COLLECTION "IntegraCollection"
#define NTG_STR_INTEGRA_VERSION "integraVersion"
#define NTG_STR_OBJECT "object"
#define NTG_STR_ATTRIBUTE "attribute"
#define NTG_STR_MODULEID "moduleId"
#define NTG_STR_ORIGINID "originId"
#define NTG_STR_NAME "name"
#define NTG_STR_TYPECODE "typeCode"

//used in older versions
#define NTG_STR_INSTANCEID "instanceId"
#define NTG_STR_CLASSID "classId"

using namespace ntg_api;
using namespace ntg_internal;


ntg_node *ntg_node_new(void)
{
	ntg_node *node = NULL;

    node = new ntg_node;

	node->id                = ntg_id_new();
	node->interface			= NULL;
    node->name              = NULL;
    node->next              = node;
    node->prev              = node;
    node->parent            = NULL;
    node->nodes             = NULL;
    node->attributes        = NULL;
    node->attribute_last    = NULL;

    return node;

}


bool ntg_node_is_root(const ntg_node *node)
{
	assert( node );
	return (node->parent == NULL);
}


void ntg_node_unlink(ntg_node * node)
{

    ntg_node *next;
    ntg_node *prev;

    next = node->next;
    prev = node->prev;

    next->prev = prev;
    prev->next = next;
    node->next = NULL;
    node->prev = NULL;

}

ntg_error_code ntg_node_free(ntg_node * node)
{
    NTG_TRACE_VERBOSE_WITH_STRING("freeing node", node->name);

    ntg_node_unlink(node);
    ntg_node_attributes_free(node->attributes);
    delete[] node->name;
    delete node;

    return NTG_NO_ERROR;

}

unsigned long ntg_node_get_id(ntg_node * node)
{
    return node->id;
}

void ntg_node_set_interface(ntg_node * node, const ntg_interface *interface)
{
	assert( node && interface );

	node->interface = interface;
}

ntg_error_code ntg_node_add( ntg_node *container, ntg_node * node )
{

    if (container == NULL) {
        NTG_TRACE_ERROR("container was NULL");
        return NTG_ERROR;
    }

    if (node == NULL) {
        NTG_TRACE_ERROR("node was NULL");
        return NTG_ERROR;
    }

    if (container->nodes == NULL) {
        /* node list is empty, first node points to itself */
        node->next = node;
        node->prev = node;
        container->nodes = node;
    } else {
        /* append node to the list end */
        container->nodes->prev->next = node;
        node->prev = container->nodes->prev;
        container->nodes->prev = node;
        node->next = container->nodes;
    }

    node->parent = container;
    node->path = ntg_node_get_path(node);

    return NTG_NO_ERROR;

}


ntg_node *ntg_node_find_by_path( const CPath &path, ntg_node *root )
{
    int n;
    ntg_node *node;

	assert( root );

	if( path.get_number_of_elements() == 0) 
	{
        return root;
    }

    node = root;

	for( n = 0; n < path.get_number_of_elements(); n++ ) 
	{
        /* step down the node graph until we reach the end node */

        node = ntg_node_find_by_name( node, path[ n ].c_str() );

        if (node == NULL) {
			NTG_TRACE_ERROR_WITH_STRING( "node not found. Path", path.get_string().c_str() );
            return NULL;
        }
    }

    if (node == NULL) {
        NTG_TRACE_ERROR_WITH_STRING( "node not found. Path", path.get_string().c_str() );
        return NULL;
    }

    return (ntg_node *) node;

}


ntg_node_attribute *ntg_node_get_attribute_root(const ntg_node * node)
{

    if (node == NULL) {
        NTG_TRACE_ERROR("node was NULL");
        return NULL;
    }

    return node->attributes;

}


ntg_node_attribute *ntg_node_attribute_find_by_name(const ntg_node * node,
                                                    const char *name)
{
    ntg_node_attribute *current;

    /* All instances should have >=1 attributes. not valid to pass in root */
    assert(node->attributes);
    assert(name);

    current = node->attributes;

    do {

		if (!strcmp(current->endpoint->name, name)) {
            return current;
        }

        current = current->next;

    } while (current != node->attributes);

    return NULL;
}


void ntg_node_update_attribute_paths( ntg_node * node )
{
    ntg_node_attribute *current;
    ntg_node_attribute *marker;

    current = node->attributes;
    marker = current;

    /* make sure the node path is correct */

    do {
        current->path = node->path;
        current->path.append_element( current->endpoint->name );

        current = current->next;

    } while (current != marker);

}

void ntg_node_add_attribute(ntg_node *node, const ntg_endpoint *endpoint)
{
    ntg_node_attribute *attribute;

    attribute = ntg_node_attribute_new();

    attribute->node  = node;
	attribute->endpoint = endpoint;

	if( endpoint->type == NTG_CONTROL && endpoint->control_info->type == NTG_STATE )
	{
		attribute->value = ntg_value_new( endpoint->control_info->state_info->type, NULL );
	}

	attribute->path = node->path;
	attribute->path.append_element( endpoint->name );

    if( node->attributes ) 
	{
		assert( node->attribute_last );

		attribute->next = node->attributes;
		node->attribute_last->next = attribute;
		node->attribute_last = attribute;
	}
	else
	{
		assert( !node->attribute_last );

		attribute->next = attribute;
		node->attribute_last = attribute;
		node->attributes = attribute;
	}
}

void ntg_node_add_attributes(ntg_node *node, const ntg_endpoint *endpoint_list)
{
	const ntg_endpoint *endpoint;

	assert( node && endpoint_list );

	for( endpoint = endpoint_list; endpoint; endpoint = endpoint->next )
	{
        ntg_node_add_attribute(node, endpoint);
    }
}


static ntg_node *ntg_node_find_by_name_(const ntg_node * root,
                                        const char *name, bool recursive)
{

    ntg_node *current;
    ntg_node *first;
    ntg_node *next;
    ntg_node *found;

    if (name == NULL) {
        NTG_TRACE_ERROR("name is NULL");
        return NULL;
    }

    if (root == NULL) {
        NTG_TRACE_ERROR("root container is NULL");
        return NULL;
    }

    first = root->nodes;

    if (first == NULL) {
        return NULL;
    }

    current = first;
    assert(current != NULL);

    do {

        assert(current != NULL);
        next = current->next;

        if (!strcmp(current->name, name)) {
            return current;
        }

        if (recursive) {
            if (current->nodes != NULL) {
                found = ntg_node_find_by_name_(current, name, true);
                if (found!=NULL) {
                    return found;
                }
            }
        }

        current = next;

    } while (current != first);

    return NULL;

}

static ntg_node *ntg_node_find_by_id_(const ntg_node * root,
                               const ntg_id id, bool recursive)
{

    ntg_node *current;
    ntg_node *first;
    ntg_node *found;

    if (root == NULL) {
        NTG_TRACE_ERROR("root container is NULL");
        return NULL;
    }

    first = root->nodes;

    if (first == NULL) {
        return NULL;
    }

    current = first;

    do {

        if (current->id == id) {
            return current;
        }

        if (recursive) {
            if (current->nodes != NULL) {
                found = ntg_node_find_by_id_(current, id, true);
                if (found) {
                    return found;
                }
            }
        }

        current = current->next;

    } while (current != first);

    return NULL;

}


ntg_node *ntg_node_sibling_find_by_name( const ntg_node *node, const char *sibling_name )
{
	ntg_node *iterator;
	assert( node && sibling_name );

	for( iterator = node->next; iterator != node; iterator = iterator->next )
	{
		if( strcmp( iterator->name, sibling_name ) == 0 )
		{
			return iterator;
		}
	}

	return NULL;
}



ntg_node *ntg_node_find_by_name(const ntg_node * root, const char *name)
{
    return ntg_node_find_by_name_(root, name, false);
}


ntg_node *ntg_node_find_by_name_r(const ntg_node * root, const char *name)
{
    return ntg_node_find_by_name_(root, name, true);
}


ntg_node *ntg_node_find_by_id(const ntg_node * root, const ntg_id id)
{
    return ntg_node_find_by_id_(root, id, false);

}

ntg_node *ntg_node_find_by_id_r(const ntg_node * root, const ntg_id id)
{
    return ntg_node_find_by_id_(root, id, true);

}


void ntg_node_set_name( ntg_node * node, const char *name )
{
	assert( node && name );
	if( node->name )
	{
		delete[] node->name;
	}

	node->name = ntg_strdup( name );
}


CPath ntg_node_get_path( const ntg_node *node)
{
	CPath path;
	if( node->parent )
	{
		path = node->parent->path; 
	}

	path.append_element( node->name );

    return path;
}


CPath ntg_node_update_path(ntg_node * node)
{
    node->path = ntg_node_get_path(node);

    ntg_node_update_attribute_paths(node);

    return node->path;
}


ntg_error_code ntg_node_save_tree( const ntg_node * node, xmlTextWriterPtr writer)
{
    ntg_node_attribute *attribute_root;
    ntg_node_attribute *attribute;
    ntg_node *child_iterator;
    xmlChar *tmp;
	int valuestr_size;
    char *valuestr;
    ntg_value_type type;

    if (node == NULL) 
	{
        NTG_TRACE_ERROR("root container is NULL");
        return NTG_ERROR;
    }

    xmlTextWriterStartElement(writer, BAD_CAST NTG_STR_OBJECT);

    /* write out node->interface->module_guid */
	valuestr = ntg_guid_to_string( &node->interface->module_guid );
    tmp = ConvertInput(valuestr, XML_ENCODING);
	xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_MODULEID, (char * ) tmp );
	free( tmp );
	delete[] valuestr;

    /* write out node->interface->origin_guid */
	valuestr = ntg_guid_to_string( &node->interface->origin_guid );
    tmp = ConvertInput(valuestr, XML_ENCODING);
	xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_ORIGINID, (char * ) tmp );
	free( tmp );
	delete[] valuestr;

    /* write out node->name */
    tmp = ConvertInput(node->name, XML_ENCODING);
    xmlTextWriterWriteAttribute(writer, BAD_CAST NTG_STR_NAME, BAD_CAST tmp);
	free( tmp );

    /* get attribute root */
    attribute_root = ntg_node_get_attribute_root(node);
    attribute = attribute_root;

    /* write out attribute list */
    do 
	{
		if( !attribute->value || !attribute->endpoint->control_info->state_info->is_saved_to_file ) 
		{
			attribute = attribute->next;
			continue;
		}

        /* write attribute->name */
		type = ntg_value_get_type(attribute->value);

		tmp = ConvertInput(attribute->endpoint->name, XML_ENCODING);
        xmlTextWriterStartElement(writer, BAD_CAST NTG_STR_ATTRIBUTE);
        xmlTextWriterWriteAttribute(writer, BAD_CAST NTG_STR_NAME,
                                    BAD_CAST tmp);
		free( tmp );

        /* write type */
        xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_TYPECODE, "%d", type);

        /* write attribute->value */
        if (type == NTG_STRING) 
		{
			valuestr_size = ( strlen(attribute->value->ctype.s) + 1 );
        } 
		else 
		{
            /* allocate enough memory for a very long number */
			valuestr_size = 1024;
        }

		valuestr = new char[ valuestr_size ]; 
        ntg_value_sprintf( valuestr, valuestr_size, attribute->value );
        tmp = ConvertInput( valuestr, XML_ENCODING );
        delete[] valuestr ;
        xmlTextWriterWriteString( writer, BAD_CAST tmp );
        xmlTextWriterEndElement( writer );
		free( tmp );

        attribute = attribute->next;

    } while (attribute != attribute_root);

    /* traverse children */
    child_iterator = node->nodes;

	if( child_iterator )
	{
		do 
		{
			ntg_node_save_tree(child_iterator, writer);
			child_iterator = child_iterator->next;

		} 
		while (child_iterator != node->nodes);
	}

    xmlTextWriterEndElement(writer);
    return NTG_NO_ERROR;
}


ntg_error_code ntg_node_save( const ntg_node *node, unsigned char **buffer, unsigned int *buffer_length )
{
    xmlTextWriterPtr writer;
	xmlBufferPtr write_buffer;
	char version_string[ NTG_LONG_STRLEN ];
    int rc;

	assert( node && buffer && buffer_length );

	xmlInitParser();

	xmlSetBufferAllocationScheme( XML_BUFFER_ALLOC_DOUBLEIT );
	write_buffer = xmlBufferCreate();
    if( !write_buffer ) 
	{
		NTG_TRACE_ERROR( "error creating xml write buffer" );
        return NTG_FAILED;
    }

    writer = xmlNewTextWriterMemory( write_buffer, 0 );

    if( writer == NULL ) 
	{
        NTG_TRACE_ERROR("Error creating the xml writer");
        return NTG_FAILED;
    }

    xmlTextWriterSetIndent( writer, true );
    rc = xmlTextWriterStartDocument( writer, NULL, XML_ENCODING, NULL );
    if (rc < 0) 
	{
        NTG_TRACE_ERROR("Error at xmlTextWriterStartDocument");
        return NTG_FAILED;
    }

    /* write header */
    xmlTextWriterStartElement(writer, BAD_CAST NTG_STR_INTEGRA_COLLECTION );
    xmlTextWriterWriteAttribute(writer, BAD_CAST "xmlns:xsi", BAD_CAST "http://www.w3.org/2001/XMLSchema-node");

	ntg_version( version_string, NTG_LONG_STRLEN );
	xmlTextWriterWriteFormatAttribute(writer, BAD_CAST NTG_STR_INTEGRA_VERSION, "%s", version_string );

    if( ntg_node_save_tree( node, writer ) != NTG_NO_ERROR )
	{
		NTG_TRACE_ERROR( "Failed to save node" );
        return NTG_FAILED;
	}

    /* we don't strictly need this as xmlTextWriterEndDocument() tidies up */
    xmlTextWriterEndElement(writer);
    rc = xmlTextWriterEndDocument(writer);

    if (rc < 0) 
	{
        NTG_TRACE_ERROR("Error at xmlTextWriterEndDocument");
        return NTG_FAILED;
    }
    xmlFreeTextWriter(writer);

	*buffer = new unsigned char[ write_buffer->use ];
	memcpy( *buffer, write_buffer->content, write_buffer->use );
	*buffer_length = write_buffer->use;
	xmlBufferFree( write_buffer );

    return NTG_NO_ERROR;
}


const ntg_interface *ntg_node_find_interface( xmlTextReaderPtr reader )
{
	/*
	 this method needs to deal with various permutations, due to the need to load modules by module id, origin id, and 
	 various old versions of integra files.

	 it's logic is as follows:

	 if element has a NTG_STR_MODULEID attribute, interpret this as the interface's module guid
	 
	 if element has a NTG_STR_ORIGINID attribute, interpret this as the interface's origin guid
	 else if element has a NTG_STR_INSTANCEID attribute, interpret this as the interface's origin guid
	 else if element has a NTG_STR_CLASSID attribute, interpret this attribute as a legacy numerical class id, from which 
										we can lookup the module's origin id using the ntg_interpret_legacy_module_id

	 if we have a module guid, and can find a matching module, use this module

	 else
		lookup the module using the origin guid
	*/

	GUID module_guid;
	GUID origin_guid;
	char *valuestr = NULL;
	const ntg_interface *interface = NULL;
	const ntg_module_manager *module_manager = server_->module_manager;

	assert( reader && module_manager );

	ntg_guid_set_null( &module_guid );
	ntg_guid_set_null( &origin_guid );

	valuestr = (char *)xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_MODULEID );
	if( valuestr )
	{
		ntg_string_to_guid( valuestr, &module_guid );
        xmlFree( valuestr );
	}

	valuestr = (char *)xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_ORIGINID );
	if( valuestr )
	{
		ntg_string_to_guid( valuestr, &origin_guid );
        xmlFree( valuestr );
	}
	else
	{
		valuestr = (char *)xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_INSTANCEID );
		if( valuestr )
		{
			ntg_string_to_guid( valuestr, &origin_guid );
			xmlFree( valuestr );
		}
		else
		{
		    valuestr = (char *) xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_CLASSID );
			if( valuestr )
			{
				if( ntg_interpret_legacy_module_id( module_manager, atoi( valuestr ), &origin_guid ) != NTG_NO_ERROR )
				{
					NTG_TRACE_ERROR_WITH_STRING( "Failed to interpret legacy class id", valuestr );
				}

				xmlFree( valuestr );
			}
		}
	}

	if( !ntg_guid_is_null( &module_guid ) )
	{
		interface = ntg_get_interface_by_module_id( module_manager, &module_guid );
		if( interface )
		{
			return interface;
		}
	}

	if( !ntg_guid_is_null( &origin_guid ) )
	{
		interface = ntg_get_interface_by_origin_id( module_manager, &origin_guid );
		return interface;
	}

	return NULL;
}


ntg_error_code ntg_node_load( const ntg_node * node, xmlTextReaderPtr reader, node_list &loaded_nodes )
{
    const ntg_node     *parent;
    ntg_value          *attribute_value;
    ntg_node_attribute *store;
    ntg_node_attribute *marker;
	const ntg_node_attribute *existing_attribute;
    xmlNodePtr          xml_node;
    xmlChar             *name;
    const xmlChar       *element;
    xmlChar             *value = NULL;
    unsigned int        attribute_type;
    unsigned int        depth;
    unsigned int        type;
    unsigned int        prev_depth;
    int                 value_i;
    int                 rv;
    float               value_f;
    char               *valuestr;
	const ntg_interface *interface;
	char				*saved_version;
	bool				saved_version_is_more_recent;

    attribute_value = NULL;
    store           = NULL;
    marker          = NULL;
    prev_depth      = 0;
    rv              = xmlTextReaderRead(reader);

    if (!rv) 
	{
        return NTG_ERROR;
    }

    NTG_TRACE_VERBOSE("loading... ");
    while (rv == 1) 
	{
        element = xmlTextReaderConstName(reader);
        depth = xmlTextReaderDepth(reader);
        type = xmlTextReaderNodeType(reader);

        if (!node) 
		{
            return NTG_ERROR;
        }

		if( strncmp( (char *) element, NTG_STR_INTEGRA_COLLECTION, strlen( NTG_STR_INTEGRA_COLLECTION ) ) == 0 )
		{
			saved_version = ( char * ) xmlTextReaderGetAttribute( reader, BAD_CAST NTG_STR_INTEGRA_VERSION );
			if( saved_version )
			{
				saved_version_is_more_recent = ntg_saved_version_is_newer_than_current( saved_version );
				xmlFree( saved_version );
				if( saved_version_is_more_recent )
				{
					return NTG_FILE_MORE_RECENT_ERROR;
				}
			}
		}

        if (!strncmp((char *)element, NTG_STR_OBJECT, strlen(NTG_STR_OBJECT))) 
		{
            if (depth > prev_depth) {
                /* step down the node graph */
                parent = node;
            } else if (depth < prev_depth) {
                /* step back up the node graph */
                node = node->parent;
                parent = node->parent;
            } else {
                /* nesting level hasn't changed since last object */
                parent = node->parent;
            }

            if (type == XML_READER_TYPE_ELEMENT) 
			{
				interface = ntg_node_find_interface( reader );
				if( interface )
				{
					name = xmlTextReaderGetAttribute(reader, BAD_CAST NTG_STR_NAME);

					/* add the new node */
					node = (ntg_node *)
						ntg_new_(server_, NTG_SOURCE_LOAD, &interface->module_guid, (char * ) name, parent->path).data;

					xmlFree(name);

					loaded_nodes.push_back( node );
				}
				else
				{
					NTG_TRACE_ERROR( "Can't find interface - skipping element" );
				}
            }

            prev_depth = depth;
        }

        if (!strncmp((char *)element, NTG_STR_ATTRIBUTE,
                     strlen(NTG_STR_ATTRIBUTE))) {

            if (type == XML_READER_TYPE_ELEMENT) {
                xml_node = xmlTextReaderExpand(reader);
                value = xmlNodeGetContent(xml_node);
                name = xmlTextReaderGetAttribute(reader,
                                                 BAD_CAST NTG_STR_NAME);
                valuestr = (char *)xmlTextReaderGetAttribute(reader,
                                                             BAD_CAST
                                                             NTG_STR_TYPECODE);
                attribute_type = atoi(valuestr);
                xmlFree( valuestr );

                switch (attribute_type) {
                    case NTG_FLOAT:
                        if (!value) {
                            value_f = 0.f;
                        } else {
                            value_f = strtof((char *)value, NULL);
                        }
                        attribute_value = ntg_value_new(NTG_FLOAT, &value_f);
                        break;
                    case NTG_STRING:
                        attribute_value = ntg_value_new(NTG_STRING,
                                (char *)value);
                        break;
                    case NTG_INTEGER:
                        if (!value) {
                            value_i = 0;
                        } else {
                            value_i = strtol((char *)value, NULL, 10);
                        }
                        attribute_value = ntg_value_new(NTG_INTEGER, &value_i);
                        break;
                }

                if (value != NULL) 
				{
                    xmlFree(value);
                    value = NULL;
                }

				existing_attribute = ntg_find_attribute( node, ( char * ) name );
				if( existing_attribute && ntg_endpoint_should_load_from_ixd( existing_attribute->endpoint, attribute_value->type ) )
				{
					/* 
					only store attribute if it exists and is of reasonable type 
					(could've been removed or changed from interface since ixd was written) 
					*/

					CPath attribute_path( node->path );
					attribute_path.append_element( (char *)name );
					store = ntg_node_attribute_insert_in_list( store, existing_attribute->endpoint, attribute_path, attribute_value );
				}

                ntg_value_free(attribute_value);
                xmlFree(name);
            }
        }

        rv = xmlTextReaderRead(reader);
    }

	NTG_TRACE_VERBOSE("done!");

    NTG_TRACE_VERBOSE("Setting values...");
    while(store != NULL) 
	{
		ntg_set_( server_, NTG_SOURCE_LOAD, store->path, store->value );
        marker = store;
        store = store->next;
        ntg_node_attribute_free(marker);
    }

    NTG_TRACE_VERBOSE("done!");

    return NTG_NO_ERROR;
}


ntg_error_code ntg_node_send_loaded_attributes_to_host( const ntg_node *node, ntg_bridge_interface *bridge )
{
	ntg_node_attribute *attribute;

	assert( node );

	if( ntg_interface_has_implementation( node->interface ) )
	{
		attribute = node->attributes;
		if( attribute )
		{
			do
			{
				if( ntg_endpoint_should_send_to_host( attribute->endpoint ) && attribute->endpoint->control_info->type == NTG_STATE )
				{
					ntg_node_attribute_send_value( attribute, bridge );
				}

				attribute = attribute->next;
			}
			while( attribute != node->attributes );
		}
	}

	return NTG_NO_ERROR;
}


void ntg_node_update_children(ntg_node *node)
{
    ntg_node *current;

    if(node->nodes){
        current = node->nodes;
        do {
            ntg_node_update_path(current);
            ntg_node_update_children(current);
            current = current->next;
        } while (current != node->nodes);
    }
}

void ntg_node_rename(ntg_node *node, const char *name)
{
    /* rename node */
    delete[] node->name;
    node->name = ntg_strdup(name);
    ntg_node_update_path(node);

    /* update child paths */
    ntg_node_update_children(node);
}


const ntg_node_attribute *ntg_find_attribute( const ntg_node *node, const char *attribute_name )
{
	ostringstream path;
	path << node->path.get_string() << "." << attribute_name;

	return ntg_find_attribute( path.str() );
}


const ntg_node_attribute *ntg_find_attribute( const string &attribute_path )
{
	map_string_to_attribute::const_iterator lookup = server_->state_table.find( attribute_path );
	if( lookup == server_->state_table.end() )
	{
		return NULL;
	}
	else
	{
		return lookup->second;
	}
}



const ntg_node *ntg_node_get_root(const ntg_node *node) {

    const ntg_node *root = node;

    while (root->parent != NULL) {
        root = root->parent;
    }

    return root;

}


void ntg_node_add_to_statetable( const ntg_node *node, map_string_to_attribute &statetable )
{
	const ntg_node_attribute *attribute;
	const ntg_node *child_node;

	/* add attributes to statetable */
	attribute = node->attributes;
	do
	{
		statetable[ attribute->path.get_string() ] = attribute;

		attribute = attribute->next;
	}
	while( attribute != node->attributes );

	/* recurse child nodes */
	child_node = node->nodes;
	if( child_node )
	{
		do
		{
			ntg_node_add_to_statetable( child_node, statetable );

			child_node = child_node->next;
		}
		while( child_node != node->nodes );
	}
}


void ntg_node_remove_from_statetable( const ntg_node *node, map_string_to_attribute &statetable )
{
	const ntg_node_attribute *attribute;
	const ntg_node *child_node;

	/* remove attributes from statetable */
	attribute = node->attributes;
	do
	{
		statetable.erase( attribute->path.get_string() );

		attribute = attribute->next;
	}
	while( attribute != node->attributes );

	/* recurse child nodes */

	child_node = node->nodes;
	if( child_node )
	{
		do
		{
			ntg_node_remove_from_statetable( child_node, statetable );

			child_node = child_node->next;
		}
		while( child_node != node->nodes );
	}
}


bool ntg_node_is_module_in_use( const ntg_node *node, const GUID *module_id )
{
	const ntg_node *child_node;

	assert( node && module_id );

	if( node->interface )
	{
		if( ntg_guids_are_equal( &node->interface->module_guid, module_id ) )
		{
			return true;
		}
	}

	/* recurse child nodes */
	child_node = node->nodes;
	if( child_node )
	{
		do
		{
			if( ntg_node_is_module_in_use( child_node, module_id ) )
			{
				return true;
			}

			child_node = child_node->next;
		}
		while( child_node != node->nodes );
	}

	return false;
}


void ntg_node_remove_in_use_module_ids_from_set( const ntg_node &node, guid_set &set )
{
	const ntg_node *child_node;

	if( node.interface )
	{
		set.erase( node.interface->module_guid );
	}

	/* recurse child nodes */
	child_node = node.nodes;
	if( child_node )
	{
		do
		{
			ntg_node_remove_in_use_module_ids_from_set( *child_node, set );

			child_node = child_node->next;
		}
		while( child_node != node.nodes );
	}
}
