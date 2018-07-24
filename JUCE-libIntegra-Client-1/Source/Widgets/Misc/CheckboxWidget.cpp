#include "JuceHeader.h"

#include "CheckboxWidget.h"

//==============================================================================
CheckboxWidget::CheckboxWidget ()
{
    Widget::setWidgetLabel ("Checkbox");
    toggle.setButtonText ("Toggle");
    toggle.onClick = [this] { toggleAction (); };

    toggle.setColour (ToggleButton::tickColourId, Colours::black);
    toggle.setColour (ToggleButton::ColourIds::tickDisabledColourId, Colours::black);

    addAndMakeVisible (toggle);
}

CheckboxWidget::~CheckboxWidget () = default;

//==============================================================================
void CheckboxWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void CheckboxWidget::resized ()
{
    Widget::resized ();

    toggle.setBounds (controllerBounds);
}

//==============================================================================
void CheckboxWidget::toggleAction ()
{
    std::cout << "Checkbox Clicked" << std::endl;

}
