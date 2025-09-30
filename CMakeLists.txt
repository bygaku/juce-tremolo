cmake_minimum_required(VERSION 3.22)

set(PROJECT_NAME "OTremolo")
set(PRODUCT_NAME "OTremolo")
set(COMPANY_NAME "bygaku")
set(COMPANY_CODE "byga")
set(PLUGIN_CODE "OTRE")
set(BUNDLE_ID "com.bygaku.OTremolo")

project(${PROJECT_NAME} VERSION 0.0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/utf-8 /TP)
endif()

# submodules
add_subdirectory(lib/JUCE)

juce_add_plugin(
    ${PROJECT_NAME}
    COMPANY_NAME "${COMPANY_NAME}"
    COMPANY_COPYRIGHT "${COMPANY_NAME}"
    BUNDLE_ID "com.${BUNDLE_ID}.${PROJECT_NAME}"
    IS_SYNTH FALSE
    NEEDS_MIDI_INPUT FALSE
    NEEDS_MIDI_OUTPUT FALSE
    IS_MIDI_EFFECT FALSE
    EDITOR_WANTS_KEYBOARD_FOCUS FALSE
    COPY_PLUGIN_AFTER_BUILD TRUE
    PLUGIN_MANUFACTURER_CODE ${COMPANY_CODE}
    PLUGIN_CODE ${PLUGIN_CODE}
    FORMATS Standalone VST3
    PRODUCT_NAME "${PRODUCT_NAME}"
)

target_sources(
    ${PROJECT_NAME}
    PRIVATE
        src/PluginProcessor.cpp
        src/PluginEditor.cpp
)

target_include_directories(
    ${PROJECT_NAME}
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_definitions(
    ${PROJECT_NAME}
    PUBLIC
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        JUCE_VST3_CAN_REPLACE_VST2=0
        JUCE_DISPLAY_SPLASH_SCREEN=0
)

target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC
        juce::juce_audio_basics
        juce::juce_audio_devices
        juce::juce_audio_formats
        juce::juce_audio_plugin_client
        juce::juce_audio_processors
        juce::juce_audio_utils
        juce::juce_core
        juce::juce_data_structures
        juce::juce_events
        juce::juce_graphics
        juce::juce_gui_basics
        juce::juce_dsp
)

juce_generate_juce_header(${PROJECT_NAME})