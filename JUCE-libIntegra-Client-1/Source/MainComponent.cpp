#include "MainComponent.h"
#include "server_startup_info.h"
#include "integra_session.h"
#include "interface_definition.h"
#include "error.h"
#include "server.h"
#include "server_lock.h"
#include "command.h"
#include "path.h"

MainComponent::MainComponent()
{
    setSize (600, 400);

    startButton.onClick = [this] { integra.start(); };
    startButton.setButtonText ("Start");
    addAndMakeVisible(startButton);

    stopButton.onClick = [this] { integra.stop(); };
    stopButton.setButtonText ("Stop");
    addAndMakeVisible(stopButton);
}

MainComponent::~MainComponent()
{
}

void MainComponent::paint (Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void MainComponent::resized()
{
    auto area = getLocalBounds();
    startButton.setBounds (area.removeFromTop (proportionOfHeight (0.4)));
    stopButton.setBounds (area.removeFromTop (proportionOfHeight (0.4)));
}
