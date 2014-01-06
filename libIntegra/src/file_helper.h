/* libIntegra multimedia module interface
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

#ifndef INTEGRA_FILE_HELPERS_H
#define INTEGRA_FILE_HELPERS_H


#include "api/common_typedefs.h"
#include "api/error.h"


using namespace integra_api;


namespace integra_internal
{
	class CFileHelper
	{
		public:
			static string extract_filename_from_path( const string &path );
			static string extract_directory_from_path( const string &path );
			static string extract_first_directory_from_path( const string &path );
			static string extract_suffix_from_path( const string &path );

			static string ensure_filename_has_suffix( const string &filename, const string &suffix );


			static bool is_directory( const string &directory_name );
			static void delete_directory( const string &directory_name );

			static bool file_exists( const string &file_name );
			static CError copy_file( const string &source_path, const string &target_path );
			static CError delete_file( const string &file_name );

			static void construct_subdirectories( const string &root_directory, const string &relative_file_path );
	};
}



#endif /*INTEGRA_FILE_HELPERS_H*/
