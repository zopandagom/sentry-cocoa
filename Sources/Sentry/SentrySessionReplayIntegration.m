#import "SentrySessionReplayIntegration.h"
#import "SentrySessionReplay.h"
#import "SentryDependencyContainer.h"
#import "SentryUIApplication.h"
#import "SentrySDK+Private.h"
#import "SentryClient+Private.h"
#import "SentryHub+Private.h"
#import "SentrySDK+Private.h"

@implementation SentrySessionReplayIntegration {
    SentrySessionReplay * sessionReplay;
}

- (BOOL)installWithOptions:(nonnull SentryOptions *)options
{
    sessionReplay = [[SentrySessionReplay alloc] init];
    [sessionReplay start: SentryDependencyContainer.sharedInstance.application.windows.firstObject];
    
    SentryClient *client = [SentrySDK.currentHub getClient];
    [client addAttachmentProcessor:sessionReplay];
    
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
