#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/XyPan.h"

//==============================================================================
/*
*/
class XyPanPadWidget    : public Widget
{
public:
    //==========================================================================
    XyPanPadWidget();
    ~XyPanPadWidget();

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    XyPan pad;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (XyPanPadWidget)
};
