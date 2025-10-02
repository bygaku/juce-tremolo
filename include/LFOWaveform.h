#pragma once

#include "ComboBoxItemList.h"


/** Waveform type enum
*/
enum class LFOType {
    kSine,      
    kSquare,
    kTriangle,
    kSaw,
    kReverseSaw
};


/** List of waveform types for ComboBox
*/
ComboBoxItemList<LFOType> lfoTypeList = {
    { LFOType::kSine,        "Sine" },
    { LFOType::kSquare,      "Square" },
    { LFOType::kTriangle,    "Triangle" },
    { LFOType::kSaw,         "Saw" },
    { LFOType::kReverseSaw,  "Reverse Saw" }
};
