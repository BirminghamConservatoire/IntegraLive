#include "JuceHeader.h"
#include "TriggerWidget.h"

//==============================================================================
TriggerWidget::TriggerWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("Trigger");

    button.setButtonText ("Trigger");
    button.onClick = [this] { buttonAction(); };

    addAndMakeVisible (button);
}

TriggerWidget::~TriggerWidget () = default;

//==============================================================================
void TriggerWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void TriggerWidget::resized()
{
    Widget::resized ();
    button.setBounds (controllerBounds);
}

//==============================================================================
void TriggerWidget::buttonAction()
{
//    setEndpointValue ("TriggerWidget", 5);
//    getEndpointValue<bool> ("TriggerWidget");
}

var TriggerWidget::getValue()
{
    return button.getToggleState();
}
