#pragma once

#include "integra_session.h"

using namespace integra_api;

class IntegraServer
{
public:
    IntegraServer();
    ~IntegraServer();

    void start();
    void stop();

private:
    CIntegraSession session;
};
