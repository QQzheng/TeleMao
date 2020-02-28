
#import "OWSDevice.h"
#import "NSNotificationCenter+OWS.h"
#import "OWSError.h"
#import "ProfileManagerProtocol.h"
#import "SSKEnvironment.h"
#import "TSAccountManager.h"
#import <Mantle/MTLValueTransformer.h>
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalServiceKit/OWSIdentityManager.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

uint32_t const OWSDevicePrimaryDeviceId = 1;
NSString *const kMayHaveLinkedDevicesKey = @"kTSStorageManager_MayHaveLinkedDevices";

@interface OWSDeviceManager ()

@property (atomic) NSDate *lastReceivedSyncMessage;

@end

#pragma mark -

@implementation OWSDeviceManager

#pragma mark - Dependencies

- (SDSDatabaseStorage *)databaseStorage
{
    return SDSDatabaseStorage.shared;
}

#pragma mark -

+ (SDSKeyValueStore *)keyValueStore
{
    static SDSKeyValueStore *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SDSKeyValueStore alloc] initWithCollection:@"kTSStorageManager_OWSDeviceCollection"];
    });
    return instance;
}

+ (instancetype)sharedManager
{
    static OWSDeviceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initDefault];
    });
    return instance;
}

- (instancetype)initDefault
{
    return [super init];
}

- (BOOL)mayHaveLinkedDevicesWithTransaction:(SDSAnyReadTransaction *)transaction
{
    OWSAssertDebug(transaction);

    return [OWSDeviceManager.keyValueStore getBool:kMayHaveLinkedDevicesKey defaultValue:YES transaction:transaction];
}

// In order to avoid skipping necessary sync messages, the default value
// for mayHaveLinkedDevices is YES.  Once we've successfully sent a
// sync message with no device messages (e.g. the service has confirmed
// that we have no linked devices), we can set mayHaveLinkedDevices to NO
// to avoid unnecessary message sends for sync messages until we learn
// of a linked device (e.g. through the device linking UI or by receiving
// a sync message, etc.).
- (void)clearMayHaveLinkedDevices
{
    // Note that we write async to avoid opening transactions within transactions.
    [self.databaseStorage asyncWriteWithBlock:^(SDSAnyWriteTransaction *transaction) {
        [OWSDeviceManager.keyValueStore setBool:NO key:kMayHaveLinkedDevicesKey transaction:transaction];
    }];
}

- (void)setMayHaveLinkedDevices
{
    // Note that we write async to avoid opening transactions within transactions.
    [self.databaseStorage asyncWriteWithBlock:^(SDSAnyWriteTransaction *transaction) {
        [OWSDeviceManager.keyValueStore setBool:YES key:kMayHaveLinkedDevicesKey transaction:transaction];
    }];
}

- (BOOL)hasReceivedSyncMessageInLastSeconds:(NSTimeInterval)intervalSeconds
{
    return (self.lastReceivedSyncMessage && fabs(self.lastReceivedSyncMessage.timeIntervalSinceNow) < intervalSeconds);
}

- (void)setHasReceivedSyncMessage
{
    self.lastReceivedSyncMessage = [NSDate new];

    [self setMayHaveLinkedDevices];
}

@end

#pragma mark -

@interface OWSDevice ()

@property (nonatomic) NSInteger deviceId;
@property (nonatomic, nullable) NSString *name;
@property (nonatomic) NSDate *createdAt;
@property (nonatomic) NSDate *lastSeenAt;

@end

#pragma mark -

@implementation OWSDevice

#pragma mark - Dependencies

+ (id<ProfileManagerProtocol>)profileManager
{
    return SSKEnvironment.shared.profileManager;
}

+ (TSAccountManager *)tsAccountManager
{
    return TSAccountManager.sharedInstance;
}

- (OWSIdentityManager *)identityManager
{
    OWSAssertDebug(SSKEnvironment.shared.identityManager);

    return SSKEnvironment.shared.identityManager;
}

#pragma mark -

- (instancetype)initWithUniqueId:(NSString *)uniqueId
                       createdAt:(NSDate *)createdAt
                        deviceId:(NSInteger)deviceId
                      lastSeenAt:(NSDate *)lastSeenAt
                            name:(nullable NSString *)name
{
    self = [super initWithUniqueId:uniqueId];

    if (!self) {
        return self;
    }

    _createdAt = createdAt;
    _deviceId = deviceId;
    _lastSeenAt = lastSeenAt;
    _name = name;

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
                       createdAt:(NSDate *)createdAt
                        deviceId:(NSInteger)deviceId
                      lastSeenAt:(NSDate *)lastSeenAt
                            name:(nullable NSString *)name
{
    self = [super initWithGrdbId:grdbId
                        uniqueId:uniqueId];

    if (!self) {
        return self;
    }

    _createdAt = createdAt;
    _deviceId = deviceId;
    _lastSeenAt = lastSeenAt;
    _name = name;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

+ (nullable instancetype)deviceFromJSONDictionary:(NSDictionary *)deviceAttributes error:(NSError **)error
{
    OWSDevice *device = [MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:deviceAttributes error:error];
    if (device.deviceId < OWSDevicePrimaryDeviceId) {
        OWSFailDebug(@"Invalid device id: %lu", (unsigned long)device.deviceId);
        *error = OWSErrorWithCodeDescription(OWSErrorCodeFailedToDecodeJson, @"Invalid device id.");
        return nil;
    }
    return device;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"createdAt": @"created",
             @"lastSeenAt": @"lastSeen",
             @"deviceId": @"id",
             @"name": @"name"
             };
}

+ (MTLValueTransformer *)createdAtJSONTransformer
{
    return self.millisecondTimestampToDateTransformer;
}

+ (MTLValueTransformer *)lastSeenAtJSONTransformer
{
    return self.millisecondTimestampToDateTransformer;
}

+ (BOOL)replaceAll:(NSArray<OWSDevice *> *)currentDevices transaction:(SDSAnyWriteTransaction *)transaction
{
    BOOL didAddOrRemove = NO;
    NSMutableArray<OWSDevice *> *existingDevices = [[self anyFetchAllWithTransaction:transaction] mutableCopy];
    for (OWSDevice *currentDevice in currentDevices) {
        NSUInteger existingDeviceIndex = [existingDevices indexOfObject:currentDevice];
        if (existingDeviceIndex == NSNotFound) {
            // New Device
            OWSLogInfo(@"Adding device: %@", currentDevice);
            [currentDevice anyInsertWithTransaction:transaction];
            didAddOrRemove = YES;
        } else {
            OWSDevice *existingDevice = existingDevices[existingDeviceIndex];
            [existingDevice anyUpdateWithTransaction:transaction
                                               block:^(OWSDevice *latestCopy) {
                                                   [existingDevice updateAttributesWithDevice:currentDevice];
                                               }];
            [existingDevices removeObjectAtIndex:existingDeviceIndex];
        }
    }

    // Since we removed existing devices as we went, only stale devices remain
    for (OWSDevice *staleDevice in existingDevices) {
        OWSLogVerbose(@"Removing device: %@", staleDevice);
        [staleDevice anyRemoveWithTransaction:transaction];
        didAddOrRemove = YES;
    }

    if (didAddOrRemove) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Device changes can affect the UD access mode for a recipient,
            // so we need to fetch the profile for this user to update UD access mode.
            [self.profileManager fetchAndUpdateLocalUsersProfile];
        });
        return YES;
    } else {
        return NO;
    }
}

+ (MTLValueTransformer *)millisecondTimestampToDateTransformer
{
    static MTLValueTransformer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [MTLValueTransformer transformerUsingForwardBlock:^id(id value, BOOL *success, NSError **error) {
            if ([value isKindOfClass:[NSNumber class]]) {
                NSNumber *number = (NSNumber *)value;
                NSDate *result = [NSDate ows_dateWithMillisecondsSince1970:[number longLongValue]];
                if (result) {
                    *success = YES;
                    return result;
                }
            }
            *success = NO;
            OWSLogError(@"unable to decode date from %@", value);
            *error = OWSErrorWithCodeDescription(OWSErrorCodeFailedToDecodeJson, @"Unable to decode date from JSON.");
            return nil;
        }
            reverseBlock:^id(id value, BOOL *success, NSError **error) {
                if ([value isKindOfClass:[NSDate class]]) {
                    NSDate *date = (NSDate *)value;
                    NSNumber *result = [NSNumber numberWithLongLong:[NSDate ows_millisecondsSince1970ForDate:date]];
                    if (result) {
                        *success = YES;
                        return result;
                    }
                }
                OWSLogError(@"unable to encode date from %@", value);
                *error = OWSErrorWithCodeDescription(OWSErrorCodeFailedToEncodeJson, @"Unable to encode date to JSON.");
                *success = NO;
                return nil;
            }];
    });
    return instance;
}

+ (uint32_t)currentDeviceId
{
    // Someday it may be possible to have a non-primary iOS device, but for now
    // any iOS device must be the primary device.
    return OWSDevicePrimaryDeviceId;
}

- (BOOL)isPrimaryDevice
{
    return self.deviceId == OWSDevicePrimaryDeviceId;
}

- (NSString *)displayName
{
    if (self.name) {
        ECKeyPair *_Nullable identityKeyPair = self.identityManager.identityKeyPair;
        OWSAssertDebug(identityKeyPair);
        if (identityKeyPair) {
            NSError *error;
            NSString *_Nullable decryptedName =
                [DeviceNames decryptDeviceNameWithBase64String:self.name identityKeyPair:identityKeyPair error:&error];
            if (error) {
                // Not necessarily an error; might be a legacy device name.
                OWSLogError(@"Could not decrypt device name: %@", error);
            } else if (decryptedName) {
                return decryptedName;
            }
        }

        return self.name;
    }

    if (self.deviceId == OWSDevicePrimaryDeviceId) {
        return @"This Device";
    }
    return NSLocalizedString(@"XXGJUSTHHANQU18", @"Label text in device manager for a device with no name");
}

- (BOOL)updateAttributesWithDevice:(OWSDevice *)other
{
    BOOL changed = NO;
    if (![self.lastSeenAt isEqual:other.lastSeenAt]) {
        self.lastSeenAt = other.lastSeenAt;
        changed = YES;
    }

    if (![self.createdAt isEqual:other.createdAt]) {
        self.createdAt = other.createdAt;
        changed = YES;
    }

    if (![self.name isEqual:other.name]) {
        self.name = other.name;
        changed = YES;
    }

    return changed;
}

+ (BOOL)hasSecondaryDevicesWithTransaction:(SDSAnyReadTransaction *)transaction
{
    return [self anyCountWithTransaction:transaction] > 1;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[OWSDevice class]]) {
        return NO;
    }

    return [self isEqualToDevice:(OWSDevice *)object];
}

- (BOOL)isEqualToDevice:(OWSDevice *)device
{
    return self.deviceId == device.deviceId;
}

@end

NS_ASSUME_NONNULL_END
