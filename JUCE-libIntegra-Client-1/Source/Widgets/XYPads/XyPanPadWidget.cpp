#include "JuceHeader.h"
#include "XyPanPadWidget.h"

//==============================================================================
XyPanPadWidget::XyPanPadWidget()
{
    // Widget not yet implemented
    jassertfalse;
    addAndMakeVisible (pad);
}

XyPanPadWidget::~XyPanPadWidget()
{
}

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
