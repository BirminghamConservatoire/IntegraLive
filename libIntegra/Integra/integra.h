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

#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WINDOWS
	#ifdef LIBINTEGRA_EXPORTS	
		#define LIBINTEGRA_API __declspec(dllexport)
	#else
		#define LIBINTEGRA_API __declspec(dllimport)
	#endif
#else
	#define LIBINTEGRA_API 
#endif

/** \file integra.h libIntegra public API */

/* system includes*/
#include <stdbool.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include "../externals/guiddef.h"

/* Maximum audio inputs or outputs per module */
#define NTG_AUDIO_PORTS_MAX 16

/*
 * Error handling
 */
typedef enum ntg_error_code_ {
    NTG_ERROR = -1,
    NTG_NO_ERROR = 0,
    NTG_FAILED = 1,
    NTG_MEMORY_ALLOCATION_ERROR = 2,
    NTG_MEMORY_FREE_ERROR = 3,
    NTG_TYPE_ERROR = 4,
    NTG_PATH_ERROR = 5,
	NTG_CONSTRAINT_ERROR = 6,
	NTG_REENTRANCE_ERROR = 7,
	NTG_FILE_VALIDATION_ERROR = 8,
	NTG_FILE_MORE_RECENT_ERROR = 9
} ntg_error_code;

/** \brief returns a textual description of a given error code */
LIBINTEGRA_API char *ntg_error_text(ntg_error_code error_code);

/*
 * Tracing System
 */

typedef enum ntg_trace_category_bits_ {
	/* no trace category bits */
	NO_TRACE_CATEGORY_BITS = 0,

	/* Something unexpected happened, indicating a likely bug */
	TRACE_ERROR_BITS = 1,
	/* nothing unexpected happened, just useful information */
	TRACE_PROGRESS_BITS = 2,
	/* nothing unexpected happened, useful information which is expected to occur in large quantities*/
	TRACE_VERBOSE_BITS = 4,

	/*all trace category bits */
	ALL_TRACE_CATEGORY_BITS = TRACE_ERROR_BITS | TRACE_PROGRESS_BITS | TRACE_VERBOSE_BITS
} ntg_trace_category_bits;


typedef enum ntg_trace_options_bits_ {
	/* no trace options bits */
	NO_TRACE_OPTIONS_BITS = 0,

	/* trace the system time at which the trace occurred*/
	TRACE_TIMESTAMP_BITS = 1,
	/* trace the filename, line number, and function in which the trace occurred*/
	TRACE_LOCATION_BITS = 2,
	/* trace the id of the thread in which the trace occurred*/
	TRACE_THREADSTAMP_BITS = 4,

	/*all trace option bits */
	ALL_TRACE_OPTION_BITS = TRACE_TIMESTAMP_BITS | TRACE_LOCATION_BITS | TRACE_THREADSTAMP_BITS
} ntg_trace_options_bits;


/*! \def TOSTRING(x)
 * Macro to convert an integer to a string at compile time
 */
#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#ifdef _WINDOWS
#define NTG_FUNCTION __FUNCTION__
#else 
#define NTG_FUNCTION TOSTRING(__FUNCTION__)
#endif /*_WINDOWS*/

#define NTG_LOCATION __FILE__ ": " TOSTRING(__LINE__) "(" NTG_FUNCTION ")"

/*these tracing functions should not be called directly - use the tracing macros below*/

LIBINTEGRA_API void ntg_trace(ntg_trace_category_bits trace_category, const char *location, const char *message);
LIBINTEGRA_API void ntg_trace_with_int(ntg_trace_category_bits trace_category, const char *location, const char *message, int int_value);
LIBINTEGRA_API void ntg_trace_with_float(ntg_trace_category_bits trace_category, const char *location, const char *message, float float_value);
LIBINTEGRA_API void ntg_trace_with_string(ntg_trace_category_bits trace_category, const char *location, const char *message, const char *string_value);

/*
 * use ntg_set_trace_options at during startup to specify what should be traced, and how it should be traced.  
 * NOTE! ntg_set_trace_options is not thread-safe!  It should only be called before ntg_server_run is called, and the trace macros should 
 * not be used until after ntg_set_trace_options has been called.
 */

LIBINTEGRA_API void ntg_set_trace_options(ntg_trace_category_bits categories_to_trace, ntg_trace_options_bits trace_options);

/*these are the set of tracing macros used to report erros or progress*/
#define NTG_TRACE_ERROR(message) ntg_trace(TRACE_ERROR_BITS, NTG_LOCATION, message);
#define NTG_TRACE_ERROR_WITH_INT(message, int_value) ntg_trace_with_int(TRACE_ERROR_BITS, NTG_LOCATION, message, int_value);
#define NTG_TRACE_ERROR_WITH_FLOAT(message, float_value) ntg_trace_with_string(TRACE_ERROR_BITS, NTG_LOCATION, message, float_value);
#define NTG_TRACE_ERROR_WITH_STRING(message, string_value) ntg_trace_with_string(TRACE_ERROR_BITS, NTG_LOCATION, message, string_value);
#define NTG_TRACE_ERROR_WITH_ERRNO(message) ntg_trace_with_string(TRACE_ERROR_BITS, NTG_LOCATION, message, strerror(errno) );

#define NTG_TRACE_PROGRESS(message) ntg_trace(TRACE_PROGRESS_BITS, NTG_LOCATION, message);
#define NTG_TRACE_PROGRESS_WITH_INT(message, int_value) ntg_trace_with_int(TRACE_PROGRESS_BITS, NTG_LOCATION, message, int_value);
#define NTG_TRACE_PROGRESS_WITH_FLOAT(message, float_value) ntg_trace_with_float(TRACE_PROGRESS_BITS, NTG_LOCATION, message, float_value);
#define NTG_TRACE_PROGRESS_WITH_STRING(message, string_value) ntg_trace_with_string(TRACE_PROGRESS_BITS, NTG_LOCATION, message, string_value);

#define NTG_TRACE_VERBOSE(message) ntg_trace(TRACE_VERBOSE_BITS, NTG_LOCATION, message);
#define NTG_TRACE_VERBOSE_WITH_INT(message, int_value) ntg_trace_with_int(TRACE_VERBOSE_BITS, NTG_LOCATION, message, int_value);
#define NTG_TRACE_VERBOSE_WITH_FLOAT(message, float_value) ntg_trace_with_float(TRACE_VERBOSE_BITS, NTG_LOCATION, message, float_value);
#define NTG_TRACE_VERBOSE_WITH_STRING(message, string_value) ntg_trace_with_string(TRACE_VERBOSE_BITS, NTG_LOCATION, message, string_value);



/*
 * class instance (node) API
 */

/* value types */
typedef enum ntg_value_type_ {
    NTG_INTEGER = 1,
    NTG_FLOAT,
    NTG_STRING,
    NTG_n_types
} ntg_value_type;

typedef unsigned long ntg_id;
typedef struct ntg_path_  ntg_path;
typedef struct ntg_value_ ntg_value;
typedef struct ntg_node_attribute_ ntg_node_attribute;

/** \brief create an ntg_path from a '.' delimited string */
LIBINTEGRA_API ntg_path *ntg_path_from_string(const char *path_string);

/** \brief create a '.' delimited string from a '.' delimited path */
LIBINTEGRA_API char *ntg_path_to_string(const ntg_path *path);

/* \brief pop an element from a path, returning that element as a string.
 * The returned string is a copy and must be freed with ntg_free() after usage. */
LIBINTEGRA_API char *ntg_path_pop_element(ntg_path *path);

/* paths */
/* \brief append an element to the end of a path. 
 * ntg_path *path is modified to hold the new path */
LIBINTEGRA_API ntg_path *ntg_path_append_element(ntg_path *path, const char *element);

/* Create a new path struct containing the contents of source */
LIBINTEGRA_API ntg_path *ntg_path_copy(const ntg_path *source);

/* Compare two paths returning true if they are the same */
LIBINTEGRA_API bool ntg_path_compare(const ntg_path *path1, const ntg_path *path2);

/* \brief Join two paths to create a new path */
LIBINTEGRA_API ntg_path *ntg_path_join(const ntg_path *start, const ntg_path *end);

/* \brief prints the contents of a path. Used for debugging */
LIBINTEGRA_API void ntg_print_path(const ntg_path *path);

/* \brief Check that a path is valid */
LIBINTEGRA_API ntg_error_code ntg_path_validate(const ntg_path *path);

LIBINTEGRA_API ntg_path *ntg_path_new(void);
LIBINTEGRA_API ntg_error_code ntg_path_free(ntg_path *path);

/** \brief Split a path at splitpoint
   \param *path a pointer to the path to be split
   \param splitpoint the splitpoint
   \return The splitted off elements
   This function modifies the passed in path, reducing it to splitpoint elements*/
LIBINTEGRA_API ntg_path *ntg_path_split(ntg_path *path, int splitpoint);

/* values */
LIBINTEGRA_API ntg_value_type ntg_value_get_type(const ntg_value *value);
LIBINTEGRA_API float ntg_value_get_float(const ntg_value *value);
LIBINTEGRA_API int ntg_value_get_int(const ntg_value *value);
LIBINTEGRA_API char *ntg_value_get_string(const ntg_value *value);


/** \brief Returns a pointer to a newly allocated value
  * \param void *v a pointer to the value initialiser
  * \param ... optional parameter of type size_t specifying byte array length for value of type NTG_BLOB */
LIBINTEGRA_API ntg_value *ntg_value_new(ntg_value_type type, const void *v, ...);

/** \brief Free ntg_value previously allocated with ntg_value_new() */
LIBINTEGRA_API ntg_error_code ntg_value_free(ntg_value *value) ;

/*
 * server API
 */
typedef struct ntg_list_ ntg_list;
typedef struct ntg_command_queue_  ntg_command_queue;

/** \brief Definition of the type ntg_command_status @see
 * Integra/integra_Server.h */
typedef struct ntg_command_status_ {
    void *data; /* arbitrary data passed back to the caller */
    ntg_error_code error_code;
} ntg_command_status;

/** \brief ntg_list memory management
 */
void ntg_list_free_as_nodelist(ntg_list *);
void ntg_list_free_as_attributes(ntg_list *);

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

LIBINTEGRA_API unsigned long ntg_list_get_n_elems(ntg_list *);

/** \brief Get the list of available interfaces from the server
  * \return a pointer to an ntg_list containing a list of guids
  * \error a pointer to NULL is returned if an error occurs 
  *
  */
LIBINTEGRA_API const ntg_list *ntg_interfacelist(void);


/** \brief Get the current version of libIntegra 
 * \param *destination: a pointer to a string into which the 
 * version number is written
 * \param *destination_size: the maximum number of characters 
 * which may be written to destination
 */
LIBINTEGRA_API void ntg_version(char *destination, int destination_size);


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
LIBINTEGRA_API ntg_command_status ntg_new(const GUID *module_id,
        const char *node_name, const ntg_path *path);

/** \brief Delete a node on the server
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
   the path to the given node. The path array must include the node 
   itself, i.e. if we are deleting a node called 'FooBar1', the path array
   might be ['Project1', 'Block1', 'FooBar1']
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h 
 * */
LIBINTEGRA_API ntg_command_status ntg_delete(const ntg_path *path);

/** \brief Rename a node on the server
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
 the path to the given node. The path array must include the node
 itself, i.e. if we are renaming a node called 'FooBar1', the path array
 might be ['Project1', 'Block1', 'FooBar1']
 * \param *name: a pointer to a string representing the new name of the
 * node
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_rename(const ntg_path *path,
        const char *name);

/** \brief Save all nodes including and below a given node on the server to a
    path on the filesystem
 * \param *server: a pointer to a struct of type ntg_server
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
   the path to the given node. The path array must include the node
   itself, i.e. if we are saving a node called 'FooBar1', the path array
   might be ['Project1', 'Block1', 'FooBar1']
 * \param *file_path: a pointer to a string representing the path to the file
   on the filesystem
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_save(const ntg_path *path,
        const char *file_path);

/** \brief Load all nodes including and below a given node from the filesystem
 beneath the path given to the given node on the server
 * \param *file_path: a pointer to a string representing the path to the file
 * on the filesystem
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
 the path to the parent node under which the new node will be
 loaded. i.e. if we are loading a node inside Project1 the path would be
 ['Project1']. A NULL value indicates that the new node will be loaded
 under the server root node
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_load(const char *file_path,
        const ntg_path *path);

/** \brief Move a node of a class on the server
 * \param *node_path: a pointer to a struct of type ntg_path giving the
 elements in the path to the given node. The path array must include the
 node itself, i.e. if we are deleting a node called 'FooBar1', the
 path array might be ['Project1', 'Block1', 'FooBar1']
 * \param *parent_path: a pointer to the new parent path. the source node
 and all children will be moved underneath the parent node
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 * */
LIBINTEGRA_API ntg_command_status ntg_move(const ntg_path *node_path,
        const ntg_path *parent_path);

/** \brief Set the value of an attribute of a node on the server
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
 the path to the given attribute. The path array must include the attribute
 itself, i.e. if we are setting the value of an attribute called 'blah' in an
 node called 'FooBar1', the path array might be ['Project1', 'Block1',
 'FooBar1', 'blah']. If the path is invalid, or the final element doesn't
 correspond to an attribute an error code of NTG_PATH_ERROR will be returned
 * \param *value: a pointer to a struct of type ntg_value containing the value
 * we are setting the attribute to. The supported types for value are given in
 * integra_model.h however, the type of *value must match the type of the
 * attribute being set as given by the attribute info. Otherwise an
 * NTG_TYPE_ERROR will be returned
 * \return a struct of type ntg_command_status. If the function succeeded,
 * this will contain the error_code NTG_NO_ERROR
 * \error possible return values for error status are given in integra_error.h
 */
LIBINTEGRA_API ntg_command_status ntg_set(const ntg_path *attribute_path,
        const ntg_value *value);

/** \brief Get the value of an attribute of a node on the server
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
 the path to the given attribute. The path array must include the attribute
 itself, i.e. if we are getting the value of an attribute called 'blah' in an
 node called 'FooBar1', the path array might be ['Project1', 'Block1',
 'FooBar1', 'blah']. If the path is invalid, or the final element doesn't
 correspond to an attribute an error code of NTG_PATH_ERROR will be returned
 * \return a pointer to a struct of type ntg_value. The type (see types.h) of
 * the value returned is guaranteed to match the type of the attribute as
 * given in the attribute info. The ntg_value must be free'd using ntg_value_free()
 * \error a pointer to NULL is returned if an error occurs */
LIBINTEGRA_API const ntg_value *ntg_get(const ntg_path *path);

/** \brief Get the list of paths to nodes on the server under a given node
 * \param *path: a pointer to a struct of type ntg_path giving the elements in
 the path to the given parent. The path gives the root of the nodelist, so if
 we want ALL nodes on the server, an empty path should be given. For all nodes
 under the container: Project1, the path array should be ['Project1']
 * \return a pointer to a struct of type ntg_list, which gives all of the
 * paths under a given node as n_nodes ntg_path arrays. The returned pointer
 * must be passed to ntg_list_free_as_nodelist() when done.
 * \error a pointer to NULL is returned if an error occurs
 *
 * */
LIBINTEGRA_API const ntg_list *ntg_nodelist(const ntg_path *path);


/** \brief Terminate the server and cleanup */
LIBINTEGRA_API void ntg_terminate(void);

/** \brief Print out info about the state of the server to stdout.
 */
LIBINTEGRA_API void ntg_print_state(void);

/** \brief Create a new Integra server 
 *
 * \param bridge_file the filename of the bridge being loaded
 * \param module_directories comma separated list of directories from which IM files are loaded
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
							const char *module_directories,
							unsigned short xmlrpc_server_port, 
							unsigned short osc_server_port, 
							const char *osc_client_url, 
							unsigned short osc_client_port);



/** \brief get the bridge callback
 * */
LIBINTEGRA_API ntg_bridge_callback ntg_server_get_bridge_callback(void);


/** \brief Evaluate a string containing lua code
 *
 * The function returns immediately.
 * The server must be locked before calling.
 *
 * \param string A string containing lua code
 *  The string can contain several lines separated by lineshifts.
 *
 */
LIBINTEGRA_API char *ntg_lua_eval( const ntg_path *parent_path, const char *script_string );


#ifdef __cplusplus
}
#endif

#endif
