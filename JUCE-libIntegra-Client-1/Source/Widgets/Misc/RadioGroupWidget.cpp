#include "JuceHeader.h"

#include "RadioGroupWidget.h"

//==============================================================================
RadioGroupWidget::RadioGroupWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    // Not yet implemented
    jassertfalse;
}

RadioGroupWidget::~RadioGroupWidget() = default;

//==============================================================================
void RadioGroupWidget::paint (Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void RadioGroupWidget::resized()
{
}

var RadioGroupWidget::getValue()
{
    // Not yet implemented
    jassertfalse;
    return -1;
}
