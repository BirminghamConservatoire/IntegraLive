#include "JuceHeader.h"

#include "NumberBoxWidget.h"

//==============================================================================
NumberBoxWidget::NumberBoxWidget () = default;

NumberBoxWidget::~NumberBoxWidget () = default;

//==============================================================================
void NumberBoxWidget::paint (Graphics& g)
{
    g.fillAll (getLookAndFeel ().findColour (ResizableWindow::backgroundColourId));
}

void NumberBoxWidget::resized ()
{
}
