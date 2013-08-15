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

#include "lua_engine.h"
#include "api/trace.h"
#include "node.h"
#include "server.h"
#include "interface_definition.h"
#include "api/command.h"
#include "string_helper.h"


#define LUA_COMPAT_MODULE

extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}

#include <time.h>
#include <assert.h>


namespace integra_internal
{
	const unsigned int CLuaEngine::error_color = 0xff4040;
	const unsigned int CLuaEngine::set_color = 0xc000c0;
	const unsigned int CLuaEngine::get_color = 0xc08000;
	const unsigned int CLuaEngine::print_color = 0x6060ff;
	const string CLuaEngine::self_key = "integra_internal::CLuaEngine";

	CLuaEngine::CLuaEngine()
	{
	}


	CLuaEngine::~CLuaEngine()
	{
	}


	string CLuaEngine::run_script( CServer &server, const CPath &parent_path, const string &script_string )
	{
		m_server = &server;

		/* initialize the state */
		lua_State *state = create_state( server, parent_path );
		if( !state ) return "Error creating Lua State";

		/* set the context */
		time_t raw_time_stamp;
		time( &raw_time_stamp );

		CLuaContext *context = new CLuaContext;

		context->m_parent_path = &parent_path;

		const char *timestamp_format = "_executing script at %H:%M:%S..._";
		int timestamp_format_length = strlen( timestamp_format ) + 1;
		char *formatted_time_stamp = new char[ timestamp_format_length ];
		strftime( formatted_time_stamp, timestamp_format_length, timestamp_format, localtime( &raw_time_stamp ) );
		context->m_output = formatted_time_stamp;
		delete formatted_time_stamp;

		/* push the stack */
		m_context_stack.push_back( context );

		/* execute the script */
		if( luaL_dostring( state, script_string.c_str() ) )
		{
			error_handler( lua_tostring( state, -1 ) );
		}

		context->m_output += "\n\n_done_";

		/* pop the stack */

		assert( !m_context_stack.empty() );		/* test that re-entrances have tidied up as expected */
		assert( context == m_context_stack.back() );		/* test that re-entrances have tidied up as expected */
	
		string output = context->m_output;
		delete context;
		m_context_stack.pop_back();

		/* free the state */
		lua_close( state );

		return output;
	}


	int CLuaEngine::handle_set( lua_State *state )
	{
		assert( !m_context_stack.empty() );
		CLuaContext *context = m_context_stack.back();

		int num_arguments = lua_gettop( state ) - 1;
		if( num_arguments < 2 )
		{
			error_handler( "Insufficient arguments passed to ntg_lua_set" );
			return 0;
		}

		CPath path = *context->m_parent_path;
		for( int i = 1; i < num_arguments; i++ ) 
		{
			path.append_element( get_string( state, i ) );
		}
	
		CPath node_path = path;
		string endpoint_name = node_path.pop_element();

		const INode *node = m_server->find_node( node_path );
		if( !node )
		{
			error_handler( "Can't find node: %s", node_path.get_string().c_str() );
			return 0;
		}

		const INodeEndpoint *endpoint = node->get_node_endpoint( endpoint_name );
		if( !endpoint )
		{
			error_handler( "Can't find endpoint: %s", path.get_string().c_str() );
			return 0;
		}

		if( endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL )
		{
			error_handler( "Endpoint is not a control: %s", path.get_string().c_str() );
			return 0;
		}

		if( !endpoint->get_endpoint_definition().get_control_info()->get_can_be_target() )
		{
			error_handler( "Endpoint is not a legal script target: %s", path.get_string().c_str() );
			return 0;
		}

		CError error;

		if( endpoint->get_value() )
		{	
			assert( endpoint->get_endpoint_definition().get_control_info()->get_type() == CControlInfo::STATEFUL );

			CValue *new_value( NULL );

			switch( lua_type( state, num_arguments ) ) 
			{
				case LUA_TNUMBER:
					new_value = new CFloatValue( get_float( state, num_arguments ) );
					break;

				case LUA_TSTRING:
					new_value = new CStringValue( get_string( state, num_arguments ) );
					break;

				default:
					error_handler( "%s received illegal value (\"%s\")\n", path.get_string().c_str(), lua_typename( state, lua_type( state, num_arguments ) ) );
					return 0;
			}

			assert( new_value );
			CValue *converted_value = new_value->transmogrify( endpoint->get_endpoint_definition().get_control_info()->get_state_info()->get_type() );

			output_handler( set_color, "Setting %s to %s...", path.get_string().c_str(), converted_value->get_as_string().c_str() );

			error = m_server->process_command( ISetCommand::create( path, converted_value ), CCommandSource::SCRIPT );

			delete new_value;
			delete converted_value;
		}
		else
		{
			assert( endpoint->get_endpoint_definition().get_control_info()->get_type() == CControlInfo::BANG );

			output_handler( set_color, "Sending bang to %s...", path.get_string().c_str() );
			error = m_server->process_command( ISetCommand::create( path, NULL ), CCommandSource::SCRIPT );
		}

		if( error != CError::SUCCESS )
		{
			error_handler( "%s", error.get_text().c_str() );
		}

		return 0;
	}


	int CLuaEngine::handle_get( lua_State *state )
	{
		assert( !m_context_stack.empty() );
		const CLuaContext *context = m_context_stack.back();

		int num_arguments = lua_gettop( state ) - 1;

		CPath path( *context->m_parent_path );
		for( int i = 1; i <= num_arguments; i++ ) 
		{
			path.append_element( get_string( state, i ) );
		}

		CPath node_path( path );
		string endpoint_name = node_path.pop_element();

		const INode *node = m_server->find_node( node_path );
		if( !node )
		{
			error_handler( "Can't find node: %s", node_path.get_string().c_str() );
			return 0;
		}

		const INodeEndpoint *node_endpoint = node->get_node_endpoint( endpoint_name );
		if( !node_endpoint )
		{
			error_handler( "Can't find endpoint: %s", node_path.get_string().c_str() );
			return 0;
		}

		if( node_endpoint->get_endpoint_definition().get_type() != CEndpointDefinition::CONTROL )
		{
			error_handler( "Endpoint is not a control: %s", node_path.get_string().c_str() );
			return 0;
		}

		if( node_endpoint->get_endpoint_definition().get_control_info()->get_type() != CControlInfo::STATEFUL )
		{
			error_handler( "Endpoint is not stateful: %s", node_path.get_string().c_str() );
			return 0;
		}

		if( !node_endpoint->get_endpoint_definition().get_control_info()->get_can_be_source() )
		{
			error_handler( "Endpoint is not a valid script input: %s", node_path.get_string().c_str() );
			return 0;
		}

		const CValue *value = m_server->get_value( path );
		if( !value ) 
		{
			error_handler( "Can't read attribute value at %s", node_path.get_string().c_str() );
			return 0;
		}

		node_path.append_element( endpoint_name );
		string value_string = value->get_as_string();
		output_handler( get_color, "Queried %s, value = %s", node_path.get_string().c_str(), value_string.c_str() );

		switch( value->get_type() ) 
		{
			case CValue::INTEGER:
				lua_pushnumber( state, (lua_Number) ( int ) *value );
				break;
			case CValue::FLOAT:
				lua_pushnumber( state, (lua_Number) ( float ) *value );
				break;
			case CValue::STRING:
				lua_pushstring( state, ( ( const string & ) *value ).c_str() );
				break;
			default:
				error_handler( "Internal error. attribute value of unknown type" );
				return 0;
		}

		return 1;
	}



	int CLuaEngine::handle_print( lua_State *state )
	{
		int num_arguments = 0;
		int i;
		ostringstream output;

		num_arguments = lua_gettop( state );

		for( i = 1; i <= num_arguments; i++ )
		{
			switch( lua_type( state, i ) ) 
			{
				case LUA_TNUMBER:
				case LUA_TSTRING:
					if( !output.str().empty() ) 
					{
						output << ", ";
					}

					output << get_string( state, i );
					break;

				default:
					/* we don't yet support printing other types */
					break;
			}
		}

		if( !output.str().empty() )
		{
			output_handler( print_color, output.str().c_str() );
		}

		return 1;
	}


	const char *CLuaEngine::get_string( lua_State *state, int argnum ) 
	{
		if(!lua_isstring( state, argnum ) )
		{
			error_handler( "Argument %d is not a string", argnum );
		}

		return lua_tostring( state, argnum );
	}


	float CLuaEngine::get_float(lua_State *state, int argnum ) 
	{
		if( !lua_isnumber( state, argnum ) )
		{
			 error_handler( "Argument %d is not a number", argnum );
		}
		return lua_tonumber( state, argnum );
	}


	lua_State *CLuaEngine::create_state( const CServer &server, const CPath &parent_path )
	{
		const luaL_Reg function_registration[] = 
		{
			{ "set", set_callback },
			{ "get", get_callback },
			{ "print", print_callback },
			{ NULL, NULL }
		};

		lua_State *state = luaL_newstate();

		/* store pointer to self */

		/* store a number */
		lua_pushstring( state, self_key.c_str() );  
		lua_pushlightuserdata( state, ( void * ) this );
	    lua_settable( state, LUA_REGISTRYINDEX );

	
		string init_script = build_init_script( server, parent_path );
		if( init_script.empty() ) return NULL;

		luaL_openlibs( state );
		luaL_register( state, "integra", function_registration );

		if( luaL_dostring( state, init_script.c_str() ) )
		{
			INTEGRA_TRACE_ERROR << "Failed to initialize lua state: " << lua_tostring( state, -1 );
		}

		return state;
	}


	void CLuaEngine::error_handler( const char *fmt, ...)
	{
		char error_string[ CStringHelper::string_buffer_length ];

		assert( !m_context_stack.empty() );
		assert( fmt );

		{
			va_list argp;
			va_start( argp, fmt );
			vsprintf_s( error_string, CStringHelper::string_buffer_length, fmt, argp);
			va_end(argp);
		}

		output_handler( error_color, "__error:__ %s", error_string );
	}


	void CLuaEngine::output_handler( unsigned int color, const char *fmt, ...)
	{
		const char *progress_template = "%s\n\n<font color='#%x'>%s</font>";
		const char *illegal_characters = "<>";

		char progress_string[ CStringHelper::string_buffer_length ];

		assert( !m_context_stack.empty() );
		assert( fmt );

		{
			va_list argp;
			va_start( argp, fmt );
			vsprintf_s( progress_string, CStringHelper::string_buffer_length, fmt, argp );
			va_end(argp);
		}

		INTEGRA_TRACE_VERBOSE << "luascript output: " << progress_string;

		/* replace illegal characters with space, to prevent invalid html */
		int progress_string_length = strlen( progress_string );
		for( int i = 0; i < progress_string_length; i++ )
		{
			if( strchr( illegal_characters, progress_string[ i ] ) != NULL )
			{
				progress_string[ i ] = ' ';
			}
		}

		color = MAX( 0, MIN( 0xffffff, color ) );

		CLuaContext *context = m_context_stack.back();

		char *new_output = new char[ context->m_output.length() + strlen( progress_template ) + strlen( progress_string ) + 7 ];
		sprintf( new_output, progress_template, context->m_output.c_str(), color, progress_string );

		context->m_output = new_output;
		delete []new_output;
	}


	string CLuaEngine::build_init_script( const CServer &server, const CPath &parent_path )
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

		string init_script;
	
		for( int i = 0; *helper_functions[ i ] != 0; i++ )
		{
			init_script += helper_functions[ i ];
			init_script += "\n";
		}

		const INode *parent_node = server.find_node( parent_path );
		const node_map &child_nodes = parent_node ? parent_node->get_children() : m_server->get_nodes();
	
		declare_child_objects( init_script, child_nodes, parent_path );
		declare_child_metatables( init_script, child_nodes, parent_path );
		init_script += global_metatable;

		return init_script;
	}


	void CLuaEngine::declare_child_objects( string &init_script, const node_map &children, const CPath &parent_path ) const
	{
		const string &child_initializer = "={}\n";

		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			//declare child object
			const INode *child = i->second;
			string child_declaration = get_lua_object_name( child->get_path(), parent_path );

			child_declaration += child_initializer;

			init_script += child_declaration;

			declare_child_objects( init_script, child->get_children(), parent_path );
		}
	}


	string CLuaEngine::get_child_metatable( const INode &node, const CPath &parent_path ) const
	{
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

		string object_name = get_lua_object_name( node_path, parent_path );
		string parameter_string = get_lua_parameter_string( node_path, parent_path );

		char *metatable = new char[ strlen( metatable_template ) + object_name.length() + parameter_string.length() * 2 + 1 ];
		sprintf( metatable, metatable_template, object_name.c_str(), parameter_string.c_str(), parameter_string.c_str() );

		string result( metatable );
		delete metatable;
		return result;
	}


	void CLuaEngine::declare_child_metatables( string &init_script, const node_map &children, const CPath &parent_path ) const
	{
		for( node_map::const_iterator i = children.begin(); i != children.end(); i++ )
		{
			const INode *child = i->second;

			string child_metatable = get_child_metatable( *child, parent_path );

			init_script += child_metatable;

			declare_child_metatables( init_script, child->get_children(), parent_path );
		}
	}


	string CLuaEngine::get_lua_object_name( const CPath &child_path, const CPath &parent_path ) const
	{
		int child_elements = child_path.get_number_of_elements();
		int parent_elements = parent_path.get_number_of_elements();

		assert( child_elements > parent_elements );

		string object_name;

		for( int i = parent_elements; i < child_elements; i++ )
		{
			const string &path_element = child_path[ i ];
			if( object_name.empty() )
			{
				object_name = path_element;
			}
			else
			{
				object_name += ( "[\"" + path_element + "\"]" );
			}
		}
	
		return object_name;
	}


	string CLuaEngine::get_lua_parameter_string( const CPath &child_path, const CPath &parent_path ) const
	{
		int child_elements = child_path.get_number_of_elements();
		int parent_elements = parent_path.get_number_of_elements();

		assert( child_elements > parent_elements );

		string parameter_string;

		for( int i = parent_elements; i < child_elements; i++ )
		{
			const string &path_element = child_path[ i ];

			parameter_string += ( "\"" + path_element + "\", " );
		}
	
		return parameter_string;
	}


	CLuaEngine *CLuaEngine::from_lua_state( lua_State *state )
	{
		lua_pushstring( state, self_key.c_str() );  
		lua_gettable( state, LUA_REGISTRYINDEX );  
		CLuaEngine *self = ( CLuaEngine * ) lua_touserdata( state, -1 );  

		assert( self );
		return self;
	}


	static int set_callback( lua_State *state )
	{
		return CLuaEngine::from_lua_state( state )->handle_set( state );
	}


	static int get_callback( lua_State *state )
	{
		return CLuaEngine::from_lua_state( state )->handle_get( state );
	}


	static int print_callback( lua_State *state )
	{
		return CLuaEngine::from_lua_state( state )->handle_print( state );
	}


}
