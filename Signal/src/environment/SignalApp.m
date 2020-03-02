
#import "SignalApp.h"
#import "AppDelegate.h"
#import "ConversationViewController.h"
#import "Signal-Swift.h"
#import <SignalCoreKit/Threading.h>
#import <SignalMessaging/DebugLogger.h>
#import <SignalMessaging/Environment.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <SignalServiceKit/TSContactThread.h>
#import <SignalServiceKit/TSGroupThread.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignalApp ()

@property (nonatomic, nullable, weak) ConversationSplitViewController *conversationSplitViewController;
@property (nonatomic, nullable, weak) OnboardingController *onboardingController;
@property (nonatomic) BOOL hasInitialRootViewController;

@end

@implementation SignalApp

+ (instancetype)sharedApp
{
    static SignalApp *sharedApp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedApp = [[self alloc] initDefault];
    });
    return sharedApp;
}

- (instancetype)initDefault
{
    self = [super init];

    if (!self) {
        return self;
    }

    OWSSingletonAssert();

    return self;
}

#pragma mark - Dependencies

- (SDSDatabaseStorage *)databaseStorage
{
    return SDSDatabaseStorage.shared;
}

+ (SDSDatabaseStorage *)databaseStorage
{
    return SDSDatabaseStorage.shared;
}

- (TSAccountManager *)tsAccountManager
{
    OWSAssertDebug(SSKEnvironment.shared.tsAccountManager);

    return SSKEnvironment.shared.tsAccountManager;
}

- (OWSBackup *)backup
{
    return AppEnvironment.shared.backup;
}

#pragma mark -

- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeCallLoggingPreference:)
                                                 name:OWSPreferencesCallLoggingDidChangeNotification
                                               object:nil];
}

#pragma mark - View Convenience Methods

- (void)presentConversationForAddress:(SignalServiceAddress *)address animated:(BOOL)isAnimated
{
    [self presentConversationForAddress:address action:ConversationViewActionNone animated:(BOOL)isAnimated];
}

- (void)presentConversationForAddress:(SignalServiceAddress *)address
                               action:(ConversationViewAction)action
                             animated:(BOOL)isAnimated
{
    __block TSThread *thread = nil;
    [self.databaseStorage writeWithBlock:^(SDSAnyWriteTransaction *transaction) {
        thread = [TSContactThread getOrCreateThreadWithContactAddress:address transaction:transaction];
    }];
    [self presentConversationForThread:thread action:action animated:(BOOL)isAnimated];
}

- (void)presentConversationForThreadId:(NSString *)threadId animated:(BOOL)isAnimated
{
    OWSAssertDebug(threadId.length > 0);

    __block TSThread *_Nullable thread;
    [self.databaseStorage readWithBlock:^(SDSAnyReadTransaction *transaction) {
        thread = [TSThread anyFetchWithUniqueId:threadId transaction:transaction];
    }];
    if (thread == nil) {
        OWSFailDebug(@"unable to find thread with id: %@", threadId);
        return;
    }

    [self presentConversationForThread:thread animated:isAnimated];
}

- (void)presentConversationForThread:(TSThread *)thread animated:(BOOL)isAnimated
{
    [self presentConversationForThread:thread action:ConversationViewActionNone animated:isAnimated];
}

- (void)presentConversationForThread:(TSThread *)thread action:(ConversationViewAction)action animated:(BOOL)isAnimated
{
    [self presentConversationForThread:thread action:action focusMessageId:nil animated:isAnimated];
}

- (void)presentConversationForThread:(TSThread *)thread
                              action:(ConversationViewAction)action
                      focusMessageId:(nullable NSString *)focusMessageId
                            animated:(BOOL)isAnimated
{
    OWSAssertIsOnMainThread();
    OWSAssertDebug(self.conversationSplitViewController);
    if (!thread) {
        OWSFailDebug(@"Can't present nil thread.");
        return;
    }

    DispatchMainThreadSafe(^{
        // lcy 20200302 这个if的意思是，如果当前有正在对话的对话框
        if (self.conversationSplitViewController.visibleThread) {
            if ([self.conversationSplitViewController.visibleThread.uniqueId isEqualToString:thread.uniqueId]) {
                [self.conversationSplitViewController.selectedConversationViewController popKeyBoard];
                return;
            }
        }

        [self.conversationSplitViewController presentThread:thread
                                                     action:action
                                             focusMessageId:focusMessageId
                                                   animated:isAnimated];
    });
}

- (void)presentConversationAndScrollToFirstUnreadMessageForThreadId:(NSString *)threadId animated:(BOOL)isAnimated
{
    OWSAssertIsOnMainThread();
    OWSAssertDebug(threadId.length > 0);
    OWSAssertDebug(self.conversationSplitViewController);

    __block TSThread *_Nullable thread;
    [self.databaseStorage readWithBlock:^(SDSAnyReadTransaction *transaction) {
        thread = [TSThread anyFetchWithUniqueId:threadId transaction:transaction];
    }];
    if (thread == nil) {
        return;
    }

    DispatchMainThreadSafe(^{
        if (self.conversationSplitViewController.visibleThread) {
            if ([self.conversationSplitViewController.visibleThread.uniqueId isEqualToString:thread.uniqueId]) {
                [self.conversationSplitViewController.selectedConversationViewController
                    scrollToFirstUnreadMessage:isAnimated];
                return;
            }
        }

        [self.conversationSplitViewController presentThread:thread
                                                     action:ConversationViewActionNone
                                             focusMessageId:nil
                                                   animated:isAnimated];
    });
}

- (void)didChangeCallLoggingPreference:(NSNotification *)notification
{
    [AppEnvironment.shared.callService createCallUIAdapter];
}

#pragma mark - Methods
//z
+ (void)resetAppData
{
    [DDLog flushLog];

    [self.databaseStorage resetAllStorage];
    [OWSUserProfile resetProfileStorage];
    [Environment.shared.preferences removeAllValues];
    [AppEnvironment.shared.notificationPresenter clearAllNotifications];
    [OWSFileSystem deleteContentsOfDirectory:[OWSFileSystem appSharedDataDirectoryPath]];
    [OWSFileSystem deleteContentsOfDirectory:[OWSFileSystem appDocumentDirectoryPath]];
    [OWSFileSystem deleteContentsOfDirectory:[OWSFileSystem cachesDirectoryPath]];
    [OWSFileSystem deleteContentsOfDirectory:OWSTemporaryDirectory()];
    [OWSFileSystem deleteContentsOfDirectory:NSTemporaryDirectory()];

    [DebugLogger.sharedLogger wipeLogs];
    exit(0);
}

//回到首页
- (void)showConversationSplitView
{
    //版本1.1 -------新UI
    UITabBarController *tabbarVC = [[UITabBarController alloc] init];
    tabbarVC.tabBar.translucent = YES;  //lcy 20200302注意，如果是NO的话ConversationSplitViewController会距离底部有段距离死活下不去
    tabbarVC.tabBar.tintColor = UIColor.blackColor;
    [tabbarVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.blackColor} forState:UIControlStateNormal];
    [tabbarVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.blackColor} forState:UIControlStateSelected];
    
    // lcy 20200302 设置root修改成这样了
    ConversationSplitViewController *viewController0 = [ConversationSplitViewController new];
    viewController0.tabBarItem.title = @"对话";
    viewController0.tabBarItem.image = [[UIImage imageNamed:@"conversation"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController0.tabBarItem.selectedImage = [[UIImage imageNamed:@"conversation_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabbarVC addChildViewController:viewController0];
    
    ComposeViewController *viewController1 = [ComposeViewController new];
    viewController1.tabBarItem.title = @"通讯录";
    viewController1.tabBarItem.image = [[UIImage imageNamed:@"list"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController1.tabBarItem.selectedImage = [[UIImage imageNamed:@"list_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabbarVC addChildViewController:[[OWSNavigationController alloc] initWithRootViewController:viewController1]];
    
    AppSettingsViewController *viewController2 = [AppSettingsViewController new];
    viewController2.tabBarItem.title = @"我";
    viewController2.tabBarItem.image = [[UIImage imageNamed:@"me"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController2.tabBarItem.selectedImage = [[UIImage imageNamed:@"me_select"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [tabbarVC addChildViewController:[[OWSNavigationController alloc] initWithRootViewController:viewController2]];
    
        
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = tabbarVC;
    self.conversationSplitViewController = viewController0;
    self.onboardingController = nil;
    
    
    //版本1.1 -------侧滑UI

//    ConversationSplitViewController *splitViewController = [ConversationSplitViewController new];
//
//    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    appDelegate.window.rootViewController = splitViewController;
//
//    self.conversationSplitViewController = splitViewController;
//    self.onboardingController = nil;
}

- (void)showOnboardingView
{
    OnboardingController *onboardingController = [OnboardingController new];
    UIViewController *initialViewController = [onboardingController initialViewController];
    OWSNavigationController *navController =
        [[OWSNavigationController alloc] initWithRootViewController:initialViewController];

//#if TESTABLE_BUILD
//    AccountManager *accountManager = AppEnvironment.shared.accountManager;
//    UITapGestureRecognizer *registerGesture =
//        [[UITapGestureRecognizer alloc] initWithTarget:accountManager action:@selector(fakeRegistration)];
//    registerGesture.numberOfTapsRequired = 8;
//    [navController.view addGestureRecognizer:registerGesture];
//#else
    UITapGestureRecognizer *submitLogGesture = [[UITapGestureRecognizer alloc] initWithTarget:[Pastelog class]
                                                                                       action:@selector(submitLogs)];
    submitLogGesture.numberOfTapsRequired = 8;
    [navController.view addGestureRecognizer:submitLogGesture];
//#endif

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = navController;

    self.onboardingController = onboardingController;
    self.conversationSplitViewController = nil;
}

- (void)showBackupRestoreView
{
    BackupRestoreViewController *backupRestoreVC = [BackupRestoreViewController new];
    OWSNavigationController *navController =
        [[OWSNavigationController alloc] initWithRootViewController:backupRestoreVC];

    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = navController;

    self.onboardingController = nil;
    self.conversationSplitViewController = nil;
}

- (void)ensureRootViewController:(NSTimeInterval)launchStartedAt
{
    OWSAssertIsOnMainThread();

    if (!AppReadiness.isAppReady || self.hasInitialRootViewController) {
        return;
    }
    self.hasInitialRootViewController = YES;

    NSTimeInterval startupDuration = CACurrentMediaTime() - launchStartedAt;

    if ([self.tsAccountManager isRegistered]) {
        if (self.backup.hasPendingRestoreDecision) {
            [self showBackupRestoreView];
        } else {
            [self showConversationSplitView];
        }
    } else {
        [self showOnboardingView];
    }

    [AppUpdateNag.sharedInstance showAppUpgradeNagIfNecessary];

    [UIViewController attemptRotationToDeviceOrientation];
}

- (BOOL)receivedVerificationCode:(NSString *)verificationCode
{
    OWSAssertDebug(self.onboardingController);

    UIViewController *currentOnboardingVC = self.onboardingController.currentViewController;
    if (![currentOnboardingVC isKindOfClass:[OnboardingVerificationViewController class]]) {
        OWSLogWarn(@"Not the verification view controller we expected. Got %@ instead",
            NSStringFromClass(currentOnboardingVC.class));

        return NO;
    }

    OnboardingVerificationViewController *verificationVC = (OnboardingVerificationViewController *)currentOnboardingVC;
    [verificationVC setVerificationCodeAndTryToVerify:verificationCode];
    return YES;
}

- (void)showNewConversationView
{
    OWSAssertIsOnMainThread();
    OWSAssertDebug(self.conversationSplitViewController);

    [self.conversationSplitViewController showNewConversationView];
}

@end

NS_ASSUME_NONNULL_END
