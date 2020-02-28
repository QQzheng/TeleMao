
#import "OWSError.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const OWSSignalServiceKitErrorDomain = @"OWSSignalServiceKitErrorDomain";
NSString *const OWSErrorRecipientAddressKey = @"OWSErrorRecipientAddress";

NSError *OWSErrorWithCodeDescription(OWSErrorCode code, NSString *description)
{
    return OWSErrorWithUserInfo(code, @{ NSLocalizedDescriptionKey: description });
}

NSError *OWSErrorWithUserInfo(OWSErrorCode code, NSDictionary *userInfo)
{
    return [NSError errorWithDomain:OWSSignalServiceKitErrorDomain
                               code:code
                           userInfo:userInfo];
}

NSError *OWSErrorMakeUnableToProcessServerResponseError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeUnableToProcessServerResponse,
        NSLocalizedString(@"XXGJUSTHHANQE40", @"Generic server error"));
}

NSError *OWSErrorMakeFailedToSendOutgoingMessageError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeFailedToSendOutgoingMessage,
        NSLocalizedString(@"XXGJUSTHHANQE31", @"Generic notice when message failed to send."));
}

NSError *OWSErrorMakeNoSuchSignalRecipientError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeNoSuchSignalRecipient,
        NSLocalizedString(
            @"XXGJUSTHHANQE42", @"Error message when attempting to send message"));
}

NSError *OWSErrorMakeAssertionError(NSString *description)
{
    OWSCFailDebug(@"Assertion failed: %@", description);
    return OWSErrorWithCodeDescription(OWSErrorCodeAssertionFailure,
        NSLocalizedString(@"XXGJUSTHHANQE41", @"Worst case generic error message"));
}

NSError *OWSErrorMakeUntrustedIdentityError(NSString *description, SignalServiceAddress *address)
{
    return [NSError
        errorWithDomain:OWSSignalServiceKitErrorDomain
                   code:OWSErrorCodeUntrustedIdentity
               userInfo:@{ NSLocalizedDescriptionKey : description, OWSErrorRecipientAddressKey : address }];
}

NSError *OWSErrorMakeMessageSendDisabledDueToPreKeyUpdateFailuresError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeMessageSendDisabledDueToPreKeyUpdateFailures,
        NSLocalizedString(@"XXGJUSTHHANQE32",
            @"Error message indicating that message send is disabled due to prekey update failures"));
}

NSError *OWSErrorMakeMessageSendFailedDueToBlockListError()
{
    return OWSErrorWithCodeDescription(OWSErrorCodeMessageSendFailedToBlockList,
        NSLocalizedString(@"XXGJUSTHHANQE33",
            @"Error message indicating that message send failed due to block list"));
}

NS_ASSUME_NONNULL_END
