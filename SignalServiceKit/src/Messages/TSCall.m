
#import "TSCall.h"
#import "TSContactThread.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

NSString *NSStringFromCallType(RPRecentCallType callType)
{
    switch (callType) {
        case RPRecentCallTypeIncoming:
            return @"RPRecentCallTypeIncoming";
        case RPRecentCallTypeOutgoing:
            return @"RPRecentCallTypeOutgoing";
        case RPRecentCallTypeIncomingMissed:
            return @"RPRecentCallTypeIncomingMissed";
        case RPRecentCallTypeOutgoingIncomplete:
            return @"RPRecentCallTypeOutgoingIncomplete";
        case RPRecentCallTypeIncomingIncomplete:
            return @"RPRecentCallTypeIncomingIncomplete";
        case RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity:
            return @"RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity";
        case RPRecentCallTypeIncomingDeclined:
            return @"RPRecentCallTypeIncomingDeclined";
        case RPRecentCallTypeOutgoingMissed:
            return @"RPRecentCallTypeOutgoingMissed";
    }
}

NSUInteger TSCallCurrentSchemaVersion = 1;

@interface TSCall ()

@property (nonatomic, getter=wasRead) BOOL read;

@property (nonatomic, readonly) NSUInteger callSchemaVersion;

@property (nonatomic) RPRecentCallType callType;

@end

#pragma mark -

@implementation TSCall

- (instancetype)initWithTimestamp:(uint64_t)timestamp
                         callType:(RPRecentCallType)callType
                         inThread:(TSContactThread *)thread
{
    self = [super initInteractionWithTimestamp:timestamp inThread:thread];

    if (!self) {
        return self;
    }

    _callSchemaVersion = TSCallCurrentSchemaVersion;
    _callType = callType;

    // Ensure users are notified of missed calls.
    BOOL isIncomingMissed = (_callType == RPRecentCallTypeIncomingMissed
        || _callType == RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity);
    if (isIncomingMissed) {
        _read = NO;
    } else {
        _read = YES;
    }

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                        callType:(RPRecentCallType)callType
                            read:(BOOL)read
{
    self = [super initWithGrdbId:grdbId
                        uniqueId:uniqueId
               receivedAtTimestamp:receivedAtTimestamp
                            sortId:sortId
                         timestamp:timestamp
                    uniqueThreadId:uniqueThreadId];

    if (!self) {
        return self;
    }

    _callType = callType;
    _read = read;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    if (self.callSchemaVersion < 1) {
        // Assume user has already seen any call that predate read-tracking
        _read = YES;
    }

    _callSchemaVersion = TSCallCurrentSchemaVersion;

    return self;
}

- (OWSInteractionType)interactionType
{
    return OWSInteractionType_Call;
}

- (NSString *)previewTextWithTransaction:(SDSAnyReadTransaction *)transaction
{
    // We don't actually use the `transaction` but other sibling classes do.
    switch (_callType) {
        case RPRecentCallTypeIncoming:
            return NSLocalizedString(@"XXGJUSTHHANQI11", @"info message text in conversation view");
        case RPRecentCallTypeOutgoing:
            return NSLocalizedString(@"XXGJUSTHHANQO47", @"info message text in conversation view");
        case RPRecentCallTypeIncomingMissed:
            return NSLocalizedString(@"XXGJUSTHHANQM57", @"info message text in conversation view");
        case RPRecentCallTypeOutgoingIncomplete:
            return NSLocalizedString(@"XXGJUSTHHANQO48", @"info message text in conversation view");
        case RPRecentCallTypeIncomingIncomplete:
            return NSLocalizedString(@"XXGJUSTHHANQI13", @"info message text in conversation view");
        case RPRecentCallTypeIncomingMissedBecauseOfChangedIdentity:
            return NSLocalizedString(@"XXGJUSTHHANQI14", @"info message text shown in conversation view");
        case RPRecentCallTypeIncomingDeclined:
            return NSLocalizedString(@"XXGJUSTHHANQI12",
                                     @"info message recorded in conversation history when local user declined a call");
        case RPRecentCallTypeOutgoingMissed:
            return NSLocalizedString(@"XXGJUSTHHANQO49",
                @"info message recorded in conversation history when local user tries and fails to call another user.");
    }
}

#pragma mark - OWSReadTracking

- (uint64_t)expireStartedAt
{
    return 0;
}

- (BOOL)shouldAffectUnreadCounts
{
    return YES;
}

- (void)markAsReadAtTimestamp:(uint64_t)readTimestamp
              sendReadReceipt:(BOOL)sendReadReceipt
                  transaction:(SDSAnyWriteTransaction *)transaction
{

    OWSAssertDebug(transaction);

    if (self.read) {
        return;
    }

    OWSLogDebug(@"marking as read uniqueId: %@ which has timestamp: %llu", self.uniqueId, self.timestamp);

    [self anyUpdateCallWithTransaction:transaction
                                 block:^(TSCall *call) {
                                     call.read = YES;
                                 }];

    // Ignore sendReadReceipt - it doesn't apply to calls.
}

#pragma mark - Methods

- (void)updateCallType:(RPRecentCallType)callType
{
    [self.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
        [self updateCallType:callType transaction:transaction];
    }];
}

- (void)updateCallType:(RPRecentCallType)callType transaction:(SDSAnyWriteTransaction *)transaction
{
    OWSAssertDebug(transaction);

    OWSLogInfo(@"updating call type of call: %@ -> %@ with uniqueId: %@ which has timestamp: %llu",
        NSStringFromCallType(_callType),
        NSStringFromCallType(callType),
        self.uniqueId,
        self.timestamp);

    [self anyUpdateCallWithTransaction:transaction
                                 block:^(TSCall *call) {
                                     call.callType = callType;
                                 }];
}

@end

NS_ASSUME_NONNULL_END
