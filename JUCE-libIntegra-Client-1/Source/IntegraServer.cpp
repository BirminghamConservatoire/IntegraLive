#include "IntegraServer.h"
#include "server_startup_info.h"
#include "integra_session.h"
#include "interface_definition.h"
#include "error.h"
#include "server.h"
#include "server_lock.h"
#include "command.h"
#include "path.h"
#include "../JuceLibraryCode/JuceHeader.h"

IntegraServer::IntegraServer()
{
}

IntegraServer::~IntegraServer()
{
}

void IntegraServer::start()
{
    CServerStartupInfo sinfo;
    sinfo.system_module_directory = "/Users/shane/Documents/GitHub/IntegraLive/IntegraLive/modules";
    sinfo.third_party_module_directory = "/Users/shane/Documents/GitHub/IntegraLive/IntegraLive/third_party_modules";

    CError err = session.start_session(sinfo);
    if (err != CError::code::SUCCESS)
    {
        return;
    }

    CServerLock server = session.get_server();
    DBG(server->get_libintegra_version());

    std::string file_path = "/Users/shane/Desktop/Integra Live/SimpleDelay.integra";
    CPath module_path;

    const guid_set& module_ids = server->get_all_module_ids();

    for (auto id : module_ids)
    {
        string module_id_string = CGuidHelper::guid_to_string(id);
        DBG(module_id_string);
        const IInterfaceDefinition *interface_definition = server->find_interface(id);
        const IInterfaceInfo& info = interface_definition->get_interface_info();
        DBG(info.get_name());
    }

    GUID module_id;
    CGuidHelper::string_to_guid("8c6ce564-9ba0-6314-5e56-599c8f5ac053", module_id);

    err = server->process_command(INewCommand::create(module_id, "AudioSettings1", module_path));

    err = server->process_command(ILoadCommand::create(file_path, module_path));
    if (err != CError::code::SUCCESS)
    {
        DBG(err.get_text());
        return;
    }

    err = server->process_command(ISetCommand::create(CPath("SimpleDelay.Track1.Block1.Delay1.delayTime"), CFloatValue(1.0)));

    server->process_command(ISaveCommand::create("/Users/shane/Desktop/test.integra", CPath("SimpleDelay")));

    server->dump_libintegra_state();
}

void IntegraServer::stop()
{
    session.end_session();
}
