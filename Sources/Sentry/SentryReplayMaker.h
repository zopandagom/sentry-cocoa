#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryReplayMaker : NSObject

- (instancetype)initWithOutputPath:(NSString *)outputPath
                        frameSize:(CGSize)frameSize
                     framesPerSec:(NSInteger)framesPerSec;

- (void)addFrame:(UIImage *)image withCompletion:(void (^)(BOOL success, NSError *error))completion;


- (void)finalizeVideoWithCompletion:(void (^)(BOOL success, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
