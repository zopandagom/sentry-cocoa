#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentrySessionReplay : NSObject

- (void)start:(UIView *)rootView;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
