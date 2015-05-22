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



#ifndef NTG_MURMUR_HASH2_PRIVATE_H
#define NTG_MURMUR_HASH2_PRIVATE_H


/*----------------------------------------------------------------------------- */
/* MurmurHash2, by Austin Appleby */

/* Note - This code makes a few assumptions about how your machine behaves - */

/* 1. We can read a 4-byte value from any address without crashing */
/* 2. sizeof(int) == 4 */

/* And it has a few limitations - */

/* 1. It will not work incrementally. */
/* 2. It will not produce the same results on little-endian and big-endian */
/*    machines. */

namespace integra_internal
{
	unsigned int MurmurHash2( const void * key, int len, unsigned int seed );
}


#endif /* NTG_MURMUR_HASH2_PRIVATE_H */