/** libIntegra multimedia module interface
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


#ifndef _WINDOWS
#include <string.h>
#include <stdarg.h>
#include <stdio.h>

int vsprintf_s_alt (char *str, size_t size, const char *format, va_list ap)
{
    int rv = vsnprintf(str, size, format, ap);

    if(rv == -1 || rv > size)
    {
        return -1;
    }
    else
    {
        return rv;
    }
}

int sprintf_s_alt (char *str, size_t size, const char *format, ...)
{
    va_list args;
    va_start(args, format);
    int rv = vsprintf_s_alt(str, size, format, args);

    return rv;
}

#endif

