
#import "SCKError.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const SCKErrorDomain;

typedef NS_ERROR_ENUM(SCKErrorDomain, SCKErrorCode){
    SCKErrorCode_AssertionError = 31,
    SCKErrorCode_FailedToDecryptMessage = 100
};

extern NSError *SCKErrorWithCodeDescription(NSUInteger code, NSString *description);
extern NSError *SCKErrorMakeAssertionError(NSString *description, ...);

NS_ASSUME_NONNULL_END
