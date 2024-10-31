#import <Foundation/Foundation.h>

#import "SentryTransport.h"

@class SentryOptions, SentryFileManager;
@protocol SentryCurrentDateProvider;
@class SentryCrashWrapper;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TransportInitializer)
@interface SentryTransportFactory : NSObject

+ (NSArray<id<SentryTransport>> *)initTransports:(SentryOptions *)options
                               sentryFileManager:(SentryFileManager *)sentryFileManager
                             currentDateProvider:(id<SentryCurrentDateProvider>)currentDateProvider
                                    crashWrapper:(SentryCrashWrapper *)crashWrapper;

@end

NS_ASSUME_NONNULL_END
