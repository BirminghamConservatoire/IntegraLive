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


#include "Integra/integra.h"
#include "node.h"
#include "module_manager.h"



#ifndef ntg_module_manager
//typedef struct ntg_module_manager_ ntg_module_manager;
#endif



ntg_command_status ntg_file_load( const char *filename, const ntg_node *parent, ntg_module_manager *module_manager );

ntg_error_code ntg_file_save( const char *filename, const ntg_node *node, const ntg_module_manager *module_manager );


void ntg_copy_directory_contents_to_zip( zipFile zip_file, const char *target_path, const char *source_path );

ntg_error_code ntg_copy_file( const char *source_path, const char *target_path );
ntg_error_code ntg_delete_file( const char *file_name );


#endif /*INTEGRA_FILE_IO_H*/
