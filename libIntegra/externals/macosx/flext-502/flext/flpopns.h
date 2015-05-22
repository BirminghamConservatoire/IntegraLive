/* 

flext - C++ layer for Max/MSP and pd (pure data) externals

Copyright (c) 2001-2009 Thomas Grill (gr@grrrr.org)
For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "license.txt," in this distribution.  

$LastChangedRevision: 3660 $
$LastChangedDate: 2009-02-10 19:17:03 +0000 (Tue, 10 Feb 2009) $
$LastChangedBy: thomas $
*/

#ifdef FLEXT_USE_NAMESPACE

#ifndef _FLEXT_IN_NAMESPACE
    #error flext namespace pop is unbalanced
#endif

#define __FLEXT_IN_NAMESPACE (_FLEXT_IN_NAMESPACE-1)
#undef _FLEXT_IN_NAMESPACE
#define _FLEXT_IN_NAMESPACE __FLEXT_IN_NAMESPACE
#undef __FLEXT_IN_NAMESPACE

#if _FLEXT_IN_NAMESPACE == 0

    #if 1 //defined(FLEXT_SHARED)
    } // namespace
    using namespace flext_ns;
    #elif defined(__GNUC__)
    } // anonymous namespace (don't export symbols)
    #endif
    
    #undef _FLEXT_IN_NAMESPACE
    
#endif
    
#endif
