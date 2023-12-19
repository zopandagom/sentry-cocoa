#import "SentryImagesReplay.h"

@implementation SentryImagesReplay {
    NSString * _outputPath;
    NSDate * _startTime;
}

- (instancetype)initWithOutputPath:(NSString *)outputPath {
    if (self = [super init]) {
        _outputPath = outputPath;
        _startTime = [[NSDate alloc] init];
    }
    return self;
}

- (void)addFrame:(UIImage *)image {
    image = [self resizeImage:image withMaxWidth:300];
    NSData * data = UIImagePNGRepresentation(image);
    NSDate* date = [[NSDate alloc] init];
    NSTimeInterval interval = [date timeIntervalSinceDate:_startTime];

    [data writeToFile:[_outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lf.png", interval] ] atomically:YES];
}

- (UIImage *)resizeImage:(UIImage *)originalImage withMaxWidth:(CGFloat)maxWidth {
    // Get the original image size
    CGSize originalSize = originalImage.size;

    // Calculate the aspect ratio
    CGFloat aspectRatio = originalSize.width / originalSize.height;

    // Calculate the new height based on the maximum width
    CGFloat newWidth = MIN(originalSize.width, maxWidth);
    CGFloat newHeight = newWidth / aspectRatio;

    // Create a new size with the calculated dimensions
    CGSize newSize = CGSizeMake(newWidth, newHeight);

    // Create a new graphics context
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1);

    // Draw the image in the new context, scaling it to fit
    [originalImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];

    // Get the resized image from the context
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();

    // Cleanup
    UIGraphicsEndImageContext();

    return resizedImage;
}



@end
