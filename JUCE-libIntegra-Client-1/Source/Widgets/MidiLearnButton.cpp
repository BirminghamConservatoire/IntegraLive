#include "JuceHeader.h"
#include "MidiLearnButton.h"

//==============================================================================
MidiLearnButton::MidiLearnButton () = default;

MidiLearnButton::~MidiLearnButton () = default;

//==============================================================================
void MidiLearnButton::paint (Graphics& g)
{
    const auto circleSize = std::min (proportionOfHeight (0.1), proportionOfWidth (0.1));
    auto area = getLocalBounds ();
    auto circlesArea = area.removeFromBottom (proportionOfHeight (0.5)).reduced (1);

    if (flashing)
        g.fillAll (Colours::blue.darker ());
    else
        g.fillAll (Colours::aliceblue.darker (0.1));

    Path iconPath;
//    iconPath.addRectangle (area.removeFromTop (rectangleHeight).
//                           reduced (proportionOfWidth (0.4)));
    iconPath.addEllipse (getX () + 5, getY () + 55, circleSize, circleSize);
    iconPath.addEllipse (getX () + 20, getY () + 75, circleSize, circleSize);
    iconPath.addEllipse (getX () + 85, getY () + 55, circleSize, circleSize);
    iconPath.addEllipse (getX () + 70, getY () + 75, circleSize, circleSize);
    iconPath.addEllipse (getX () + 45, getY () + 85, circleSize, circleSize);

    g.setColour (Colours::black);
    g.fillPath (iconPath);
}
void MidiLearnButton::timerCallback ()
{
    flashing = ! flashing;
    repaint ();
}
void MidiLearnButton::mouseDown (const MouseEvent& event)
{
    learning = ! learning;

    std::cout << learning << std::endl;
    if (learning)
        startTimer (300);
    else
    {
        stopTimer ();
        flashing = false;
    }

    repaint ();
}
