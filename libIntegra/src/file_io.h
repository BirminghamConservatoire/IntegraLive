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

#ifndef INTEGRA_FILE_IO_H
#define INTEGRA_FILE_IO_H


#include "api/common_typedefs.h"
#include "api/guid_helper.h"
#include "api/error.h"
#include "node.h"

#include "../externals/minizip/zip.h"
#include <libxml/xmlreader.h>
#include <libxml/xmlwriter.h>

using namespace integra_api;

namespace integra_internal
{
	class CServer;
	class CModuleManager;
	class CInterfaceDefinition;
	class CDspEngine;


	class CFileIO
	{
		public:

			static CError load( CServer &server, const string &filename, const CNode *parent, guid_set &new_embedded_module_ids );
			static CError save( const CServer &server, const string &filename, const CNode &node );

			static void copy_file_to_zip( zipFile zip_file, const string &target_path, const string &source_path );

			static const char path_separator;
			static const string file_suffix;

			static const int data_copy_buffer_size;
			static const string internal_ixd_file_name;
			static const string data_directory_name;
			static const string implementation_directory_name;


		private:

			static CError load_ixd_buffer( const string &file_path, unsigned char **ixd_buffer, unsigned int *ixd_buffer_length, bool *is_zip_file );
			static CError load_ixd_buffer_directly( const string &file_path, unsigned char **ixd_buffer, unsigned int *ixd_buffer_length );

			static CError load_nodes( CServer &server, const CNode *node, xmlTextReaderPtr reader, node_list &loaded_nodes );
			static CError send_loaded_values_to_module( const CNode &node, CDspEngine &dsp_engine );
			static string get_top_level_node_name( const string &filename );

			static const CInterfaceDefinition *find_interface( xmlTextReaderPtr reader, const CModuleManager &module_manager );
			static bool is_saved_version_newer_than_current( const CServer &server, const string &saved_version );

			static CError save_nodes( const CServer &server, const CNode &node, unsigned char **buffer, unsigned int *buffer_length );
			static void copy_node_modules_to_zip( zipFile zip_file, const CNode &node, const CModuleManager &module_manager );
			static CError save_node_tree( const CNode &node, xmlTextWriterPtr writer );
			static void find_module_guids_to_embed( const CNode &node, guid_set &module_guids_to_embed );

			static xmlChar *CFileIO::convert_input( const string &in, const string &encoding );

			static void init_zip_file_info( zip_fileinfo *info );

			typedef std::unordered_map<internal_id, value_map *> map_id_to_value_map;


			static const string xml_encoding;

			static const string integra_collection;
			static const string integra_version;
			static const string object;
			static const string attribute;
			static const string module_id;
			static const string origin_id;
			static const string name_attribute;
			static const string type_code;

			//used in older versions
			static const string instance_id;
			static const string class_id;
	};
}



#endif /*INTEGRA_FILE_IO_H*/
