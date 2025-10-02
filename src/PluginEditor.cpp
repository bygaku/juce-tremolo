#include "PluginProcessor.h"
#include "PluginEditor.h"


//==============================================================================
PluginAudioProcessorEditor::PluginAudioProcessorEditor (PluginAudioProcessor& p)
    : AudioProcessorEditor (&p), processorRef (p)
{
    juce::ignoreUnused (processorRef);
    
    // setup ComboBox
    addAndMakeVisible(waveformSelector);
    
    // apply items to ComboBox
    lfoTypeList.applyTo(waveformSelector);
    
    // connect parameter and ComboBox
    waveformAttachment = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(
        processorRef.parameters,
        "waveformType",
        waveformSelector
    );

    // Make sure that before the constructor has finished, you've set the
    // editor's size to whatever you need it to be.
    setSize (400, 300);

}

PluginAudioProcessorEditor::~PluginAudioProcessorEditor()
{
}

//==============================================================================
void PluginAudioProcessorEditor::paint (juce::Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (juce::ResizableWindow::backgroundColourId));

    g.setColour (juce::Colours::white);
    g.setFont (15.0f);
    g.drawFittedText ("Hello World!", getLocalBounds(), juce::Justification::centred, 1);
}

void PluginAudioProcessorEditor::resized()
{
    // This is generally where you'll want to lay out the positions of any
    // subcomponents in your editor..

    // get area for layout
    auto area = getLocalBounds();
    
    // add margin
    area.reduce(10, 10);
    
    // set bounds for waveform selector
    waveformSelector.setBounds(area.removeFromTop(30));
}
