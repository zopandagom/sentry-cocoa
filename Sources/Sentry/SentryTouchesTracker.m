#import "SentryTouchesTracker.h"
#import "SentryDependencyContainer.h"
#import "SentrySwizzleWrapper.h"
#import "SentryCurrentDateProvider.h"

@implementation SentryTouchesTracker {
    NSMutableArray<SentryUITouch *> *_touches;
    SentryCurrentDateProvider * _dateProvider;
}

- (instancetype)init {
    if (self = [super init]) {
        _touches = [NSMutableArray array];
        _dateProvider = SentryDependencyContainer.sharedInstance.dateProvider;
    }
    return self;
}

- (void)start {
    [SentryDependencyContainer.sharedInstance.swizzleWrapper swizzleSendEvent:^(UIEvent * _Nullable event) {
        if (event != nil) {
            [self parseEvent:event];
        }
    } forKey:@"SENTRY_TOUCHES_TRACKER"];
}

- (void) parseEvent:(UIEvent *)event {
    [event.allTouches enumerateObjectsUsingBlock:^(UITouch * _Nonnull obj, BOOL * _Nonnull stop) {
        [_touches addObject:[self convertTouch:obj]];
    }];
}

- (void)stop {
    [SentryDependencyContainer.sharedInstance.swizzleWrapper removeSwizzleSendEventForKey:@"SENTRY_TOUCHES_TRACKER"];
}

- (NSArray<SentryUITouch *> *)touchsFrom:(NSDate *)from to:(NSDate *)to {
    NSMutableArray * result = [NSMutableArray array];
    
    [_touches enumerateObjectsUsingBlock:^(SentryUITouch * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.timestamp compare:from] != NSOrderedAscending && [obj.timestamp compare:to] != NSOrderedDescending) {
            [result addObject:obj];
        }
    }];
    
    return result;
}


- (SentryUITouch *)convertTouch:(UITouch *)touch {
    SentryUITouch * result = [[SentryUITouch alloc] init];
    result.position  = [touch locationInView:touch.window];
    result.timestamp = _dateProvider.date;
    result.phase = touch.phase;
    return result;
}
@end
