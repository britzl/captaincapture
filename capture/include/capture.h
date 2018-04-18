#pragma once

#include <dmsdk/sdk.h>


extern "C" {
    void Capture_PlatformStart(const char* path);
    void Capture_PlatformStop();
}
