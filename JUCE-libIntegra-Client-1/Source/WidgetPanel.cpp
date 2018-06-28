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

void WidgetPanel::make_checkbox(IWidgetDefinition* widget, const INode* node)
{
    ToggleButton* toggle = new ToggleButton();
    const IWidgetPosition& pos = widget->get_position();
    toggle->setBounds(pos.get_x(), pos.get_y(), pos.get_width(), pos.get_height());
    addAndMakeVisible(toggle);
    make_label(widget, pos);

    // get the endpoint we're controlling (look it up by name)
    const std::string& endpoint_name = widget->get_attribute_mappings().find("value")->second;
    const INodeEndpoint* node_endpoint = node->get_node_endpoint(endpoint_name);

    // set slider value
    toggle->setToggleState(int(*node_endpoint->get_value()) != 0, dontSendNotification);

    // create a listener callback
    CPath endpoint_path = node_endpoint->get_path();
    toggle->onStateChange = [ this, toggle, endpoint_path ] {
        CServerLock server = integra.get_session().get_server();
        server->process_command(ISetCommand::create(CPath(endpoint_path), CIntegerValue(toggle->getToggleState() ? 1 : 0)));
    };
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

    // get the endpoint we're controlling (look it up by name)
    const std::string& endpoint_name = widget->get_attribute_mappings().find("value")->second;
    const INodeEndpoint* node_endpoint = node->get_node_endpoint(endpoint_name);

    // set slider range and step
    const IEndpointDefinition& endpoint_definition = node_endpoint->get_endpoint_definition();
    const IControlInfo* control_info = endpoint_definition.get_control_info();
    const IStateInfo* control_state_info = control_info->get_state_info();
    const IConstraint& constraint = control_state_info->get_constraint();
    const IValueRange* range = constraint.get_value_range();
    if (control_state_info->get_type() == CValue::type::INTEGER)
    {
        slider->setRange(int(range->get_minimum()), int(range->get_maximum()), 1.0);

        // set slider value
        slider->setValue(int(*node_endpoint->get_value()));
    }
    else
    {
        slider->setRange(float(range->get_minimum()), float(range->get_maximum()));

        // set slider linearity
        switch (control_state_info->get_value_scale()->get_scale_type())
        {
            case IValueScale::scale_type::EXPONENTIAL:
                slider->setSkewFactor(2.5);
            case IValueScale::scale_type::DECIBEL:
                slider->setSkewFactor(0.25);
            default: {}
        }

        // set slider value
        slider->setValue(float(*node_endpoint->get_value()));
    }

    // create a listener callback
    CPath endpoint_path = node_endpoint->get_path();
    slider->onValueChange = [ this, slider, endpoint_path ] {
        CServerLock server = integra.get_session().get_server();
        server->process_command(ISetCommand::create(CPath(endpoint_path), CFloatValue(slider->getValue())));
    };
}

void WidgetPanel::make_knob(IWidgetDefinition* widget, const INode* node)
{
    make_slider(widget, node);
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
        else if (type == "Knob") make_knob(widget, node);
        else if (type == "Checkbox") make_checkbox(widget, node);
    }
}
