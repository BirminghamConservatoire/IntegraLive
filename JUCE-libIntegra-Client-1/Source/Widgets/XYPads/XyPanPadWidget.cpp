#include "JuceHeader.h"
#include "XyPanPadWidget.h"

//==============================================================================
XyPanPadWidget::XyPanPadWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    // Widget not yet implemented
    jassertfalse;
    addAndMakeVisible (pad);
}

XyPanPadWidget::~XyPanPadWidget () = default;

//==============================================================================
void XyPanPadWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void XyPanPadWidget::resized()
{
    Widget::resized ();
    pad.setBounds (controllerBounds);
}

var XyPanPadWidget::getValue()
{
    // Not yet implemented
    jassertfalse;
    return -1;
}
