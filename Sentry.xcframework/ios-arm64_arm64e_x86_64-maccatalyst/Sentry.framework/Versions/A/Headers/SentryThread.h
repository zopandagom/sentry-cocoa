#if __has_include(<Sentry/Sentry.h>)
#    import <Sentry/SentryDefines.h>
#    import <Sentry/SentrySerializable.h>
#else
#    import <SentryWithoutUIKit/SentryDefines.h>
#    import <SentryWithoutUIKit/SentrySerializable.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class SentryStacktrace;

@interface SentryThread : NSObject <SentrySerializable>
SENTRY_NO_INIT

/**
 * Number of the thread
 */
@property (nonatomic, copy) NSNumber *threadId;

/**
 * Name (if available) of the thread
 */
@property (nullable, nonatomic, copy) NSString *name;

/**
 * SentryStacktrace of the SentryThread
 */
@property (nullable, nonatomic, strong) SentryStacktrace *stacktrace;

/**
 * Did this thread crash?
 */
@property (nullable, nonatomic, copy) NSNumber *crashed;

/**
 * Was it the current thread.
 */
@property (nullable, nonatomic, copy) NSNumber *current;

/**
 * Was it the main thread?
 */
@property (nullable, nonatomic, copy) NSNumber *isMain;

/**
 * Initializes a SentryThread with its id
 * @param threadId NSNumber
 * @return SentryThread
 */
- (instancetype)initWithThreadId:(NSNumber *)threadId;

@end

NS_ASSUME_NONNULL_END
