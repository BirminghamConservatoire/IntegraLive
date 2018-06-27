#pragma once

#include "integra_api.h"
#include <map>

class IntegraServer
{
public:
    IntegraServer(std::string mainModulePath, std::string thirdPartyPath);
    ~IntegraServer();

    CError start();
    CError stop();
    void dump_state();
    void dump_modules_details();
    void dump_nodes_details();
    CError open_file(std::string integraFilePath);
    CError update_param(std::string paramPath, float value);
    CError save_file(std::string saveFilePath);

private:
    CServerStartupInfo sinfo;
    CIntegraSession session;
    bool session_started;
    std::map< std::string, GUID > moduleGUIDs;  // maps canonical module names to GUIDs
    CPath lastLoadedPath;
};
