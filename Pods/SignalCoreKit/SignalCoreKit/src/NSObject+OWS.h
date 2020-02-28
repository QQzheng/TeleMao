
NS_ASSUME_NONNULL_BEGIN

@interface NSObject (OWS)

#pragma mark - Logging

@property (nonatomic, readonly) NSString *logTag;

@property (class, nonatomic, readonly) NSString *logTag;

+ (BOOL)isNullableObject:(nullable NSObject *)left equalTo:(nullable NSObject *)right;

@end

NS_ASSUME_NONNULL_END
