//
//  SentryReplayRecorder.h
//  Sentry
//
//  Created by Indragie Karunaratne on 8/22/22.
//  Copyright © 2022 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryReplayRecorder : NSObject

- (void)startRecording;
- (void)stopRecording;

@end

NS_ASSUME_NONNULL_END
