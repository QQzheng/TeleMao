

#import "AppSettingsViewController.h"
#import "AboutTableViewController.h"
#import "AdvancedSettingsTableViewController.h"
#import "DebugUITableViewController.h"
#import "NotificationSettingsViewController.h"
#import "OWSBackup.h"
#import "OWSBackupSettingsViewController.h"
#import "OWSLinkedDevicesTableViewController.h"
#import "OWSNavigationController.h"
#import "PrivacySettingsTableViewController.h"
#import "ProfileViewController.h"
#import "RegistrationUtils.h"
#import "Signal-Swift.h"
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalMessaging/UIUtil.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSSocketManager.h>

@interface AppSettingsViewController ()
@property (nonatomic, readonly) OWSContactsManager *contactsManager;
@property (nonatomic, nullable) OWSInviteFlow *inviteFlow;
@end

#pragma mark -
@implementation AppSettingsViewController
+ (OWSNavigationController *)inModalNavigationController
{
    AppSettingsViewController *viewController = [AppSettingsViewController new];
    OWSNavigationController *navController =
        [[OWSNavigationController alloc] initWithRootViewController:viewController];
    return navController;
}

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _contactsManager = Environment.shared.contactsManager;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }
    _contactsManager = Environment.shared.contactsManager;
    return self;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - Dependencies
- (TSAccountManager *)tsAccountManager
{
    return TSAccountManager.sharedInstance;
}

#pragma mark - UIViewController
- (void)loadView
{
    self.tableViewStyle = UITableViewStylePlain;
    [super loadView];
}

//版本1.0 UI
- (void)viewDidLoad
{
    [super viewDidLoad];
   
    self.navigationController.navigationBar.barTintColor = UIColor.ows_signalBlueColor;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"Person_bg"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationItem setHidesBackButton:YES];

    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                      target:self
                                                      action:@selector(dismissWasPressed:)
                                     accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"dismiss")];
    //注释黑暗模式
    //[self updateRightBarButtonForTheme];
    [self observeNotifications];

//    self.title = NSLocalizedString(@"XXGJUSTHHANQK13", @"Title for settings activity");

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

    __weak AppSettingsViewController *weakSelf = self;

#ifdef INTERNAL
    OWSTableSection *internalSection = [OWSTableSection new];
    [section addItem:[OWSTableItem softCenterLabelItemWithText:@"Internal Build"]];
    [contents addSection:internalSection];
#endif

    OWSTableSection *section = [OWSTableSection new];
    [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
        return [weakSelf profileHeaderCell];
    }
                         customRowHeight:100.f
                         actionBlock:^{
                             [weakSelf showProfile];
                         }]];

  // cell
    [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
        UITableViewCell *cell = [OWSTableItem newCell];
        cell.textLabel.text = NSLocalizedString(@"XXGJUSTHHANQN8", @"网络状态");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *accessoryLabel = [UILabel new];
        accessoryLabel.textColor = UIColor.ows_signalBlueColor;
         
        if (weakSelf.tsAccountManager.isDeregistered) {
            accessoryLabel.text = self.tsAccountManager.isPrimaryDevice
            ? NSLocalizedString(@"XXGJUSTHHANQN7", @"未注册")
            : NSLocalizedString(@"XXGJUSTHHANQN6",@"设备未关联");
         } else {
             switch (TSSocketManager.shared.highestSocketState) {
                 case OWSWebSocketStateClosed:
                     accessoryLabel.text = NSLocalizedString(@"XXGJUSTHHANQN9", @"离线");
                     break;
                 case OWSWebSocketStateConnecting:
                     accessoryLabel.text = NSLocalizedString(@"XXGJUSTHHANQN5", @"");
                     accessoryLabel.textColor = UIColor.ows_accentYellowColor;
                     break;
                 case OWSWebSocketStateOpen:
                     accessoryLabel.text = NSLocalizedString(@"XXGJUSTHHANQN4", @"");
                     accessoryLabel.textColor = UIColor.ows_accentGreenColor;
                     break;
             }
         }
         [accessoryLabel sizeToFit];
         cell.accessoryView = accessoryLabel;
         cell.accessibilityIdentifier
             = ACCESSIBILITY_IDENTIFIER_WITH_NAME(AppSettingsViewController, @"network_status");
         return cell;
     }actionBlock:nil]];

    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQS92",
                                                              @"邀请朋友")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"invite")
                                              actionBlock:^{
                                                  [weakSelf showInviteFlow];
                                              }]];

    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQS112",
                                                              @"隐私服务")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"privacy")
                                              actionBlock:^{
                                                  [weakSelf showPrivacy];
                                              }]];
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQS103", @"通知管理")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"notifications")
                                              actionBlock:^{
                                                  [weakSelf showNotifications];
                                              }]];

    // There's actually nothing AFAIK preventing linking another linked device from an
    // existing linked device, but maybe it's not something we want to expose until
    // after unifying the other experiences between secondary/primary devices.
    if (self.tsAccountManager.isRegisteredPrimaryDevice) {
        [section
            addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQL12",
                                                             @"绑定设备")
                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"linked_devices")
                                             actionBlock:^{
                                                 [weakSelf showLinkedDevices];
                                             }]];
    }
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQS60", @"高级设置")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"advanced")
                                              actionBlock:^{
                                                  [weakSelf showAdvanced];
                                              }]];
    BOOL isBackupEnabled = [OWSBackup.sharedManager isBackupEnabled];
    BOOL showBackup = (OWSBackup.isFeatureEnabled && isBackupEnabled);
    if (showBackup) {
        [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQS65",
                                                                  @"备份")
                                      accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"backup")
                                                  actionBlock:^{
                                                      [weakSelf showBackup];
                                                  }]];
    }
    [section addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"XXGJUSTHHANQS49", @"关于我们")
                                  accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"about")
                                              actionBlock:^{
                                                  [weakSelf showAbout];
                                              }]];

    if (self.tsAccountManager.isDeregistered) {
        [section
            addItem:[self destructiveButtonItemWithTitle:self.tsAccountManager.isPrimaryDevice
                              ? NSLocalizedString(@"XXGJUSTHHANQS116", @"Label for re-registration button.")
                              : NSLocalizedString(@"XXGJUSTHHANQS115", @"Label for re-link button.")
                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"reregister")
                                                selector:@selector(reregisterUser)
                                                   color:UIColor.ows_signalBlueColor]];
        [section addItem:[self destructiveButtonItemWithTitle:NSLocalizedString(@"XXGJUSTHHANQS86",
                                                                  @"Label for 'delete data' button.")
                                      accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"delete_data")
                                                     selector:@selector(deleteUnregisterUserData)
                                                        color:UIColor.ows_accentRedColor]];
    } else if (self.tsAccountManager.isRegisteredPrimaryDevice) {
        [section
            addItem:[self destructiveButtonItemWithTitle:NSLocalizedString(@"XXGJUSTHHANQS85", @"")
                                 accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"delete_account")
                                                selector:@selector(unregisterUser)
                                                   color:UIColor.ows_accentRedColor]];
    } else {
        [section addItem:[self destructiveButtonItemWithTitle:NSLocalizedString(@"XXGJUSTHHANQS86",
                                                                  @"Label for 'delete data' button.")
                                      accessibilityIdentifier:ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"delete_data")
                                                     selector:@selector(deleteLinkedData)
                                                        color:UIColor.ows_accentRedColor]];
    }

    [contents addSection:section];

    self.contents = contents;
}

- (OWSTableItem *)destructiveButtonItemWithTitle:(NSString *)title
                         accessibilityIdentifier:(NSString *)accessibilityIdentifier
                                        selector:(SEL)selector
                                           color:(UIColor *)color
{
    __weak AppSettingsViewController *weakSelf = self;
   return [OWSTableItem
        itemWithCustomCellBlock:^{
            UITableViewCell *cell = [OWSTableItem newCell];
            cell.preservesSuperviewLayoutMargins = YES;
            cell.contentView.preservesSuperviewLayoutMargins = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            const CGFloat kButtonHeight = 40.f;
            OWSFlatButton *button = [OWSFlatButton buttonWithTitle:title
                                                              font:[OWSFlatButton fontForHeight:kButtonHeight]
                                                        titleColor:[UIColor whiteColor]
                                                   backgroundColor:color
                                                            target:weakSelf
                                                          selector:selector];
            [cell.contentView addSubview:button];
            [button autoSetDimension:ALDimensionHeight toSize:kButtonHeight];
            [button autoVCenterInSuperview];
            [button autoPinLeadingAndTrailingToSuperviewMargin];
            button.accessibilityIdentifier = accessibilityIdentifier;

            return cell;
        }
                customRowHeight:90.f
                    actionBlock:nil];
}

- (UITableViewCell *)profileHeaderCell
{
    UITableViewCell *cell = [OWSTableItem newCell];
    cell.contentView.backgroundColor = [UIColor colorWithRGBHex:0xfad140];
    cell.preservesSuperviewLayoutMargins = YES;
    cell.contentView.preservesSuperviewLayoutMargins = YES;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UIImage *_Nullable localProfileAvatarImage = [OWSProfileManager.sharedManager localProfileAvatarImage];
    UIImage *avatarImage = (localProfileAvatarImage
            ?: [[[OWSContactAvatarBuilder alloc] initForLocalUserWithDiameter:kLargeAvatarSize] buildDefaultImage]);
    OWSAssertDebug(avatarImage);

    AvatarImageView *avatarView = [[AvatarImageView alloc] initWithImage:avatarImage];
    avatarView.layer.borderWidth = 1;
    avatarView.layer.borderColor = [UIColor whiteColor].CGColor;
    [cell.contentView addSubview:avatarView];
    [avatarView autoVCenterInSuperview];
    [avatarView autoPinLeadingToSuperviewMargin];
    [avatarView autoSetDimension:ALDimensionWidth toSize:kLargeAvatarSize];
    [avatarView autoSetDimension:ALDimensionHeight toSize:kLargeAvatarSize];

    UIView *nameView = [UIView containerView];
    [cell.contentView addSubview:nameView];
    [nameView autoVCenterInSuperview];
    [nameView autoPinLeadingToTrailingEdgeOfView:avatarView offset:16.f];
    [nameView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16.f];//版本1.1
    

    UILabel *titleLabel = [UILabel new];
    NSString *_Nullable localProfileName = [OWSProfileManager.sharedManager localFullName];
    if (localProfileName.length > 0) {
        titleLabel.text = localProfileName;
    } else {
        titleLabel.text = NSLocalizedString(
            @"XXGJUSTHHANQA28", @"Text prompting user to edit their profile name.");
    }
     titleLabel.font = [UIFont ows_dynamicTypeTitle2Font];
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle; // 版本1.1
    [nameView addSubview:titleLabel];
    [titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [titleLabel autoPinWidthToSuperview];

    __block UIView *lastTitleView = titleLabel;
    const CGFloat kSubtitlePointSize = 12.f;
    void (^addSubtitle)(NSString *) = ^(NSString *subtitle) {
        UILabel *subtitleLabel = [UILabel new];
        subtitleLabel.textColor = UIColor.whiteColor;
        subtitleLabel.font = [UIFont ows_regularFontWithSize:kSubtitlePointSize];
        subtitleLabel.text = subtitle;
        subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [nameView addSubview:subtitleLabel];
        [subtitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:lastTitleView];
        [subtitleLabel autoPinLeadingToSuperviewMargin];
        lastTitleView = subtitleLabel;
    };

    addSubtitle(
        [PhoneNumber bestEffortFormatPartialUserSpecifiedTextToLookLikeAPhoneNumber:[TSAccountManager localNumber]]);

    NSString *_Nullable username = [OWSProfileManager.sharedManager localUsername];
    if (username.length > 0) {
        addSubtitle([CommonFormats formatUsername:username]);
    }

    [lastTitleView autoPinEdgeToSuperviewEdge:ALEdgeBottom];

    cell.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"profile");

    return cell;
}

- (void)showInviteFlow
{
    OWSInviteFlow *inviteFlow = [[OWSInviteFlow alloc] initWithPresentingViewController:self];
    self.inviteFlow = inviteFlow;
    [inviteFlow presentWithIsAnimated:YES completion:nil];
}

- (void)showPrivacy
{
    PrivacySettingsTableViewController *vc = [[PrivacySettingsTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAppearance
{
    AppearanceSettingsTableViewController *vc = [AppearanceSettingsTableViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showNotifications
{
    NotificationSettingsViewController *vc = [[NotificationSettingsViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showLinkedDevices
{
    OWSLinkedDevicesTableViewController *vc = [OWSLinkedDevicesTableViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showProfile
{
    [ProfileViewController presentForAppSettings:self.navigationController];
}

- (void)showAdvanced
{
    AdvancedSettingsTableViewController *vc = [[AdvancedSettingsTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAbout
{
    AboutTableViewController *vc = [[AboutTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showBackup
{
    OWSBackupSettingsViewController *vc = [OWSBackupSettingsViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

//#ifdef USE_DEBUG_UI
//- (void)showDebugUI
//{
//    [DebugUITableViewController presentDebugUIFromViewController:self];
//}
//#endif

- (void)dismissWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Unregister & Re-register

- (void)unregisterUser
{
    [self showDeleteAccountUI:YES];
}

- (void)deleteLinkedData
{
    ActionSheetController *actionSheet =
        [[ActionSheetController alloc] initWithTitle:NSLocalizedString(@"XXGJUSTHHANQC133", @"")
                                             message:NSLocalizedString(@"XXGJUSTHHANQC132", @"")];
    [actionSheet addAction:[[ActionSheetAction alloc] initWithTitle:NSLocalizedString(@"XXGJUSTHHANQP82", @"")
                                                              style:ActionSheetActionStyleDestructive
                                                            handler:^(ActionSheetAction *action) {
                                                                [SignalApp resetAppData];
                                                            }]];
    [actionSheet addAction:[OWSActionSheets cancelAction]];

    [self presentActionSheet:actionSheet];
}

- (void)deleteUnregisterUserData
{
    [self showDeleteAccountUI:NO];
}

- (void)showDeleteAccountUI:(BOOL)isRegistered
{
    __weak AppSettingsViewController *weakSelf = self;

    ActionSheetController *actionSheet =
        [[ActionSheetController alloc] initWithTitle:NSLocalizedString(@"XXGJUSTHHANQC47", @"")
                                             message:NSLocalizedString(@"XXGJUSTHHANQC46", @"")];
    [actionSheet addAction:[[ActionSheetAction alloc] initWithTitle:NSLocalizedString(@"XXGJUSTHHANQP82", @"")
                                                              style:ActionSheetActionStyleDestructive
                                                            handler:^(ActionSheetAction *action) {
                                                                [weakSelf deleteAccount:isRegistered];
                                                            }]];
    [actionSheet addAction:[OWSActionSheets cancelAction]];

    [self presentActionSheet:actionSheet];
}

- (void)deleteAccount:(BOOL)isRegistered
{
    if (isRegistered) {
        [ModalActivityIndicatorViewController
            presentFromViewController:self
                            canCancel:NO
                      backgroundBlock:^(ModalActivityIndicatorViewController *modalActivityIndicator) {
                          [TSAccountManager
                              unregisterTextSecureWithSuccess:^{
                                  [SignalApp resetAppData];
                              }
                              failure:^(NSError *error) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [modalActivityIndicator dismissWithCompletion:^{
                                          [OWSActionSheets
                                              showActionSheetWithTitle:NSLocalizedString(
                                                                           @"XXGJUSTHHANQU19", @"")];
                                      }];
                                  });
                              }];
                      }];
    } else {
        [SignalApp resetAppData];
    }
}

- (void)reregisterUser
{
    [RegistrationUtils showReregistrationUIFromViewController:self];
}

#pragma mark - Dark Theme

- (UIBarButtonItem *)darkThemeBarButton
{
    UIBarButtonItem *barButtonItem;
    if (Theme.isDarkThemeEnabled) {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_dark_theme_on"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(didPressDisableDarkTheme:)];
    } else {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_dark_theme_off"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(didPressEnableDarkTheme:)];
    }
    barButtonItem.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, @"dark_theme");
    return barButtonItem;
}

- (void)didPressEnableDarkTheme:(id)sender
{
    [Theme setCurrentTheme:ThemeMode_Dark];
    [self updateRightBarButtonForTheme];
    [self updateTableContents];
}

- (void)didPressDisableDarkTheme:(id)sender
{
    [Theme setCurrentTheme:ThemeMode_Light];
    [self updateRightBarButtonForTheme];
    [self updateTableContents];
}

- (void)updateRightBarButtonForTheme
{
//    // TODO Xcode 11: Delete this once we're compiling only in Xcode 11
//#ifdef __IPHONE_13_0
//    if (@available(iOS 13, *)) {
//        // Don't show the moon button in iOS 13+, theme settings are now in a menu
//        return;
//    }
//#endif
//    self.navigationItem.rightBarButtonItem = [self darkThemeBarButton];
}

#pragma mark - Notifications

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketStateDidChange)
                                                 name:kNSNotification_OWSWebSocketStateDidChange
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localProfileDidChange:)
                                                 name:kNSNotificationNameLocalProfileDidChange
                                               object:nil];
}

- (void)socketStateDidChange
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

- (void)localProfileDidChange:(id)notification
{
    OWSAssertIsOnMainThread();

    [self updateTableContents];
}

@end
