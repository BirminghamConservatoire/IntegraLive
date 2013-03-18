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

#ifndef INTEGRA_SERVER_PRIVATE_H
#define INTEGRA_SERVER_PRIVATE_H

#define NTG_RETURN_COMMAND_STATUS command_status.error_code = error_code;return command_status;
#define NTG_RETURN_ERROR_CODE( ERROR_CODE ) command_status.error_code = ERROR_CODE;return command_status;
#define NTG_COMMAND_STATUS_INIT command_status.data = NULL, command_status.error_code = NTG_NO_ERROR;

#ifdef __cplusplus
extern "C" {
#endif

#include "Integra/integra_bridge.h"
#include "node.h"
#include "hashtable.h"
#include "path.h"
#include "command.h"

#define NTG_COMMAND_QUEUE_ELEMENTS 1024

#define NTG_HASHTABLE struct ntg_hash_node_ *

#ifndef ntg_system_class_data 
typedef struct ntg_system_class_data_ ntg_system_class_data;
#endif

#ifndef ntg_module_manager
//typedef struct ntg_module_manager_ ntg_module_manager;
#endif


/** \brief Definition of the type ntg_server. @see Integra/integra.h */
typedef struct ntg_server_ {
    ntg_node *root;
    ntg_bridge_interface *bridge;
    struct ntg_osc_client_ *osc_client;
    NTG_HASHTABLE *state_table; /* resolves path-as-string to node attribute */
    struct ntg_system_class_data_ *system_class_data;
    char *scratch_directory_root;
	struct ntg_module_manager_ *module_manager;
    bool terminate;
    bool loading;
} ntg_server;

void ntg_server_halt(ntg_server *server);

ntg_server *ntg_server_new(const char *osc_client_url, unsigned short osc_client_port, const char *interfaces_directories);
void ntg_server_free(ntg_server *server);

/** \brief Callback function corresponing to ih_callback in the bridge interface (see integra_bridge.h ntg_bridge_interface->ih_callback */
void receive_callback(ntg_id id, const char *attribute_name, const ntg_value *value);


/**
 * \brief Get the root of the node graph */
ntg_node *ntg_server_get_root(const ntg_server *server);

/** \brief Get the list of nodes under a container node as an array */
ntg_list *ntg_server_get_nodelist(const ntg_server *server, 
        ntg_node *container, ntg_path *parent_path, 
        ntg_list *nodelist);

/** \brief Update a connection 
    \param do_connect Toggles the connection 0 = disconnect 1 = connec
 */
ntg_error_code ntg_server_connect_in_host( ntg_server *server, const ntg_node_attribute *source, 
											const ntg_node_attribute *target, bool connect );

/** \brief Remove a node from the server
 *
 * \param *node a pointer to the node to removed
 * \param *container a pointer to the containing node
 *
 * */
ntg_error_code ntg_server_node_delete(ntg_server *server, ntg_node *node);

/** \brief Fix connections that point to node so that the point to 'name'
  */
ntg_error_code ntg_server_fix_connections(ntg_server *server, 
        ntg_node *node, const char *name);


/** \brief shortcut for making/removing connections 
 *  \param *parent_path, a pointer to the path of the parent we want to make the connection inside, e.g. ["Track1", "Block1"]
 *  \param *source_path_s a string representing the *relative* path to the source attribute in dot-separated notation, e.g. "TapDelay1.out1"
 *  \param *target_path_s a string representing the *relative* path to the target attribute in dot-separated notation, e.g. "AudioOut1.in1"
    \return a pointer to a struct of type ntg_node, containing the new Connection node 
    */
ntg_node *ntg_server_connect(ntg_server * server,
                                      const ntg_path * parent_path,
                                      const char * source_path_s,
                                      const char * target_path_s);



/** \brief return an ntg_node_attribute from a path relative to a base node */
const ntg_node_attribute *ntg_server_resolve_relative_path ( 
        const ntg_server *server,
		const ntg_node *root,
        const char *path);


/* this function is for receiving set messages back from the module host or
   the osc interface.  It is identical to ntg_set_() except that it avoids 
   the need to pass in an ntg_path * struct (we already have node/attribute) */

void ntg_server_receive_(ntg_server * server,
        ntg_command_source source,
        const ntg_node_attribute *node_attribute,
        const ntg_value * value);

void ntg_server_set_host_dsp(const ntg_server *server, bool status);

void print_node_state(ntg_server *server, ntg_node *first,int indentation);

bool ntg_saved_version_is_newer_than_current( const char *saved_version );

void ntg_lock_server(void);
void ntg_unlock_server(void);
void ntg_command_enqueue(ntg_command_id command_id, const int argc, ...);

#ifdef __cplusplus
}
#endif

#endif
