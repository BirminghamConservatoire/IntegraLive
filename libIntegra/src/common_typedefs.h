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


#ifndef INTEGRA_COMMON_TYPEDEFS
#define INTEGRA_COMMON_TYPEDEFS

#include <sstream>
#include <string>
#include <string>
#include <unordered_set>

#include "../externals/guiddef.h"

#include "MurmurHash2.h"



namespace ntg_api
{
	/* Strings */
	typedef std::ostringstream ostringstream;
	typedef std::string string;
	typedef std::vector<string> string_vector;


	/* Guids */ 
	struct GuidHash 
	{
	  size_t operator()(const GUID& x) const { return MurmurHash2( &x, sizeof( GUID ), 53 ); }
	};


	typedef std::unordered_set<GUID, GuidHash> guid_set;
};




namespace ntg_internal
{
	typedef enum ntg_command_source_ {
		NTG_SOURCE_NONE = -1,
		NTG_SOURCE_INITIALIZATION,
		NTG_SOURCE_LOAD,
		NTG_SOURCE_SYSTEM,
		NTG_SOURCE_CONNECTION,
		NTG_SOURCE_HOST,
		NTG_SOURCE_SCRIPT,
		NTG_SOURCE_XMLRPC_API,
		NTG_SOURCE_OSC_API,
		NTG_SOURCE_C_API,
		NTG_COMMAND_SOURCE_end
	} ntg_command_source;




}




#endif /* INTEGRA_COMMON_TYPEDEFS */