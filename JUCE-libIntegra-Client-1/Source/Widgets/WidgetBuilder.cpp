#include "WidgetBuilder.h"
#include "JuceHeader.h"
#include "Widgets.h"
#include "interface_definition.h"

//==============================================================================
WidgetBuilder::WidgetBuilder (Component& ownerView)
:   ownerView (ownerView)
{
}

WidgetBuilder::~WidgetBuilder() = default;

//==============================================================================
Widget* WidgetBuilder::createWidget (integra_api::IWidgetDefinition& widgetDefinition)
{
    auto widgetType = widgetDefinition.get_type();
    Widget* widget;
    
    if (widgetType == "Checkbox")                   widget = new CheckboxWidget (widgetDefinition);
    else if (widgetType == "DryWetBalance")         widget = new DryWetBalanceWidget (widgetDefinition);
    else if (widgetType == "EarlyLateBalance")      widget = new EarlyLateBalanceWidget (widgetDefinition);
    else if (widgetType == "FileSaveDialog")        widget = new FileSaveDialogWidget (widgetDefinition);
    else if (widgetType == "Knob")                  widget = new KnobWidget (widgetDefinition);
    else if (widgetType == "NumberBox")             widget = new NumberBoxWidget (widgetDefinition);
    else if (widgetType == "PanoramaBalance")       widget = new PanoramaBalanceWidget (widgetDefinition);
    else if (widgetType == "PlayButton")            widget = new PlayButtonWidget (widgetDefinition);
    else if (widgetType == "RadioGroup")            widget = new RadioGroupWidget (widgetDefinition);
    else if (widgetType == "RangeSlider")           widget = new RangeSliderWidget (widgetDefinition);
    else if (widgetType == "RecButton")             widget = new RecordButtonWidget (widgetDefinition);
    else if (widgetType == "Slider")                widget = new SliderWidget (widgetDefinition);
    else if (widgetType == "SoundFileLoadDialog")   widget = new SoundFileLoadDialogWidget (widgetDefinition);
    else if (widgetType == "StopButton")            widget = new StopButtonWidget (widgetDefinition);
    else if (widgetType == "Trigger")               widget = new TriggerWidget (widgetDefinition);
    else if (widgetType == "VuMeter")               widget = new VuMeterWidget (widgetDefinition);
    else if (widgetType == "XYPanPad")              widget = new XyPanPadWidget (widgetDefinition);
    else if (widgetType == "XYScratchPad")          widget = new XyScratchPadWidget (widgetDefinition);
    else
        // This should be a valid widget type
        jassertfalse;

    addWidgetToView (*widget, widgetDefinition);

    auto attributeMappings = widgetDefinition.get_attribute_mappings();
    
    
    return widget;
}

//==============================================================================
void WidgetBuilder::addWidgetToView (Widget& widget, integra_api::IWidgetDefinition& widgetDefinition)
{
    ownerView.addAndMakeVisible (widget);
    
    widget.setBounds (widget.getWidgetBounds());
}
