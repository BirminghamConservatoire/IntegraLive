/** libIntegra multimedia module interface
 *
 * Copyright (C) 2012 Birmingham City University
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

#include <assert.h>
#ifdef _WINDOWS
#include <direct.h>
#else
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#define mkdir(x) mkdir(x, 0777)
#endif
#include <dirent.h>

#include "file_helpers.h"

using namespace ntg_api;

namespace ntg_internal
{
	string CFileHelpers::extract_filename_from_path( const string &path )
	{
		size_t last_slash = path.find_last_of( '/' );
		size_t last_backslash = path.find_last_of( '\\' );

		size_t filename_start = ( last_slash == string::npos ) ? 0 : last_slash + 1;

		if( last_backslash != string::npos )
		{
			filename_start = MAX( filename_start, last_backslash + 1 );
		}

		return path.substr( filename_start );
	}


	string CFileHelpers::extract_first_directory_from_path( const string &path )
	{
		size_t first_slash = path.find_first_of( '/' );
		size_t first_backslash = path.find_first_of( '\\' );

		if( first_slash == string::npos )
		{
			if( first_backslash == string::npos )
			{
				return string();
			}
			else
			{
				return path.substr( 0, first_backslash );
			}
		}
		else
		{
			if( first_backslash == string::npos )
			{
				return path.substr( 0, first_slash );
			}
			else
			{
				return path.substr( 0, MIN( first_slash, first_backslash ) );
			}
		}
	}


}