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

#include "scratch_directory.h"
#include "file_io.h"
#include "file_helper.h"
#include "string_helper.h"


#include <assert.h>
#ifdef _WINDOWS
#include <direct.h>
#else
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#define mkdir(x) mkdir(x, 0777)
#endif
#include <dirent.h>


using namespace ntg_internal;



namespace ntg_internal
{
	const string CScratchDirectory::scratch_directory_root_name = "libIntegra";

	CScratchDirectory::CScratchDirectory()
	{
		#ifdef _WINDOWS

			char path_buffer[ CStringHelper::string_buffer_length ];
			int i;
			GetTempPathA( CStringHelper::string_buffer_length, path_buffer );

			/* replace windows slashes with unix slashes */
			for( i = strlen( path_buffer ) - 1; i >= 0; i-- )
			{
				if( path_buffer[ i ] == '\\' )
				{
					path_buffer[ i ] = '/';
				}
			}

			m_scratch_directory = path_buffer;

		#else

			const char *tmp_dir = getenv( "TMPDIR" );
			if( tmp_dir )
			{
				m_scratch_directory = string( tmp_dir ) + CFileIO::path_separator + ".";
			}
			else
			{
				m_scratch_directory = "~/.";
			}
		#endif
	
			m_scratch_directory += scratch_directory_root_name;

			if( CFileHelper::is_directory( m_scratch_directory ) )
			{
				CFileHelper::delete_directory( m_scratch_directory );
			}

			m_scratch_directory += CFileIO::path_separator;

			mkdir( m_scratch_directory.c_str() );
	}


	CScratchDirectory::~CScratchDirectory()
	{
		CFileHelper::delete_directory( m_scratch_directory );
	}


}

