#include "JuceHeader.h"

#include "NumberBoxWidget.h"

//==============================================================================
NumberBoxWidget::NumberBoxWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
}

NumberBoxWidget::~NumberBoxWidget () = default;

//==============================================================================
void NumberBoxWidget::paint (Graphics& g)
{
    g.fillAll (getLookAndFeel ().findColour (ResizableWindow::backgroundColourId));
}

void NumberBoxWidget::resized ()
{
}
