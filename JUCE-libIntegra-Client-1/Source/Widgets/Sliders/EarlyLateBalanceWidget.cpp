#include "JuceHeader.h"
#include "EarlyLateBalanceWidget.h"

//==============================================================================
EarlyLateBalanceWidget::EarlyLateBalanceWidget ()
{
    Widget::setWidgetLabel ("Early / Late");

    slider.onValueChange = [this] { sliderMoved (); };

    slider.setSliderStyle (Slider::SliderStyle::LinearBar);

    slider.setTextBoxStyle (Slider::NoTextBox, false, 0, 0);

    addAndMakeVisible (slider);
}

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
