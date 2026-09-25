#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBJKAudioMixer : NSObject
@property (nonatomic, readonly) NSUInteger objkChannelCount;
- (instancetype)initWithObjkChannelCount:(NSUInteger)channelCount;
- (void)objkSetGain:(float)gain forChannel:(NSUInteger)channel;
@end

typedef NS_ENUM(NSInteger, OBJKMixerMode) {
    OBJKMixerModeStereo,
    OBJKMixerModeSurround,
};

NS_ASSUME_NONNULL_END
