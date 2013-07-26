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

#ifndef INTEGRA_SCRATCH_DIRECTORY_H
#define INTEGRA_SCRATCH_DIRECTORY_H

#include "api/common_typedefs.h"


namespace ntg_internal
{
	class CScratchDirectory
	{
		public:

			CScratchDirectory();
			~CScratchDirectory();

			const ntg_api::string &get_scratch_directory() { return m_scratch_directory; }

		private:

			ntg_api::string m_scratch_directory;
	};
}


#if 0 //DEPRECATED 
void ntg_scratch_directory_initialize( ntg_internal::CServer &server );
void ntg_scratch_directory_free( ntg_internal::CServer &server );

bool ntg_is_directory( const char *directory_name );
void ntg_delete_directory( const char *directory_name );

void ntg_construct_subdirectories( const char *root_directory, const char *relative_file_path );


#endif	/*deprecated */



#endif /* INTEGRA_SCRATCH_DIRECTORY_H */
