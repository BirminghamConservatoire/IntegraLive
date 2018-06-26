/* 
fsplay~ - file and stream player

Copyright (c)2004-2008 Thomas Grill (gr@grrrr.org)
For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "license.txt," in this distribution.

$LastChangedRevision: 3684 $
$LastChangedDate: 2009-06-01 15:27:26 -0400 (Mon, 01 Jun 2009) $
$LastChangedBy: thomas $
*/

#ifndef __RESAMPLE_H
#define __RESAMPLE_H

#include "fsplay.h"
#include <algorithm>


class Resampler
{
public:
    Resampler() { reset(); }
    virtual ~Resampler() {}

    virtual void reset() {}

    virtual void work(const t_sample *speed,int spdstride,t_sample ratio,t_sample *out,int outstride,int &outcnt,const t_sample *in,int instride,int &incnt,bool lastflag) = 0;
};

template<typename T>
class StridedArray
{
public:
    StridedArray(T *d,int s): data(d),stride(s) {}
    
    T &operator [](size_t ix) { return data[ix*stride]; }
    const T &operator [](size_t ix) const { return data[ix*stride]; }
    StridedArray operator +(size_t o) const { return StridedArray(data+(o*stride),stride); }
    
private:
    T *data;
    int stride;
};

template<typename T>
class StridedConstArray
{
public:
    StridedConstArray(T const *d,int s): data(d),stride(s) {}
    
    const T &operator [](size_t ix) const { return data[ix*stride]; }
    StridedConstArray operator +(size_t o) const { return StridedConstArray(data+(o*stride),stride); }
    
private:
    T const *data;
    int stride;
};

template<typename T,int S>
class StridedNArray
{
public:
    StridedNArray(T *d,int = 0): data(d) {}
    
    T &operator [](size_t ix) { return data[ix*S]; }
    const T &operator [](size_t ix) const { return data[ix*S]; }
    StridedNArray operator +(size_t o) const { return StridedNArray(data+(o*S),S); }
    
private:
    T *data;
};

template<typename T,int S>
class StridedConstNArray
{
public:
    StridedConstNArray(T const *d,int = 0): data(d) {}
    
    const T &operator [](size_t ix) const { return data[ix*S]; }
    StridedConstNArray operator +(size_t o) const { return StridedConstNArray(data+(o*S),S); }
    
private:
    T const *data;
};


// sample and hold
class SAHAlgo
{
public:
    static const int order = 0;

    template<typename T,typename A>
    static inline T calc(A f,T frac)
    {
        return f[0];
    }
};

// linear interpolation algorithm
class LinearAlgo
{
public:
    static const int order = 1;

    template<typename T,typename A>
    static inline T calc(A f,T frac)
    {
        FLEXT_ASSERT(frac >= 0 && frac <= 1);
        return f[0] + frac*(f[1]-f[0]);
    }
};

class CubicAlgo
{
public:
    static const int order = 3;

    template<typename T,typename A>
    static inline T calc(A f,T frac)
    {
        FLEXT_ASSERT(frac >= 0 && frac <= 1);

        const T f1 = frac*0.5f-0.5f;
        const T f3 = frac*3.0f-1.0f;
        
        const T amdf = (f[0]-f[3])*frac;
        const T cmb = f[2]-f[1];
        const T bma = f[1]-f[0];
        return f[1] + frac*( cmb - f1 * ( amdf+bma+cmb*f3 ) );
    }
};


template<typename A>
class AlgoResampler
    : public Resampler
{
public:
    AlgoResampler() { reset(); }

    virtual void reset() 
    { 
        offset = 0; 
        for(int i = 0; i <= A::order; ++i) memory[i] = 0; 
    }

    virtual void work(const t_sample *speed,int spdstride,t_sample ratio,t_sample *out,int outstride,int &outcnt,const t_sample *in,int instride,int &incnt,bool lastflag)
    {
        if(!spdstride) 
            _work(StridedConstNArray<t_sample,0>(speed),ratio,out,outstride,outcnt,in,instride,incnt,lastflag);
        else if(spdstride == 1)
            _work(StridedConstNArray<t_sample,1>(speed),ratio,out,outstride,outcnt,in,instride,incnt,lastflag);
        else
            _work(StridedConstArray<t_sample>(speed,spdstride),ratio,out,outstride,outcnt,in,instride,incnt,lastflag);
    }

private:

    template<typename TS>
    void _work(TS speed,t_sample ratio,t_sample *out,int outstride,int &outcnt,const t_sample *in,int instride,int &incnt,bool lastflag)    
    {
        FLEXT_ASSERT(incnt >= 0);
        FLEXT_ASSERT(outcnt >= 0);

        // exploit common strides
        if(outstride == 1) {
            StridedNArray<t_sample,1> aout(out,outstride);
            if(instride == 1)
                __work(speed,ratio,aout,outcnt,StridedConstNArray<t_sample,1>(in,instride),incnt,lastflag);
            else if(instride == 2)
                __work(speed,ratio,aout,outcnt,StridedConstNArray<t_sample,2>(in,instride),incnt,lastflag);
            else if(instride == 4)
                __work(speed,ratio,aout,outcnt,StridedConstNArray<t_sample,4>(in,instride),incnt,lastflag);
            else
                __work(speed,ratio,aout,outcnt,StridedConstArray<t_sample>(in,instride),incnt,lastflag);
        }
        else {
            StridedArray<t_sample> aout(out,outstride);
            if(instride == 1)
                __work(speed,ratio,aout,outcnt,StridedConstNArray<t_sample,1>(in,instride),incnt,lastflag);
            else if(instride == 2)
                __work(speed,ratio,aout,outcnt,StridedConstNArray<t_sample,2>(in,instride),incnt,lastflag);
            else
                __work(speed,ratio,aout,outcnt,StridedConstArray<t_sample>(in,instride),incnt,lastflag);
        }
    }

    template<typename TO,typename TI,typename TS>
    void __work(TS speed,t_sample ratio,TO out,int &outcnt,TI in,int &incnt,bool lastflag)
    {
        double o = offset;
        int inc = 0,outc = 0;
        while(LIKELY(outc < outcnt)) {           
            if(LIKELY(o >= 0)) {
                // need new sample(s) from input
            
    		    long oint = (long)o;
                int ninc = (int)(inc + oint);
                if(UNLIKELY(ninc >= incnt)) {
                    int dif = incnt-inc;  // remaining samples in the buffer
                    o -= dif; // consider remaining input samples
                    inc = incnt;
                    break; // not enough input samples
                }

                inc = ninc+1;
                o -= oint+1; // got oint+1 samples
            }

            t_sample frac = (t_sample)o+1;
            
            if(UNLIKELY(inc <= A::order)) {
                t_sample f[A::order+1];
                int i;
                for(i = 0; i <= A::order-inc; ++i) 
                    f[i] = memory[i+inc];
                for(; i <= A::order; ++i) 
                    f[i] = in[(i+inc-(A::order+1))];   

                out[outc] = A::calc(StridedConstNArray<t_sample,1>(f),frac);
            }
            else
                out[outc] = A::calc(in+(inc-(A::order+1)),frac);

            o += speed[outc]*ratio;
            outc++;
        }

        // save some samples
        // count could be dependent on value of offset
        int i = 0;
        for(; UNLIKELY(i <= A::order-inc); ++i)
            memory[i] = memory[i+inc];
        for(; i <= A::order; ++i)
            memory[i] = in[i+inc-(A::order+1)];

        offset = o;
        incnt = inc;
        outcnt = outc;
    }


    double offset;
    t_sample memory[A::order+1];
};

#endif
