#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class MidiLearnButton : public Component,
                        public Timer
{
public:
    //==========================================================================
    MidiLearnButton ();
    ~MidiLearnButton ();

    //==========================================================================
    void paint (Graphics&) override;

private:
    //==========================================================================
    bool learning = false;
    bool flashing = false;

    //==========================================================================
    void timerCallback () override;

    //==========================================================================
    void mouseDown (const MouseEvent& event) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MidiLearnButton)
};
