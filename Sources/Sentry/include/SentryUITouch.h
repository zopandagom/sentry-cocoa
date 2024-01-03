#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryUITouch : NSObject

@property (nonatomic) CGPoint position;
@property (nonatomic, strong) NSDate * timestamp;
@property (nonatomic) UITouchPhase phase;

@end

NS_ASSUME_NONNULL_END
