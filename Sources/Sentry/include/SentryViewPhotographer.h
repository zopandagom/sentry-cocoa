#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryViewPhotographer : NSObject


@property (nonatomic, readonly, class) SentryViewPhotographer* shared;

-(UIImage*)imageFromUIView:(UIView *)view;


@end

NS_ASSUME_NONNULL_END
