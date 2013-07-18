 /* libIntegra multimedia module definition interface
 *  
 * Copyright (C) 2007 Jamie Bullock, Henrik Frisk
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


#ifdef WIN32

	#pragma warning(disable : 4996)		//disable warnings about deprecated string functions
	#pragma warning(disable : 4018)		//disable warnings about signed/unsigned mismatch
	#pragma warning(disable : 4244)		//disable warnings about type conversion
	#pragma warning(disable : 4267)		//disable warnings about type conversion
	#pragma warning(disable : 4251)		//disable warnings about exporting classes which use stl

	#pragma warning(disable : 4800)		//disable warnings about forcing value to bool
//#pragma warning(disable : 4047)		//disable warnings about differing levels of indirection

	#define snprintf _snprintf

	#define strtof( a, b ) atof( a )

	#define __STR2__(x) #x
	#define __STR1__(x) __STR2__(x)
	#define __LOC__ __FILE__ "("__STR1__(__LINE__)") : Warning: "

	#define sigset_t int		//placeholder until we work out how we'll handle signals in win32

#endif
