/* helper to close any processes that may have been orphaned by a prevous crash */

#include "close_orphaned_processes.h"

#include <unistd.h>
#include <stdlib.h>

#include "src/platform_specifics.h"

#include "api/trace.h"


#ifdef _WINDOWS

#include <windows.h>
#include <TlHelp32.h>
#pragma warning(disable : 4996)
#pragma warning(disable : 4047)
#pragma warning(disable : 4024)
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

void close_orphaned_processes(const char **filenames, int number_of_filenames)
{
	PROCESSENTRY32 process_entry;
	MODULEENTRY32 module_entry;

	HANDLE process_snapshot = NULL;
	HANDLE module_snapshot = NULL;

	HANDLE process_handle = NULL;

	int i = 0;
	bool terminated = false;

	char *absolute_path = NULL;
	char **absolute_paths = NULL;
	WCHAR **absolute_paths_wide = NULL;
	int number_of_absolute_paths = 0;
	size_t number_of_characters = 0;

	/*build absolute paths and convert to wide-char*/
	
	absolute_paths = new char *[ number_of_filenames ];
	absolute_paths_wide = new WCHAR *[ number_of_filenames ];

	for(i = 0; i < number_of_filenames; i++)
	{
		absolute_path = build_absolute_path(filenames[i]);
		if(absolute_path)
		{
			absolute_paths[number_of_absolute_paths] = absolute_path;
			absolute_paths_wide[number_of_absolute_paths] = new WCHAR[ LONG_STRLEN ];
			if( mbstowcs_s( &number_of_characters, absolute_paths_wide[number_of_absolute_paths], LONG_STRLEN, absolute_path, LONG_STRLEN ) != 0 )
			{
				INTEGRA_TRACE_ERROR << "failed to convert path to wide-string";

				/*failsafe - reset the string*/
				*absolute_paths_wide[number_of_absolute_paths] = 0;
			}
			number_of_absolute_paths++;
		}
	}

	/*look for processes matching these absolute paths, and kill them*/

    process_entry.dwSize = sizeof(PROCESSENTRY32);

    process_snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, NULL);

	if(Process32First(process_snapshot, &process_entry) == TRUE)
	{
		do{
			terminated = false;
			if(process_entry.th32ProcessID > 0)
			{
				module_snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, process_entry.th32ProcessID);

				module_entry.dwSize = sizeof(MODULEENTRY32);
				if(Module32First(module_snapshot, &module_entry) == TRUE)
				{
					for(i = 0; i < number_of_absolute_paths; i++)
					{
						if(wcscmp(absolute_paths_wide[i], module_entry.szExePath) == 0)
						{
							if(process_entry.th32ProcessID != GetCurrentProcessId())
							{
								process_handle = OpenProcess(PROCESS_TERMINATE, FALSE, process_entry.th32ProcessID);
								if(process_handle)
								{
									if(TerminateProcess(process_handle, 0) != 0)
									{
										INTEGRA_TRACE_PROGRESS << "Killed orphaned process" << absolute_paths[ i ];
										terminated = true;
									}
									else
									{
										INTEGRA_TRACE_ERROR << "failed to terminate orphaned process.  Error:" << GetLastError();
									}

									CloseHandle(process_handle);
								}
								else
								{
									INTEGRA_TRACE_ERROR << "failed to kill orphaned process - couldn't open process handle.  Error: " << GetLastError();
								}
							}
						}

						if(terminated)
						{
							break;
						}

					}
					while(!terminated && Module32Next(module_snapshot, &module_entry) == TRUE);
				}

				CloseHandle(module_snapshot);
			}
		}
		while(Process32Next(process_snapshot, &process_entry) == TRUE);
	}

    CloseHandle(process_snapshot);

	for(i = 0; i < number_of_absolute_paths; i++)
	{
		free(absolute_paths[i]);
		free(absolute_paths_wide[i]);
	}

	free(absolute_paths);
	free(absolute_paths_wide);
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

    proc_list = malloc(buffer_size);  
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

void close_orphaned_processes(const char **filenames, int number_of_filenames)
{
    pid_t my_pid      = getpid();
    unsigned int i = 0;
    int orphans[MAX_ORPHANS] = {0};
    int *orphan_marker = orphans;

    for( i = 0; i < number_of_filenames; ++i )
    {
        const char *filename = filenames[i];
        get_pids_by_name(basename(filename), orphan_marker);
    }

    qsort(orphans, MAX_ORPHANS, sizeof(int), integer_comparison);

    for( i = 0; i < MAX_ORPHANS; ++i )
    {
        if( orphans[i] == 0 || orphans[i] == my_pid)
        {
            continue;
        }
        NTG_TRACE_VERBOSE_WITH_INT("killing process %d", orphans[i]);
        kill(orphans[i], SIGKILL);
    }

}

#else
void close_orphaned_processes(const char **filenames, int number_of_filenames)
{
	INTEGRA_TRACE_ERROR << "close_orphaned_processes not implemented on this OS, orphaned processes must be killed manually";
}
#endif	
#endif

