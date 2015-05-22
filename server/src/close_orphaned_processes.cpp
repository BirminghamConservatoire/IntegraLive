/** IntegraServer - console app to expose xmlrpc interface to libIntegra
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



/* helper to close any processes that may have been orphaned by a previous crash */

#include "close_orphaned_processes.h"

#include <unistd.h>
#include <stdlib.h>

#ifdef _WINDOWS

#include <windows.h>
#include <TlHelp32.h>
#pragma warning(disable : 4996)
#pragma warning(disable : 4047)
#pragma warning(disable : 4024)
#pragma warning(disable : 4251)		/* disable warnings about exported classes which use stl */

#define PATH_SEPARATOR '\\'

#else

#define PATH_SEPARATOR '/'
#include <string.h>
#include <signal.h>
char *strcpy_s(char *s1, size_t n, const char *s2)
{
    return strncpy(s1, s2, n);
}

#endif

#include "trace.h"


#define LONG_STRLEN (1024)
#define MAX_ORPHANS 1000

/* strnlen only became available on OS X in 10.7 */
size_t strnlen_(const char *begin, size_t maxlen) {
    const char *end = static_cast<const char *>( memchr(begin, '\0', maxlen) );
    return end ? (end - begin) : maxlen;
}

char *build_absolute_path(const char *filename)
{
	unsigned int directory_up_marker_length = 0;
	unsigned int length_of_path = 0;
	unsigned int length_of_filename = 0;

	char *absolute_path = new char[ LONG_STRLEN ];
	char *last_separator = NULL;

	const char directory_up_marker[] = {'.', '.', PATH_SEPARATOR, '\0'}; 

	if(filename[1] == ':')
	{
		//filename is already an absolute path
		strcpy_s(absolute_path, LONG_STRLEN, filename);
		return absolute_path;
	}

	if(getcwd(absolute_path, LONG_STRLEN) == NULL)
	{
		INTEGRA_TRACE_ERROR << "getcwd() failed";
		free( absolute_path );
		return NULL;
	}

	directory_up_marker_length = strlen(directory_up_marker);

	while(strlen(filename) > directory_up_marker_length && memcmp(filename, directory_up_marker, directory_up_marker_length) == 0)
	{
		filename+=directory_up_marker_length;
		
		last_separator = strrchr(absolute_path, PATH_SEPARATOR);
		if(!last_separator)
		{
			INTEGRA_TRACE_ERROR << "failed to resolve absolute path - too many 'directory up' markers";
			free( absolute_path );
			return NULL;
		}

		*last_separator=0;
	}

	length_of_path = strlen( absolute_path );
	length_of_filename = strlen( filename );
	
	/*append separator*/
	absolute_path[ length_of_path ] = PATH_SEPARATOR;
	length_of_path++;

	/*append filename*/
	if(length_of_path + length_of_filename + 1 >= LONG_STRLEN)
	{
		INTEGRA_TRACE_ERROR << "failed to resolve absolute path - too long";
		free( absolute_path );
		return NULL;
	}
	strcpy( absolute_path + length_of_path, filename );

	return absolute_path;
}




#ifdef _WINDOWS

/* Windows implementation of close_orphaned_processes*/

void close_orphaned_processes( const std::list<std::string> &filenames )
{
	/*build absolute paths and convert to wide-char*/
	
	std::list<std::string> absolute_paths;

	for( std::list<std::string>::const_iterator i = filenames.begin(); i != filenames.end(); i++ )
	{
		char *absolute_path = build_absolute_path( i->c_str() );
		if( absolute_path )
		{
			absolute_paths.push_back( absolute_path );
			delete absolute_path;
		}
	}

	/*look for processes matching these absolute paths, and kill them*/

    PROCESSENTRY32 process_entry;
	process_entry.dwSize = sizeof( PROCESSENTRY32 );

    HANDLE process_snapshot = CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, NULL );

	if( Process32First( process_snapshot, &process_entry ) == TRUE )
	{
		do{
			bool terminated = false;
			if( process_entry.th32ProcessID > 0 )
			{
				HANDLE module_snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, process_entry.th32ProcessID);

				MODULEENTRY32 module_entry;
				module_entry.dwSize = sizeof( MODULEENTRY32 );
				if( Module32First( module_snapshot, &module_entry ) == TRUE )
				{
					for( std::list<std::string>::const_iterator i = absolute_paths.begin(); i != absolute_paths.end(); i++ )
					{
						std::wstring absolute_path_wide;
						absolute_path_wide.assign( i->begin(), i->end() );

						if( absolute_path_wide == module_entry.szExePath )
						{
							if( process_entry.th32ProcessID != GetCurrentProcessId() )
							{
								HANDLE process_handle = OpenProcess( PROCESS_TERMINATE, FALSE, process_entry.th32ProcessID );
								if( process_handle )
								{
									if( TerminateProcess( process_handle, 0 ) != 0 )
									{
										INTEGRA_TRACE_PROGRESS << "Killed orphaned process " << *i;
										terminated = true;
									}
									else
									{
										INTEGRA_TRACE_ERROR << "failed to terminate orphaned process.  Error:" << GetLastError();
									}

									CloseHandle( process_handle );
								}
								else
								{
									INTEGRA_TRACE_ERROR << "failed to kill orphaned process - couldn't open process handle.  Error: " << GetLastError();
								}
							}
						}

						if( terminated )
						{
							break;
						}

					}
					while( !terminated && Module32Next( module_snapshot, &module_entry ) == TRUE );
				}

				CloseHandle( module_snapshot );
			}
		}
		while( Process32Next( process_snapshot, &process_entry ) == TRUE );
	}

    CloseHandle( process_snapshot );
}

#else
#ifdef __MACH__ /* OS X */
#include <sys/sysctl.h>
#include <sys/param.h>

char *basename(const char *name)
{
    const char *base = name;

    while (*name)
    {
        if (*name++ == '/')
        {
            base = name;
        }
    }
    return (char *) base;
}

int integer_comparison(const void *a, const void *b) 
{
    const int *ia = (const int *)a;
    const int *ib = (const int *)b;
    return *ia  - *ib; 
}

/* adds PIDs matching process *name to the *pids array, starting from pid_index */
void get_pids_by_name(const char *name, int *pids)
{
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    unsigned int i = 0;
    size_t buffer_size, num_procs;
    struct kinfo_proc *pproc, *proc_list;
    sysctl(mib, 4, NULL, &buffer_size, NULL, 0);

    proc_list = (kinfo_proc *)malloc(buffer_size);
    sysctl(mib, 4, proc_list, &buffer_size, NULL, 0);

    num_procs = buffer_size / sizeof(struct kinfo_proc);
    for (i = 0; i < num_procs; i++) {
        pproc = proc_list + i;
        if(!strncmp(pproc->kp_proc.p_comm, name, strnlen_(name, MAXCOMLEN)))
        {
                *pids++ = pproc->kp_proc.p_pid;
        }
    }
    free(proc_list);
}

void close_orphaned_processes( const std::list<std::string> &filenames )
{
    pid_t my_pid      = getpid();
    int orphans[MAX_ORPHANS] = {0};
    int *orphan_marker = orphans;

    for( std::list<std::string>::const_iterator i = filenames.begin(); i != filenames.end(); i++ )
    {
        const char *filename = i->c_str();
        get_pids_by_name(basename(filename), orphan_marker);
    }

    qsort(orphans, MAX_ORPHANS, sizeof(int), integer_comparison);

    for( unsigned int i = 0; i < MAX_ORPHANS; ++i )
    {
        if( orphans[i] == 0 || orphans[i] == my_pid)
        {
            continue;
        }
        INTEGRA_TRACE_VERBOSE << "killing process " << orphans[i];
        kill(orphans[i], SIGKILL);
    }

}

#else
void close_orphaned_processes(  const std::list<std::string> &filenames )
{
	INTEGRA_TRACE_ERROR << "close_orphaned_processes not implemented on this OS, orphaned processes must be killed manually";
}
#endif	
#endif

