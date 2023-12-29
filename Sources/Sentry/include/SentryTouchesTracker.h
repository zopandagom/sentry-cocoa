#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface SentryTouch : NSObject

@property (nonatomic) CGPoint position;
@property (nonatomic) NSDate * timestamp;
@property (nonatomic) UIToc

@end

@interface SentryTouchesTracker : NSObject

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
