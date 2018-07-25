#include "JuceHeader.h"

#include "DryWetBalanceWidget.h"

//==============================================================================
DryWetBalanceWidget::DryWetBalanceWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("Dry / Wet");

    slider.onValueChange = [this] { sliderMoved (); };

    slider.setSliderStyle (Slider::SliderStyle::LinearBar);

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

DryWetBalanceWidget::~DryWetBalanceWidget () = default;

//==============================================================================
void DryWetBalanceWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void DryWetBalanceWidget::resized ()
{
    Widget::resized ();

    slider.setBounds (controllerBounds);
}
void DryWetBalanceWidget::sliderMoved ()
{
    std::cout << "DRY WET MOVED" << std::endl;
}