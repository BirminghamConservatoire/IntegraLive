#pragma once

#include "integra_api.h"
#include <map>
#include <vector>

class IntegraServer
{
public:
    IntegraServer(std::string mainModulePath, std::string thirdPartyPath);
    ~IntegraServer();

    CError start();
    CError stop();
    CError open_file(std::string integraFilePath);
    CError update_param(std::string paramPath, float value);
    CError save_file(std::string saveFilePath);

    CIntegraSession& get_session() { return session; }
    void get_changed_endpoints( CPollingNotificationSink::changed_endpoint_map &changed_endpoints ) { sink.get_changed_endpoints(changed_endpoints); }
    const std::vector< std::string > & get_node_paths() { return node_paths; }

    void dump_state();
    void dump_modules_details();
    void dump_nodes_details();
    void dump_changed_endpoints();

private:
    CServerStartupInfo sinfo;
    CIntegraSession session;
    CPollingNotificationSink sink;
    bool session_started;
    std::map< std::string, GUID > moduleGUIDs;  // maps canonical module names to GUIDs
    CPath lastLoadedPath;
    std::vector< std::string > node_paths;

    void walk_node_tree(const INode* root);
};
