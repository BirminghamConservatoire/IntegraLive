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

#ifndef INTEGRA_DATA_DIRECTORY_H
#define INTEGRA_DATA_DIRECTORY_H

#include "../externals/minizip/zip.h"
#include "../externals/minizip/unzip.h"

#include "error.h"
#include "api/common_typedefs.h"

namespace ntg_api
{
	class CPath;
}


namespace ntg_internal
{
	class CNode;
	class CNodeEndpoint;
	class CServer;

	class CDataDirectory
	{
		public:
			static ntg_api::string create_for_node( const CNode &node, const CServer &server );

			static void change( const ntg_api::string &old_directory, const ntg_api::string &new_directory );

			static void copy_to_zip( zipFile zip_file, const CNode &node, const ntg_api::CPath &path_root );

			static ntg_api::error_code extract_from_zip( const ntg_api::string &file_path, const CNode *parent_node );

			static ntg_api::string copy_file_to_data_directory( const CNodeEndpoint &node_endpoint );

		private:

			static ntg_api::string get_relative_node_path( const CNode &node, const ntg_api::CPath &root );

			static ntg_api::string get_node_directory_path_in_zip( unzFile unzip_file );

			static void extract_from_zip_to_data_directory( unzFile unzip_file, unz_file_info *file_info, const CNode &node, const char *relative_file_path );

			static bool does_zip_contain_directory( unzFile unzip_file, const ntg_api::string &directory );
	};
}


#if 0 //deprecated 


ntg_api::string ntg_node_data_directory_create( const ntg_internal::CNode &node, const ntg_internal::CServer &server );
void ntg_node_data_directory_change( const char *previous_directory_name, const char *new_directory_name );

void ntg_copy_node_data_directories_to_zip( zipFile zip_file, const ntg_internal::CNode &node, const ntg_api::CPath &path_root );


ntg_api::error_code ntg_load_data_directories( const char *file_path, const ntg_internal::CNode *parent_node );

const char *ntg_copy_file_to_data_directory( const ntg_internal::CNodeEndpoint *node_endpoint );

const char *ntg_extract_filename_from_path( const char *path );


#endif

#endif /*INTEGRA_DATA_DIRECTORY_H*/
