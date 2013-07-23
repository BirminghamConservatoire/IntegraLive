/* libIntegra multimedia module info interface
 *
 * Copyright (C) 2007 Jamie Bullock, Henrik Frisk
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

#ifndef INTEGRA_H
#define INTEGRA_H


/** \file integra.h libIntegra public API */

/* system includes*/
#include <stdbool.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#include <unordered_map>

#include "../src/error.h"
#include "../src/common_typedefs.h"
#include "../src/path.h"


/* Maximum audio inputs or outputs per module */
#define NTG_AUDIO_PORTS_MAX 16


namespace ntg_api
{
	class CPath;
	class CValue;
}


/*
 * class instance (node) API
 */

/* value types */

typedef unsigned long ntg_id;


/*
 * server API
 */
typedef struct ntg_command_queue_  ntg_command_queue;

/** \brief Definition of the type ntg_command_status @see
 * Integra/integra_Server.h */
typedef struct ntg_command_status_ {
    void *data; /* arbitrary data passed back to the caller */
    ntg_error_code error_code;
} ntg_command_status;


/** \brief Callback function that gets passed to the module host when the 
  * server is started.
  *
  * This function is the mechanism by which data is passed *back* from
  * the module host to the bridge, and then on to the server. It
  * enables messages to be passed 'natively' to the server,
  * without involving OSC.
  *
 */
typedef void (*ntg_bridge_callback)(int argc, void *argv);


/** \brief Get the list of available interfaces from the server
  * \return a reference to a guid_set 
  * \error a pointer to NULL is returned if an error occurs 
  *
  */
LIBINTEGRA_API const ntg_api::guid_set &ntg_interfacelist(void);




/** \brief Create a new node on the server
 *
 * \param *class_name: a string representing the name of the class to be
 * instantiated
 * \param *node_name: the name of the node. Node names must be
 * unique within containing scope. If an aready exisiting node name is
 * provided, then an error code will be returned. If NULL is provided, a
 * unique node name will be generated and returned
 * \param *path: the path for the containing scope. this identifies the
 * node names of the containers enclosing our new
 * node. e.g. ['Project1', 'Block1']
 * \return a pointer to the new node 
 * \error a pointer to NULL is returned if an error occurs */
LIBINTEGRA_API ntg_command_status ntg_new(const GUID *module_id, ntg_api::string node_name, const ntg_api::CPath &path);

/** \brief Delete a node on the server
 * \param *path: a reference to a class of type ntg_api::CPath giving the elements in
   the path to the given node. The path array must include the node 
   itself, i.e. if we are deleting a node called 'FooBar1', the path array
   might be ['Project1', 'Block1', 'FooBar1']
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h 
 * */
LIBINTEGRA_API ntg_command_status ntg_delete(const ntg_api::CPath &path);

/** \brief Rename a node on the server
 * \param *path: a reference to a class of type ntg_api::CPath giving the elements in
 the path to the given node. The path array must include the node
 itself, i.e. if we are renaming a node called 'FooBar1', the path array
 might be ['Project1', 'Block1', 'FooBar1']
 * \param *name: a pointer to a string representing the new name of the
 * node
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_rename( const ntg_api::CPath &path, const char *name);

/** \brief Save all nodes including and below a given node on the server to a
    path on the filesystem
 * \param *server: a pointer to a struct of type ntg_server
 * \param *path: a reference to a class of type CPath giving the elements in
   the path to the given node. The path array must include the node
   itself, i.e. if we are saving a node called 'FooBar1', the path array
   might be ['Project1', 'Block1', 'FooBar1']
 * \param *file_path: a pointer to a string representing the path to the file
   on the filesystem
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_save( const ntg_api::CPath &, const char *file_path );

/** \brief Load all nodes including and below a given node from the filesystem
 beneath the path given to the given node on the server
 * \param *file_path: a pointer to a string representing the path to the file
 * on the filesystem
 * \param *path: a reference to a class of type CPath giving the elements in
 the path to the parent node under which the new node will be
 loaded. i.e. if we are loading a node inside Project1 the path would be
 ['Project1']. A NULL value indicates that the new node will be loaded
 under the server root node
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR, and ntg_command_status.data 
 * will contain a guid_set  of all embedded modules ids that were loaded.  This 
 * guid_set is allocated on the heap, and the caller should delete it 
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_load(const char *file_path, const ntg_api::CPath &path);

/** \brief Move a node of a class on the server
 * \param *node_path: a reference to a class of type CPath giving the
 elements in the path to the given node. The path array must include the
 node itself, i.e. if we are deleting a node called 'FooBar1', the
 path array might be ['Project1', 'Block1', 'FooBar1']
 * \param *parent_path: a pointer to the new parent path. the source node
 and all children will be moved underneath the parent node
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_move( const ntg_api::CPath &node_path, const ntg_api::CPath &parent_path);

/** \brief Set the value of an attribute of a node on the server
 * \param *path: a reference to a class of type CPath giving the elements in
 the path to the given attribute. The path array must include the attribute
 itself, i.e. if we are setting the value of an attribute called 'blah' in an
 node called 'FooBar1', the path array might be ['Project1', 'Block1',
 'FooBar1', 'blah']. If the path is invalid, or the final element doesn't
 correspond to an attribute an error code of NTG_PATH_ERROR will be returned
 * \param *value: a pointer to a class of type CValue containing the value
 * we are setting the attribute to.
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 */
LIBINTEGRA_API ntg_command_status ntg_set(const ntg_api::CPath &attribute_path, const ntg_api::CValue *value );

/** \brief Get the value of an attribute of a node on the server
 * \param *path: a reference to a class of type CPath giving the elements in
 the path to the given attribute. The path array must include the attribute
 itself, i.e. if we are getting the value of an attribute called 'blah' in an
 node called 'FooBar1', the path array might be ['Project1', 'Block1',
 'FooBar1', 'blah']. If the path is invalid, or the final element doesn't
 correspond to an attribute an error code of NTG_PATH_ERROR will be returned
 * \return a pointer to a class of type CValue.  The CValue must be deleted by 
 the caller
 * \error a pointer to NULL is returned if an error occurs */
LIBINTEGRA_API ntg_api::CValue *ntg_get( const ntg_api::CPath &path );

/** \brief Get the list of paths to nodes on the server under a given node
 * \param *path: a reference to a class of type CPath giving the elements in
 the path to the given parent. The path gives the root of the nodelist, so if
 we want ALL nodes on the server, an empty path should be given. For all nodes
 under the container: Project1, the path array should be ['Project1']
 * \return a pointer to a path_list, which gives all of the
 * paths under a given node as n_nodes CPath arrays. The returned pointer
 * must be deleted when done.
 * \error a pointer to NULL is returned if an error occurs
 *
 * */
LIBINTEGRA_API ntg_error_code ntg_nodelist( const ntg_api::CPath &path, ntg_api::path_list &results );


/** \brief Unloads embedded modules that are not in use
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h *
 */
LIBINTEGRA_API ntg_command_status ntg_unload_orphaned_embedded_modules(void);

/** \brief install a 3rd party integra module from disk
 * \param *file_path: path to the integra-module file to install
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR, and the data member will point to 
 * a struct of type ntg_module_install_result.  This struct contains the members 
 * module_id (id of the newly installed module), and bool was_previously_embedded
 * (informs the caller as to whether the installed module was already in memory 
 * as an embedded module).  Note: it is the caller's responsibility to free the
 * ntg_module_install_result using ntg_free.
 * \error possible return values for error status are given in integra_error.h *
 * */
LIBINTEGRA_API ntg_command_status ntg_install_module( const char *file_path );

/** \brief install a 3rd party integra module which is already loaded into memory as an
 * embedded module
 * \param *module_id: id of the embedded module to install
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR.
 * \error possible return values for error status are given in integra_error.h *
 * */

LIBINTEGRA_API ntg_command_status ntg_install_embedded_module( const GUID *module_id );

/** \brief uninstall a 3rd party module
 * \param *module_id: id of the 3rd party module to uninstall
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR, and the data member will point to 
 * a struct of type ntg_module_uninstall_result.  This struct contains the bool
 * remains_as_embedded.  This value informs the caller as to whether the uninstalled 
 * is still loaded into memory as an embedded module, due to being currently in use.
 * Note: it is the caller's responsibility to free the ntg_module_uninstall_result 
 * using ntg_free
 * \error possible return values for error status are given in integra_error.h *
 * */

LIBINTEGRA_API ntg_command_status ntg_uninstall_module( const GUID *module_id );

/** \brief load a 3rd party integra module from disk, as a 'module in development'
 * \param *file_path: path to the integra-module file to load
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR, and the data member will point to 
 * a struct of type ntg_module_in_development_install_result.  This struct contains the member
 * module_id (id of the loaded module).  Note: it is the caller's responsibility to free the
 * ntg_module_in_development_install_result using ntg_free.
 * \error possible return values for error status are given in integra_error.h *
 * */
LIBINTEGRA_API ntg_command_status ntg_load_module_in_development( const char *file_path );



/** \brief Print out info about the state of the server to stdout.
 */
LIBINTEGRA_API void ntg_print_state(void);


/** \brief Create a new Integra server 
 *
 * \param bridge_file the filename of the bridge being loaded
 * \param system_module_directory location of system-installed integra module files 
 * \param third_party_module_directory location of 3rd party integra module files
 * \param xmlrpc_server_port port on which the xmlrpc interface 
 * listens for connections
 * \param osc_server_port port on which the osc interface 
 * listens for connections
 * \param osc_client_url url to which libIntegra sends osc feedback
 * about executed commands, if NULL is passed localhost will be selected
 * \param osc_client_port port on which libIntegra sends osc feedback
 * about executed commands
 * \return NTG_NO_ERROR, NTG_FAILED or NTG_ERROR
 *
 * \note ntg_server_run() will not return until the server has been terminated by an OS signal 
 * or via the xmlrpc interface.
 *
 * */
LIBINTEGRA_API ntg_error_code ntg_server_run(const char *bridge_file, 
							const char *system_module_directory,
							const char *third_party_module_directory,
							unsigned short xmlrpc_server_port, 
							const char *osc_client_url, 
							unsigned short osc_client_port);



/** \brief Evaluate a string containing lua code
 *
 * The function returns immediately.
 * The server must be locked before calling.
 *
 * \param string A string containing lua code
 *  The string can contain several lines separated by lineshifts.
 *
 */
LIBINTEGRA_API char *ntg_lua_eval( const ntg_api::CPath &parent_path, const char *script_string );



/** \brief Get the current version of libIntegra 
 * \param *destination: a pointer to a string into which the 
 * version number is written
 * \param *destination_size: the maximum number of characters 
 * which may be written to destination
 */
LIBINTEGRA_API void ntg_version(char *destination, int destination_size);



#endif
