#include "JuceHeader.h"

#include "RadioGroupWidget.h"

//==============================================================================
RadioGroupWidget::RadioGroupWidget() = default;

RadioGroupWidget::~RadioGroupWidget() = default;

//==============================================================================
void RadioGroupWidget::paint (Graphics& g)
{
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void RadioGroupWidget::resized()
{
}
