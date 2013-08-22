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

/* helper to close any processes that may have been orphaned by a prevous crash */


#ifndef INTEGRA_CLOSE_ORPHANED_PROCESSES_H
#define INTEGRA_CLOSE_ORPHANED_PROCESSES_H

#include <string>
#include <list>


/* 
closes all processes whose filenames match these in filenames.  
filenames can be provided as a complete path or as a relative path from the current working directory
*/
	
void close_orphaned_processes( const std::list<std::string> &filenames );



#endif