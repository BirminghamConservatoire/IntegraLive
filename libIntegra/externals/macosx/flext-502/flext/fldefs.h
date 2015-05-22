/* 

flext - C++ layer for Max/MSP and pd (pure data) externals

Copyright (c) 2001-2009 Thomas Grill (gr@grrrr.org)
For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "license.txt," in this distribution.  

$LastChangedRevision: 3657 $
$LastChangedDate: 2009-02-09 22:58:30 +0000 (Mon, 09 Feb 2009) $
$LastChangedBy: thomas $
*/

/*! \file fldefs.h
    \brief This file includes all the #define header files 
*/

#ifndef __FLEXT_DEFS_H
#define __FLEXT_DEFS_H

/*! \defgroup FLEXT_DEFS Definitions for basic flext functionality
    @{ 
*/

/*! \brief Switch for compilation of derived virtual classes
    \remark These need dynamic type casts (and RTTI, naturally)
    \ingroup FLEXT_GLOBALS
*/
#ifdef FLEXT_VIRT
#define FLEXT_CAST dynamic_cast
#else
#define FLEXT_CAST static_cast
#endif

//! @}  FLEXT_DEFS

#include "fldefs_hdr.h"

#include "fldefs_setup.h"


// ====================================================================================

/*! \defgroup FLEXT_D_METHOD Declarations for flext methods
    @{ 
*/

#include "fldefs_methcb.h"
#include "fldefs_meththr.h"
#include "fldefs_methadd.h"
#include "fldefs_methbind.h"
#include "fldefs_methcall.h"

//! @} FLEXT_D_METHOD



#ifdef FLEXT_ATTRIBUTES 

/*! \defgroup FLEXT_D_ATTRIB Attribute definition
    \note These have to reside inside the class declaration
    @{ 
*/

#include "fldefs_attrcb.h"
#include "fldefs_attrvar.h"
#include "fldefs_attradd.h"

//! @} FLEXT_D_ATTRIB

#endif // FLEXT_ATTRIBUTES

#endif // __FLEXT_DEFS_H
