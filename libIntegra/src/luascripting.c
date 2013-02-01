/** libIntegra lua scripting interface
 *  
 * Copyright (C) 2013 Birmingham City University
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

#ifdef HAVE_CONFIG_H
#    include <config.h>
#endif

#include "platform_specifics.h"

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#if BUILD_LUASCRIPTING

#define LUA_COMPAT_MODULE

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
	 
#include "attribute.h"
#include "node.h"
#include "lua.h"
#include "luascripting.h"
#include "server_commands.h"
#include "memory.h"
#include "value.h"
#include "helper.h"
#include "queue.h"
#include "command.h"
#include "globals.h"
#include "interface.h"
#include "helper.h"

#include "lua_init.c"
#include "lua_functions.c"



typedef struct ntg_script_context_stack_
{
	const ntg_path *parent_path;
	char *output;

	struct ntg_script_context_stack_ *next;

} ntg_script_context_stack;



static ntg_script_context_stack *context_stack = NULL;


static void error_handler( const char *fmt, ...)
{
	char *new_output;
	const char *error_prompt = "__error:__ ";
	const char *separator = "\n\n";

	char error_string[8192];

	assert( context_stack && context_stack->output );
	assert( fmt );

	{
        va_list argp;
        va_start(argp, fmt);
        vsprintf(error_string, fmt, argp);
        va_end(argp);
    }

	NTG_TRACE_ERROR_WITH_STRING( "luascript error", error_string );

	new_output = ntg_malloc( strlen( error_prompt ) + strlen( context_stack->output ) + strlen( separator ) + strlen( error_string ) + 1 );
	sprintf( new_output, "%s%s%s%s", context_stack->output, separator, error_prompt, error_string );

	ntg_free( context_stack->output );
	context_stack->output = new_output;
}


static void progress_handler( const char *fmt, ...)
{
	char *new_output;
	const char *separator = "\n\n";

	char progress_string[8192];

	assert( context_stack && context_stack->output );
	assert( fmt );

	{
        va_list argp;
        va_start(argp, fmt);
        vsprintf(progress_string, fmt, argp);
        va_end(argp);
    }

	NTG_TRACE_VERBOSE_WITH_STRING( "luascript progress", progress_string );

	new_output = ntg_malloc( strlen( context_stack->output ) + strlen( separator ) + strlen( progress_string ) + 1 );
	sprintf( new_output, "%s%s%s", context_stack->output, separator, progress_string );

	ntg_free( context_stack->output );
	context_stack->output = new_output;
}


static void ilua_check_num_arguments(lua_State * L, int supposed)
{
    int n = lua_gettop(L);      /* number of arguments */
    if (n != supposed)
         error_handler( "incorrect number of arguments. Expected %d, found %d",
                   supposed, n);
}


static const char *ilua_get_string(lua_State * L, int argnum)
{
    if (!lua_isstring(L, argnum))
         error_handler( "Argument %d is not a string", argnum);
    return lua_tostring(L, argnum);
}


static float ilua_get_float(lua_State * L, int argnum)
{
    if (!lua_isnumber(L, argnum))
         error_handler( "Argument %d is not a number", argnum);
    return (float)lua_tonumber(L, argnum);
}


static float ilua_get_double(lua_State * L, int argnum)
{
    if (!lua_isnumber(L, argnum))
         error_handler( "Argument %d is not a number", argnum);
    return (double)lua_tonumber(L, argnum);
}


static void pcall_with_error_checking( lua_State * L, int nargs, int nresults, int errfunc )
{
	const char* error_message = NULL;
	int error_value = lua_pcall( L, nargs, nresults, errfunc );

	switch( error_value )
	{
		case 0:
			//success
			break;

		case LUA_ERRRUN:
			error_message = lua_tostring(L, -1);
			error_handler( "lua runtime error: %s", error_message );
			break;

		case LUA_ERRMEM:
			error_message = lua_tostring(L, -1);
			error_handler( "lua memory allocation error: %s", error_message );
			break;

		case LUA_ERRERR:
			error_message = lua_tostring(L, -1);
			error_handler( "lua error running error handler: %s", error_message );
			break;

		default:
			//unrecognised error
			error_handler( "unrecognised error" );
			break;
	}
}


static int ilua_set( lua_State * L )
{
    ntg_path *path = NULL;
	ntg_path *node_path = NULL;
	ntg_path *received_path = NULL;
    ntg_value *value = NULL;
	char *attribute_name = NULL;
	const ntg_node *node = NULL;
	const ntg_node_attribute *attribute = NULL;
	ntg_value *converted_value = NULL;
    float value_f;
    const char *value_s;

	assert( context_stack && context_stack->parent_path );

	ilua_check_num_arguments(L, 3);

    received_path = ntg_path_from_string( ilua_get_string( L, 1 ) );
    ntg_path_append_element( received_path, ilua_get_string( L, 2 ) );
    path = ntg_path_join( context_stack->parent_path, received_path );
    ntg_path_free(received_path);

    switch( lua_type( L, 3 ) ) 
	{
        case LUA_TNUMBER:
            value_f = ilua_get_float(L, 3);
            value = ntg_value_new(NTG_FLOAT, &value_f);
            break;
        case LUA_TSTRING:
            value_s = ilua_get_string(L, 3);
            value = ntg_value_new(NTG_STRING, value_s);
            break;
        default:
             error_handler( "Illegal value sent to integra.set. (\"%s\")\n",
                    lua_typename(L, lua_type(L, 3)));
            break;
    }

	if( !value )
	{
		error_handler( "No value provided" );
		goto CLEANUP;
	}

	node_path = ntg_path_copy( path );
	attribute_name = ntg_path_pop_element( node_path );
	assert( attribute_name );

	node = ntg_node_find_by_path( node_path, ntg_server_get_root( server_ ) );
	if( !node )
	{
		error_handler( "Can't find node: %s", node_path->string );
		goto CLEANUP;
	}

	attribute = ntg_find_attribute( node, attribute_name );
	if( !attribute )
	{
		error_handler( "Can't find endpoint: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->endpoint->type != NTG_CONTROL )
	{
		error_handler( "Endpoint is not a control: %s", path->string );
		goto CLEANUP;
	}

	if( !attribute->endpoint->control_info->can_be_target )
	{
		error_handler( "Endpoint is not a legal script target: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->value )
	{	
		static char value_string[ NTG_LONG_STRLEN ];
	
		assert( attribute->endpoint->control_info->type == NTG_STATE );

		converted_value = ntg_value_change_type( value, attribute->value->type );

		ntg_set_( server_, NTG_SOURCE_SCRIPT, path, converted_value );

		ntg_value_sprintf( value_string, converted_value );
		progress_handler( "Set endpoint %s to %s", path->string, value_string );

		ntg_value_free(converted_value);
	}
	else
	{
		assert( attribute->endpoint->control_info->type == NTG_BANG );

		ntg_set_( server_, NTG_SOURCE_SCRIPT, path, NULL );

		progress_handler( "Sent bang to endpoint %s", path->string );
	}

	CLEANUP:

	if( node_path ) ntg_path_free( node_path );
	if( attribute_name ) ntg_free( attribute_name );
	if( value ) ntg_value_free(value);
	if( path ) ntg_path_free(path);

    return 0;
}


static int ilua_get(lua_State * L)
{
    const ntg_value *value = NULL;
	const ntg_node *node = NULL;
	ntg_path *node_path = NULL;
	char *attribute_name = NULL;
	const ntg_node_attribute *attribute = NULL;
    int i;
	int return_value = 0;
    int num_arguments = 0;
	ntg_path *path = NULL;

	assert( context_stack && context_stack->parent_path );

	num_arguments = lua_gettop( L );

    path = ntg_path_copy( context_stack->parent_path );
    for(i = 1; i <= num_arguments; i++) 
	{
        ntg_path_append_element( path, ilua_get_string( L, i ) );
    }

	node_path = ntg_path_copy( path );
	attribute_name = ntg_path_pop_element( node_path );

	node = ntg_node_find_by_path( node_path, ntg_server_get_root( server_ ) );
	if( !node )
	{
		error_handler( "Can't find node: %s", node_path->string );
		goto CLEANUP;
	}

	attribute = ntg_find_attribute( node, attribute_name );
	if( !attribute )
	{
		error_handler( "Can't find endpoint: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->endpoint->type != NTG_CONTROL )
	{
		error_handler( "Endpoint is not a control: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->endpoint->control_info->type != NTG_STATE )
	{
		error_handler( "Endpoint is not stateful: %s", path->string );
		goto CLEANUP;
	}

	if( !attribute->endpoint->control_info->can_be_source )
	{
		error_handler( "Endpoint is not a valid script input: %s", path->string );
		goto CLEANUP;
	}

    value = ntg_get_( server_, path );

    if( !value ) 
	{
		error_handler( "Can't read attribute value at %s", path->string );
		goto CLEANUP;
	}

	switch (ntg_value_get_type(value)) 
	{
        case NTG_INTEGER:
            lua_pushnumber(L, (lua_Number) ntg_value_get_int(value));
			return_value = 1;
            break;
        case NTG_FLOAT:
            lua_pushnumber(L, (lua_Number) ntg_value_get_float(value));
			return_value = 1;
            break;
        case NTG_STRING:
            lua_pushstring(L, ntg_value_get_string(value));
			return_value = 1;
            break;
        default:
            error_handler( "Internal error. ntg_get_()->type has unknown value: %d", ntg_value_get_type( value ) );
            break;
    }

	CLEANUP:

	if( path ) ntg_path_free( path );
	if( node_path ) ntg_path_free( node_path );
	if( attribute_name ) ntg_free( attribute_name );

    return return_value;
}


static const luaL_Reg ilua_funcreg[] = 
{
    {"set", ilua_set},
    {"get", ilua_get},
    { NULL, NULL }
};


lua_State *ntg_lua_state = NULL; /* Secret global variable. Set this one before calling ntg_server_run to avoid creating a new state. */


bool init_luascripting(ntg_server * server)
{
	char *ilua_startup = NULL;

    const char *ilua_init_traceeval =
        "ilua_init_traceeval = function(code)\n"
        "     local func,message=loadstring(code)\n"
        "     if func==nil then\n"
        "        print(message)\n"
        "        os.exit(-2)\n"
        "     end\n"
        "     local status,message = xpcall(func,debug.traceback)\n"
        "     if status==false then\n"
        "        print(message)\n"
        "        os.exit(-1)\n" "     end\n" "     return status\n" "  end\n";

	ilua_startup = ntg_string_join(ilua_functionscode, ilua_initcode);

    if( !ntg_lua_state )
	{
		ntg_lua_state = luaL_newstate();
	}

    luaL_openlibs( ntg_lua_state );
    luaL_register( ntg_lua_state, "integra", ilua_funcreg );

    luaL_loadbuffer( ntg_lua_state, ilua_init_traceeval, strlen( ilua_init_traceeval ), "ilua_init_traceeval" );
    pcall_with_error_checking( ntg_lua_state , 0, 0, 0);

    lua_getglobal( ntg_lua_state, "ilua_init_traceeval");
    lua_pushstring( ntg_lua_state, ilua_startup );
    pcall_with_error_checking( ntg_lua_state, 1, 1, 0);

    ntg_free(ilua_startup);

    return true;
}




/** \brief Evaluate a string containing lua code
 *
 * The server must be locked before calling.
 * This method is designed to handle re-entrance correctly, by using a 
 * context stack.  This allows script outputs to cause other scripts to be executed.
 *
 * returns textual output from operation, returned string should be freed by caller
 */
char *ntg_lua_eval( const ntg_path *parent_path, const char *script_string )
{
	ntg_script_context_stack *context;
	char *output = NULL;
	time_t raw_time_stamp;
	const char *timestamp_format = "_executing script at %H:%M:%S..._";
	int timestamp_format_length = strlen( timestamp_format ) + 1;
	
	assert( parent_path && script_string );

	/* set the context */
	time( &raw_time_stamp );

	context = ntg_malloc( sizeof( ntg_script_context_stack ) );

	context->parent_path = parent_path;

	context->output = ntg_malloc( timestamp_format_length );
	strftime( context->output, timestamp_format_length, timestamp_format, localtime( &raw_time_stamp ) );

	/* push the stack */
	context->next = context_stack;
	context_stack = context;

	/* execute the script */

	if( luaL_dostring( ntg_lua_state, script_string ) )
	{
		error_handler( lua_tostring( ntg_lua_state, -1 ) );
	}

	progress_handler( "_done_" );

	/* pop the stack */

	assert( context == context_stack );		/* test that re-entrances have tidied up as expected */
	
	output = context_stack->output;
	context_stack = context_stack->next;
	ntg_free( context );

	return output;
}


#endif	/* BUILD_LUASCRIPTING */
