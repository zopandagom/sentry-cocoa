#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SentryBreadcrumbTracker : NSObject

+ (NSDictionary *)extractDataFromView:(UIView *)view;

@end


@interface SentryViewPhotographer : NSObject

@property (nonatomic, readonly, class) SentryViewPhotographer* shared;

-(UIImage*)imageFromUIView:(UIView *)view;

@end
