#include "JuceHeader.h"
#include "PanoramaBalanceWidget.h"

//==============================================================================
PanoramaBalanceWidget::PanoramaBalanceWidget ()
{
    Widget::setWidgetLabel ("Balance");

    slider.onValueChange = [this] { sliderMoved (); };

    slider.setSliderStyle (Slider::SliderStyle::LinearBar);

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

//==============================================================================
void PanoramaBalanceWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void PanoramaBalanceWidget::resized ()
{
    Widget::resized ();

    slider.setBounds (controllerBounds);
}
void PanoramaBalanceWidget::sliderMoved ()
{
    std::cout << "PANORAMA BALANCE MOVED" << std::endl;
}
