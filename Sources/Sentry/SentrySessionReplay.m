#import "SentrySessionReplay.h"
#import "SentryVideoReplay.h"
#import "SentryImagesReplay.h"
#import "SentryViewPhotographer.h"
#import "SentryOndemandReplay.h"
#import "SentryAttachment+Private.h"

//#define use_video 1
#define use_ondemand 1

@implementation SentrySessionReplay {
    UIView * _rootView;
    BOOL processingScreenshot;
    CADisplayLink * displayLink;
    NSDate * lastScreenShot;
    NSURL * urlToCache;
    NSDate * sessionStart;
    
#if use_video
    SentryVideoReplay * replayMaker;
#elif use_ondemand
    SentryOndemandReplay * replayMaker;
#else
    SentryImagesReplay * replayMaker;
#endif
    
    
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
        replayMaker =
#if use_video
        [[SentryVideoReplay alloc] initWithOutputPath:[urlToCache URLByAppendingPathComponent:@"sr.mp4"].path frameSize:rootView.frame.size framesPerSec:1];
#elif use_ondemand
        [[SentryOndemandReplay alloc] initWithOutputPath:urlToCache.path];
#else
        [[SentryImagesReplay alloc] initWithOutputPath:urlToCache.path];
#endif
        imageCollection = [NSMutableArray array];
        
        NSLog(@"Recording session to %@",urlToCache);
    }
}

- (void)stop {
#ifdef use_video
    [videoReplay finalizeVideoWithCompletion:^(BOOL success, NSError * _Nonnull error) {
        if (!success) {
            NSLog(@"%@", error);
        }
    }];
#endif
}

- (NSArray<SentryAttachment *> *)processAttachments:(NSArray<SentryAttachment *> *)attachments
                                           forEvent:(nonnull SentryEvent *)event
{
#if use_ondemand
    if (event.error == nil && (event.exceptions == nil || event.exceptions.count == 0)) {
        return attachments;
    }
    
    NSLog(@"Recording session event id %@", event.eventId);
    NSMutableArray<SentryAttachment *> *result = [NSMutableArray arrayWithArray:attachments];
    
    NSURL * finalPath  = [urlToCache URLByAppendingPathComponent:@"replay.mp4"];
    
    dispatch_group_t _wait_for_render = dispatch_group_create();
    
    dispatch_group_enter(_wait_for_render);
    [replayMaker createVideoOf:30
                          from:[NSDate dateWithTimeIntervalSinceNow:-30]
                 outputFileURL:finalPath
                    completion:^(BOOL success, NSError * _Nonnull error) {
        dispatch_group_leave(_wait_for_render);
    }];
    dispatch_group_wait(_wait_for_render, DISPATCH_TIME_FOREVER);
    
    SentryAttachment *attachment =
        [[SentryAttachment alloc] initWithPath:finalPath.path
                                      filename:@"replay.mp4"
                                   contentType:@"video/mp4"];

    [result addObject:attachment];
    
    return result;
#else
    return attachments;
#endif
}

- (void)sendReplayForEvent:(SentryEvent *)event {
#if use_ondemand
    
#endif
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
#if use_video
        [self->replayMaker addFrame:screenshot withCompletion:^(BOOL success, NSError * _Nonnull error) {
            
        }];
#else
        [self->replayMaker addFrame:screenshot];
#endif
    });
}


@end
