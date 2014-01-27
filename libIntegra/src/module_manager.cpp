/* libIntegra modular audio framework
 *
 * Copyright (C) 2007 Birmingham City University
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

#include <assert.h>
#include <dirent.h>

#ifdef _WINDOWS
#include <direct.h>
#else
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#define mkdir(x) mkdir(x, 0777)
#endif

#include "module_manager.h"
#include "scratch_directory.h"
#include "interface_definition.h"
#include "api/trace.h"
#include "file_io.h"
#include "file_helper.h"
#include "api/guid_helper.h"
#include "server.h"
#include "interface_definition_loader.h"
#include "file_io.h"
#include "MurmurHash2.h"
#include "api/string_helper.h"

using namespace integra_api;


#ifndef _WINDOWS
#include <sys/stat.h>
#define _S_IFMT S_IFMT
#endif


namespace integra_internal
{
	const string CModuleManager::module_suffix = "module";


	const string CModuleManager::module_inner_directory_name = "integra_module_data/";
	const string CModuleManager::idd_file_name = "integra_module_data/interface_definition.iid";
	const string CModuleManager::internal_implementation_directory_name =  "integra_module_data/implementation/";

	const string CModuleManager::implementation_directory_name = "implementations/";
	const string CModuleManager::embedded_module_directory_name = "loaded_embedded_modules/";

	const string CModuleManager::legacy_class_id_filename = "id2guid.csv";

	const int CModuleManager::checksum_seed = 53;


	CModuleManager::CModuleManager( const CServer &server, const string &system_module_directory, const string &third_party_module_directory )
		:	m_server( server )
	{
		load_legacy_module_id_file();

		string scratch_directory_root = server.get_scratch_directory();
		m_implementation_directory_root = scratch_directory_root + implementation_directory_name;

		if( !CFileHelper::is_directory( m_implementation_directory_root.c_str() ) )
		{
			mkdir( m_implementation_directory_root.c_str() );
		}

		m_embedded_module_directory = scratch_directory_root + embedded_module_directory_name;

		if( !CFileHelper::is_directory( m_embedded_module_directory.c_str() ) )
		{
			mkdir( m_embedded_module_directory.c_str() );
		}

		load_modules_from_directory( system_module_directory, CInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA );

		load_modules_from_directory( third_party_module_directory, CInterfaceDefinition::MODULE_3RD_PARTY );
		m_third_party_module_directory = third_party_module_directory + CFileIO::path_separator;
	}


	CModuleManager::~CModuleManager()
	{
		unload_all_modules();

		CFileHelper::delete_directory( m_implementation_directory_root.c_str() );

		CFileHelper::delete_directory( m_embedded_module_directory.c_str() );
	}


	CModuleManager &CModuleManager::downcast( IModuleManager &module_manager )
	{
		return dynamic_cast<CModuleManager &>( module_manager );
	}


	CError CModuleManager::load_from_integra_file( const string &integra_file, guid_set &new_embedded_modules )
	{
		unzFile unzip_file;
		unz_file_info file_info;
		char file_name[ CStringHelper::string_buffer_length ];
		char *temporary_file_name;
		FILE *temporary_file;
        string::size_type implementation_directory_length;
		unsigned char *copy_buffer;
		int bytes_read;
		int total_bytes_read;
		int bytes_remaining;
		GUID loaded_module_id;
		CError CError = CError::SUCCESS;

		new_embedded_modules.clear();

		unzip_file = unzOpen( integra_file.c_str() );
		if( !unzip_file )
		{
			INTEGRA_TRACE_ERROR << "Couldn't open zip file: " << integra_file;
			return CError::FAILED;
		}

		implementation_directory_length = CFileIO::implementation_directory_name.length();

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			INTEGRA_TRACE_ERROR << "Couldn't iterate contents: " << integra_file;
			unzClose( unzip_file );
			return CError::FAILED;
		}

		copy_buffer = new unsigned char[ CFileIO::data_copy_buffer_size ];

		do
		{
			temporary_file_name = NULL;
			temporary_file = NULL;

			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name, CStringHelper::string_buffer_length, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				INTEGRA_TRACE_ERROR << "Couldn't extract file info: " << integra_file;
				continue;
			}

			if( strlen( file_name ) <= implementation_directory_length || string( file_name ).substr( 0, implementation_directory_length ) != CFileIO::implementation_directory_name )
			{
				/* skip file not in node directory */
				continue;
			}

			temporary_file_name = tempnam( m_server.get_scratch_directory().c_str(), "embedded_module" );
			if( !temporary_file_name )
			{
				INTEGRA_TRACE_ERROR << "couldn't generate temporary filename";
				CError = CError::FAILED;
				continue;
			}

			temporary_file = fopen( temporary_file_name, "wb" );
			if( !temporary_file )
			{
				INTEGRA_TRACE_ERROR << "couldn't open temporary file: " << temporary_file_name;
				CError = CError::FAILED;
				goto CLEANUP;
			}

			if( unzOpenCurrentFile( unzip_file ) != UNZ_OK )
			{
				INTEGRA_TRACE_ERROR << "couldn't open zip contents: " << file_name;
				CError = CError::FAILED;
				goto CLEANUP;
			}

			total_bytes_read = 0;
			while( total_bytes_read < file_info.uncompressed_size )
			{
				bytes_remaining = file_info.uncompressed_size - total_bytes_read;
				assert( bytes_remaining > 0 );

				bytes_read = unzReadCurrentFile( unzip_file, copy_buffer, MIN( CFileIO::data_copy_buffer_size, bytes_remaining ) );
				if( bytes_read <= 0 )
				{
					INTEGRA_TRACE_ERROR << "Error decompressing file";
					CError = CError::FAILED;
					goto CLEANUP;
				}

				fwrite( copy_buffer, 1, bytes_read, temporary_file );

				total_bytes_read += bytes_read;
			}

			fclose( temporary_file );
			temporary_file = NULL;

			if( load_module( temporary_file_name, CInterfaceDefinition::MODULE_EMBEDDED, loaded_module_id ) )
			{
				new_embedded_modules.insert( loaded_module_id );

				store_module( loaded_module_id );
			}

			CLEANUP:

			if( temporary_file )
			{
				fclose( temporary_file );
			}

			if( temporary_file_name )
			{
				CFileHelper::delete_file( temporary_file_name );
				delete[] temporary_file_name;
			}

			unzCloseCurrentFile( unzip_file );
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		unzClose( unzip_file );

		delete[] copy_buffer;

		return CError;
	}


	CError CModuleManager::install_module( const string &module_file, CModuleInstallResult &result )
	{
		bool module_was_loaded = false;
		GUID module_id = CGuidHelper::null_guid;
	
		memset( &result, 0, sizeof( CModuleInstallResult ) );

		module_was_loaded = load_module( module_file, CInterfaceDefinition::MODULE_3RD_PARTY, module_id );
		if( module_was_loaded )
		{
			result.module_id = module_id;
			return store_module( module_id );
		}

        
        if (CGuidHelper::guid_is_null(module_id))
        {
			return CError::FILE_VALIDATION_ERROR;
		}

		const CInterfaceDefinition *existing_interface = get_interface_by_module_id( module_id );
		if( !existing_interface )
		{
			INTEGRA_TRACE_ERROR << "can't lookup existing interface";
			return CError::FAILED;
		}

		switch( existing_interface->get_module_source() )
		{
			case CInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA:
			case CInterfaceDefinition::MODULE_3RD_PARTY:
			case CInterfaceDefinition::MODULE_IN_DEVELOPMENT:
				return CError::MODULE_ALREADY_INSTALLED;

			case CInterfaceDefinition::MODULE_EMBEDDED:
				result.module_id = module_id;
				result.was_previously_embedded = true;
				return change_module_source( ( CInterfaceDefinition & ) *existing_interface, CInterfaceDefinition::MODULE_3RD_PARTY );

			default:

				INTEGRA_TRACE_ERROR << "existing interface has unexpected module source";
				return CError::FAILED;
		}
	}


	CError CModuleManager::install_embedded_module( const GUID &module_id )
	{
		const CInterfaceDefinition *interface_definition = get_interface_by_module_id( module_id );
		if( !interface_definition )
		{
			INTEGRA_TRACE_ERROR << "Can't find interface";
			return CError::INPUT_ERROR;
		}

		if( interface_definition->get_module_source() != CInterfaceDefinition::MODULE_EMBEDDED )
		{
			INTEGRA_TRACE_ERROR << "Module isn't embedded";
			return CError::INPUT_ERROR;
		}

		return change_module_source( ( CInterfaceDefinition & ) *interface_definition, CInterfaceDefinition::MODULE_3RD_PARTY );
	}


	CError CModuleManager::uninstall_module( const GUID &module_id, CModuleUninstallResult &result )
	{
		CError CError = CError::SUCCESS;

		result.remains_as_embedded = false;

		const CInterfaceDefinition *interface_definition = get_interface_by_module_id( module_id );
		if( !interface_definition )
		{
			INTEGRA_TRACE_ERROR << "Can't find interface";
			return CError::INPUT_ERROR;
		}

		if( interface_definition->get_module_source() != CInterfaceDefinition::MODULE_3RD_PARTY )
		{
			INTEGRA_TRACE_ERROR << "Can't uninstall module - it is not a 3rd party module";
			return CError::INPUT_ERROR;
		}

		if( is_module_in_use( m_server.get_nodes(), module_id ) )
		{
			result.remains_as_embedded = true;
			return change_module_source( ( CInterfaceDefinition & ) *interface_definition, CInterfaceDefinition::MODULE_EMBEDDED );
		}

		result.remains_as_embedded = false;

		CError = CFileHelper::delete_file( interface_definition->get_file_path() );
		if( CError != CError::SUCCESS )
		{
			return CError;
		}

		unload_module( ( CInterfaceDefinition * ) interface_definition );
		return CError::SUCCESS;
	}


	CError CModuleManager::load_module_in_development( const string &module_file, CLoadModuleInDevelopmentResult &result )
	{
		for( map_guid_to_interface_definition::const_iterator i = m_module_id_map.begin(); i != m_module_id_map.end(); i++ )
		{
			CInterfaceDefinition &interface_definition = CInterfaceDefinition::downcast_writable( *i->second );

			if( interface_definition.get_module_source() != CInterfaceDefinition::MODULE_IN_DEVELOPMENT )
			{
				continue;
			}

            if ( CGuidHelper::guid_is_null( result.previous_module_id ) )
			{
				result.previous_module_id = interface_definition.get_module_guid();

				if( is_module_in_use( m_server.get_nodes(), interface_definition.get_module_guid() ) )
				{
					change_module_source( interface_definition, CInterfaceDefinition::MODULE_EMBEDDED );
					result.previous_remains_as_embedded = true;
				}
				else
				{
					unload_module( &interface_definition );
				}
			}
			else
			{
				INTEGRA_TRACE_ERROR << "Encountered more than one in-development module!";
				return CError::FAILED;
			}
		}

		return CError::SUCCESS;
	}

	
	const guid_set &CModuleManager::get_all_module_ids() const
	{
		return m_module_ids;
	}


	const CInterfaceDefinition *CModuleManager::get_interface_by_module_id( const GUID &id ) const
	{
		map_guid_to_interface_definition::const_iterator lookup = m_module_id_map.find( id );
		if( lookup == m_module_id_map.end() ) 
		{
			return NULL;
		}
		else
		{
			return CInterfaceDefinition::downcast( lookup->second );
		}
	}


	const CInterfaceDefinition *CModuleManager::get_interface_by_origin_id( const GUID &id ) const
	{
		map_guid_to_interface_definition::const_iterator lookup = m_origin_id_map.find( id );
		if( lookup == m_origin_id_map.end() ) 
		{
			return NULL;
		}
		else
		{
			return CInterfaceDefinition::downcast( lookup->second );
		}
	}


	const CInterfaceDefinition *CModuleManager::get_core_interface_by_name( const string &name ) const
	{
		map_string_to_interface_definition::const_iterator lookup = m_core_name_map.find( name );
		if( lookup == m_core_name_map.end() ) 
		{
			return NULL;
		}
		else
		{
			return CInterfaceDefinition::downcast( lookup->second );
		}
	}


	string CModuleManager::get_unique_interface_name( const CInterfaceDefinition &interface_definition ) const
	{
		string module_guid = CGuidHelper::guid_to_string( interface_definition.get_module_guid() );

		ostringstream unique_name;
		unique_name << interface_definition.get_interface_info().get_name() << "-" << module_guid;

		return unique_name.str();
	}


	string CModuleManager::get_patch_path( const CInterfaceDefinition &interface_definition ) const
	{
		const string patch_extension = ".pd";

		const CImplementationInfo *implementation_info = CImplementationInfo::downcast( interface_definition.get_implementation_info() );

		assert( implementation_info && !implementation_info->get_patch_name().empty() );

		string implementation_path = get_implementation_path( interface_definition ) + implementation_info->get_patch_name();

		/* chop off patch extension */
		int implementation_path_length = implementation_path.length() - patch_extension.length();
		if( implementation_path_length <= 0 || implementation_path.substr( implementation_path_length ) != patch_extension )
		{
			INTEGRA_TRACE_ERROR << "Implementation path doesn't end in correct patch extension: " << implementation_path;
			return NULL;
		}

		return implementation_path.substr( 0, implementation_path_length );
	}


	CError CModuleManager::unload_unused_embedded_modules()
	{
		guid_set module_ids;
		/* first pass - collect ids of all embedded modules */
		for( map_guid_to_interface_definition::const_iterator i = m_module_id_map.begin(); i != m_module_id_map.end(); i++ )
		{
			const IInterfaceDefinition *interface_definition = i->second;

			if( interface_definition->get_module_source() == CInterfaceDefinition::MODULE_EMBEDDED )
			{
				module_ids.insert( interface_definition->get_module_guid() );
			}
		}

		/* second pass - walk node tree pruning any modules still in use */
		remove_in_use_module_ids_from_set( m_server.get_nodes(), module_ids );

		/* third pass - unload modules */
		unload_modules( module_ids );

		return CError::SUCCESS;
	}


	void CModuleManager::unload_modules( const guid_set &module_ids )
	{
		for( guid_set::const_iterator i = module_ids.begin(); i != module_ids.end(); i++ )
		{
			CInterfaceDefinition *interface_definition = ( CInterfaceDefinition * ) get_interface_by_module_id( *i );
			assert( interface_definition );

			unload_module( interface_definition );
		}
	}


	CError CModuleManager::interpret_legacy_module_id( internal_id old_id, GUID &output ) const
	{
		if( old_id >= m_legacy_module_id_table.size() )
		{
			INTEGRA_TRACE_ERROR << "Can't interpret class id: " << old_id;
			return CError::INPUT_ERROR;
		}

		output = m_legacy_module_id_table[ old_id ];

		return ( CGuidHelper::guid_is_null( output ) ) ? CError::INPUT_ERROR : CError::SUCCESS;
	}


	const CInterfaceDefinition *CModuleManager::get_inhouse_replacement_version( const CInterfaceDefinition &interface_definition ) const
	{
		const CInterfaceDefinition *best_version = get_interface_by_origin_id( interface_definition.get_origin_guid() );
		if( !best_version )
		{
			INTEGRA_TRACE_ERROR << "Can't find best version for moduleid: " << CGuidHelper::guid_to_string( interface_definition.get_module_guid() );
			return NULL;
		}

		if( !CGuidHelper::guids_are_equal( interface_definition.get_module_guid(), best_version->get_module_guid() ) )
		{
			const CInterfaceInfo &info = CInterfaceInfo::downcast( best_version->get_interface_info() );
			if( info.get_implemented_in_libintegra() )
			{
				return best_version;
			}
		}

		return NULL;
	}


	void CModuleManager::load_modules_from_directory( const string &module_directory, CInterfaceDefinition::module_source source )
	{
		DIR *directory_stream;
		struct dirent *directory_entry;
		const char *name;
		struct stat entry_data;
		GUID module_guid;

		directory_stream = opendir( module_directory.c_str() );
		if( !directory_stream )
		{
			INTEGRA_TRACE_ERROR << "unable to open directory: " << module_directory;
			return;
		}

		while( true )
		{
			directory_entry = readdir( directory_stream );
			if( !directory_entry )
			{
				break;
			}

			name = directory_entry->d_name;

			string full_path = module_directory + CFileIO::path_separator + name;

			if( stat( full_path.c_str(), &entry_data ) != 0 )
			{
				INTEGRA_TRACE_ERROR << "couldn't read directory entry data: " << strerror( errno );
				continue;
			}

			switch( entry_data.st_mode & _S_IFMT )
			{
				case S_IFDIR:	/* directory */
					continue;

				default:
					load_module( full_path, source, module_guid );
					break;
			}
		}
	}


	void CModuleManager::load_legacy_module_id_file()
	{
		char line[ CStringHelper::string_buffer_length ];
		FILE *file = NULL;
		const char *guid_as_string;
		internal_id old_id;
		GUID guid;

		m_legacy_module_id_table.clear();

		file = fopen( legacy_class_id_filename.c_str(), "r" );
		if( !file )
		{
			INTEGRA_TRACE_ERROR << "failed to open legacy class id file: " << legacy_class_id_filename;
			return;
		}

		while( !feof( file ) )
		{
			if( !fgets( line, CStringHelper::string_buffer_length, file ) )
			{
				break;
			}

			old_id = atoi( line );
			if( old_id == 0 )
			{
				INTEGRA_TRACE_ERROR << "Error reading old id from legacy class id file line " << line;
				continue;
			}

			guid_as_string = strchr( line, ',' );
			if( !guid_as_string )
			{
				INTEGRA_TRACE_ERROR << "Error reading guid from legacy class id file line: " << line;
				continue;
			}

			/* skip comma and space */
			guid_as_string += 2;	

			if( CGuidHelper::string_to_guid( guid_as_string, guid ) != CError::SUCCESS )
			{
				INTEGRA_TRACE_ERROR << "Error parsing guid: " << guid_as_string;
				continue;
			}

			for( int i = m_legacy_module_id_table.size(); i <= old_id; i++ )
			{
				m_legacy_module_id_table.push_back( CGuidHelper::null_guid ); 
			}

			m_legacy_module_id_table[ old_id ] = guid;
		}

		fclose( file );
	}


	/* 
	 CModuleManager::load_module only returns true if the module isn't already loaded
	 however, it stores the id of the loaded module in module_guid regardless of whether the module was already loaded
	*/

	bool CModuleManager::load_module( const string &filename, CInterfaceDefinition::module_source source, GUID &module_guid )
	{
		unzFile unzip_file;

		module_guid = CGuidHelper::null_guid;

		unzip_file = unzOpen( filename.c_str() );
		if( !unzip_file )
		{
			INTEGRA_TRACE_ERROR << "Unable to open zip: " << filename;
			return false;
		}

		CInterfaceDefinition *interface_definition = load_interface( unzip_file );
		if( !interface_definition ) 
		{
			INTEGRA_TRACE_ERROR << "Failed to load interface: " << filename;
			unzClose( unzip_file );
			return false;
		}

		module_guid = interface_definition->get_module_guid();

		if( m_module_id_map.count( module_guid ) > 0 )
		{
			INTEGRA_TRACE_VERBOSE << "Module already loaded: " << interface_definition->get_interface_info().get_name();
			delete interface_definition;
			unzClose( unzip_file );
			return false;
		}

		const CInterfaceInfo &interface_info = CInterfaceInfo::downcast( interface_definition->get_interface_info() );
		if( interface_info.get_implemented_in_libintegra() && source != CInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA )
		{
			INTEGRA_TRACE_ERROR << "Attempt to load 'implemented in libintegra' module as 3rd party or embedded: " << interface_definition->get_interface_info().get_name();
			delete interface_definition;
			unzClose( unzip_file );
			return false;
		}

		interface_definition->set_file_path( filename );
		interface_definition->set_module_source( source );

		m_module_id_map[ interface_definition->get_module_guid() ] = interface_definition;

		if( m_origin_id_map.count( interface_definition->get_origin_guid() ) > 0 )
		{
			INTEGRA_TRACE_VERBOSE << "Two modules with same origin!  Leaving original in origin->interface table: " << interface_definition->get_interface_info().get_name();
		}
		else
		{
			m_origin_id_map[ interface_definition->get_origin_guid() ] = interface_definition;
		}

		if( interface_definition->is_core_interface() )
		{
			const string &name = interface_definition->get_interface_info().get_name();
			if( m_core_name_map.count( name ) > 0 )
			{
				INTEGRA_TRACE_VERBOSE << "Two core modules with same name!  Leaving original in name->interface table: " << name;
			}
			else
			{
				m_core_name_map[ name ] = interface_definition;
			}
		}
	
		m_module_ids.insert( interface_definition->get_module_guid() );

		if( interface_definition->has_implementation() )
		{
			unsigned int checksum = 0;
			extract_implementation( unzip_file, *interface_definition, checksum );

			interface_definition->set_implementation_checksum( checksum );
		}

		unzClose( unzip_file );

		return true;
	}


	void CModuleManager::unload_all_modules()
	{
		/* take a copy, as the original will change as we delete */
		guid_set module_ids( m_module_ids );

		for( guid_set::const_iterator i = module_ids.begin(); i != module_ids.end(); i++ )
		{
			CInterfaceDefinition *interface_definition = ( CInterfaceDefinition * ) get_interface_by_module_id( *i );
			assert( interface_definition );

			unload_module( interface_definition );
		}

		assert( m_module_ids.empty() );
		assert( m_module_id_map.empty() );
		assert( m_origin_id_map.empty() );
		assert( m_core_name_map.empty() );
	}


	CInterfaceDefinition *CModuleManager::load_interface( unzFile unzip_file )
	{
		unz_file_info file_info;
		unsigned char *buffer = NULL;
		unsigned int buffer_size = 0;

		assert( unzip_file );

		if( unzLocateFile( unzip_file, idd_file_name.c_str(), 0 ) != UNZ_OK )
		{
			INTEGRA_TRACE_ERROR << "Unable to locate " << idd_file_name;
			return NULL;
		}

		if( unzGetCurrentFileInfo( unzip_file, &file_info, NULL, 0, NULL, 0, NULL, 0 ) != UNZ_OK )
		{
			INTEGRA_TRACE_ERROR << "Couldn't get info for " << idd_file_name;
			return NULL;
		}

		if( unzOpenCurrentFile( unzip_file ) != UNZ_OK )
		{
			INTEGRA_TRACE_ERROR << "Unable to open " << idd_file_name;
			return NULL;
		}

		buffer_size = file_info.uncompressed_size;
		buffer = new unsigned char[ buffer_size ];

		if( unzReadCurrentFile( unzip_file, buffer, buffer_size ) != buffer_size )
		{
			INTEGRA_TRACE_ERROR << "Unable to read " << idd_file_name;
			delete[] buffer;
			return NULL;
		}

		CInterfaceDefinitionLoader interface_definition_loader;
		CInterfaceDefinition *interface_definition = interface_definition_loader.load( *buffer, buffer_size );
		delete[] buffer;

		return interface_definition;
	}


	CError CModuleManager::extract_implementation( unzFile unzip_file, const CInterfaceDefinition &interface_definition, unsigned int &checksum )
	{
		assert( unzip_file );

		checksum = 0;

		string implementation_directory = get_implementation_path( interface_definition );

		if( CFileHelper::is_directory( implementation_directory.c_str() ) )
		{
			INTEGRA_TRACE_ERROR << "Can't extract module implementation - target directory already exists: " << implementation_directory;
			return CError::FAILED;
		}

		mkdir( implementation_directory.c_str() );

		if( unzGoToFirstFile( unzip_file ) != UNZ_OK )
		{
			INTEGRA_TRACE_ERROR << "Couldn't iterate contents";
			return CError::FAILED;
		}

		do
		{
			unz_file_info file_info;
			char file_name_buffer[ CStringHelper::string_buffer_length ];
			if( unzGetCurrentFileInfo( unzip_file, &file_info, file_name_buffer, CStringHelper::string_buffer_length, NULL, 0, NULL, 0 ) != UNZ_OK )
			{
				INTEGRA_TRACE_ERROR << "Couldn't extract file info";
				continue;
			}

			string file_name( file_name_buffer );

			if( file_name.substr( 0, internal_implementation_directory_name.length() ) != internal_implementation_directory_name )
			{
				/* skip files not in NTG_INTERNAL_IMPLEMENTATION_DIRECTORY_NAME */
				continue;
			}

			if( file_name.back() == CFileIO::path_separator )
			{
				/* skip directories */
				continue;
			}

			string relative_file_path = file_name.substr( internal_implementation_directory_name.length() );

			CFileHelper::construct_subdirectories( implementation_directory, relative_file_path );

			string target_path = implementation_directory + relative_file_path;

			checksum ^= MurmurHash2( relative_file_path.c_str(), relative_file_path.length(), checksum_seed );

			if( unzOpenCurrentFile( unzip_file ) == UNZ_OK )
			{
				FILE *output_file = fopen( target_path.c_str(), "wb" );
				if( output_file )
				{
					unsigned char *output_buffer = new unsigned char[ file_info.uncompressed_size ];

					if( unzReadCurrentFile( unzip_file, output_buffer, file_info.uncompressed_size ) != file_info.uncompressed_size )
					{
						INTEGRA_TRACE_ERROR << "Error decompressing file: " << file_name;
					}
					else
					{
						checksum ^= MurmurHash2( output_buffer, file_info.uncompressed_size, checksum_seed );

						fwrite( output_buffer, 1, file_info.uncompressed_size, output_file );
					}

					delete[] output_buffer;

					fclose( output_file );
				}
				else
				{
					INTEGRA_TRACE_ERROR << "Couldn't write to implementation file: " << target_path;
				}

				unzCloseCurrentFile( unzip_file );
			}
			else
			{
				INTEGRA_TRACE_ERROR << "couldn't open zip contents: " << file_name;
			}
		}
		while( unzGoToNextFile( unzip_file ) != UNZ_END_OF_LIST_OF_FILE );

		return CError::SUCCESS;
	}


	void CModuleManager::unload_module( CInterfaceDefinition *interface_definition )
	{
		assert( interface_definition );

		if( interface_definition->has_implementation() )
		{
			delete_implementation( *interface_definition );
		}

		if( interface_definition->get_module_source() == CInterfaceDefinition::MODULE_EMBEDDED )
		{
			CFileHelper::delete_file( interface_definition->get_file_path() );
		}

		m_module_id_map.erase( interface_definition->get_module_guid() );

		/* only remove origin id keys if the entry points to this interface */
		map_guid_to_interface_definition::const_iterator lookup = m_origin_id_map.find( interface_definition->get_origin_guid() );
		if( lookup != m_origin_id_map.end() )
		{
			if( lookup->second == interface_definition )
			{
				m_origin_id_map.erase( interface_definition->get_origin_guid() );
			}
		}

		if( interface_definition->is_core_interface() )
		{
			/* only remove from core name map if the entry points to this interface */
			map_string_to_interface_definition::const_iterator lookup = m_core_name_map.find( interface_definition->get_interface_info().get_name() );
			if( lookup != m_core_name_map.end() )
			{
				if( lookup->second == interface_definition )
				{
					m_core_name_map.erase( interface_definition->get_interface_info().get_name() );
				}
			}
		}

		/* remove from id set */
		m_module_ids.erase( interface_definition->get_module_guid() );

		delete interface_definition;
	}


	string CModuleManager::get_implementation_path( const CInterfaceDefinition &interface_definition ) const
	{
		return m_implementation_directory_root + get_implementation_directory_name( interface_definition );
	}


	string CModuleManager::get_implementation_directory_name( const CInterfaceDefinition &interface_definition ) const
	{
		return get_unique_interface_name( interface_definition ) + CFileIO::path_separator;
	}


	void CModuleManager::delete_implementation( const CInterfaceDefinition &interface_definition )
	{
		CFileHelper::delete_directory( get_implementation_path( interface_definition ).c_str() );
	}


	CError CModuleManager::store_module( const GUID &module_id )
	{
		CInterfaceDefinition *interface_definition;
		CError CError;

		interface_definition = ( CInterfaceDefinition * ) get_interface_by_module_id( module_id );
		if( !interface_definition )
		{
			INTEGRA_TRACE_ERROR << "failed to lookup interface";
			return CError::INPUT_ERROR;
		}

		if( interface_definition->get_file_path().empty() )
		{
			INTEGRA_TRACE_ERROR << "Unknown interface file path";
			return CError::INPUT_ERROR;
		}

		string module_storage_path = get_storage_path( *interface_definition );
		if( module_storage_path.empty() )
		{
			INTEGRA_TRACE_ERROR << "failed to get storage path";
			return CError::INPUT_ERROR;
		}

		CError = CFileHelper::copy_file( interface_definition->get_file_path(), module_storage_path );
		if( CError != CError::SUCCESS )
		{
			return CError;
		}

		interface_definition->set_file_path( module_storage_path );

		return CError::SUCCESS;
	}


	string CModuleManager::get_storage_path( const CInterfaceDefinition &interface_definition ) const
	{
		string storage_directory;

		switch( interface_definition.get_module_source() )
		{
			case CInterfaceDefinition::MODULE_3RD_PARTY:
				storage_directory = m_third_party_module_directory;
				break;

			case CInterfaceDefinition::MODULE_EMBEDDED:
				storage_directory = m_embedded_module_directory; 
				break;

			case CInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA:
			case CInterfaceDefinition::MODULE_IN_DEVELOPMENT:
			default:
				INTEGRA_TRACE_ERROR << "Unexpected module source";
				return string();
		}

		string unique_name = get_unique_interface_name( interface_definition );

		return storage_directory + unique_name + "." + module_suffix;
	}


	CError CModuleManager::change_module_source( CInterfaceDefinition &interface_definition, CInterfaceDefinition::module_source new_source )
	{
		/* sanity checks */
		if( interface_definition.get_module_source() == CInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA || new_source == CInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA )
		{
			return CError::INPUT_ERROR;
		}

		if( interface_definition.get_module_source() == new_source )
		{
			return CError::INPUT_ERROR;
		}

		interface_definition.set_module_source( new_source );

		string new_file_path = get_storage_path( interface_definition );
		if( new_file_path.empty() )
		{
			return CError::FAILED;			
		}

		rename( interface_definition.get_file_path().c_str(), new_file_path.c_str() );

		interface_definition.set_file_path( new_file_path );
	
		return CError::SUCCESS;
	}


	bool CModuleManager::is_module_in_use( const node_map &search_nodes, const GUID &module_id ) const
	{
		for( node_map::const_iterator i = search_nodes.begin(); i != search_nodes.end(); i++ )
		{
			const INode *node = i->second;

            if ( CGuidHelper::guids_are_equal( node->get_interface_definition().get_module_guid(), module_id ) )
            {
				return true;
			}

			if( is_module_in_use( node->get_children(), module_id ) )
			{
				return true;
			}
		}

		return false;
	}


	void CModuleManager::remove_in_use_module_ids_from_set( const node_map &search_nodes, guid_set &set ) const
	{
		for( node_map::const_iterator i = search_nodes.begin(); i != search_nodes.end(); i++ )
		{
			const INode *node = i->second;
			
			set.erase( node->get_interface_definition().get_module_guid() );

			remove_in_use_module_ids_from_set( node->get_children(), set );
		}
	}
}


