#include "IntegraServer.h"
#include "../JuceLibraryCode/JuceHeader.h"

static const char* mod_source(IInterfaceDefinition::module_source src)
{
    switch (src)
    {
        case IInterfaceDefinition::MODULE_SHIPPED_WITH_INTEGRA:
            return "MODULE_SHIPPED_WITH_INTEGRA";
        case IInterfaceDefinition::MODULE_IN_DEVELOPMENT:
            return "MODULE_IN_DEVELOPMENT";
        case IInterfaceDefinition::MODULE_EMBEDDED:
            return "MODULE_EMBEDDED";
        case IInterfaceDefinition::MODULE_3RD_PARTY:
            return "MODULE_3RD_PARTY";
        default:
            return "*** UNKNOWN ***";
    }
}

static const char* endpt_type(IEndpointDefinition::endpoint_type type)
{
    switch (type)
    {
        case IEndpointDefinition::CONTROL:
            return "CONTROL";
        case IEndpointDefinition::STREAM:
            return "STREAM";
        default:
            return "*** UNKNOWN ***";
    }
}

static const char* ctrl_type(IControlInfo::control_type type)
{
    switch (type)
    {
        case IControlInfo::control_type::STATEFUL:
            return "STATEFUL";
        case IControlInfo::control_type::BANG:
            return "BANG";
        default:
            return "*** UNKNOWN ***";
    }
}

static const char* val_type(CValue::type type)
{
    switch (type)
    {
        case CValue::type::INTEGER:
            return "INTEGER";
        case CValue::type::FLOAT:
            return "FLOAT";
        case CValue::type::STRING:
            return "STRING";
        default:
            return "*** UNKNOWN ***";
    }
}

static const char* scale_type(const IValueScale::scale_type type)
{
    switch (type)
    {
        case IValueScale::scale_type::LINEAR:
            return "LINEAR";
        case IValueScale::scale_type::EXPONENTIAL:
            return "EXPONENTIAL";
        case IValueScale::scale_type::DECIBEL:
            return "DECIBEL";
        default:
            return "*** UNKNOWN ***";
    }
}

static std::string endpt_stream_details(IEndpointDefinition* endpt)
{
    const IStreamInfo* info = endpt->get_stream_info();
    std::string details;
    if (info->get_direction() == IStreamInfo::stream_direction::INPUT)
        details.append("INPUT");
    else
        details.append("OUTPUT");
    return details;
}

static std::string constraint_details(const IConstraint& cst)
{
    std::string details;
    const IValueRange* range = cst.get_value_range();
    const value_set* states = cst.get_allowed_states();
    if (range)
    {
        details.append("Range ");
        details.append(range->get_minimum().get_as_string());
        details.append(" to ");
        details.append(range->get_maximum().get_as_string());
    }
    else if (states)
    {
        details.append("Values ");
        for (auto val : *states)
        {
            details.append(val->get_as_string());
            details.append(" ");
        }
    }

    return details;
}

static std::string endpt_control_details(IEndpointDefinition* endpt)
{
    const IControlInfo* info = endpt->get_control_info();
    IControlInfo::control_type type = info->get_type();
    std::string details;
    details.append(ctrl_type(type));
    if (info->get_can_be_source()) details.append(" can_be_source");
    if (info->get_can_be_target()) details.append(" can_be_target");
    if (type == IControlInfo::control_type::STATEFUL)
    {
        const IStateInfo* sinfo = info->get_state_info();
        details.append("\n      ");
        details.append(val_type(sinfo->get_type()));
        details.append(" ");
        details.append(constraint_details(sinfo->get_constraint()));
        details.append("\n      Default ");
        details.append(sinfo->get_default_value().get_as_string());
        const IValueScale* vscale = sinfo->get_value_scale();
        if (vscale)
        {
            details.append("\n      Scale Type ");
            details.append(scale_type(sinfo->get_value_scale()->get_scale_type()));
        }
        const value_map& state_labels = sinfo->get_state_labels();
        if (state_labels.size() > 0)
        {
            details.append("\n      State Labels:");
            for (auto label : state_labels)
            {
                details.append(" ");
                details.append(label.first);
                details.append(" (");
                details.append(label.second->get_as_string());
                details.append(")");
            }
        }
    }
    return details;
}

static std::string endpt_details(IEndpointDefinition* endpt)
{
    std::string details;
    //details.append(endpt_type(endpt->get_type()));
    //details.append(" ");
    if (endpt->is_audio_stream())
        details.append(endpt_stream_details(endpt));
    else
        details.append(endpt_control_details(endpt));
    return details;
}

static std::string widget_pos (const IWidgetPosition& wpos)
{
    std::string details;
    details.append("X " + std::to_string(wpos.get_x()));
    details.append(", Y " + std::to_string(wpos.get_y()));
    details.append(", Width " + std::to_string(wpos.get_width()));
    details.append(", Height " + std::to_string(wpos.get_height()));
    return details;
}

static std::string widget_attr (const string_map& map)
{
    std::string details;
    for (auto entry : map)
    {
        details.append(entry.first + "->" + entry.second + ", ");
    }
    return details;
}

IntegraServer::IntegraServer(std::string mainModulePath, std::string thirdPartyPath)
: session_started(false)
{
    sinfo.system_module_directory = mainModulePath;
    sinfo.third_party_module_directory = thirdPartyPath;
    sinfo.notification_sink = &sink;

    // silence debug-trace chatter
    CTrace::set_categories_to_trace(false, false, false);
}

IntegraServer::~IntegraServer()
{
    if (session_started) stop();
}

CError IntegraServer::start()
{
    if (session_started) return CError::SUCCESS;

    CError err = session.start_session(sinfo);
    if (err != CError::SUCCESS)
    {
        return err;
    }
    session_started = true;
    
    CServerLock server = session.get_server();

    // Build moduleGUIDs map, so we can look up GUID for AudioSettings below
    const guid_set& module_ids = server->get_all_module_ids();
    moduleGUIDs.clear();
    for (auto id : module_ids)
    {
        const IInterfaceDefinition *interface_definition = server->find_interface(id);
        const IInterfaceInfo& info = interface_definition->get_interface_info();
        moduleGUIDs.insert(std::pair< std::string, GUID >(info.get_name(), id));
    }

    // Create an AudioSettings object at top level (required to activate audio I/O)
    CPath module_path;
    GUID module_id = moduleGUIDs["AudioSettings"];
    err = server->process_command(INewCommand::create(module_id, "AudioSettings1", module_path));

    return err;
}

void IntegraServer::dump_modules_details()
{
    CServerLock server = session.get_server();

    // Get libIntegra version
    DBG("libIntegra version " + server->get_libintegra_version());

    // Get a complete list of available module IDs and some information about them
    const guid_set& module_ids = server->get_all_module_ids();
    moduleGUIDs.clear();
    for (auto id : module_ids)
    {
        const IInterfaceDefinition *interface_definition = server->find_interface(id);
        const IInterfaceInfo& info = interface_definition->get_interface_info();
        moduleGUIDs.insert(std::pair< std::string, GUID >(info.get_name(), id));

        DBG(info.get_name() + ":");
        for (auto endpoint : interface_definition->get_endpoint_definitions())
        {
            //            DBG("   " + endpoint->get_name() + " (" + endpoint->get_label() + ") " + endpoint->get_description());
            DBG("   " + endpoint->get_name() + " (" + endpoint->get_label() + ") " + endpt_details(endpoint));
        }

        DBG("  Widgets:");
        for (auto widget : interface_definition->get_widget_definitions())
        {
            DBG("   " + widget->get_type() + ": " + widget->get_label());
            DBG("       Position " + widget_pos(widget->get_position()));
            DBG("       Attribute Mappings " + widget_attr(widget->get_attribute_mappings()));
        }

        //        DBG(info.get_name() + " -- " + info.get_description());
        //        DBG(info.get_name() + " -- " + mod_source(interface_definition->get_module_source()));
        //        DBG(info.get_name() + ": " +
        //            CGuidHelper::guid_to_string(id) + "  " +
        //            CGuidHelper::guid_to_string(interface_definition->get_module_guid()) + "  " +
        //            CGuidHelper::guid_to_string(interface_definition->get_origin_guid()) );
    }
}

static void dump_node_tree(INode* root, int indent_level=0)
{
    std::string spaces;
    for (int level=indent_level; level > 0; level--) spaces.append("   ");
    DBG(spaces + root->get_name() /*+ ": " + root->get_path().get_string()*/);

#if 0
    // display userData XML where present
    const IInterfaceDefinition *interface_definition = &(root->get_interface_definition());
    const IInterfaceInfo& info = interface_definition->get_interface_info();
    const node_endpoint_map& endpoints_map = root->get_node_endpoints();
    for (auto ep_entry : endpoints_map)
    {
        std::string ep_name = ep_entry.first;
        if (ep_name == "userData")
        {
            INodeEndpoint* ep = ep_entry.second;
            const CValue* user_data = ep->get_value();
            DBG(spaces + ep_name + ": " + user_data->get_as_string());
        }
    }
#endif

    for (auto child : root->get_children())
        dump_node_tree(child.second, indent_level + 1);
}

void IntegraServer::dump_nodes_details()
{
    CServerLock server = session.get_server();

    DBG("");
    const node_map &nmap = server->get_nodes();
    for (auto entry : nmap)
    {
        dump_node_tree(entry.second);
    }
}

void IntegraServer::dump_state()
{
    session.get_server()->dump_libintegra_state();
}

static const char* cmd_source(CCommandSource src)
{
    // I could just use src.get_text(), but I want to figure out how to set up a
    // switch statement like this.
    switch ((integra_api::CCommandSource::source)src)
    {
        case integra_api::CCommandSource::NONE:
            return "NONE";
        case integra_api::CCommandSource::INITIALIZATION:
            return "INITIALIZATION";
        case integra_api::CCommandSource::LOAD:
            return "LOAD";
        case integra_api::CCommandSource::SYSTEM:
            return "SYSTEM";
        case integra_api::CCommandSource::CONNECTION:
            return "CONNECTION";
        case integra_api::CCommandSource::SCRIPT:
            return "SCRIPT";
        case integra_api::CCommandSource::MODULE_IMPLEMENTATION:
            return "MODULE_IMPLEMENTATION";
        case integra_api::CCommandSource::PUBLIC_API:
            return "PUBLIC_API";
    }
}

// Call this instead of get_changed_endpoints(), not in addition to it
void IntegraServer::dump_changed_endpoints()
{
    CPollingNotificationSink::changed_endpoint_map change_map;
    sink.get_changed_endpoints(change_map);
    if (change_map.empty()) return;

    DBG("\nChanges:");
    for (auto change : change_map)
    {
        std::string endpoint_name(change.first);
        CCommandSource source(change.second);
        DBG("  " + endpoint_name + ": " + cmd_source(source));
    }
}

// Perform breadth-first traversal of a node tree, building a list of node paths in node_paths
void IntegraServer::walk_node_tree(const INode* root)
{
    node_paths.push_back(root->get_path().get_string());
    for (auto child : root->get_children())
        walk_node_tree(child.second);
}

CError IntegraServer::clear_any_loaded_graph()
{
    CServerLock server = session.get_server();

    // If we had loaded a file already, delete that whole node tree
    if (lastLoadedPath.get_number_of_elements() > 0)
    {
        CError err = server->process_command(IDeleteCommand::create(lastLoadedPath));
        if (err != CError::code::SUCCESS)
        {
            DBG("Unable to delete path " + lastLoadedPath.get_string());
            return err;
        }

        node_paths.clear();
        lastLoadedPath = CPath();
    }
    return CError::code::SUCCESS;
}

CError IntegraServer::open_file(std::string integraFilePath)
{
    CError err = clear_any_loaded_graph();
    if (err != CError::code::SUCCESS) return err;

    CServerLock server = session.get_server();

    CPath module_path;
    err = server->process_command(ILoadCommand::create(integraFilePath, module_path));
    if (err == CError::code::SUCCESS)
    {
        // get the path to what we just loaded: it's the first Container object
        for (auto node : server->get_nodes())
        {
            const CPath path = node.second->get_path();
            const IInterfaceDefinition *interface_definition = &(node.second->get_interface_definition());
            const IInterfaceInfo& info = interface_definition->get_interface_info();
            if (info.get_name() == std::string("Container"))
            {
                lastLoadedPath = path;
                break;
            }
        }

        // populate node_paths
        walk_node_tree(server->find_node(lastLoadedPath));

    }
    else DBG(err.get_text());
    return err;
}

void IntegraServer::set_last_loaded_path(CServerLock &server, const CPath& path)
{
    lastLoadedPath = path;
    node_paths.clear();
    walk_node_tree(server->find_node(lastLoadedPath));
}

CError IntegraServer::update_param(std::string paramPath, float value)
{
    CServerLock server = session.get_server();

    return server->process_command(ISetCommand::create(CPath(paramPath), CFloatValue(value)));
}

CError IntegraServer::save_file(std::string saveFilePath)
{
    CServerLock server = session.get_server();

    return server->process_command(ISaveCommand::create(saveFilePath, lastLoadedPath));
}

CError IntegraServer::stop()
{
    if (!session_started) return CError::SUCCESS;
    
    CError err = session.end_session();
    if (err != CError::SUCCESS) DBG(err.get_text());
    else session_started = false;
    return err;
}
