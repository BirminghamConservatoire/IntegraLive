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


#ifndef INTEGRA_LUA_H
#define INTEGRA_LUA_H

#include "api/common_typedefs.h"
#include "node.h"

extern "C"
{
#include "lua.h"
}


namespace integra_api
{
	class CPath;
}


namespace integra_internal
{
	class CServer;
    
	static int set_callback( lua_State *state );
    static int get_callback( lua_State *state );
    static int print_callback( lua_State *state );
    
	class CLuaEngine
	{
		public:
			CLuaEngine();
			~CLuaEngine();

			string run_script( CServer &server, const CPath &parent_path, const string &script_string );

		private:

            friend int set_callback( lua_State *state );
            friend int get_callback( lua_State *state );
            friend int print_callback( lua_State *state );

			int handle_set( lua_State *state );
			int handle_get( lua_State *state );
			int handle_print( lua_State *state );

			const char *get_string( lua_State *state, int argnum );
			float get_float( lua_State *state, int argnum );

			static CLuaEngine *from_lua_state( lua_State *state );

			lua_State *create_state( const CServer &server, const CPath &parent_path );
			string build_init_script( const CServer &server, const CPath &parent_path );

			void error_handler( const char *fmt, ... );
			void output_handler( unsigned int color, const char *fmt, ... );

			void declare_child_objects( string &init_script, const node_map &children, const CPath &parent_path ) const;
			string get_child_metatable( const INode &node, const CPath &parent_path ) const;
			void declare_child_metatables( string &init_script, const node_map &children, const CPath &parent_path ) const;
			string get_lua_object_name( const CPath &child_path, const CPath &parent_path ) const;
			string get_lua_parameter_string( const CPath &child_path, const CPath &parent_path ) const;

			class CLuaContext
			{
				public:
					const CPath *m_parent_path;
					string m_output;
			};

			typedef std::list<CLuaContext *> lua_context_list;

			lua_context_list m_context_stack;
			CServer *m_server;


			static const unsigned int error_color;
			static const unsigned int set_color;
			static const unsigned int get_color;
			static const unsigned int print_color;

			static const string self_key;
	};
}






#endif