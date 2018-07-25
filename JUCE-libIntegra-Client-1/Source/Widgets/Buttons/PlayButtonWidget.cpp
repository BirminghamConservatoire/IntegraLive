#include "JuceHeader.h"

#include "PlayButtonWidget.h"

//==============================================================================
PlayButtonWidget::PlayButtonWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition),
    button ({ "Play" }, DrawableButton::ButtonStyle::ImageFitted)
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

PlayButtonWidget::~PlayButtonWidget () = default;

//==============================================================================
void PlayButtonWidget::paint (Graphics& g)
{
    Widget::paint (g);
}


const DrawablePath PlayButtonWidget::createIcon (const IconStyle style) const
{
    const auto area = Rectangle<float> (0, 0, 100, 100);
    DrawablePath icon;

    Path iconPath;
    auto iconArea = area.reduced (20);
    if (style == IconStyle::Normal)
    {
        iconPath.addTriangle (0, 0,
                              100, 50,
                              0, 100);
        icon.setFill (FillType (baseColour));
    }
    else if (style == IconStyle::Over)
    {
        iconPath.addTriangle (0, 0,
                              100, 50,
                              0, 100);
        icon.setFill (FillType (baseColour.contrasting (0.2f)));
    }

    else if (style == IconStyle::Down)
    {
        iconPath.addTriangle (0, 0,
                              100, 50,
                              0, 100);
        icon.setFill (FillType (baseColour.contrasting (0.6f)));
    }
    else if (style == IconStyle::NormalOn)
    {
        auto rectangleSize = iconArea.proportionOfWidth (0.3);
        iconPath.addRectangle (iconArea.removeFromLeft (rectangleSize));
        iconPath.startNewSubPath (iconArea.getTopLeft ());
        iconPath.addRectangle (iconArea.removeFromRight (rectangleSize));
        iconPath.closeSubPath ();
        icon.setFill (FillType (Colours::green));
    }
    else if (style == IconStyle::OverOn)
    {
        auto rectangleSize = iconArea.proportionOfWidth (0.3);
        iconPath.addRectangle (iconArea.removeFromLeft (rectangleSize));
        iconPath.startNewSubPath (iconArea.getTopLeft ());
        iconPath.addRectangle (iconArea.removeFromRight (rectangleSize));
        iconPath.closeSubPath ();
        icon.setFill (FillType (Colours::green.contrasting (0.2f)));
    }

    else if (style == IconStyle::DownOn)
    {
        auto rectangleSize = iconArea.proportionOfWidth (0.3);
        iconPath.addRectangle (iconArea.removeFromLeft (rectangleSize));
        iconPath.startNewSubPath (iconArea.getTopLeft ());
        iconPath.addRectangle (iconArea.removeFromRight (rectangleSize));
        iconPath.closeSubPath ();
        icon.setFill (FillType (Colours::green.contrasting (0.6f)));
    }

    icon.setPath (iconPath);

    return icon;
}

void PlayButtonWidget::resized ()
{
    Widget::resized ();
    button.setBounds (controllerBounds);
}

//==============================================================================
void PlayButtonWidget::buttonClicked ()
{
    DBG ("BUTTON CLICKED");
}
