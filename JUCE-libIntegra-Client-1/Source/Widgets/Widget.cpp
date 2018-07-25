#include "JuceHeader.h"
#include "Widget.h"

//==============================================================================
Widget::Widget (integra_api::IWidgetDefinition& widgetDefinition)
:   widgetDefinition (widgetDefinition)
{
    const Colour tickColour (Colour::fromRGB (186, 201, 207));
    showInPerformanceToggle.setColour (ToggleButton::ColourIds::tickColourId, tickColour);
    showInPerformanceToggle.setColour (ToggleButton::ColourIds::tickDisabledColourId, tickColour);

    widgetLabel.setJustificationType (Justification::centred);
    widgetLabel.setText ("LABEL", dontSendNotification);

    addAndMakeVisible (showInPerformanceToggle);
    addAndMakeVisible (midiLearnButton);
    addAndMakeVisible (widgetLabel);
    
    const auto& positionInfo = widgetDefinition.get_position ();
    bounds = { positionInfo.get_x (),
               positionInfo.get_y (),
               positionInfo.get_width (),
               positionInfo.get_height () };
}

Widget::~Widget () = default;

//==============================================================================
void Widget::paint (Graphics& g)
{
    auto rectangleSize = proportionOfHeight (0.75);
    auto cornerSize = std::min (proportionOfWidth (0.05), proportionOfHeight (0.05));

    auto area = getLocalBounds ().toFloat ();

    g.setColour (Colours::white);
    g.fillRoundedRectangle (area.removeFromTop (rectangleSize), cornerSize);
}

void Widget::resized ()
{
    const auto borderSize = std::min (proportionOfWidth (0.058), proportionOfHeight (0.058));
    const auto topAreaSize = proportionOfHeight (0.12) - borderSize;
    const auto performanceViewToggleWidth = proportionOfWidth (0.2);
    const auto midiLearnWidth = std::min (topAreaSize, proportionOfWidth (0.2));
    const auto widgetSpacing = std::min (proportionOfWidth (0.05), proportionOfHeight (0.05));
    const auto widgetSize = proportionOfHeight (0.6);
    const auto labelSpacing = proportionOfHeight (0.1);
    const auto labelSize = proportionOfHeight (0.1);

    auto area = getLocalBounds ().reduced (borderSize);

    auto topArea = area.removeFromTop (topAreaSize);
    showInPerformanceToggle.setBounds (topArea.removeFromRight (performanceViewToggleWidth));
    midiLearnButton.setBounds (topArea.removeFromLeft (midiLearnWidth));

    controllerBounds = area.removeFromTop (widgetSize).reduced (widgetSpacing);

    area.removeFromTop (labelSpacing);
    widgetLabel.setBounds (area.removeFromTop (labelSize));
}

//==============================================================================
void Widget::setWidgetLabel (const String& label)
{
    widgetLabel.setText (label, dontSendNotification);
}

//==============================================================================
Rectangle<int> Widget::getWidgetBounds() noexcept
{
    return bounds.toNearestInt();
}
