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


#define NTG_ERROR_COLOR		0xff4040
#define NTG_SET_COLOR		0xc000c0
#define NTG_GET_COLOR		0xc08000
#define NTG_PRINT_COLOR		0x6060ff



typedef struct ntg_lua_context_stack_
{
	const ntg_path *parent_path;
	char *output;

	struct ntg_lua_context_stack_ *next;

} ntg_lua_context_stack;



static ntg_lua_context_stack *context_stack = NULL;


static void ntg_lua_output_handler( int color, const char *fmt, ...)
{
	char *new_output;
	int progress_string_length;
	int i;
	const char *progress_template = "%s\n\n<font color='#%x'>%s</font>";
	const char *illegal_characters = "<>";

	char progress_string[ NTG_LONG_STRLEN ];

	assert( context_stack && context_stack->output );
	assert( fmt );

	{
        va_list argp;
        va_start( argp, fmt );
		vsprintf_s( progress_string, NTG_LONG_STRLEN, fmt, argp );
        va_end(argp);
    }

	NTG_TRACE_VERBOSE_WITH_STRING( "luascript output", progress_string );

	/* replace illegal characters with space, to prevent invalid html */
	progress_string_length = strlen( progress_string );
	for( i = 0; i < progress_string_length; i++ )
	{
		if( strchr( illegal_characters, progress_string[ i ] ) != NULL )
		{
			progress_string[ i ] = ' ';
		}
	}

	color = max( 0, min( 0xffffff, color ) );

	new_output = ntg_malloc( strlen( context_stack->output ) + strlen( progress_template ) + strlen( progress_string ) + 7 );
	sprintf( new_output, progress_template, context_stack->output, color, progress_string );

	ntg_free( context_stack->output );
	context_stack->output = new_output;
}


static void ntg_lua_error_handler( const char *fmt, ...)
{
	char error_string[ NTG_LONG_STRLEN ];

	assert( context_stack && context_stack->output );
	assert( fmt );

	{
        va_list argp;
        va_start( argp, fmt );
        vsprintf_s( error_string, NTG_LONG_STRLEN, fmt, argp);
        va_end(argp);
    }

	ntg_lua_output_handler( NTG_ERROR_COLOR, "__error:__%s", error_string );
}


static const char *ntg_lua_get_string(lua_State * L, int argnum)
{
    if (!lua_isstring(L, argnum))
         ntg_lua_error_handler( "Argument %d is not a string", argnum);
    return lua_tostring(L, argnum);
}


static float ntg_lua_get_float(lua_State * L, int argnum)
{
    if (!lua_isnumber(L, argnum))
         ntg_lua_error_handler( "Argument %d is not a number", argnum);
    return (float)lua_tonumber(L, argnum);
}


static float ntg_lua_get_double(lua_State * L, int argnum)
{
    if (!lua_isnumber(L, argnum))
         ntg_lua_error_handler( "Argument %d is not a number", argnum);
    return (double)lua_tonumber(L, argnum);
}


static int ntg_lua_set( lua_State * L )
{
    ntg_path *path = NULL;
	ntg_path *node_path = NULL;
    ntg_value *value = NULL;
	char *attribute_name = NULL;
	const ntg_node *node = NULL;
	const ntg_node_attribute *attribute = NULL;
	ntg_value *converted_value = NULL;
	ntg_command_status set_result;
	int num_arguments;
	int i;
    float value_f;
    const char *value_s;

	assert( context_stack && context_stack->parent_path );

	num_arguments = lua_gettop( L );
	if( num_arguments < 2 )
	{
		ntg_lua_error_handler( "Insufficient arguments passed to ntg_lua_set" );
		goto CLEANUP;
	}

    path = ntg_path_copy( context_stack->parent_path );
    for( i = 1; i <= num_arguments - 1; i++) 
	{
        ntg_path_append_element( path, ntg_lua_get_string( L, i ) );
    }
	
	node_path = ntg_path_copy( path );
	attribute_name = ntg_path_pop_element( node_path );
	assert( attribute_name );

	node = ntg_node_find_by_path( node_path, ntg_server_get_root( server_ ) );
	if( !node )
	{
		ntg_lua_error_handler( "Can't find node: %s", node_path->string );
		goto CLEANUP;
	}

	attribute = ntg_find_attribute( node, attribute_name );
	if( !attribute )
	{
		ntg_lua_error_handler( "Can't find endpoint: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->endpoint->type != NTG_CONTROL )
	{
		ntg_lua_error_handler( "Endpoint is not a control: %s", path->string );
		goto CLEANUP;
	}

	if( !attribute->endpoint->control_info->can_be_target )
	{
		ntg_lua_error_handler( "Endpoint is not a legal script target: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->value )
	{	
		char value_string[ NTG_LONG_STRLEN ];

		assert( attribute->endpoint->control_info->type == NTG_STATE );

		switch( lua_type( L, num_arguments ) ) 
		{
			case LUA_TNUMBER:
				value_f = ntg_lua_get_float(L, num_arguments);
				value = ntg_value_new( NTG_FLOAT, &value_f );
				break;

			case LUA_TSTRING:
				value_s = ntg_lua_get_string(L, num_arguments);
				value = ntg_value_new(NTG_STRING, value_s);
				break;

			default:
				ntg_lua_error_handler( "%s received illegal value (\"%s\")\n", path->string, lua_typename( L, lua_type( L, num_arguments ) ) );
				goto CLEANUP;
		}

		converted_value = ntg_value_change_type( value, attribute->value->type );

		ntg_value_sprintf( value_string, NTG_LONG_STRLEN, converted_value );
		ntg_lua_output_handler( NTG_SET_COLOR, "Setting %s to %s...", path->string, value_string );

		set_result = ntg_set_( server_, NTG_SOURCE_SCRIPT, path, converted_value );

		ntg_value_free(converted_value);
	}
	else
	{
		assert( attribute->endpoint->control_info->type == NTG_BANG );

		ntg_lua_output_handler( NTG_SET_COLOR, "Sending bang to %s...", path->string );
		set_result = ntg_set_( server_, NTG_SOURCE_SCRIPT, path, NULL );
	}

	if( set_result.error_code != NTG_NO_ERROR )
	{
		ntg_lua_error_handler( "failed: %s", ntg_error_text( set_result.error_code ) );
	}

	CLEANUP:

	if( node_path ) ntg_path_free( node_path );
	if( attribute_name ) ntg_free( attribute_name );
	if( value ) ntg_value_free(value);
	if( path ) ntg_path_free(path);

    return 0;
}


static int ntg_lua_get(lua_State * L)
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
	char value_string[ NTG_LONG_STRLEN ];

	assert( context_stack && context_stack->parent_path );

	num_arguments = lua_gettop( L );

    path = ntg_path_copy( context_stack->parent_path );
    for(i = 1; i <= num_arguments; i++) 
	{
        ntg_path_append_element( path, ntg_lua_get_string( L, i ) );
    }

	node_path = ntg_path_copy( path );
	attribute_name = ntg_path_pop_element( node_path );

	node = ntg_node_find_by_path( node_path, ntg_server_get_root( server_ ) );
	if( !node )
	{
		ntg_lua_error_handler( "Can't find node: %s", node_path->string );
		goto CLEANUP;
	}

	attribute = ntg_find_attribute( node, attribute_name );
	if( !attribute )
	{
		ntg_lua_error_handler( "Can't find endpoint: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->endpoint->type != NTG_CONTROL )
	{
		ntg_lua_error_handler( "Endpoint is not a control: %s", path->string );
		goto CLEANUP;
	}

	if( attribute->endpoint->control_info->type != NTG_STATE )
	{
		ntg_lua_error_handler( "Endpoint is not stateful: %s", path->string );
		goto CLEANUP;
	}

	if( !attribute->endpoint->control_info->can_be_source )
	{
		ntg_lua_error_handler( "Endpoint is not a valid script input: %s", path->string );
		goto CLEANUP;
	}

    value = ntg_get_( server_, path );

    if( !value ) 
	{
		ntg_lua_error_handler( "Can't read attribute value at %s", path->string );
		goto CLEANUP;
	}

	ntg_value_sprintf( value_string, NTG_LONG_STRLEN, value );
	ntg_lua_output_handler( NTG_GET_COLOR, "Queried %s, value = %s", path->string, value_string );

	switch (ntg_value_get_type(value)) 
	{
        case NTG_INTEGER:
            lua_pushnumber(L, (lua_Number) ntg_value_get_int( value ) );
			return_value = 1;
            break;
        case NTG_FLOAT:
            lua_pushnumber(L, (lua_Number) ntg_value_get_float( value ) );
			return_value = 1;
            break;
        case NTG_STRING:
            lua_pushstring(L, ntg_value_get_string( value ) );
			return_value = 1;
            break;
        default:
            ntg_lua_error_handler( "Internal error. ntg_get_()->type has unknown value: %d", ntg_value_get_type( value ) );
            break;
    }

	CLEANUP:

	if( path ) ntg_path_free( path );
	if( node_path ) ntg_path_free( node_path );
	if( attribute_name ) ntg_free( attribute_name );

    return return_value;
}


static int ilua_print( lua_State * L )
{
    int num_arguments = 0;
	int i;
	char *print = NULL;

	num_arguments = lua_gettop( L );

	for( i = 1; i <= num_arguments; i++ )
	{
		switch( lua_type( L, i ) ) 
		{
			case LUA_TNUMBER:
			case LUA_TSTRING:
				if( print ) 
				{
					print = ntg_string_append( print, ", " );
				}

				print = ntg_string_append( print, ntg_lua_get_string( L, i ) );
				break;

			default:
				/* we don't yet support printing other types */
				break;
		}
	}

	if( print )
	{
		ntg_lua_output_handler( NTG_PRINT_COLOR, print );
		ntg_free( print );
	}

	return 1;
}


static const luaL_Reg ilua_funcreg[] = 
{
    {"set", ntg_lua_set},
    {"get", ntg_lua_get},
	{"print", ilua_print},
    { NULL, NULL }
};


char *get_lua_object_name( const ntg_path *child_path, const ntg_path *parent_path )
{
	int i;
	const char *path_element;
	char *object_name = NULL;
	char *new_object_name;

	assert( child_path && parent_path && child_path->n_elems > parent_path->n_elems );

	for( i = parent_path->n_elems; i < child_path->n_elems; i++ )
	{
		path_element = child_path->elems[ i ];
		if( !object_name )
		{
			object_name = ntg_strdup( path_element );
		}
		else
		{
			new_object_name = ntg_malloc( strlen( object_name ) + strlen( path_element ) + 5 );
			sprintf( new_object_name, "%s[\"%s\"]", object_name, path_element );
			ntg_free( object_name );
			object_name = new_object_name;
		}
	}
	
	return object_name;
}


char *ntg_lua_get_parameter_string( const ntg_path *child_path, const ntg_path *parent_path )
{
	int i;
	const char *path_element;
	char *parameter_string;
	char *new_parameter_string;

	assert( child_path && parent_path && child_path->n_elems > parent_path->n_elems );

	parameter_string = ntg_strdup( "" );

	for( i = parent_path->n_elems; i < child_path->n_elems; i++ )
	{
		path_element = child_path->elems[ i ];

		new_parameter_string = ntg_malloc( strlen( parameter_string ) + strlen( path_element ) + 5 );
		sprintf( new_parameter_string, "%s\"%s\", ", parameter_string, path_element );
		ntg_free( parameter_string );
		parameter_string = new_parameter_string;
	}
	
	return parameter_string;
}


char *ntg_lua_declare_child_objects( char *init_script, const ntg_node *node, const ntg_path *parent_path )
{
	const ntg_node *child_iterator;
	char *child_declaration;
	const char *child_initializer = "={}\n";

	assert( node && parent_path && parent_path->n_elems <= node->path->n_elems );

	child_iterator = node->nodes;
	if( child_iterator )
	{
		do 
		{
			//declare child object
			child_declaration = get_lua_object_name( child_iterator->path, parent_path );
			assert( child_declaration );

			child_declaration = ntg_string_append( child_declaration, child_initializer );

			init_script = ntg_string_append( init_script, child_declaration );
			ntg_free( child_declaration );

			init_script = ntg_lua_declare_child_objects( init_script, child_iterator, parent_path );

			child_iterator = child_iterator->next;

		} 
		while (child_iterator != node->nodes);
	}

	return init_script;
}


char *ntg_lua_get_child_metatable( const ntg_node *node, const ntg_path *parent_path )
{
	char *object_name;
	char *parameter_string;
	char *metatable;
	const char *metatable_template = 
		"setmetatable(%s,\n"
		"{\n"
		"	__index=function(_,attribute)\n"
		"		return integra.get(%sattribute )\n"
		"	end,\n"
		"	__newindex = function( _, attribute, value )\n"
		"		integra.set( %sattribute, value )\n"
		"	end\n"
		"})\n";

	assert( node && parent_path && parent_path->n_elems < node->path->n_elems );

	object_name = get_lua_object_name( node->path, parent_path );
	parameter_string = ntg_lua_get_parameter_string( node->path, parent_path );
	assert( object_name && parameter_string );

	metatable = ntg_malloc( strlen( metatable_template ) + strlen( object_name ) + strlen( parameter_string ) * 2 + 1 );
	sprintf( metatable, metatable_template, object_name, parameter_string, parameter_string );

	return metatable;
}


char *ntg_lua_declare_child_metatables( char *init_script, const ntg_node *node, const ntg_path *parent_path )
{
	const ntg_node *child_iterator;
	char *child_metatable;

	assert( node && parent_path && parent_path->n_elems <= node->path->n_elems );

	child_iterator = node->nodes;
	if( child_iterator )
	{
		do 
		{
			child_metatable = ntg_lua_get_child_metatable( child_iterator, parent_path );
			assert( child_metatable );

			init_script = ntg_string_append( init_script, child_metatable );
			ntg_free( child_metatable );

			init_script = ntg_lua_declare_child_metatables( init_script, child_iterator, parent_path );

			child_iterator = child_iterator->next;

		} 
		while (child_iterator != node->nodes);
	}

	return init_script;
}


char *ntg_lua_build_init_script( const ntg_path *parent_path )
{
	const char *helper_functions[] = 
	{
		/*
		Minimal MIDI to frequency conversion with argument checking
		usage: mtof(midi-value)
		*/
		"function mtof(value)"
		"   local input = value>0 and value or 0"
		"   input = input<128 and input or 128"
		"   local freq = 440 * (2^((input - 69) / 12 ))"
		"   return freq"
		"	end",

		/*
		Minimal frequency to MIDI conversion with argument checking 
		usage: lua_ftom(frequency-in-hertz)
		*/
		"function ftom(freq)"
		"  local  input = freq>0 and freq or 0"
		"   return 69 + math.log(freq/440) * 17.31234"
		"	end",

		/* end of helper functions */
		"\0"
	};

	const char *global_metatable = 
		"setmetatable(_G,\n"
		"{\n"
		"	__index = function( _, attribute )\n"
		"		return integra.get( attribute )\n"
		"	end,\n"
		"	__newindex = function( _, attribute, value )\n"
		"		integra.set( attribute, value )\n"
		"	end\n"
		"})\n";

	char *init_script = NULL;
	ntg_node *parent_node;
	int i;

	assert( parent_path );

	for( i = 0; *helper_functions[ i ] != 0; i++ )
	{
		init_script = ntg_string_append( init_script, helper_functions[ i ] );
		init_script = ntg_string_append( init_script, "\n" );
	}

	parent_node = ntg_node_find_by_path( parent_path, ntg_server_get_root( server_ ) );
	if( !parent_node )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Can't find node", parent_path->string );
		return NULL;
	}

	init_script = ntg_lua_declare_child_objects( init_script, parent_node, parent_path );
	init_script = ntg_lua_declare_child_metatables( init_script, parent_node, parent_path );
	init_script = ntg_string_append( init_script, global_metatable );

	return init_script;
}


lua_State *ntg_lua_create_state( const ntg_path *parent_path )
{
	lua_State *state;
	char *init_script = NULL;

	assert( parent_path );

	init_script = ntg_lua_build_init_script( parent_path );
	if( !init_script ) return NULL;

	state = luaL_newstate();

    luaL_openlibs( state );
    luaL_register( state, "integra", ilua_funcreg );

	if( luaL_dostring( state, init_script ) )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to initialize lua state", lua_tostring( state, -1 ) );
	}

	ntg_free( init_script );

	return state;
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
	lua_State *state;
	ntg_lua_context_stack *context;
	char *output = NULL;
	time_t raw_time_stamp;
	const char *timestamp_format = "_executing script at %H:%M:%S..._";
	int timestamp_format_length = strlen( timestamp_format ) + 1;
	
	assert( parent_path && script_string );

	/* initialize the state */

	state = ntg_lua_create_state( parent_path );
	if( !state ) return "Error creating Lua State";

	/* set the context */
	time( &raw_time_stamp );

	context = ntg_malloc( sizeof( ntg_lua_context_stack ) );

	context->parent_path = parent_path;

	context->output = ntg_malloc( timestamp_format_length );
	strftime( context->output, timestamp_format_length, timestamp_format, localtime( &raw_time_stamp ) );

	/* push the stack */
	context->next = context_stack;
	context_stack = context;

	/* execute the script */

	if( luaL_dostring( state, script_string ) )
	{
		ntg_lua_error_handler( lua_tostring( state, -1 ) );
	}

	context->output = ntg_string_append( context->output, "\n\n_done_" );

	/* pop the stack */

	assert( context == context_stack );		/* test that re-entrances have tidied up as expected */
	
	output = context_stack->output;
	context_stack = context_stack->next;
	ntg_free( context );

	/* free the state */
	lua_close( state );

	return output;
}


#endif	/* BUILD_LUASCRIPTING */
