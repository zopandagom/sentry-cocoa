#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryReplaySettings : NSObject

/**
 * Indicates the percentage in which the replay for the session will be created.
 * @discussion Specifying @c 0 means never, @c 1.0 means always.
 * @note The value needs to be >= 0.0 and \<= 1.0. When setting a value out of range the SDK sets it
 * to the default.
 * @note The default is @c 0.
 */
@property (nonatomic) CGFloat replaysSessionSampleRate;

/**
 * Indicates the percentage in which a 30 seconds replay will be send with error events.
 * @discussion Specifying @c 0 means never, @c 1.0 means always.
 * @note The value needs to be >= 0.0 and \<= 1.0. When setting a value out of range the SDK sets it
 * to the default.
 * @note The default is @c 0.
 */
@property (nonatomic) CGFloat replaysOnErrorSampleRate;

/**
 * Defines the quality of the session replay.
 * Higher bit rates better quality, but also bigger files to transfer.
 * @note The default value is @c 20000;
 */
@property (nonatomic) NSInteger replayBitRate;

- (instancetype)initWithReplaySessionSampleRate:(CGFloat)sessionSampleRate replaysOnErrorSampleRate:(CGFloat)errorSampleRate;

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@end

NS_ASSUME_NONNULL_END
