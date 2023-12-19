#import "SentryVideoReplay.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SentryVideoReplay ()

@property (nonatomic, strong) NSURL * url;

@end

@implementation SentryVideoReplay {
    NSString *_outputPath;
    CGSize _frameSize;
    NSInteger _framesPerSec;
    AVAssetWriter *_videoWriter;
    AVAssetWriterInput * _videoWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_adaptor;
    NSUInteger _frameIndex;
}

- (instancetype)initWithOutputPath:(NSString *)outputPath
                        frameSize:(CGSize)frameSize
                     framesPerSec:(NSInteger)framesPerSec {
    self = [super init];
    if (self) {
        _outputPath = outputPath;
        _frameSize = frameSize;
        _framesPerSec = framesPerSec;
        [self initializeVideoWriter];
    }
    return self;
}

- (void)initializeVideoWriter {
    NSError *error = nil;

    // Define the output URL for the video
    NSURL *outputURL = [NSURL fileURLWithPath:_outputPath];

    // Define video settings
    NSDictionary *videoSettings = @{
        AVVideoCodecKey: AVVideoCodecTypeH264,
        AVVideoWidthKey: @(_frameSize.width),
        AVVideoHeightKey: @(_frameSize.height),
    };

    // Create AVAssetWriter
    _videoWriter = [AVAssetWriter assetWriterWithURL:outputURL
                                             fileType:AVFileTypeMPEG4
                                                error:&error];

    if (error) {
        NSLog(@"Error creating video writer: %@", error);
        return;
    }

    // Create AVAssetWriterInput
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                           outputSettings:videoSettings];

    // Add input to writer
    [_videoWriter addInput:_videoWriterInput];

    // Create pixel buffer attributes
    NSDictionary *pixelBufferAttributes = @{
        (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
        (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
    };

    // Create AVAssetWriterInputPixelBufferAdaptor
    _adaptor = [AVAssetWriterInputPixelBufferAdaptor
                assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput
                sourcePixelBufferAttributes:pixelBufferAttributes];

    // Start writing session
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)addFrame:(UIImage *)image withCompletion:(void (^)(BOOL success, NSError *error))completion {
    if (!_videoWriter || !_adaptor) {
        NSLog(@"Video writer or adaptor not initialized");
        return;
    }

    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);

    // Perform frame adding on a background queue
    dispatch_async(dispatchQueue, ^{
        // Ensure video writer is ready for more media data
        if (![self->_adaptor.assetWriterInput isReadyForMoreMediaData]) {
            NSLog(@"Writer not ready for more media data");
            return;
        }

        // Convert UIImage to CVPixelBuffer
        CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:[image CGImage]];

        
        // Append pixelBuffer to adaptor
        if (![self->_adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(self->_frameIndex, (int32_t)self->_framesPerSec)]) {
            NSError *error = self->_videoWriter.error;
            NSLog(@"Error appending pixel buffer: %@", error);
            CVPixelBufferRelease(pixelBuffer);

            if (completion) {
                completion(NO, error);
            }
            return;
        }
        self->_frameIndex++;
        

        // Release pixelBuffer
        CVPixelBufferRelease(pixelBuffer);

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
    });
}

- (void)finalizeVideoWithCompletion:(void (^)(BOOL success, NSError *error))completion {
    if (!_videoWriter) {
        NSLog(@"Video writer not initialized");
        return;
    }

    [_videoWriter.inputs.firstObject markAsFinished];
    [_videoWriter finishWritingWithCompletionHandler:^{
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(self->_videoWriter.status == AVAssetWriterStatusCompleted, self->_videoWriter.error);
            });
        }
    }];
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    NSDictionary *options = @{
            (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
        };

        CVPixelBufferRef pixelBuffer;
        CVPixelBufferCreate(kCFAllocatorDefault,
                            (size_t)_frameSize.width,
                            (size_t)_frameSize.height,
                            kCVPixelFormatType_32ARGB,
                            (__bridge CFDictionaryRef)options,
                            &pixelBuffer);

        CVPixelBufferLockBaseAddress(pixelBuffer, 0);

        void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        CGContextRef context = CGBitmapContextCreate(pixelData,
                                                     (size_t)_frameSize.width,
                                                     (size_t)_frameSize.height,
                                                     8,
                                                     CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                     colorSpace,
                                                     kCGImageAlphaNoneSkipFirst);

        CGContextDrawImage(context, CGRectMake(0, 0, _frameSize.width, _frameSize.height), image);

        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

        return pixelBuffer;
}

@end
