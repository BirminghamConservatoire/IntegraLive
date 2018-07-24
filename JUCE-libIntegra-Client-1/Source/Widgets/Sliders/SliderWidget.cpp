#include "JuceHeader.h"

#include "SliderWidget.h"

//==============================================================================
SliderWidget::SliderWidget ()
{
    slider.onValueChange = [this] { sliderMoved (); };

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

//==============================================================================
void SliderWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void SliderWidget::resized ()
{
    Widget::resized ();
    
    if (getWidth() > getHeight())
    {
        Widget::setWidgetLabel ("VSlider");
        slider.setSliderStyle (Slider::SliderStyle::LinearVertical);
    }
    else
    {
        Widget::setWidgetLabel ("HSlider");
        slider.setSliderStyle (Slider::SliderStyle::LinearVertical);
    }

    slider.setBounds (controllerBounds);
}

//==========================================================================
void SliderWidget::sliderMoved ()
{
    DBG ("SLIDER MOVED");
}
