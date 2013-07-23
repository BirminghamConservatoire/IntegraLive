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


#include "server.h"

namespace ntg_internal
{
	class CNode;
}


char *ntg_node_data_directory_create( const ntg_internal::CNode &node, const ntg_server *server );
void ntg_node_data_directory_change( const char *previous_directory_name, const char *new_directory_name );

void ntg_copy_node_data_directories_to_zip( zipFile zip_file, const ntg_internal::CNode &node, const ntg_api::CPath &path_root );


ntg_error_code ntg_load_data_directories( const char *file_path, const ntg_internal::CNode *parent_node );

const char *ntg_copy_file_to_data_directory( const ntg_internal::CNodeEndpoint *node_endpoint );

const char *ntg_extract_filename_from_path( const char *path );



#endif /*INTEGRA_DATA_DIRECTORY_H*/
