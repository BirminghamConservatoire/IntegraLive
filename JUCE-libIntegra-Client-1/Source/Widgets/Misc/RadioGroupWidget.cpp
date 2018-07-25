#include "JuceHeader.h"

#include "RadioGroupWidget.h"

//==============================================================================
RadioGroupWidget::RadioGroupWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
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
