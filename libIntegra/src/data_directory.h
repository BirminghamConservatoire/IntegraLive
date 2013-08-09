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

using namespace ntg_api;

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
			static string create_for_node( const CNode &node, const CServer &server );

			static void change( const string &old_directory, const string &new_directory );

			static void copy_to_zip( zipFile zip_file, const CNode &node, const CPath &path_root );

			static CError extract_from_zip( const string &file_path, const CNode *parent_node );

			static string copy_file_to_data_directory( const CNodeEndpoint &input_file );

		private:

			static string get_relative_node_path( const CNode &node, const CPath &root );

			static string get_node_directory_path_in_zip( unzFile unzip_file );

			static void extract_from_zip_to_data_directory( unzFile unzip_file, unz_file_info *file_info, const CNode &node, const char *relative_file_path );

			static bool does_zip_contain_directory( unzFile unzip_file, const string &directory );

			static void copy_directory_contents_to_zip( zipFile zip_file, const string &target_path, const string &source_path );

			static const string s_node_directory;
	};
}


#endif /*INTEGRA_DATA_DIRECTORY_H*/
