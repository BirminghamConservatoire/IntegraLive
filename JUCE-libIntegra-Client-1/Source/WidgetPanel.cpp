#include "WidgetPanel.h"

WidgetPanel::WidgetPanel(IntegraServer& server)
: integra(server)
{
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
}

void WidgetPanel::make_label(IWidgetDefinition* widget, const IWidgetPosition& pos)
{
    Label* label = new Label("lbl" + widget->get_label(), widget->get_label());
    label->setJustificationType(Justification(Justification::Flags::centred));
    label->setBounds(pos.get_x(), pos.get_y() + pos.get_height(), pos.get_width(), 24);
    addAndMakeVisible(label);
}

void WidgetPanel::make_slider(IWidgetDefinition* widget, const INode* node)
{
    Slider* slider = new Slider();
    Slider::SliderStyle style = Slider::SliderStyle::LinearBar;
    const IWidgetPosition& pos = widget->get_position();
    if (pos.get_height() > pos.get_width()) style = Slider::SliderStyle::LinearBarVertical;
    slider->setSliderStyle(style);
    slider->setBounds(pos.get_x(), pos.get_y(), pos.get_width(), pos.get_height());

    

    addAndMakeVisible(slider);
    make_label(widget, pos);
}

void WidgetPanel::make_checkbox(IWidgetDefinition* widget, const INode* node)
{
    ToggleButton* toggle = new ToggleButton();
    const IWidgetPosition& pos = widget->get_position();
    toggle->setBounds(pos.get_x(), pos.get_y(), pos.get_width(), pos.get_height());
    addAndMakeVisible(toggle);
    make_label(widget, pos);
}

void WidgetPanel::make_drywet(IWidgetDefinition* widget, const INode* node)
{
    make_slider(widget, node);
}

void WidgetPanel::populate(CPath activeNodePath)
{
    clear();
    nodePath = activeNodePath;

    CServerLock server = integra.get_session().get_server();
    const INode* node = server->find_node(activeNodePath);
    const IInterfaceDefinition& interface = node->get_interface_definition();

    for (auto widget : interface.get_widget_definitions())
    {
        std::string type = widget->get_type();
        if (type == "DryWetBalance") make_drywet(widget, node);
        else if (type == "Slider") make_slider(widget, node);
        else if (type == "Checkbox") make_checkbox(widget, node);
    }
}
