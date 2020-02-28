
NS_ASSUME_NONNULL_BEGIN

@interface YDBLegacyMigration : NSObject

+ (BOOL)ensureIsYDBReadyForAppExtensions:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
