
#import "AdvancedSettingsTableViewController.h"
#import "DebugLogger.h"
#import "DomainFrontingCountryViewController.h"
#import "OWSCountryMetadata.h"
#import "Pastelog.h"
#import "Signal-Swift.h"
#import "TSAccountManager.h"
#import <PromiseKit/AnyPromise.h>
#import <Reachability/Reachability.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSPreferences.h>
#import <SignalServiceKit/OWSSignalService.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdvancedSettingsTableViewController ()

@property (nonatomic) Reachability *reachability;

@end

#pragma mark -

@implementation AdvancedSettingsTableViewController

- (void)loadView
{
    [super loadView];

    self.title = NSLocalizedString(@"XXGJUSTHHANQS60", @"");

    self.reachability = [Reachability reachabilityForInternetConnection];

    [self observeNotifications];

    [self updateTableContents];
}

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketStateDidChange)
                                                 name:kNSNotification_OWSWebSocketStateDidChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)socketStateDidChange
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

- (void)reachabilityChanged
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak AdvancedSettingsTableViewController *weakSelf = self;

    OWSTableSection *loggingSection = [OWSTableSection new];
    loggingSection.headerTitle = NSLocalizedString(@"XXGJUSTHHANQL17", nil);
    [loggingSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"XXGJUSTHHANQS58", @"")
                                accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"enable_debug_log")
                                isOnBlock:^{
                                    return [OWSPreferences isLoggingEnabled];
                                }
                                isEnabledBlock:^{
                                    return YES;
                                }
                                target:weakSelf
                                selector:@selector(didToggleEnableLogSwitch:)]];

    if ([OWSPreferences isLoggingEnabled]) {
        [loggingSection
            addItem:[OWSTableItem actionItemWithText:NSLocalizedString(@"XXGJUSTHHANQS59", @"")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"submit_debug_log")
                                         actionBlock:^{
                                             [DDLog flushLog];
                                             [Pastelog submitLogs];
                                         }]];
    }

    if (SSKFeatureFlags.audibleErrorLogging) {
        [loggingSection
            addItem:[OWSTableItem actionItemWithText:NSLocalizedString(
                                                         @"XXGJUSTHHANQS61", @"table cell label")
                             accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"view_error_log")
                                         actionBlock:^{
                                             [weakSelf didPressViewErrorLog];
                                         }]];
    }

    [contents addSection:loggingSection];

    OWSTableSection *pushNotificationsSection = [OWSTableSection new];
    pushNotificationsSection.headerTitle
        = NSLocalizedString(@"XXGJUSTHHANQP108", @"Used in table section header and alert view title contexts");
    [pushNotificationsSection addItem:[OWSTableItem actionItemWithText:NSLocalizedString(@"XXGJUSTHHANQR49", nil)
                                               accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(
                                                                           self, @"reregister_push_notifications")
                                                           actionBlock:^{
                                                               [weakSelf syncPushTokens];
                                                           }]];
    [contents addSection:pushNotificationsSection];

    //版本1.0 去掉审查规避
    self.contents = contents;
}

- (void)showDomainFrontingCountryView
{
    DomainFrontingCountryViewController *vc = [DomainFrontingCountryViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (OWSCountryMetadata *)ensureManualCensorshipCircumventionCountry
{
    OWSAssertIsOnMainThread();

    OWSCountryMetadata *countryMetadata = nil;
    NSString *countryCode = OWSSignalService.sharedInstance.manualCensorshipCircumventionCountryCode;
    if (countryCode) {
        countryMetadata = [OWSCountryMetadata countryMetadataForCountryCode:countryCode];
    }

    if (!countryMetadata) {
        countryCode = [PhoneNumber defaultCountryCode];
        if (countryCode) {
            countryMetadata = [OWSCountryMetadata countryMetadataForCountryCode:countryCode];
        }
    }

    if (!countryMetadata) {
        countryCode = @"US";
        countryMetadata = [OWSCountryMetadata countryMetadataForCountryCode:countryCode];
        OWSAssertDebug(countryMetadata);
    }

    if (countryMetadata) {
        // Ensure the "manual censorship circumvention" country state is in sync.
        OWSSignalService.sharedInstance.manualCensorshipCircumventionCountryCode = countryCode;
    }

    return countryMetadata;
}

#pragma mark - Actions

- (void)syncPushTokens
{
    OWSSyncPushTokensJob *job =
        [[OWSSyncPushTokensJob alloc] initWithAccountManager:AppEnvironment.shared.accountManager
                                                 preferences:Environment.shared.preferences];
    job.uploadOnlyIfStale = NO;
    [[job run]
            .then(^{
                [OWSActionSheets
                    showActionSheetWithTitle:NSLocalizedString(@"XXGJUSTHHANQP107",
                                                 @"Title of alert shown when push tokens sync job succeeds.")];
            })
            .catch(^(NSError *error) {
                [OWSActionSheets
                    showActionSheetWithTitle:NSLocalizedString(@"XXGJUSTHHANQR26",
                                                 @"Title of alert shown when push tokens sync job fails.")];
            }) retainUntilComplete];
}

- (void)didToggleEnableLogSwitch:(UISwitch *)sender
{
    if (!sender.isOn) {
        [[DebugLogger sharedLogger] wipeLogs];
        [[DebugLogger sharedLogger] disableFileLogging];
    } else {
        [[DebugLogger sharedLogger] enableFileLogging];
    }

    [OWSPreferences setIsLoggingEnabled:sender.isOn];

    [self updateTableContents];
}

- (void)didToggleEnableCensorshipCircumventionSwitch:(UISwitch *)sender
{
    OWSSignalService *service = OWSSignalService.sharedInstance;
    if (sender.isOn) {
        service.isCensorshipCircumventionManuallyDisabled = NO;
        service.isCensorshipCircumventionManuallyActivated = YES;
    } else {
        service.isCensorshipCircumventionManuallyDisabled = YES;
        service.isCensorshipCircumventionManuallyActivated = NO;
    }

    [self updateTableContents];
}

- (void)didPressViewErrorLog
{
    OWSAssert(SSKFeatureFlags.audibleErrorLogging);

    [DDLog flushLog];
    NSURL *errorLogsDir = DebugLogger.sharedLogger.errorLogsDir;
    LogPickerViewController *logPicker = [[LogPickerViewController alloc] initWithLogDirUrl:errorLogsDir];
    [self.navigationController pushViewController:logPicker animated:YES];
}

@end

NS_ASSUME_NONNULL_END
