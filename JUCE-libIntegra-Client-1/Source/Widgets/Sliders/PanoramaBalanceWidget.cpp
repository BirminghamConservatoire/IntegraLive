#include "JuceHeader.h"
#include "PanoramaBalanceWidget.h"

//==============================================================================
PanoramaBalanceWidget::PanoramaBalanceWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("Balance");

    slider.onValueChange = [this] { sliderMoved (); };

    slider.setSliderStyle (Slider::SliderStyle::LinearBar);

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

PanoramaBalanceWidget::~PanoramaBalanceWidget () = default;

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
