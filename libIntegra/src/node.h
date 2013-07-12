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

#ifndef INTEGRA_INSTANCE_PRIVATE_H
#define INTEGRA_INSTANCE_PRIVATE_H


#include "attribute.h"

#include "MurmurHash2.h"
#include <string>
#include <sstream>
#include <unordered_map>
#include <unordered_set>

#ifndef __XML_XMLREADER_H__
#ifndef NTG_TEXTREADER_TYPEDEF
typedef struct _xmlTextReader xmlTextReader;
typedef xmlTextReader *xmlTextReaderPtr;
#define NTG_TEXTREADER_TYPEDEF
#endif 
#endif

#ifndef NTG_INTERFACE_TYPEDEF
typedef struct ntg_interface_ ntg_interface;
#define NTG_INTERFACE_TYPEDEF
#endif

#ifdef _WINDOWS
	#ifdef interface 
		#undef interface
	#endif
#endif



/** \struct ntg_node "integra_node.h"
 * \brief Linked list node for nodes 
 *
 * This struct is a generic container for all node types. 
 * The purpose of nodes hold attribute state data at runtme.
 * Instances are stored in a linked list. The ability to arbitrarily nest 
 * nodes is provided through the *nodes pointer, which serves as
 * a reference to //contained// nodes.
 *
 */
typedef struct ntg_node_ {

    /** \note {Collections share the same id allocation pool as other
     *  classes} Corresponds to the 'id' attribute of the
     *  '/Collection/object' element of the CollectionSchema.
     */
    ntg_id id;

    /** The interface definition of which this node is an instance
     */
    const ntg_interface *interface;

    /**  This is the node name, used to uniquely identify an
     * node in it's containing scope. Corresponds to the
     * '/Collection/object/name' element of the CollectionSchema.
     */
    char *name;

    /** This points to a node list node on the same nesting level. */
    struct ntg_node_ *next;

    /** Points back to the previous node. Used mainly in node deletion */
    struct ntg_node_ *prev;

    /** Points back to the containing node */
    struct ntg_node_ *parent;

    /** Contained nodes. This is a pointer to a node node that is 
     * conceptually 'inside' the current node. If *nodes is NULL, we
     * at an end node in the node graph */
    struct ntg_node_ *nodes; 

    /** Linked list of attributes. These actually hold the state data for
     * the node. The pointer *attributes always points to the root 
     * node of the list */
    /* FIX: maybe this should be an array, so we don't need to search 
     * the list for index match */
    ntg_node_attribute *attributes;

    /* Pointer to the last attribute in the list. Used as a marker for creating
     * the 'circular' link back to the root of the list */
    ntg_node_attribute *attribute_last;

    /** Pointer to the absolute path to the node */
    ntg_path *path;

} ntg_node;



/* 
 standard library container typedefs go here for now 

 TODO - move them somewhere better
*/

struct GuidHash {
  size_t operator()(const GUID& x) const { return MurmurHash2( &x, sizeof( GUID ), 53 ); }
};


typedef std::ostringstream ostringstream;
typedef std::string string;
typedef std::unordered_map<string, const ntg_node_attribute *> map_string_to_attribute;
typedef std::unordered_set<GUID, GuidHash> guid_set;
typedef std::unordered_map<GUID, ntg_interface *, GuidHash> map_guid_to_interface;
typedef std::unordered_map<string, ntg_interface *> map_string_to_interface;

typedef std::list<const ntg_node *> node_list;


/** \brief Allocate a new empty node, and return a pointer to it 
 *
 * \param const int type An integer indicating the node type to be created.
 * This corresponds to the type variable in the node struct, and must be 
 * taken from the ntg_entity_types enum in types.h
 * */
ntg_node *ntg_node_new(void);

/** \brief determines whether node is the root of the node tree
  *
  * Examines the node's properties to determine whether it is the root node
  */

bool ntg_node_is_root(const ntg_node *node);

/** \brief Find an instance by name inside the given container
  *
  * Traverses the node list given by container->nodes looking for the string
  * *node_name
  */

ntg_node *ntg_node_find_by_name(const ntg_node *container, const char *node_name);


/** \brief Find an instance by name amongst the node's siblings, excluding the node itself
  *
  * Traverses the node list given by node->parent->nodes looking for the string
  * *node_name
  */

ntg_node *ntg_node_sibling_find_by_name(const ntg_node *node, const char *sibling_name);


/** \brief Find an instance by name inside the given container
  *
  * Traverses the node list given by container->nodes looking for the string
  * *node_name
  *
  */
ntg_node *ntg_node_find_by_path(const ntg_path * path, ntg_node *root );

/** \brief recursive version of ntg_node_find_by_name()
  */
ntg_node *ntg_node_find_by_name_r(const ntg_node *root, 
        const char *name);

/** \brief Find an isntance by id inside the given container
  *
  * Traverses the node list given by container->nodes looking for the string
  * *node_id
  */
ntg_node *ntg_node_find_by_id(const ntg_node *container,
        const ntg_id node_id);

/** \brief recursive version of ntg_node_find_by_id()
  */
ntg_node *ntg_node_find_by_id_r(const ntg_node *root, 
        const ntg_id id);


/** \brief Remove a node from a linked list of nodes
 */
void ntg_node_unlink(ntg_node *node);

/** \brief Set the name of a node (assigned to function pointe in struct)
 *
 * \param ntg_node *node a pointer to an struct of type ntg_node
 * \param char *name A pointer to a NULL-terminated string representing the 
 * new name for a node
 */
void ntg_node_set_name(ntg_node *node, const char *name);

/** \brief Set the interface of a node */
void ntg_node_set_interface(ntg_node *node, const ntg_interface *interface);

/** \brief Get the ID of a node 
 *
 * \param ntg_node *node a pointer to an struct of type ntg_node
 */
unsigned long ntg_node_get_id(ntg_node *node);

/** \brief Add a node to a given collection
 *
 * \param ntg_node *collection A pointer to a collection node
 * \param ntg_node *node A pointer to a node node to be added to 
 * the collection node
 *
 * This function is responsible for safely adding a node (to a collection), 
 * and setting the collection's dirty flag.
 *
 */
ntg_error_code ntg_node_add(ntg_node *collection, ntg_node *node);

/** \brief Get the attribute root from a node */
ntg_node_attribute *ntg_node_get_attribute_root(
        const ntg_node *node);

/** \brief Find an attribute by name
 *
 * \param ntg_node *node A pointer to the node we want to get the attribute from
 * \param char *name The name of the given attribute
 *
 * */

/*FIX: 
ntg_find_attribute has same signature as ntg_node_attribute_find_by_name, 
and might be more efficient due to its use of a hash table.
we should try to test which is more efficient and deprecate the less efficient method!
*/

ntg_node_attribute *ntg_node_attribute_find_by_name(
        const ntg_node *node,
        const char *name);


/** \brief Add attributes to node */
void ntg_node_add_attributes(ntg_node *node, const ntg_endpoint *endpoint_list);

char *ntg_node_name_from_path(const ntg_node *node, const ntg_path *path);

/** \brief A check that 'node' and 'sibling' share the same parent
  */
bool ntg_node_is_sibling(const ntg_node *node, 
        const ntg_node *sibling);

/** \brief get the full path for a node
  * This function works out the path by traversing the node graph
  */
ntg_path *ntg_node_get_path(const ntg_node *node);

/** \brief update and get the full path for a node
  * As ntg_node_get_path() but additionally sets node->path
  */
ntg_path *ntg_node_update_path(ntg_node *node);


/** \brief free a node
  */
ntg_error_code ntg_node_free(ntg_node *node);


/** \brief save a node and all of its children */
ntg_error_code ntg_node_save( const ntg_node *node, unsigned char **buffer, unsigned int *buffer_length );

/** \brief load from XML under a given node */
ntg_error_code ntg_node_load( const ntg_node *node, xmlTextReaderPtr reader, node_list &loaded_nodes);

/** \brief send node's newly-loaded attributes to host */
ntg_error_code ntg_node_send_loaded_attributes_to_host( const ntg_node *node, ntg_bridge_interface *bridge ); 

/** \brief update all attribute paths */
void ntg_node_update_attribute_paths(ntg_node *node);


/** \brief rename a node */
void ntg_node_rename(ntg_node *node, const char *name);

/** \brief update vertices that connect to a node 
 *  \param bool nullify if this is true, then any vertices that connect
 *  to the node will be set to NULL. This is usually the case just before
 *  a node is deleted
 *
 * */

const ntg_node_attribute *ntg_find_attribute( const ntg_node *node, const char *attribute_name );

/** \brief recursively update paths for children */
void ntg_node_update_children(ntg_node *node);

/** \brief get root node from any node */
const ntg_node *ntg_node_get_root(const ntg_node *node);

void ntg_node_add_to_statetable( const ntg_node *node, map_string_to_attribute &statetable );
void ntg_node_remove_from_statetable( const ntg_node *node, map_string_to_attribute &statetable );


/** \brief test whether module is in use
 *  \param node node to search from
 *  \param module_id id of module to search for
 * */

bool ntg_node_is_module_in_use( const ntg_node *node, const GUID *module_id );


/** \brief recursively removes ids of modules that are still in use
 *  \param node node to search from
 *  \param hashtable a map of module id => NULL.  This map is updated by the method, 
 *  removing any module ids which are still in use
 *
 * */

void ntg_node_remove_in_use_module_ids_from_set( const ntg_node &node, guid_set &set );



#endif
