/* 
fsplay~ - file and stream player

Copyright (c)2004-2007 Thomas Grill (gr@grrrr.org)
For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "license.txt," in this distribution.

$LastChangedRevision: 3599 $
$LastChangedDate: 2008-04-13 07:48:35 -0400 (Sun, 13 Apr 2008) $
$LastChangedBy: thomas $
*/

#include "fsplay.h"
#include "sndfile.h"

void CnvFlnm(std::string &dst,const char *src);

class fsp_libsndfile
    : public fspformat
{
public:
    static bool Setup()
    {
        Add(New);
        return true;
    }

    static fspformat *New(const std::string &filename)
    {
        fsp_libsndfile *ret = new fsp_libsndfile(filename.c_str());
        if(ret->sndfile)
            return ret;
        else {
            delete ret;
            return NULL;
        }
    }

    virtual ~fsp_libsndfile()
    {
        if(sndfile) sf_close(sndfile);
    }

    virtual int Channels() const 
    {
        FLEXT_ASSERT(sndfile);
        return info.channels;
    }

    virtual float Samplerate() const 
    {
        FLEXT_ASSERT(sndfile);
        return float(info.samplerate);
    }

    virtual cnt_t Frames() const 
    {
        FLEXT_ASSERT(sndfile);
        return info.frames;
    }

    virtual cnt_t Read(t_sample *rbuf,cnt_t frames)
    {
        FLEXT_ASSERT(sndfile);
        cnt_t rd = sf_readf_float(sndfile,rbuf,frames);
        return rd?rd:-1;
    }

    virtual bool Seek(double pos)
    {
        FLEXT_ASSERT(sndfile);
        cnt_t p = cnt_t(pos*info.samplerate+0.5);
        return sf_seek(sndfile,p,SEEK_SET) >= 0;
    }

protected:
    fsp_libsndfile(const char *filename)
    {
        std::string name;
        CnvFlnm(name,filename);
        sndfile = sf_open(name.c_str(),SFM_READ,&info);
    }

    SNDFILE *sndfile;
    SF_INFO info;
};

// should not be static....
bool loaded_libsndfile = fspformat::Add(fsp_libsndfile::Setup);
