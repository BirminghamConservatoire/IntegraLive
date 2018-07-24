#include "JuceHeader.h"

#include "VuMeterWidget.h"

//==============================================================================
VuMeterWidget::VuMeterWidget ()
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
void VuMeterWidget::setValue (double value)
{
    meter.setValue (value);
}
