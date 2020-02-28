#import "AppDelegate.h"
#import "ConversationListViewController.h"
#import "DebugLogger.h"
#import "MainAppContext.h"
#import "OWS2FASettingsViewController.h"
#import "OWSBackup.h"
#import "OWSOrphanDataCleaner.h"
#import "OWSScreenLockUI.h"
#import "Pastelog.h"
#import "Signal-Swift.h"
#import "SignalApp.h"
#import "ViewControllerUtils.h"
#import "YDBLegacyMigration.h"
#import <Intents/Intents.h>
#import <PromiseKit/AnyPromise.h>
#import <SignalCoreKit/iOSVersions.h>
#import <SignalMessaging/AppSetup.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalMessaging/OWSNavigationController.h>
#import <SignalMessaging/OWSPreferences.h>
#import <SignalMessaging/OWSProfileManager.h>
#import <SignalMessaging/SignalMessaging.h>
#import <SignalMessaging/VersionMigrations.h>
#import <SignalServiceKit/AppReadiness.h>
#import <SignalServiceKit/CallKitIdStore.h>
#import <SignalServiceKit/OWS2FAManager.h>
#import <SignalServiceKit/OWSBatchMessageProcessor.h>
#import <SignalServiceKit/OWSDisappearingMessagesJob.h>
#import <SignalServiceKit/OWSMath.h>
#import <SignalServiceKit/OWSMessageManager.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSReadReceiptManager.h>
#import <SignalServiceKit/SSKEnvironment.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <SignalServiceKit/StickerInfo.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSPreKeyManager.h>
#import <SignalServiceKit/TSSocketManager.h>
#import <UserNotifications/UserNotifications.h>
#import <WebRTC/WebRTC.h>

NSString *const AppDelegateStoryboardMain = @"Main";
static NSString *const kInitialViewControllerIdentifier = @"UserInitialViewController";
static NSString *const kURLSchemeSGNLKey                = @"sgnl";
static NSString *const kURLHostVerifyPrefix             = @"verify";
static NSString *const kURLHostAddStickersPrefix = @"addstickers";

static NSTimeInterval launchStartedAt;

typedef NS_ENUM(NSUInteger, LaunchFailure) {
    LaunchFailure_None,
    LaunchFailure_CouldNotLoadDatabase,
    LaunchFailure_UnknownDatabaseVersion,
};

NSString *NSStringForLaunchFailure(LaunchFailure launchFailure);
NSString *NSStringForLaunchFailure(LaunchFailure launchFailure)
{
    switch (launchFailure) {
        case LaunchFailure_None:
            return @"LaunchFailure_None";
        case LaunchFailure_CouldNotLoadDatabase:
            return @"LaunchFailure_CouldNotLoadDatabase";
        case LaunchFailure_UnknownDatabaseVersion:
            return @"LaunchFailure_UnknownDatabaseVersion";
    }
}

@interface AppDelegate () <UNUserNotificationCenterDelegate>
@property (nonatomic) BOOL areVersionMigrationsComplete;
@property (nonatomic) BOOL didAppLaunchFail;
@end

#pragma mark -

@implementation AppDelegate

@synthesize window = _window;

#pragma mark -  创建
- (OWSProfileManager *)profileManager
{
    return [OWSProfileManager sharedManager];
}

- (OWSReadReceiptManager *)readReceiptManager
{
    return [OWSReadReceiptManager sharedManager];
}
- (id<OWSUDManager>)udManager
{
    OWSAssertDebug(SSKEnvironment.shared.udManager); //用于捕捉错误异常，发布版本无效
    return SSKEnvironment.shared.udManager;
}

- (nullable OWSPrimaryStorage *)primaryStorage
{
    return SSKEnvironment.shared.primaryStorage;
}

- (PushRegistrationManager *)pushRegistrationManager
{
    OWSAssertDebug(AppEnvironment.shared.pushRegistrationManager);

    return AppEnvironment.shared.pushRegistrationManager;
}

- (TSAccountManager *)tsAccountManager
{
    OWSAssertDebug(SSKEnvironment.shared.tsAccountManager);

    return SSKEnvironment.shared.tsAccountManager;
}

- (OWSDisappearingMessagesJob *)disappearingMessagesJob
{
    OWSAssertDebug(SSKEnvironment.shared.disappearingMessagesJob);

    return SSKEnvironment.shared.disappearingMessagesJob;
}

- (TSSocketManager *)socketManager
{
    OWSAssertDebug(SSKEnvironment.shared.socketManager);

    return SSKEnvironment.shared.socketManager;
}

- (OWSMessageManager *)messageManager
{
    OWSAssertDebug(SSKEnvironment.shared.messageManager);

    return SSKEnvironment.shared.messageManager;
}

- (OWSWindowManager *)windowManager
{
    return Environment.shared.windowManager;
}

- (OWSBackup *)backup
{
    return AppEnvironment.shared.backup;
}

- (OWSNotificationPresenter *)notificationPresenter
{
    return AppEnvironment.shared.notificationPresenter;
}

- (OWSUserNotificationActionHandler *)userNotificationActionHandler
{
    return AppEnvironment.shared.userNotificationActionHandler;
}

- (SDSDatabaseStorage *)databaseStorage
{
    return SDSDatabaseStorage.shared;
}

- (id<SyncManagerProtocol>)syncManager
{
    OWSAssertDebug(SSKEnvironment.shared.syncManager);

    return SSKEnvironment.shared.syncManager;
}

- (StorageCoordinator *)storageCoordinator
{
    return SSKEnvironment.shared.storageCoordinator;
}

- (LaunchJobs *)launchJobs
{
    return Environment.shared.launchJobs;
}

- (DeviceService *)deviceService
{
    return DeviceService.shared;
}

#pragma mark - application

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [DDLog flushLog];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [DDLog flushLog];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SetCurrentAppContext([MainAppContext new]);
    launchStartedAt = CACurrentMediaTime();

    BOOL isLoggingEnabled;
    isLoggingEnabled = OWSPreferences.isLoggingEnabled;
    if (isLoggingEnabled) {
        [DebugLogger.sharedLogger enableFileLogging];
    }
    if (SSKFeatureFlags.audibleErrorLogging) {
        [DebugLogger.sharedLogger enableErrorReporting];
    }
    
    [Cryptography seedRandom];

    [self verifyDBKeysAvailableBeforeBackgroundLaunch];

    NSError *_Nullable launchError = nil;
    LaunchFailure launchFailure = LaunchFailure_None;

    BOOL isYdbNotReady = ![YDBLegacyMigration ensureIsYDBReadyForAppExtensions:&launchError];
    if (isYdbNotReady || launchError != nil) {
        launchFailure = LaunchFailure_CouldNotLoadDatabase;
    } else if (StorageCoordinator.hasInvalidDatabaseVersion) {
        launchFailure = LaunchFailure_UnknownDatabaseVersion;
    }
    if (launchFailure != LaunchFailure_None) {
        [self showUIForLaunchFailure:launchFailure];
        return YES;
    }

    if (isLoggingEnabled && !OWSPreferences.isLoggingEnabled) {
        [DebugLogger.sharedLogger disableFileLogging];
    }

    [AppVersion sharedInstance];

    // 防止设备在数据库视图异步注册期间休眠（例如长时间的数据库升级）在storageIsReady中清除block
    [DeviceSleepManager.sharedInstance addBlockWithBlockObject:self];

    if (CurrentAppContext().isRunningTests) {
        return YES;
    }
    [AppSetup
        setupEnvironmentWithAppSpecificSingletonBlock:^{
            [AppEnvironment.shared setup];
            [SignalApp.sharedApp setup];
        }migrationCompletion:^{
            OWSAssertIsOnMainThread();
            [self versionMigrationsDidComplete];
        }];

    [UIUtil setupSignalAppearence];

    UIWindow *mainWindow = [OWSWindow new];
    self.window = mainWindow;
    CurrentAppContext().mainWindow = mainWindow;
    mainWindow.rootViewController = [LoadingViewController new];
    [mainWindow makeKeyAndVisible];

    if (@available(iOS 10, *)) {
        UNUserNotificationCenter.currentNotificationCenter.delegate = self;
    }

    NSDictionary *remoteNotif = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        [self application:application didReceiveRemoteNotification:remoteNotif];
    }

    [OWSScreenLockUI.sharedManager setupWithRootWindow:self.window];
    [[OWSWindowManager sharedManager] setupWithRootWindow:self.window
                                     screenBlockingWindow:OWSScreenLockUI.sharedManager.screenBlockingWindow];
    [OWSScreenLockUI.sharedManager startObserving];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storageIsReady)
                                                 name:StorageIsReadyNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationStateDidChange)
                                                 name:RegistrationStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationLockDidChange:)
                                                 name:NSNotificationName_2FAStateDidChange
                                               object:nil];
    [OWSAnalytics appLaunchDidBegin];

    return YES;
}

//重新启动后，用户必须解锁设备后才能访问数据库
- (void)verifyDBKeysAvailableBeforeBackgroundLaunch
{
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        return;
    }
    
    if (StorageCoordinator.hasYdbFile && !SSKPreferences.isYdbMigrated
        && OWSPrimaryStorage.isDatabasePasswordAccessible) {
        return;
    }
    
    if (SSKPreferences.isYdbMigrated && GRDBDatabaseStorageAdapter.isKeyAccessible) {
        return;
    }
    
    if (!StorageCoordinator.hasYdbFile && StorageCoordinator.hasGrdbFile
        && GRDBDatabaseStorageAdapter.isKeyAccessible) {
        return;
    }

    UILocalNotification *notification = [UILocalNotification new];
    NSString *messageFormat = NSLocalizedString(@"XXGJUSTHHANQN29",
        @"Lock screen notification text presented after user powers on their device without unlocking. Embeds "
        @"{{device model}} (either 'iPad' or 'iPhone')");
    notification.alertBody = [NSString stringWithFormat:messageFormat, UIDevice.currentDevice.localizedModel];

    [UIApplication.sharedApplication cancelAllLocalNotifications];
    [UIApplication.sharedApplication setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    [UIApplication.sharedApplication setApplicationIconBadgeNumber:1];

    [DDLog flushLog];
    exit(0);
}

- (void)showUIForLaunchFailure:(LaunchFailure)launchFailure
{
    self.didAppLaunchFail = YES;

    [AppVersion sharedInstance];

    self.window = [OWSWindow new];

    UIViewController *viewController = [[UIStoryboard storyboardWithName:@"Launch Screen"
                                                                  bundle:nil] instantiateInitialViewController];
    self.window.rootViewController = viewController;

    [self.window makeKeyAndVisible];

    NSString *alertTitle;
    NSString *alertMessage
        = NSLocalizedString(@"XXGJUSTHHANQA23", @"应用启动失败的警报消息");
    
    switch (launchFailure) {
        case LaunchFailure_CouldNotLoadDatabase:
            alertTitle = NSLocalizedString(@"XXGJUSTHHANQA25",
                @"由于无法加载数据库而导致应用无法启动的错误");
            break;
        case LaunchFailure_UnknownDatabaseVersion:
            alertTitle = NSLocalizedString(@"XXGJUSTHHANQA27",
                @"如果不还原未知的数据库迁移，应用程序将无法启动。");
            alertMessage = NSLocalizedString(@"XXGJUSTHHANQA26", @"");
            break;
        default:
            alertTitle
                = NSLocalizedString(@"XXGJUSTHHANQA19", @"应用启动失败");
            break;
    }

    ActionSheetController *actionSheet = [[ActionSheetController alloc] initWithTitle:alertTitle message:alertMessage];

    [actionSheet
        addAction:[[ActionSheetAction alloc] initWithTitle:NSLocalizedString(@"XXGJUSTHHANQS59", nil)
                                                     style:ActionSheetActionStyleDefault
                                                   handler:^(ActionSheetAction *_Nonnull action) {
                                                       [Pastelog submitLogsWithCompletion:^{
                                                           OWSFail(@"共享调试日志后退出");
                                                       }];
                                                   }]];
    [viewController presentActionSheet:actionSheet];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return;
    }

    [self.pushRegistrationManager didReceiveVanillaPushToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return;
    }

#ifdef DEBUG
    [self.pushRegistrationManager didReceiveVanillaPushToken:[[NSMutableData dataWithLength:32] copy]];
#else
    OWSProdError([OWSAnalyticsEvents appDelegateErrorFailedToRegisterForRemoteNotifications]);
    [self.pushRegistrationManager didFailToReceiveVanillaPushTokenWithError:error];
#endif
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    OWSAssertIsOnMainThread();
    return [self tryToOpenUrl:url];
}

- (BOOL)tryToOpenUrl:(NSURL *)url
{
    OWSAssertDebug(!self.didAppLaunchFail);

    if (self.didAppLaunchFail) {
        return NO;
    }

    if ([StickerPackInfo isStickerPackShareUrl:url]) {
        StickerPackInfo *_Nullable stickerPackInfo = [StickerPackInfo parseStickerPackShareUrl:url];
        if (stickerPackInfo == nil) {
            return NO;
        }
        return [self tryToShowStickerPackView:stickerPackInfo];
    } else if ([url.scheme isEqualToString:kURLSchemeSGNLKey]) {
        if ([url.host hasPrefix:kURLHostVerifyPrefix] && ![self.tsAccountManager isRegistered]) {
            if (!AppReadiness.isAppReady) {
                return NO;
            }
            return [SignalApp.sharedApp receivedVerificationCode:[url.path substringFromIndex:1]];
        } else if ([url.host hasPrefix:kURLHostAddStickersPrefix] && [self.tsAccountManager isRegistered]) {
            if (!SSKFeatureFlags.stickerAutoEnable && !SSKFeatureFlags.stickerSend) {
                return NO;
            }
            StickerPackInfo *_Nullable stickerPackInfo = [self parseAddStickersUrl:url];
            if (stickerPackInfo == nil) {
                return NO;
            }
            return [self tryToShowStickerPackView:stickerPackInfo];
        }
    }

    return NO;
}

- (nullable StickerPackInfo *)parseAddStickersUrl:(NSURL *)url
{
    NSString *_Nullable packIdHex;
    NSString *_Nullable packKeyHex;
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    for (NSURLQueryItem *queryItem in [components queryItems]) {
        if ([queryItem.name isEqualToString:@"pack_id"]) {
            OWSAssertDebug(packIdHex == nil);
            packIdHex = queryItem.value;
        } else if ([queryItem.name isEqualToString:@"pack_key"]) {
            OWSAssertDebug(packKeyHex == nil);
            packKeyHex = queryItem.value;
        }
    }

    return [StickerPackInfo parsePackIdHex:packIdHex packKeyHex:packKeyHex];
}

- (BOOL)tryToShowStickerPackView:(StickerPackInfo *)stickerPackInfo
{
    OWSAssertDebug(!self.didAppLaunchFail);

    if (!SSKFeatureFlags.stickerAutoEnable && !SSKFeatureFlags.stickerSend) {
        return NO;
    }

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        if (!self.tsAccountManager.isRegistered) {
            return;
        }

        StickerPackViewController *packView =
            [[StickerPackViewController alloc] initWithStickerPackInfo:stickerPackInfo];
        UIViewController *rootViewController = self.window.rootViewController;
        if (rootViewController.presentedViewController) {
            [rootViewController dismissViewControllerAnimated:NO
                                                   completion:^{
                                                       [packView presentFrom:rootViewController animated:NO];
                                                   }];
        } else {
            [packView presentFrom:rootViewController animated:NO];
        }
    }];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return;
    }
    if (CurrentAppContext().isRunningTests) {
        return;
    }

    [SignalApp.sharedApp ensureRootViewController:launchStartedAt];

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        [self handleActivation];
    }];

    [self clearAllNotificationsAndRestoreBadgeCount];

    ClearOldTemporaryDirectories();

    [self.windowManager updateWindowFrames];
}

- (void)enableBackgroundRefreshIfNecessary
{
    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        if (OWS2FAManager.sharedManager.is2FAEnabled && [self.tsAccountManager isRegisteredAndReady]) {
            //每天一次Ping服务器以使2FA客户端保持活动状态。
            const NSTimeInterval kBackgroundRefreshInterval = 24 * 60 * 60;
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:kBackgroundRefreshInterval];
        } else {
            [[UIApplication sharedApplication]
                setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        }
    }];
}

- (void)handleActivation
{
    OWSAssertIsOnMainThread();
    
    [TSPreKeyManager checkPreKeysIfNecessary];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RTCInitializeSSL();

        if ([self.tsAccountManager isRegistered]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.disappearingMessagesJob startIfNecessary];
                [self enableBackgroundRefreshIfNecessary];
            });
        } else {
            [AppEnvironment.shared.notificationPresenter clearAllNotifications];
            [self.socketManager requestSocketOpen];
        }
    });

    if ([self.tsAccountManager isRegistered]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.socketManager requestSocketOpen];
            [Environment.shared.contactsManager fetchSystemContactsOnceIfAlreadyAuthorized];
            [[AppEnvironment.shared.messageFetcherJob run] retainUntilComplete];

            if (![UIApplication sharedApplication].isRegisteredForRemoteNotifications) {
                __unused AnyPromise *promise =
                    [OWSSyncPushTokensJob runWithAccountManager:AppEnvironment.shared.accountManager
                                                    preferences:Environment.shared.preferences];
            }

            if ([OWS2FAManager sharedManager].hasPending2FASetup) {
                UIViewController *frontmostViewController = UIApplication.sharedApplication.frontmostViewController;
                OWSAssertDebug(frontmostViewController);

                if ([frontmostViewController isKindOfClass:[OWSPinSetupViewController class]]) {
                    return;
                }

                OWSPinSetupViewController *setupVC = [[OWSPinSetupViewController alloc] initWithCompletionHandler:^{
                    [frontmostViewController dismissViewControllerAnimated:YES completion:nil];
                }];

                [frontmostViewController
                    presentFullScreenViewController:[[OWSNavigationController alloc] initWithRootViewController:setupVC]
                                           animated:YES
                                         completion:nil];
            } else if ([OWS2FAManager sharedManager].isDueForV1Reminder) {
                UIViewController *frontmostViewController = UIApplication.sharedApplication.frontmostViewController;
                OWSAssertDebug(frontmostViewController);

                UIViewController *reminderVC = [OWS2FAReminderViewController wrappedInNavController];
                reminderVC.modalPresentationStyle = UIModalPresentationFullScreen;

                if ([frontmostViewController isKindOfClass:[OWS2FAReminderViewController class]]) {
                    // We're already presenting this
                    return;
                }

                [frontmostViewController presentFullScreenViewController:reminderVC animated:YES completion:nil];
            }
        });
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return;
    }
    [self clearAllNotificationsAndRestoreBadgeCount];

    [DDLog flushLog];
}

- (void)clearAllNotificationsAndRestoreBadgeCount
{
    OWSAssertIsOnMainThread();

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        [AppEnvironment.shared.notificationPresenter clearAllNotifications];
        [OWSMessageUtils.sharedManager updateApplicationBadgeCount];
    }];
}

- (void)application:(UIApplication *)application
    performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        completionHandler(NO);
        return;
    }

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        if (![self.tsAccountManager isRegisteredAndReady]) {
            ActionSheetController *controller = [[ActionSheetController alloc]
                initWithTitle:NSLocalizedString(@"XXGJUSTHHANQR22", nil)
                      message:NSLocalizedString(@"XXGJUSTHHANQR33", nil)];

            [controller addAction:[[ActionSheetAction alloc] initWithTitle:NSLocalizedString(@"OK", nil)
                                                                     style:ActionSheetActionStyleDefault
                                                                   handler:^(ActionSheetAction *_Nonnull action) {

                                                                   }]];
            UIViewController *fromViewController = [[UIApplication sharedApplication] frontmostViewController];
            [fromViewController presentFullScreenViewController:controller
                                             animated:YES
                                           completion:^{
                                               completionHandler(NO);
                                           }];
            return;
        }

        [SignalApp.sharedApp showNewConversationView];

        completionHandler(YES);
    }];
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(nonnull NSUserActivity *)userActivity
      restorationHandler:(nonnull void (^)(NSArray *_Nullable))restorationHandler
{
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return NO;
    }

    if ([userActivity.activityType isEqualToString:@"INStartVideoCallIntent"]) {
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(10, 0)) {
            return NO;
        }
        INInteraction *interaction = [userActivity interaction];
        INIntent *intent = interaction.intent;

        if (![intent isKindOfClass:[INStartVideoCallIntent class]]) {
            return NO;
        }
        INStartVideoCallIntent *startCallIntent = (INStartVideoCallIntent *)intent;
        NSString *_Nullable handle = startCallIntent.contacts.firstObject.personHandle.value;
        if (!handle) {
            return NO;
        }

        [AppReadiness runNowOrWhenAppDidBecomeReady:^{
            if (![self.tsAccountManager isRegisteredAndReady]) {
                return;
            }

            if (!SSKFeatureFlags.calling) {
                return;
            }

            SignalServiceAddress *_Nullable address = [self addressForIntentHandle:handle];
            if (!address.isValid) {
                return;
            }

            if (AppEnvironment.shared.callService.currentCall != nil) {
                if ([address isEqualToAddress:AppEnvironment.shared.callService.currentCall.remoteAddress]) {
                    [AppEnvironment.shared.callService handleCallKitStartVideo];
                    return;
                } else {
                    return;
                }
            }

            OutboundCallInitiator *outboundCallInitiator = AppEnvironment.shared.outboundCallInitiator;
            OWSAssertDebug(outboundCallInitiator);
            [outboundCallInitiator initiateCallWithAddress:address];
        }];
        return YES;
    } else if ([userActivity.activityType isEqualToString:@"INStartAudioCallIntent"]) {

        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(10, 0)) {
            return NO;
        }
        INInteraction *interaction = [userActivity interaction];
        INIntent *intent = interaction.intent;

        if (![intent isKindOfClass:[INStartAudioCallIntent class]]) {
            return NO;
        }
        INStartAudioCallIntent *startCallIntent = (INStartAudioCallIntent *)intent;
        NSString *_Nullable handle = startCallIntent.contacts.firstObject.personHandle.value;
        if (!handle) {
            return NO;
        }

        [AppReadiness runNowOrWhenAppDidBecomeReady:^{
            if (![self.tsAccountManager isRegisteredAndReady]) {
                return;
            }

            if (!SSKFeatureFlags.calling) {
                return;
            }

            SignalServiceAddress *_Nullable address = [self addressForIntentHandle:handle];
            if (!address.isValid) {
                return;
            }

            if (AppEnvironment.shared.callService.currentCall != nil) {
                return;
            }

            OutboundCallInitiator *outboundCallInitiator = AppEnvironment.shared.outboundCallInitiator;
            OWSAssertDebug(outboundCallInitiator);
            [outboundCallInitiator initiateCallWithAddress:address];
        }];
        return YES;
    } else if ([userActivity.activityType isEqualToString:@"INStartCallIntent"]) {
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(13, 0)) {
            return NO;
        }

        INInteraction *interaction = [userActivity interaction];
        INIntent *intent = interaction.intent;
        if (![intent isKindOfClass:NSClassFromString(@"INStartCallIntent")]) {
            return NO;
        }

        NSArray<INPerson *> *contacts = [intent performSelector:@selector(contacts)];
        NSString *_Nullable handle = contacts.firstObject.personHandle.value;
        if (!handle) {
            return NO;
        }

        [AppReadiness runNowOrWhenAppDidBecomeReady:^{
            if (![self.tsAccountManager isRegisteredAndReady]) {
                return;
            }

            if (!SSKFeatureFlags.calling) {
                return;
            }

            SignalServiceAddress *_Nullable address = [self addressForIntentHandle:handle];
            if (!address.isValid) {
                return;
            }

            if (AppEnvironment.shared.callService.currentCall != nil) {
                return;
            }

            OutboundCallInitiator *outboundCallInitiator = AppEnvironment.shared.outboundCallInitiator;
            OWSAssertDebug(outboundCallInitiator);
            [outboundCallInitiator initiateCallWithAddress:address];
        }];
        return YES;
    } else if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        if (userActivity.webpageURL == nil) {
            return NO;
        }
        return [self tryToOpenUrl:userActivity.webpageURL];
    }
    return NO;
}

- (nullable SignalServiceAddress *)addressForIntentHandle:(NSString *)handle
{
    OWSAssertDebug(handle.length > 0);

    if ([handle hasPrefix:CallKitCallManager.kAnonymousCallHandlePrefix]) {
        SignalServiceAddress *_Nullable address = [CallKitIdStore addressForCallKitId:handle];
        if (!address.isValid) {
            return nil;
        }
        return address;
    }

    for (PhoneNumber *phoneNumber in
        [PhoneNumber tryParsePhoneNumbersFromUserSpecifiedText:handle
                                              clientPhoneNumber:[TSAccountManager localNumber]]) {
        return [[SignalServiceAddress alloc] initWithPhoneNumber:phoneNumber.toE164];
    }
    return nil;
}

#pragma mark - Orientation
- (UIInterfaceOrientationMask)application:(UIApplication *)application
    supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
    if (CurrentAppContext().isRunningTests) {
        return UIInterfaceOrientationMaskPortrait;
    }

    if (self.didAppLaunchFail) {
        return UIInterfaceOrientationMaskPortrait;
    }

    if (self.hasCall) {
        if (!UIDevice.currentDevice.isIPad) {
            return UIInterfaceOrientationMaskPortrait;
        }
    }

    UIViewController *_Nullable rootViewController = self.window.rootViewController;
    if (!rootViewController) {
        return UIDevice.currentDevice.defaultSupportedOrienations;
    }
    return rootViewController.supportedInterfaceOrientations;
}

- (BOOL)hasCall
{
    return self.windowManager.hasCall;
}

#pragma mark Push Notifications Delegate Methods

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return;
    }
    if (!(AppReadiness.isAppReady && [self.tsAccountManager isRegisteredAndReady])) {
        return;
    }

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        [[AppEnvironment.shared.messageFetcherJob run] retainUntilComplete];
    }];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    OWSAssertIsOnMainThread();

    if (self.didAppLaunchFail) {
        return;
    }
    if (!(AppReadiness.isAppReady && [self.tsAccountManager isRegisteredAndReady])) {
        return;
    }

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        [[AppEnvironment.shared.messageFetcherJob run] retainUntilComplete];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            completionHandler(UIBackgroundFetchResultNewData);
        });
    }];
}

- (void)application:(UIApplication *)application
    performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        __block AnyPromise *job = [AppEnvironment.shared.messageFetcherJob run].then(^{
            // HACK: Call completion handler after n seconds.
            //
            // We don't currently have a convenient API to know when message fetching is *done* when
            // working with the websocket.
            //
            // We *could* substantially rewrite the TSSocketManager to take advantage of the `empty` message
            // But once our REST endpoint is fixed to properly de-enqueue fallback notifications, we can easily
            // use the rest endpoint here rather than the websocket and circumvent making changes to critical code.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completionHandler(UIBackgroundFetchResultNewData);
                job = nil;
            });
        });
        [job retainUntilComplete];
    }];
}

- (void)versionMigrationsDidComplete
{
    OWSAssertIsOnMainThread();

    self.areVersionMigrationsComplete = YES;

    [self checkIfAppIsReady];
}

- (void)storageIsReady
{
    OWSAssertIsOnMainThread();

    [self checkIfAppIsReady];
}

- (void)checkIfAppIsReady
{
    OWSAssertIsOnMainThread();

    //在存储就绪且所有版本迁移完成之前，应用程序尚未就绪
    if (!self.areVersionMigrationsComplete) {
        return;
    }
    if (![self.storageCoordinator isStorageReady]) {
        return;
    }
    if ([AppReadiness isAppReady]) {
        return;
    }
    BOOL launchJobsAreComplete = [self.launchJobs ensureLaunchJobsWithCompletion:^{
        [self checkIfAppIsReady];
    }];
    if (!launchJobsAreComplete) {
        return;
    }
    [AppReadiness setAppIsReady];

    if (CurrentAppContext().isRunningTests) {
        return;
    }

    if ([self.tsAccountManager isRegistered]) {
        [[AppEnvironment.shared.messageFetcherJob run] retainUntilComplete];
        __unused AnyPromise *pushTokenpromise =
            [OWSSyncPushTokensJob runWithAccountManager:AppEnvironment.shared.accountManager
                                            preferences:Environment.shared.preferences];
    }

    [DeviceSleepManager.sharedInstance removeBlockWithBlockObject:self];

    [AppVersion.sharedInstance mainAppLaunchDidComplete];

    [Environment.shared.audioSession setup];

    [SSKEnvironment.shared.reachabilityManager setup];

    if (!Environment.shared.preferences.hasGeneratedThumbnails) {
        [self.databaseStorage
            asyncReadWithBlock:^(SDSAnyReadTransaction *transaction) {
                [TSAttachment anyEnumerateWithTransaction:transaction
                                                  batched:YES
                                                    block:^(TSAttachment *attachment, BOOL *stop) {
                                                        // no-op. It's sufficient to initWithCoder: each object.
                                                    }];
            }
            completion:^{
                [Environment.shared.preferences setHasGeneratedThumbnails:YES];
            }];
    }

    [self.profileManager fetchAndUpdateLocalUsersProfile];
    [self.readReceiptManager prepareCachedValues];

    [SignalApp.sharedApp ensureRootViewController:launchStartedAt];

    [self.messageManager startObserving];

    [self.udManager setup];

    if (StorageCoordinator.dataStoreForUI == DataStoreYdb) {
        [self.primaryStorage touchDbAsync];
    }

    if ([self.tsAccountManager isRegistered]) {
        AppVersion *appVersion = AppVersion.sharedInstance;
        if (appVersion.lastAppVersion.length > 0
            && ![appVersion.lastAppVersion isEqualToString:appVersion.currentAppVersion]) {

            if (self.tsAccountManager.isRegisteredPrimaryDevice) {
                [[self.tsAccountManager updateAccountAttributes] retainUntilComplete];
                [self.syncManager sendConfigurationSyncMessage];
            } else {
                [[self.deviceService updateCapabilities] retainUntilComplete];
            }
        }
    }

    [ViewOnceMessages appDidBecomeReady];
}

- (void)registrationStateDidChange
{
    OWSAssertIsOnMainThread();

    [self enableBackgroundRefreshIfNecessary];

    if ([self.tsAccountManager isRegistered]) {

        [self.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
            [ExperienceUpgradeFinder markAllCompleteForNewUserWithTransaction:transaction.unwrapGrdbWrite];
        }];
        [self.disappearingMessagesJob startIfNecessary];
        [AppEnvironment.shared.callService createCallUIAdapter];
    }
}

- (void)registrationLockDidChange:(NSNotification *)notification
{
    [self enableBackgroundRefreshIfNecessary];
}

#pragma mark - status bar touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectContainsPoint(statusBarFrame, location)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TappedStatusBarNotification object:nil];
    }
}

#pragma mark - UNUserNotificationsDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
    __IOS_AVAILABLE(10.0)__TVOS_AVAILABLE(10.0)__WATCHOS_AVAILABLE(3.0)__OSX_AVAILABLE(10.14)
{
    [AppReadiness runNowOrWhenAppDidBecomeReady:^() {
        UNNotificationPresentationOptions options = UNNotificationPresentationOptionAlert
            | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;
        completionHandler(options);
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler __IOS_AVAILABLE(10.0)__WATCHOS_AVAILABLE(3.0)
                                       __OSX_AVAILABLE(10.14)__TVOS_PROHIBITED
{
    [AppReadiness runNowOrWhenAppDidBecomeReady:^() {
        [self.userNotificationActionHandler handleNotificationResponse:response completionHandler:completionHandler];
    }];
}
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    openSettingsForNotification:(nullable UNNotification *)notification __IOS_AVAILABLE(12.0)
                                    __OSX_AVAILABLE(10.14)__WATCHOS_PROHIBITED __TVOS_PROHIBITED
{
    OWSLogInfo(@"");
}

@end
