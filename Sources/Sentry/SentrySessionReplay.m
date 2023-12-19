#import "SentrySessionReplay.h"
#import "SentryReplayMaker.h"
#import "SentryViewPhotographer.h"

@implementation SentrySessionReplay {
    UIView * _rootView;
    BOOL processingScreenshot;
    CADisplayLink * displayLink;
    NSDate * lastScreenShot;
    NSURL * urlToCache;
    NSDate * sessionStart;
    SentryReplayMaker * replayMaker;
    
    NSMutableArray<UIImage *>* imageCollection;
}

- (void)start:(UIView *)rootView {
    @synchronized (self) {
        _rootView = rootView;
        lastScreenShot = [[NSDate alloc] init];
        sessionStart = lastScreenShot;
        
        if (displayLink == nil) {
            displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(newFrame:)];
            [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else {
            return;
        }
        
        NSURL * docs = [[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject URLByAppendingPathComponent:@"io.sentry"];
        
        NSString * currentSession = [NSUUID UUID].UUIDString;
        urlToCache = [docs URLByAppendingPathComponent:currentSession];
        
        if (![NSFileManager.defaultManager fileExistsAtPath:urlToCache.path]) {
            [NSFileManager.defaultManager createDirectoryAtURL:urlToCache withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        replayMaker = [[SentryReplayMaker alloc] initWithOutputPath:[urlToCache URLByAppendingPathComponent:@"sr.mp4"].path frameSize:rootView.frame.size framesPerSec:1];
        imageCollection = [NSMutableArray array];
        
        NSLog(@"Recording session to %@",urlToCache);
    }
}

- (void)stop {
    [replayMaker finalizeVideoWithCompletion:^(BOOL success, NSError * _Nonnull error) {
        if (!success) {
            NSLog(@"%@", error);
        }
    }];
}

- (void)newFrame:(CADisplayLink *)sender {
    NSDate * now = [[NSDate alloc] init];
    
    if ([now timeIntervalSinceDate:lastScreenShot] > 1) {
        [self takeScreenshot];
        lastScreenShot = now;
    }
}

- (void)takeScreenshot {
   // measure(^{
    if (processingScreenshot) { return; }
    @synchronized (self) {
        if (processingScreenshot) { return; }
        processingScreenshot = YES;
    }
       
    UIImage* screenshot = [SentryViewPhotographer.shared imageFromUIView:_rootView];
    
    self->processingScreenshot = NO;
 
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(backgroundQueue, ^{
        [self->replayMaker addFrame:screenshot withCompletion:^(BOOL success, NSError * _Nonnull error) {
            
        }];
    });
}

@end
