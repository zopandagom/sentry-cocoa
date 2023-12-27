#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SentryEvent.h"
#import "SentryClient+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface SentrySessionReplay : NSObject <SentryClientAttachmentProcessor>

- (void)start:(UIView *)rootView;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
