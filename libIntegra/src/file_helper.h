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
#include "error.h"


namespace ntg_internal
{
	class CFileHelper
	{
		public:
			static ntg_api::string extract_filename_from_path( const ntg_api::string &path );

			static ntg_api::string extract_first_directory_from_path( const ntg_api::string &path );

			static ntg_api::string ensure_filename_has_suffix( const ntg_api::string &filename, const ntg_api::string &suffix );


			static bool is_directory( const ntg_api::string &directory_name );
			static void delete_directory( const ntg_api::string &directory_name );

			static ntg_api::CError copy_file( const ntg_api::string &source_path, const ntg_api::string &target_path );
			static ntg_api::CError delete_file( const ntg_api::string &file_name );

			static void construct_subdirectories( const ntg_api::string &root_directory, const ntg_api::string &relative_file_path );

	};
}



#endif /*INTEGRA_FILE_HELPERS_H*/
