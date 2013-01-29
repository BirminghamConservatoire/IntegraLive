
/* helper to close any processes that may have been orphaned by a prevous crash */


#ifndef INTEGRA_CLOSE_ORPHANED_PROCESSES_H
#define INTEGRA_CLOSE_ORPHANED_PROCESSES_H

#ifdef __cplusplus
extern "C" {
#endif


/* 
closes all processes whose filenames match these in filenames.  
filenames can be provided as a complete path or as a relative path from the current working directory
*/
	
void close_orphaned_processes(const char **filenames, int number_of_filenames);



#endif