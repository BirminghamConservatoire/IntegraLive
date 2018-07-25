#include "JuceHeader.h"
#include "SliderWidget.h"

//==============================================================================
SliderWidget::SliderWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    slider.onValueChange = [this] { sliderMoved (); };

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
    
    endpointName = widgetDefinition.get_attribute_mappings ().find ("value")->second;
}

SliderWidget::~SliderWidget () = default;

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

void SliderWidget::setValue (var value)
{
    slider.setValue (value);
}

var SliderWidget::getValue()
{
    return slider.getValue();
}
