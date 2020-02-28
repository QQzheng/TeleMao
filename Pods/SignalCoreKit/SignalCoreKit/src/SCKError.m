
#import "SCKError.h"

NSErrorDomain const SCKErrorDomain = @"SignalCoreKitErrorDomain";

NSError *SCKErrorWithCodeDescription(NSUInteger code, NSString *description)
{
    return [NSError errorWithDomain:SCKErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey: description }];
}

NSError *SCKErrorMakeAssertionError(NSString *description, ...) {
    OWSCFailDebug(@"Assertion failed: %@", description);
    return SCKErrorWithCodeDescription(SCKErrorCode_AssertionError,
                                       NSLocalizedString(@"XXGJUSTHHANQE41", @"Worst case generic error message"));
}
