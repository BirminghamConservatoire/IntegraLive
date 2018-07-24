#include "JuceHeader.h"
#include "RecordButtonWidget.h"

//==============================================================================
RecordButtonWidget::RecordButtonWidget ()
: button ({ "Record" }, DrawableButton::ButtonStyle::ImageFitted)
//:   ButtonWidgetBase (ButtonType::Record, { "Record" })
{
    Widget::setWidgetLabel (button.getName ());

    auto normalIcon = createIcon (IconStyle::Normal);
    auto overIcon = createIcon (IconStyle::Over);
    auto downIcon = createIcon (IconStyle::Down);
    auto normalOnIcon = createIcon (IconStyle::NormalOn);
    auto overOnIcon = createIcon (IconStyle::OverOn);
    auto downOnIcon = createIcon (IconStyle::DownOn);
    button.setImages (&normalIcon,
                      &overIcon,
                      &downIcon,
                      &normalOnIcon,
                      &overOnIcon,
                      &downOnIcon);

    button.setColour (DrawableButton::ColourIds::backgroundOnColourId, Colours::transparentWhite);
    button.onClick = [this] { buttonClicked (); };
    button.setClickingTogglesState (true);

    addAndMakeVisible (button);

}

RecordButtonWidget::~RecordButtonWidget () = default;

//==============================================================================
void RecordButtonWidget::paint (Graphics& g)
{
    Widget::paint (g);
}


const DrawablePath RecordButtonWidget::createIcon (const IconStyle style) const
{
    const auto area = Rectangle<float> (0, 0, 100, 100);
    DrawablePath icon;

    Path iconPath;
    auto iconArea = area.reduced (20);
    if (style == IconStyle::Normal)
    {
        iconPath.addEllipse (area);
        icon.setFill (FillType (baseColour));
    }
    else if (style == IconStyle::Over)
    {
        iconPath.addEllipse (area);
        icon.setFill (FillType (baseColour.contrasting (0.2f)));
    }

    else if (style == IconStyle::Down)
    {
        iconPath.addEllipse (area);
        icon.setFill (FillType (baseColour.contrasting (0.6f)));
    }
    else if (style == IconStyle::NormalOn)
    {
        iconPath.addEllipse (area.reduced (proportionOfWidth (0.2)));
        icon.setFill (FillType (baseColour));
    }
    else if (style == IconStyle::OverOn)
    {
        iconPath.addEllipse (area.reduced (proportionOfWidth (0.2)));
        icon.setFill (FillType (baseColour.contrasting (0.2f)));
    }

    else if (style == IconStyle::DownOn)
    {
        iconPath.addEllipse (area.reduced (proportionOfWidth (0.2)));
        icon.setFill (FillType (baseColour.contrasting (0.6f)));
    }

    icon.setPath (iconPath);

    return icon;
}

void RecordButtonWidget::resized ()
{
    Widget::resized ();
    button.setBounds (controllerBounds);
}

//==============================================================================
void RecordButtonWidget::buttonClicked ()
{
    String state (button.getToggleState () ? "On" : "Off");
    std::cout << "RECORD BUTTON: " + state << std::endl;
}
