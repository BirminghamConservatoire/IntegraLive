#include "JuceHeader.h"
#include "EarlyLateBalanceWidget.h"

//==============================================================================
EarlyLateBalanceWidget::EarlyLateBalanceWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("Early / Late");

    slider.onValueChange = [this] { sliderMoved (); };

    slider.setSliderStyle (Slider::SliderStyle::LinearBar);

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

EarlyLateBalanceWidget::~EarlyLateBalanceWidget () = default;

//==============================================================================
void EarlyLateBalanceWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void EarlyLateBalanceWidget::resized ()
{
    Widget::resized ();

    slider.setBounds (controllerBounds);
}

void EarlyLateBalanceWidget::sliderMoved ()
{
    std::cout << "EARLY LATE MOVED" << std::endl;
}

var EarlyLateBalanceWidget::getValue()
{
    return slider.getValue();
}
