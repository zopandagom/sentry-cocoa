#import "SentryTouchesTracker.h"
#import "SentryDependencyContainer.h"
#import "SentrySwizzleWrapper.h"

@implementation SentryTouchesTracker {
    NSMutableArray<SentryTouch *> *_touches;
}

- (instancetype)init {
    if (self = [super init]) {
        _touches = [NSMutableArray array];
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
    
}

- (void)stop {
    [SentryDependencyContainer.sharedInstance.swizzleWrapper removeSwizzleSendEventForKey:@"SENTRY_TOUCHES_TRACKER"];
}

- (NSArray<SentryTouch *> *)touchsFrom:(NSDate *)from to:(NSDate *)to {
    NSMutableArray * result = [NSMutableArray array];
    
    [_touches enumerateObjectsUsingBlock:^(SentryTouch * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.timestamp compare:from] != NSOrderedAscending && [obj.timestamp compare:to] != NSOrderedDescending) {
            [result addObject:obj];
        }
    }];
    
    return result;
}

@end
