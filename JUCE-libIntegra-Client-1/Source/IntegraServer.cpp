#include "IntegraServer.h"
#include "../JuceLibraryCode/JuceHeader.h"

IntegraServer::IntegraServer(std::string mainModulePath, std::string thirdPartyPath)
: session_started(false)
{
    sinfo.system_module_directory = mainModulePath;
    sinfo.third_party_module_directory = thirdPartyPath;

    // Stop the incessant chatter
    CTrace::set_categories_to_trace(false, false, false);
}

IntegraServer::~IntegraServer()
{
    if (session_started) stop();
}

CError IntegraServer::start()
{
    CError err = session.start_session(sinfo);
    if (err != CError::SUCCESS)
    {
        return err;
    }
    session_started = true;
    
    CServerLock server = session.get_server();

    // Get libIntegra version
    DBG(server->get_libintegra_version());

    // Get a complete list of available module IDs and some information about them
    const guid_set& module_ids = server->get_all_module_ids();
    moduleGUIDs.clear();
    for (auto id : module_ids)
    {
        string module_id_string = CGuidHelper::guid_to_string(id);
        //DBG(module_id_string);
        const IInterfaceDefinition *interface_definition = server->find_interface(id);
        const IInterfaceInfo& info = interface_definition->get_interface_info();
        DBG(info.get_name() + " " + info.get_label());
        moduleGUIDs.insert(std::pair< std::string, GUID >(info.get_name(), id));
    }

    // Create an AudioSettings object at top level (required to activate audio I/O)
    CPath module_path;
    GUID module_id = moduleGUIDs["AudioSettings"];
    err = server->process_command(INewCommand::create(module_id, "AudioSettings1", module_path));

    return err;
}

void IntegraServer::dump_state()
{
    session.get_server()->dump_libintegra_state();
}

CError IntegraServer::open_file(std::string integraFilePath)
{
    CServerLock server = session.get_server();

    CPath module_path;
    CError err = server->process_command(ILoadCommand::create(integraFilePath, module_path));
    if (err != CError::code::SUCCESS) DBG(err.get_text());
    return err;
}

CError IntegraServer::update_param(std::string paramPath, float value)
{
    CServerLock server = session.get_server();

    return server->process_command(ISetCommand::create(CPath(paramPath), CFloatValue(value)));
}

CError IntegraServer::save_file(std::string saveFilePath)
{
    CServerLock server = session.get_server();

    return server->process_command(ISaveCommand::create(saveFilePath, CPath("SimpleDelay")));
}

CError IntegraServer::stop()
{
    if (!session_started) return CError::SUCCESS;
    
    CError err = session.end_session();
    if (err != CError::SUCCESS) DBG(err.get_text());
    else session_started = false;
    return err;
}
