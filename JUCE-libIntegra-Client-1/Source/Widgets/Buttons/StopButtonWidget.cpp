#include "JuceHeader.h"
#include "StopButtonWidget.h"

//==============================================================================
StopButtonWidget::StopButtonWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition),
    button ({ "Stop" }, DrawableButton::ButtonStyle::ImageFitted)
{
    Widget::setWidgetLabel (button.getName ());

    auto normalIcon = createIcon (IconStyle::Normal);
    auto overIcon = createIcon (IconStyle::Over);
    auto downIcon = createIcon (IconStyle::Down);

    button.setImages (&normalIcon,
                      &overIcon,
                      &downIcon);

    button.onClick = [this] { buttonClicked (); };

    addAndMakeVisible (button);
}

StopButtonWidget::~StopButtonWidget () = default;

//==============================================================================
void StopButtonWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

const DrawablePath StopButtonWidget::createIcon (const IconStyle style) const
{
    const auto area = Rectangle<float> (0, 0, 100, 100);
    DrawablePath icon;
    icon.setFill (FillType (Colours::red));

    Path iconPath;
    auto iconArea = area.reduced (20);

    if (style == IconStyle::Normal)
    {
        iconPath.addRectangle (iconArea);
        icon.setFill (FillType (baseColour));
    }
    else if (style == IconStyle::Over)
    {
        iconPath.addRectangle (iconArea);
        icon.setFill (FillType (baseColour.contrasting (0.2f)));
    }

    else if (style == IconStyle::Down)
    {
        iconPath.addRectangle (iconArea);
        icon.setFill (FillType (baseColour.contrasting (0.6f)));
    }

    icon.setPath (iconPath);

    return icon;
}

void StopButtonWidget::resized ()
{
    Widget::resized ();
    button.setBounds (controllerBounds);
}

//==============================================================================
void StopButtonWidget::buttonClicked ()
{
    DBG ("BUTTON CLICKED");
}

var StopButtonWidget::getValue()
{
    return button.getToggleState();
}
