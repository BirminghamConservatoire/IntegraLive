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

#include "platform_specifics.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>

#define LUA_COMPAT_MODULE

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}
	 
#include "error.h"
#include "node.h"
#include "lua.h"
#include "luascripting.h"
#include "server_commands.h"
#include "value.h"
#include "helper.h"
#include "globals.h"
#include "interface_definition.h"
#include "helper.h"



#define NTG_ERROR_COLOR		0xff4040
#define NTG_SET_COLOR		0xc000c0
#define NTG_GET_COLOR		0xc08000
#define NTG_PRINT_COLOR		0x6060ff

using namespace ntg_api;
using namespace ntg_internal;



typedef struct ntg_lua_context_stack_
{
	const CPath *parent_path;
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

	color = MAX( 0, MIN( 0xffffff, color ) );

	new_output = new char[ strlen( context_stack->output ) + strlen( progress_template ) + strlen( progress_string ) + 7 ];
	sprintf( new_output, progress_template, context_stack->output, color, progress_string );

	delete[] context_stack->output;
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

	ntg_lua_output_handler( NTG_ERROR_COLOR, "__error:__ %s", error_string );
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
	command_status set_result;
	int num_arguments;
	CPath path, node_path;
	string endpoint_name;

	assert( context_stack && context_stack->parent_path );

	num_arguments = lua_gettop( L );
	if( num_arguments < 2 )
	{
		ntg_lua_error_handler( "Insufficient arguments passed to ntg_lua_set" );
		return 0;
	}

    path = *context_stack->parent_path;
    for( int i = 1; i <= num_arguments - 1; i++) 
	{
        path.append_element( ntg_lua_get_string( L, i ) );
    }
	
	node_path = path;
	endpoint_name = node_path.pop_element();

	const CNode *node = server_->find_node( node_path );
	if( !node )
	{
		ntg_lua_error_handler( "Can't find node: %s", node_path.get_string().c_str() );
		return 0;
	}

	const CNodeEndpoint *endpoint = node->get_node_endpoint( endpoint_name );
	if( !endpoint )
	{
		ntg_lua_error_handler( "Can't find endpoint: %s", path.get_string().c_str() );
		return 0;
	}

	if( endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL )
	{
		ntg_lua_error_handler( "Endpoint is not a control: %s", path.get_string().c_str() );
		return 0;
	}

	if( !endpoint->get_endpoint_definition().get_control_info()->get_can_be_target() )
	{
		ntg_lua_error_handler( "Endpoint is not a legal script target: %s", path.get_string().c_str() );
		return 0;
	}

	if( endpoint->get_value() )
	{	
		assert( endpoint->get_endpoint_definition().get_control_info()->get_type() == CControlInfo::STATEFUL );

		CValue *new_value( NULL );

		switch( lua_type( L, num_arguments ) ) 
		{
			case LUA_TNUMBER:
				new_value = new CFloatValue( ntg_lua_get_float( L, num_arguments ) );
				break;

			case LUA_TSTRING:
				new_value = new CStringValue( ntg_lua_get_string( L, num_arguments ) );
				break;

			default:
				ntg_lua_error_handler( "%s received illegal value (\"%s\")\n", path.get_string().c_str(), lua_typename( L, lua_type( L, num_arguments ) ) );
				return 0;
		}

		assert( new_value );
		CValue *converted_value = new_value->transmogrify( endpoint->get_endpoint_definition().get_control_info()->get_state_info()->get_type() );

		ntg_lua_output_handler( NTG_SET_COLOR, "Setting %s to %s...", path.get_string().c_str(), converted_value->get_as_string().c_str() );

		set_result = ntg_set_( *server_, NTG_SOURCE_SCRIPT, path, converted_value );

		delete new_value;
		delete converted_value;
	}
	else
	{
		assert( endpoint->get_endpoint_definition().get_control_info()->get_type() == CControlInfo::BANG );

		ntg_lua_output_handler( NTG_SET_COLOR, "Sending bang to %s...", path.get_string().c_str() );
		set_result = ntg_set_( *server_, NTG_SOURCE_SCRIPT, path, NULL );
	}

	if( set_result.error_code != NTG_NO_ERROR )
	{
		ntg_lua_error_handler( "%s", ntg_error_text( set_result.error_code ) );
	}

    return 0;
}


static int ntg_lua_get(lua_State * L)
{
	assert( context_stack && context_stack->parent_path );

	int num_arguments = lua_gettop( L );

    CPath path( *context_stack->parent_path );
    for( int i = 1; i <= num_arguments; i++) 
	{
        path.append_element( ntg_lua_get_string( L, i ) );
    }

	CPath node_path( path );
	string endpoint_name = node_path.pop_element();

	const CNode *node = server_->find_node( node_path );
	if( !node )
	{
		ntg_lua_error_handler( "Can't find node: %s", node_path.get_string().c_str() );
		return 0;
	}

	const CNodeEndpoint *node_endpoint = node->get_node_endpoint( endpoint_name );
	if( !node_endpoint )
	{
		ntg_lua_error_handler( "Can't find endpoint: %s", node_path.get_string().c_str() );
		return 0;
	}

	if( node_endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL )
	{
		ntg_lua_error_handler( "Endpoint is not a control: %s", node_path.get_string().c_str() );
		return 0;
	}

	if( node_endpoint->get_endpoint_definition().get_control_info()->get_type() != CControlInfo::STATEFUL )
	{
		ntg_lua_error_handler( "Endpoint is not stateful: %s", node_path.get_string().c_str() );
		return 0;
	}

	if( !node_endpoint->get_endpoint_definition().get_control_info()->get_can_be_source() )
	{
		ntg_lua_error_handler( "Endpoint is not a valid script input: %s", node_path.get_string().c_str() );
		return 0;
	}

    const CValue *value = ntg_get_( *server_, path );
    if( !value ) 
	{
		ntg_lua_error_handler( "Can't read attribute value at %s", node_path.get_string().c_str() );
		return 0;
	}

	string value_string = value->get_as_string();
	ntg_lua_output_handler( NTG_GET_COLOR, "Queried %s, value = %s", node_path.get_string().c_str(), value_string.c_str() );

	switch( value->get_type() ) 
	{
		case CValue::INTEGER:
            lua_pushnumber( L, (lua_Number) ( int ) *value );
            break;
        case CValue::FLOAT:
            lua_pushnumber( L, (lua_Number) ( float ) *value );
            break;
        case CValue::STRING:
            lua_pushstring( L, ( ( const string & ) *value ).c_str() );
            break;
        default:
            ntg_lua_error_handler( "Internal error. attribute value of unknown type" );
			return 0;
    }

    return 1;
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
		delete[] print;
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


char *get_lua_object_name( const CPath &child_path, const CPath &parent_path )
{
	int i;
	const char *path_element;
	char *object_name = NULL;
	char *new_object_name;

	int child_elements = child_path.get_number_of_elements();
	int parent_elements = parent_path.get_number_of_elements();

	assert( child_elements > parent_elements );

	for( i = parent_elements; i < child_elements; i++ )
	{
		path_element = child_path[ i ].c_str();
		if( !object_name )
		{
			object_name = ntg_strdup( path_element );
		}
		else
		{
			new_object_name = new char[ strlen( object_name ) + strlen( path_element ) + 5 ];
			sprintf( new_object_name, "%s[\"%s\"]", object_name, path_element );
			delete[] object_name;
			object_name = new_object_name;
		}
	}
	
	return object_name;
}


char *ntg_lua_get_parameter_string( const CPath &child_path, const CPath &parent_path )
{
	const char *path_element;
	char *parameter_string;
	char *new_parameter_string;

	int child_elements = child_path.get_number_of_elements();
	int parent_elements = parent_path.get_number_of_elements();

	assert( child_elements > parent_elements );

	parameter_string = ntg_strdup( "" );

	for( int i = parent_elements; i < child_elements; i++ )
	{
		path_element = child_path[ i ].c_str();

		new_parameter_string = new char[ strlen( parameter_string ) + strlen( path_element ) + 5 ];
		sprintf( new_parameter_string, "%s\"%s\", ", parameter_string, path_element );
		delete[] parameter_string;
		parameter_string = new_parameter_string;
	}
	
	return parameter_string;
}


char *ntg_lua_declare_child_objects( char *init_script, const node_map &children, const CPath &parent_path )
{
	char *child_declaration;
	const char *child_initializer = "={}\n";

	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		//declare child object
		const CNode *child = i->second;
		child_declaration = get_lua_object_name( child->get_path(), parent_path );
		assert( child_declaration );

		child_declaration = ntg_string_append( child_declaration, child_initializer );

		init_script = ntg_string_append( init_script, child_declaration );
		delete[] child_declaration;

		init_script = ntg_lua_declare_child_objects( init_script, child->get_children(), parent_path );
	}

	return init_script;
}


char *ntg_lua_get_child_metatable( const CNode &node, const CPath &parent_path )
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

	const CPath &node_path = node.get_path();
	assert( parent_path.get_number_of_elements() < node_path.get_number_of_elements() );

	object_name = get_lua_object_name( node_path, parent_path );
	parameter_string = ntg_lua_get_parameter_string( node_path, parent_path );
	assert( object_name && parameter_string );

	metatable = new char[ strlen( metatable_template ) + strlen( object_name ) + strlen( parameter_string ) * 2 + 1 ];
	sprintf( metatable, metatable_template, object_name, parameter_string, parameter_string );

	return metatable;
}


char *ntg_lua_declare_child_metatables( char *init_script, const node_map &children, const CPath &parent_path )
{
	char *child_metatable;

	for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
	{
		const CNode *child = i->second;

		child_metatable = ntg_lua_get_child_metatable( *child, parent_path );
		assert( child_metatable );

		init_script = ntg_string_append( init_script, child_metatable );
		delete[] child_metatable;

		init_script = ntg_lua_declare_child_metatables( init_script, child->get_children(), parent_path );
	}

	return init_script;
}


char *ntg_lua_build_init_script( const CPath &parent_path )
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
	
	int i;

	for( i = 0; *helper_functions[ i ] != 0; i++ )
	{
		init_script = ntg_string_append( init_script, helper_functions[ i ] );
		init_script = ntg_string_append( init_script, "\n" );
	}

	const CNode *parent_node = server_->find_node( parent_path );
	const node_map &child_nodes = parent_node ? parent_node->get_children() : server_->get_nodes();


	init_script = ntg_lua_declare_child_objects( init_script, child_nodes, parent_path );
	init_script = ntg_lua_declare_child_metatables( init_script, child_nodes, parent_path );
	init_script = ntg_string_append( init_script, global_metatable );

	return init_script;
}


lua_State *ntg_lua_create_state( const CPath &parent_path )
{
	lua_State *state;
	char *init_script = NULL;

	init_script = ntg_lua_build_init_script( parent_path );
	if( !init_script ) return NULL;

	state = luaL_newstate();

    luaL_openlibs( state );
    luaL_register( state, "integra", ilua_funcreg );

	if( luaL_dostring( state, init_script ) )
	{
		NTG_TRACE_ERROR_WITH_STRING( "Failed to initialize lua state", lua_tostring( state, -1 ) );
	}

	delete[] init_script;

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
char *ntg_lua_eval( const CPath &parent_path, const char *script_string )
{
	lua_State *state;
	ntg_lua_context_stack *context;
	char *output = NULL;
	time_t raw_time_stamp;
	const char *timestamp_format = "_executing script at %H:%M:%S..._";
	int timestamp_format_length = strlen( timestamp_format ) + 1;
	
	assert( script_string );

	/* initialize the state */

	state = ntg_lua_create_state( parent_path );
	if( !state ) return "Error creating Lua State";

	/* set the context */
	time( &raw_time_stamp );

	context = new ntg_lua_context_stack;

	context->parent_path = &parent_path;

	context->output = new char[ timestamp_format_length ];
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
	delete[] context;

	/* free the state */
	lua_close( state );

	return output;
}

