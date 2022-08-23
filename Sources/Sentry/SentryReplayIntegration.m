#import "SentryReplayIntegration.h"
#import "SentryOptions.h"
#import "SentryReplayRecorder.h"

@implementation SentryReplayIntegration {
    SentryReplayRecorder *_recorder;
}

- (BOOL)installWithOptions:(SentryOptions *)options
{
    _recorder = [[SentryReplayRecorder alloc] init];
    [_recorder startRecording];
    return YES;
}

- (void)uninstall
{
    [_recorder stopRecording];
    _recorder = nil;
}

@end
