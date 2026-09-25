#include "EngineC.h"

EngineCMixHandle engine_c_make_mix(int trackCount) {
    EngineCMixHandle h = { trackCount, 120.0 };
    return h;
}

void engine_c_set_tempo(EngineCMixHandle *handle, double tempo) {
    handle->engineCTempo = tempo;
}
