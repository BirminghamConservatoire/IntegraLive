#include "JuceHeader.h"

#include "XyScratchPadWidget.h"

//==============================================================================
XyScratchPadWidget::XyScratchPadWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    // Widget not yet implemented
    jassertfalse;
}

XyScratchPadWidget::~XyScratchPadWidget () = default;

//==============================================================================
void XyScratchPadWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void XyScratchPadWidget::resized()
{
    Widget::resized();
}

var XyScratchPadWidget::getValue()
{
    // Not yet implemented
    jassertfalse;
    return -1;
}
