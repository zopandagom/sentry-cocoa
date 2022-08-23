#import "SentryBaseIntegration.h"
#import "SentryIntegrationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * This automatically adds breadcrumbs for different user actions.
 */
@interface SentryReplayIntegration : SentryBaseIntegration <SentryIntegrationProtocol>

@end

NS_ASSUME_NONNULL_END
