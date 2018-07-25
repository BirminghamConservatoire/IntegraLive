#include "JuceHeader.h"

#include "NumberBoxWidget.h"

//==============================================================================
NumberBoxWidget::NumberBoxWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    // Not yet implemented
    jassertfalse;
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

var NumberBoxWidget::getValue()
{
    // Not yet implemented
    jassertfalse;
    return -1;
}
