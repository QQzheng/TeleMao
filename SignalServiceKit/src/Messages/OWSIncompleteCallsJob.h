
NS_ASSUME_NONNULL_BEGIN

@class OWSStorage;
@class YapDatabaseReadTransaction;

@interface OWSIncompleteCallsJob : NSObject

- (void)runSync;

+ (NSArray<NSString *> *)ydb_incompleteCallIdsWithTransaction:(YapDatabaseReadTransaction *)transaction;

+ (NSString *)databaseExtensionName;
+ (void)asyncRegisterDatabaseExtensionsWithPrimaryStorage:(OWSStorage *)storage;

@end

NS_ASSUME_NONNULL_END
