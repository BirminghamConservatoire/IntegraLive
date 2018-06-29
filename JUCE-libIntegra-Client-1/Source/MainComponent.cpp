#include "MainComponent.h"

MainComponent::MainComponent()
: integra("/Users/shane/Documents/GitHub/IntegraLive/IntegraLive/modules",
          "/Users/shane/Documents/GitHub/IntegraLive/IntegraLive/third_party_modules")
, widgetPanel(integra)
{
    setSize (800, 600);

    getModulesBtn.onClick = [this] { integra.dump_modules_details(); };
    getModulesBtn.setButtonText ("Dump module details");
    addAndMakeVisible(getModulesBtn);

    getNodesBtn.onClick = [this] { integra.dump_nodes_details(); };
    getNodesBtn.setButtonText ("Dump node details");
    addAndMakeVisible(getNodesBtn);

    dumpStateBtn.onClick = [this] { integra.dump_state(); };
    dumpStateBtn.setButtonText ("Dump state");
    addAndMakeVisible(dumpStateBtn);

    loadFileBtn.onClick = [this] {
        integra.open_file("/Users/shane/Desktop/Integra Live/SimpleDelay.integra");
        widgetPanel.clear();
        populateNodeCombo();
    };
    loadFileBtn.setButtonText ("Load SimpleDelay.integra");
    addAndMakeVisible(loadFileBtn);

    loadFile2Btn.onClick = [this] {
//        integra.open_file("/Users/shane/Desktop/Integra Live/StereoChorus.integra");
        integra.open_file("/Users/shane/Desktop/Integra Live/learning(fixed).integra");
        widgetPanel.clear();
        populateNodeCombo();
    };
//    loadFile2Btn.setButtonText ("Load StereoChorus.integra");
    loadFile2Btn.setButtonText ("Load learning(fixed).integra");
    addAndMakeVisible(loadFile2Btn);

    updateParamBtn.onClick = [this] { integra.update_param("SimpleDelay.Track1.Block1.Delay1.delayTime", 1.0f); };
    updateParamBtn.setButtonText ("Update delay time");
    addAndMakeVisible(updateParamBtn);

    saveFileBtn.onClick = [this] { integra.save_file("/Users/shane/Desktop/test.integra"); };
    saveFileBtn.setButtonText ("Save file");
    addAndMakeVisible(saveFileBtn);

    nodeCombo.setEditableText(false);
    nodeCombo.onChange = [this] {
        int path_index = nodeCombo.getSelectedItemIndex();
        if (path_index >= 0)
        {
            // path_index may be -1 when rebuilding the list
            widgetPanel.populate(CPath(integra.get_node_paths()[path_index]));
        }
    };
    addAndMakeVisible(nodeCombo);

    addAndMakeVisible(widgetPanel);

    integra.start();
}

MainComponent::~MainComponent()
{
    integra.stop();
}

void MainComponent::paint (Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void MainComponent::resized()
{
    int buttonHeight = 30;
    int comboHeight = 36;

    auto area = getLocalBounds();

    getModulesBtn.setBounds(area.removeFromTop(buttonHeight));
    getNodesBtn.setBounds(area.removeFromTop(buttonHeight));
    dumpStateBtn.setBounds(area.removeFromTop(buttonHeight));
    loadFileBtn.setBounds(area.removeFromTop(buttonHeight));
    loadFile2Btn.setBounds(area.removeFromTop(buttonHeight));
    updateParamBtn.setBounds(area.removeFromTop(buttonHeight));
    saveFileBtn.setBounds(area.removeFromTop(buttonHeight));

    nodeCombo.setBounds(area.removeFromTop(comboHeight));

    widgetPanel.setBounds(area);
}

void MainComponent::populateNodeCombo()
{
    nodeCombo.clear();
    int itemId = 1;
    for (auto path : integra.get_node_paths())
    {
        nodeCombo.addItem(path, itemId++);
    }
}
