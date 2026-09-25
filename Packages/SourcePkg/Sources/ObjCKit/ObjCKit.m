#import "ObjCKit.h"

@implementation OBJKAudioMixer
- (instancetype)initWithObjkChannelCount:(NSUInteger)channelCount {
    if ((self = [super init])) { _objkChannelCount = channelCount; }
    return self;
}
- (void)objkSetGain:(float)gain forChannel:(NSUInteger)channel {}
@end
