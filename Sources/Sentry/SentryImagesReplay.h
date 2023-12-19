#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryImagesReplay : NSObject

- (instancetype)initWithOutputPath:(NSString *)outputPath;

- (void)addFrame:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
