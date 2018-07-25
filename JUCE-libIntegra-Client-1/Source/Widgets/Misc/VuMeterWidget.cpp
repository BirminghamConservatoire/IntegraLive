#include "JuceHeader.h"
#include "VuMeterWidget.h"

//==============================================================================
VuMeterWidget::VuMeterWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("VU Meter");

    addAndMakeVisible (meter);
}

VuMeterWidget::~VuMeterWidget () = default;

//==============================================================================
void VuMeterWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void VuMeterWidget::resized ()
{
    Widget::resized ();

    meter.setBounds (controllerBounds);
}

//==============================================================================
void VuMeterWidget::setValue (var value)
{
    DBG ("VU CHANGE");
    meter.setValue (value);
}