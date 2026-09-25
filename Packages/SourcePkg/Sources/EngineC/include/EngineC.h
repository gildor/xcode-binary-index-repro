#ifndef ENGINEC_H
#define ENGINEC_H

typedef struct EngineCMixHandle {
    int engineCTrackCount;
    double engineCTempo;
} EngineCMixHandle;

EngineCMixHandle engine_c_make_mix(int trackCount);
void engine_c_set_tempo(EngineCMixHandle *handle, double tempo);

#endif
