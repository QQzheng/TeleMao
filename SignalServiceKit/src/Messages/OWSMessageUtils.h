
NS_ASSUME_NONNULL_BEGIN

@class TSMessage;
@class TSThread;

@interface OWSMessageUtils : NSObject

+ (instancetype)sharedManager;

- (NSUInteger)unreadMessagesCount;
- (NSUInteger)unreadMessagesCountExcept:(TSThread *)thread;

- (void)updateApplicationBadgeCount;

@end

NS_ASSUME_NONNULL_END
