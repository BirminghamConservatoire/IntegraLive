/** libIntegra multimedia module interface
 *  
 * Copyright (C) 2007 Birmingham City University
 *
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

#include <pthread.h>

#define DEFINE_GLOBALS
#include "globals.h"
#include "server.h"

void do_init()
{
    /** Initialise the id counter */
    server_ = NULL;

}


#ifdef __GNUC__
void __attribute__((constructor)) my_init(void)
{
	do_init();
}
#else
#ifdef _WINDOWS
BOOL WINAPI DllMain( HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved )
{
	switch( fdwReason )
	{
		case DLL_PROCESS_ATTACH:
			do_init();
			break;

		default:
			break;
	}

	return TRUE;
}
#else
void _init()
{
	do_init();
}
#endif
#endif


