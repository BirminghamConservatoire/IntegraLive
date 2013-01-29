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

#include <stdio.h>

#include "id.h"
#include "globals.h"

/** Initialise the id counter mutex */
static pthread_mutex_t id_counter_mutex = PTHREAD_MUTEX_INITIALIZER;

ntg_id ntg_id_new(void)
{

    ntg_id id;

    pthread_mutex_lock(&id_counter_mutex);

    id = id_counter_++;

    pthread_mutex_unlock(&id_counter_mutex);

    return id;

}

unsigned long ntg_id_get_as_long(ntg_id id)
{
    return (unsigned long)id;
}

char *ntg_id_get_as_string(ntg_id id, const char *prefix)
{
    char *idstr = NULL;

    idstr = ntg_malloc(sizeof("xxx.2147483647"));
    if (prefix == NULL)
        sprintf(idstr, "%ld", ntg_id_get_as_long(id));
    else
        sprintf(idstr, "%s%ld", prefix, ntg_id_get_as_long(id));

    return idstr;
}
