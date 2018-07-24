#include "JuceHeader.h"
#include "EarlyLateBalanceController.h"

//==============================================================================
EarlyLateBalanceController::EarlyLateBalanceController () = default;

EarlyLateBalanceController::~EarlyLateBalanceController () = default;

//==============================================================================
void EarlyLateBalanceController::paint (Graphics& g)
{
    auto area = getLocalBounds ();

    g.fillRect (Rectangle<float> (area.getTopLeft().x, area.getTopLeft().y,
                                  getPositionOfValue (getValue()), getHeight()));
}
