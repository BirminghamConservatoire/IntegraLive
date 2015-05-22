//  $Id: prefix.hpp 3760 2012-08-12 19:05:26Z thomas $
//
//  Copyright (C) 2007 Tim Blechmann & Thomas Grill
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; see the file COPYING.  If not, write to
//  the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
//  Boston, MA 02111-1307, USA.

//  $Revision: 3760 $
//  $LastChangedRevision: 3760 $
//  $LastChangedDate: 2012-08-12 20:05:26 +0100 (Sun, 12 Aug 2012) $
//  $LastChangedBy: thomas $


#ifndef __LOCKFREE_PREFIX_H
#define __LOCKFREE_PREFIX_H

#include <cassert>

#ifdef USE_ATOMIC_OPS
    #define AO_REQUIRE_CAS
    #define AO_USE_PENTIUM4_INSTRS

    extern "C" {
        #include <atomic_ops.h>
    }
#endif

#ifdef _WIN32
    #include <windows.h>
#endif

#ifdef __APPLE__
    #include <libkern/OSAtomic.h>
#else
    #if defined(__GLIBCPP__) || defined(__GLIBCXX__)
        #if (__GNUC__ > 4) || ((__GNUC__ == 4) && (__GNUC_MINOR__ >= 2))
            #include <ext/atomicity.h>
        #else
            #include <bits/atomicity.h>
        #endif
    #endif
#endif

#if defined(_MSC_VER)
// \note: Must use /Oi option for VC++ to enable intrinsics
    extern "C" {
        void __cdecl _ReadWriteBarrier();
        LONG __cdecl _InterlockedCompareExchange(LONG volatile* Dest,LONG Exchange, LONG Comp); 
    }
#endif

#endif /* __LOCKFREE_PREFIX_H */
