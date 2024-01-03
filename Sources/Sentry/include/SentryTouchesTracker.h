#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SentryUITouch.h"

NS_ASSUME_NONNULL_BEGIN

@interface SentryTouchesTracker : NSObject

- (void)start;
- (void)stop;

- (NSArray<SentryUITouch *> *)touchsFrom:(NSDate *)from to:(NSDate *)to;

@end

NS_ASSUME_NONNULL_END
