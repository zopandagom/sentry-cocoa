#import "SentryOndemandReplay.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SentryReplayFrame : NSObject

@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSDate *time;

-(instancetype) initWithPath:(NSString *)path time:(NSDate*)time;

@end

@implementation SentryReplayFrame
-(instancetype) initWithPath:(NSString *)path time:(NSDate*)time {
    if (self = [super init]) {
        self.imagePath = path;
        self.time = time;
    }
    return self;
}

@end


@implementation SentryOndemandReplay

{
    NSString * _outputPath;
    NSDate * _startTime;
    NSMutableArray * _frames;
    CGSize _videoSize;
}

- (instancetype)initWithOutputPath:(NSString *)outputPath {
    if (self = [super init]) {
        _outputPath = outputPath;
        _startTime = [[NSDate alloc] init];
        _frames = [NSMutableArray array];
        _videoSize = CGSizeMake(300, 651);
    }
    return self;
}

- (void)addFrame:(UIImage *)image {
    image = [self resizeImage:image withMaxWidth:300];
    NSData * data = UIImagePNGRepresentation(image);
    NSDate* date = [[NSDate alloc] init];
    NSTimeInterval interval = [date timeIntervalSinceDate:_startTime];
    NSString *imagePath = [_outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lf.png", interval]];
    
    [data writeToFile:imagePath atomically:YES];
    
    SentryReplayFrame *frame = [[SentryReplayFrame alloc] initWithPath:imagePath time:date];
    [_frames addObject:frame];
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
//
//- (NSString *)createVideoOf:(NSTimeInterval)duration from:(NSDate *)beginning {
//     for (SentryReplayFrame *frame in _frames) {
//        UIImage *image = [UIImage imageWithContentsOfFile:frame.imagePath];
//
//        if (image) {
//            NSDate *imageDate = [beginning dateByAddingTimeInterval:[frame.creationTime timeIntervalSinceDate:beginning]];
//            CMTime presentTime = CMTimeMakeWithSeconds([imageDate timeIntervalSinceDate:beginning], 600);
//
//            // Append the image to the video
//            [videoWriterInput appendSampleBuffer:[self sampleBufferFromImage:image presentTime:presentTime]];
//        }
//    }
//
//}

- (void)createVideoOf:(NSTimeInterval)duration from:(NSDate *)beginning
        outputFileURL:(NSURL *)outputFileURL
           completion:(void (^)(BOOL success, NSError *error))completion {
    // Set up AVAssetWriter with appropriate settings
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:outputFileURL
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:nil];
    
    NSDictionary *videoSettings = @{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: @(_videoSize.width),
        AVVideoHeightKey: @(_videoSize.height),
        AVVideoCompressionPropertiesKey: @{
            AVVideoAverageBitRateKey: @(20000),
            AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel,
        },
    };
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSDictionary *bufferAttributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
    };
    
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
    
    [videoWriter addInput:videoWriterInput];
    
    // Start writing video
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);

    NSDate* end = [beginning dateByAddingTimeInterval:duration];
    __block NSInteger frameCount = 0;
    NSMutableArray<NSString *> * frames = [NSMutableArray array];
    for (SentryReplayFrame *frame in self->_frames) {
       if ([frame.time compare:beginning] == NSOrderedAscending) {
            continue;;
        } else if ([frame.time compare:end] == NSOrderedDescending) {
            break;
        }
        [frames addObject:frame.imagePath];
    }
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        UIImage *image = [UIImage imageWithContentsOfFile:frames[frameCount]];
        if (image) {
            CMTime presentTime = CMTimeMake(frameCount++, 1);
            
            if (![self appendPixelBufferForImage:image pixelBufferAdaptor:pixelBufferAdaptor presentationTime:presentTime]) {
                if (completion) {
                    completion(NO, videoWriter.error);
                }
            }
        }
    
        if (frameCount >= frames.count){
            [videoWriterInput markAsFinished];
            [videoWriter finishWritingWithCompletionHandler:^{
                if (completion) {
                    completion(videoWriter.status == AVAssetWriterStatusCompleted, videoWriter.error);
                }
            }];
        }
    }];
}

- (BOOL)appendPixelBufferForImage:(UIImage *)image pixelBufferAdaptor:(AVAssetWriterInputPixelBufferAdaptor *)pixelBufferAdaptor presentationTime:(CMTime)presentationTime {
    CVReturn status = kCVReturnSuccess;
    
    CVPixelBufferRef pixelBuffer = NULL;
    status = CVPixelBufferCreate(kCFAllocatorDefault, (size_t)image.size.width, (size_t)image.size.height, kCVPixelFormatType_32ARGB, NULL, &pixelBuffer);
    
    if (status != kCVReturnSuccess) {
        return NO;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, (size_t)image.size.width, (size_t)image.size.height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    UIGraphicsPushContext(context);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIGraphicsPopContext();
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    // Append the pixel buffer with the current image to the video
    BOOL success = [pixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
    
    CVPixelBufferRelease(pixelBuffer);
    
    return success;
}


@end
