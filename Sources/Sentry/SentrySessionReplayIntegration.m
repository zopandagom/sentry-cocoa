#import "SentrySessionReplayIntegration.h"
#import "SentrySessionReplay.h"
#import "SentryDependencyContainer.h"
#import "SentryUIApplication.h"

@implementation SentrySessionReplayIntegration {
    SentrySessionReplay * sessionReplay;
}

- (BOOL)installWithOptions:(nonnull SentryOptions *)options
{
    sessionReplay = [[SentrySessionReplay alloc] init];
    [sessionReplay start: SentryDependencyContainer.sharedInstance.application.windows.firstObject];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stop) name:UIApplicationDidEnterBackgroundNotification object:nil];
    return YES;
}

-(void)stop {
    [sessionReplay stop];
}

- (SentryIntegrationOption)integrationOptions
{
    return kIntegrationOptionNone;
}

- (void)uninstall
{
    
}

@end
