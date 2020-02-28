
NS_ASSUME_NONNULL_BEGIN

@class OWSStorage;
@class YapDatabaseReadTransaction;

@interface OWSFailedAttachmentDownloadsJob : NSObject

- (void)runSync;

+ (NSArray<NSString *> *)unfailedAttachmentPointerIdsWithTransaction:(YapDatabaseReadTransaction *)transaction;

+ (NSString *)databaseExtensionName;
+ (void)asyncRegisterDatabaseExtensionsWithPrimaryStorage:(OWSStorage *)storage;

@end

NS_ASSUME_NONNULL_END
