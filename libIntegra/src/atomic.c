
/* Code copied from jack and slightly modified. -Kjetil. */

#ifndef _rtgc_atomicity_atomicity_h_
#define _rtgc_atomicity_atomicity_h_

#if defined(__i386__) || defined(__x86_64)

typedef int _Atomic_word;

static __inline _Atomic_word 
__attribute__ ((__unused__))
__exchange_and_add(volatile _Atomic_word* __mem, int __val)
{
  register _Atomic_word __result;
  __asm__ __volatile__ ("lock; xaddl %0,%1"
			: "=r" (__result), "=m" (*__mem) 
			: "0" (__val), "m" (*__mem));
  return __result;
}

static __inline void
__attribute__ ((__unused__))
__atomic_add(volatile _Atomic_word* __mem, int __val)
{
  __asm__ __volatile__ ("lock; addl %1,%0"
			: "=m" (*__mem) : "ir" (__val), "m" (*__mem));
}


#elif defined(__powerpc__) || defined(__ppc__) /* linux and OSX use different tokens */

typedef int _Atomic_word;

static __inline _Atomic_word
__attribute__ ((__unused__))
__exchange_and_add(volatile _Atomic_word* __mem, int __val)
{
  _Atomic_word __tmp, __res;
  __asm__ __volatile__ (
	"/* Inline exchange & add */\n"
	"0:\t"
	"lwarx    %0,0,%3 \n\t"
	"add%I4   %1,%0,%4 \n\t"
	_STWCX "  %1,0,%3 \n\t"
	"bne-     0b \n\t"
	"/* End exchange & add */"
	: "=&b"(__res), "=&r"(__tmp), "=m" (*__mem)
	: "r" (__mem), "Ir"(__val), "m" (*__mem)
	: "cr0");
  return __res;
}

static __inline void
__attribute__ ((__unused__))
__atomic_add(volatile _Atomic_word* __mem, int __val)
{
  _Atomic_word __tmp;
  __asm__ __volatile__ (
	"/* Inline atomic add */\n"
	"0:\t"
	"lwarx    %0,0,%2 \n\t"
	"add%I3   %0,%0,%3 \n\t"
	_STWCX "  %0,0,%2 \n\t"
	"bne-     0b \n\t"
	"/* End atomic add */"
	: "=&b"(__tmp), "=m" (*__mem)
	: "r" (__mem), "Ir"(__val), "m" (*__mem)
	: "cr0");
}

#else


#pragma message( __LOC__ "Need to reimplement these functions atomically!" )

int __exchange_and_add( int *mem, int val)
{
	int result = *mem;
	*mem += val;
	return result;
}


void __atomic_add( int *mem, int val)
{
	*mem += val;
}



#endif /* processor selection */

#endif /* _rtgc_atomicity_atomicity_h_ */
