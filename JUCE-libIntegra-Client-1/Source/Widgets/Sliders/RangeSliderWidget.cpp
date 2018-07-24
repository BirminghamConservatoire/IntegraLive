#include "JuceHeader.h"

#include "RangeSliderWidget.h"

//==============================================================================
RangeSliderWidget::RangeSliderWidget ()
{
    // Widget not yet implemented
    jassertfalse;
    
    Widget::setWidgetLabel ("Range Slider");

    slider.onValueChange = [this] { this->sliderMoved (); };
    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

RangeSliderWidget::~RangeSliderWidget ()
{
}

//==============================================================================
void RangeSliderWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void RangeSliderWidget::resized ()
{
    Widget::resized ();

    slider.setBounds (controllerBounds);
}

//==============================================================================
void RangeSliderWidget::sliderMoved ()
{
    DBG ("Range Slider Moved");
}
