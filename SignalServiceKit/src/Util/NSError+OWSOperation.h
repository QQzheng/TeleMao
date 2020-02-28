
NS_ASSUME_NONNULL_BEGIN

@interface NSError (OWSOperation)

@property (nonatomic) BOOL isRetryable;
@property (nonatomic) BOOL isFatal;
@property (nonatomic) BOOL shouldBeIgnoredForGroups;

@end

NS_ASSUME_NONNULL_END
