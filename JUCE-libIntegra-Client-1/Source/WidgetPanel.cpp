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
    widget_map.clear();
}

void WidgetPanel::populate (CPath activeNodePath)
{
    clear();
    nodePath = activeNodePath;

    auto server = integra.get_session ().get_server ();
    const auto node = server->find_node (activeNodePath);
    const auto& nodeDefinition = node->get_interface_definition ();

    for (auto& widget : nodeDefinition.get_widget_definitions())
        widgetBuilder.buildWidget (*widget);
}

void WidgetPanel::update()
{
    CPollingNotificationSink::changed_endpoint_map change_map;
    integra.get_changed_endpoints(change_map);
    if (change_map.empty()) return;

    for (auto change : change_map)
    {
        std::string endpoint_name(change.first);
        //CCommandSource source(change.second);

        auto it = widget_map.find(endpoint_name);
        if (it != widget_map.end())
        {
            //TODO: Implement Integra Session communication between widgets
        }
    }
}
