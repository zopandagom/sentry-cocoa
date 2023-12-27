#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryOndemandReplay : NSObject

- (instancetype)initWithOutputPath:(NSString *)outputPath;

- (void)addFrame:(UIImage *)image;

- (void)createVideoOf:(NSTimeInterval)duration from:(NSDate *)beginning
        outputFileURL:(NSURL *)outputFileURL
           completion:(void (^)(BOOL success, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
