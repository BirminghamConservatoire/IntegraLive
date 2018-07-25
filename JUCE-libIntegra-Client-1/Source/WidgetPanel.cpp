#include "WidgetPanel.h"

WidgetPanel::WidgetPanel (IntegraServer& server)
: integra(server), widgetBuilder (*this)
{
    setFramesPerSecond(15);
}

WidgetPanel::~WidgetPanel()
{
    clear();
}

void WidgetPanel::paint (Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void WidgetPanel::resized()
{
}

void WidgetPanel::clear()
{
    deleteAllChildren();
    widgetMap.clear();
}

void WidgetPanel::populate (CPath activeNodePath)
{
    clear();
    nodePath = activeNodePath;

    auto server = integra.get_session ().get_server ();
    const auto* node = server->find_node (activeNodePath);
    const auto& nodeDefinition = node->get_interface_definition ();

    for (auto& widgetDefinition : nodeDefinition.get_widget_definitions())
    {
        auto* widget = widgetBuilder.createWidget (*widgetDefinition);
        const auto& widgetEndpointName = widget->getEndpointName ();
        const auto* endpoint = node->get_node_endpoint (widgetEndpointName);
        const auto& endpointPath = endpoint->get_path ();
        
        DBG ("Setup: " + endpointPath);
        
        const auto endpointType = endpoint->get_endpoint_definition ().get_control_info ()->get_state_info ()->get_type ();
        
        if (endpointType == CValue::type::INTEGER)
        {
            auto value = static_cast<CIntegerValue> ( widget->getValue () );
            widget->onValueChange = [&] { setIntegraValue (endpointPath, value); };
        }
        else if (endpointType == CValue::type::FLOAT)
        {
            auto value = static_cast<CFloatValue> ( widget->getValue () );
            widget->onValueChange = [&] { setIntegraValue (endpointPath, value); };
        }
        else
        {
            auto value = static_cast<CStringValue> (String ((float) widget->getValue ()).toStdString()  );
                widget->onValueChange = [&] { setIntegraValue (endpointPath, value); };
        }
        
        widgetMap[widget->getEndpointName ()] = widget;
        
    }
}

void WidgetPanel::update()
{
    CPollingNotificationSink::changed_endpoint_map changes;
    integra.get_changed_endpoints (changes);
    if (changes.empty ())
        return;

    for (auto& change : changes)
    {
        auto endpointName { change.first };
        
        DBG ("Changed: " + endpointName);
        
        auto iterator = widgetMap.find (endpointName);
        if (iterator != widgetMap.end())
        {
            auto& widget = iterator->second;
            
            auto server = integra.get_session ().get_server ();
            const auto* value = server->get_value ({ endpointName });
            DBG (value->get_type ());
            widget->setValue (value);
        }
    }
}

template <typename Type>
void WidgetPanel::setIntegraValue (integra_api::CPath path, Type value)
{
    auto server = integra.get_session ().get_server ();
    server->process_command (ISetCommand::create (path, value));
}
