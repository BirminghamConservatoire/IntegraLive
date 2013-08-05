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


#include "error.h"
#include "node.h"
#include "module_manager.h"


namespace ntg_internal
{
	class CModuleManager;
}


ntg_api::CError ntg_file_load( const char *filename, const ntg_internal::CNode *parent, ntg_internal::CModuleManager &module_manager, ntg_api::guid_set &new_embedded_module_ids );

ntg_api::CError ntg_file_save( const char *filename, const ntg_internal::CNode &node, const ntg_internal::CModuleManager &module_manager );


void ntg_copy_directory_contents_to_zip( zipFile zip_file, const ntg_api::string &target_path, const ntg_api::string &source_path );



#endif /*INTEGRA_FILE_IO_H*/
