/* libIntegra modular audio framework
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

/** \file common_typedefs.h
 *  \brief #defines and typedefs used throughout the application

	This file defines widely used standard library collection classes, for enhanced code readability 
	
	It also defines macros for windows DLL import/export qualifiers
 */



#ifndef INTEGRA_COMMON_TYPEDEFS
#define INTEGRA_COMMON_TYPEDEFS

#include <sstream>
#include <string>
#include <vector>
#include <unordered_set>
#include <unordered_map>

#include "../externals/guiddef.h"


#ifdef _WINDOWS
	#ifdef LIBINTEGRA_EXPORTS	
		#define INTEGRA_API __declspec(dllexport)
	#else
		#define INTEGRA_API __declspec(dllimport)
	#endif
#else
	#define INTEGRA_API 
#endif


namespace integra_api
{
	/* Strings */
	typedef std::ostringstream ostringstream;
	typedef std::string string;
	typedef std::vector<string> string_vector;
	typedef std::unordered_set<string> string_set;
	typedef std::unordered_map<string, string> string_map;

	/* others */
	typedef std::vector<int> int_vector;
	typedef std::vector<float> float_vector;
	typedef std::unordered_set<int> int_set;
	typedef std::unordered_map<int, int> int_map;
};



#endif /* INTEGRA_COMMON_TYPEDEFS */