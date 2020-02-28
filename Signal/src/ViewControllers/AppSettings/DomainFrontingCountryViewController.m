
#import "DomainFrontingCountryViewController.h"
#import "OWSCountryMetadata.h"
#import "OWSTableViewController.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import <SignalMessaging/Theme.h>
#import <SignalServiceKit/OWSSignalService.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

@interface DomainFrontingCountryViewController ()

@property (nonatomic, readonly) OWSTableViewController *tableViewController;

@end

#pragma mark -

@implementation DomainFrontingCountryViewController

- (void)loadView
{
    [super loadView];

    self.title = NSLocalizedString(
        @"XXGJUSTHHANQC28", @"Title for the 'censorship circumvention country' view.");

    self.view.backgroundColor = Theme.backgroundColor;

    [self createViews];
}

- (void)createViews
{
    _tableViewController = [OWSTableViewController new];
    [self.view addSubview:self.tableViewController.view];
    [self.tableViewController.view autoPinEdgeToSuperviewSafeArea:ALEdgeLeading];
    [self.tableViewController.view autoPinEdgeToSuperviewSafeArea:ALEdgeTrailing];
    [_tableViewController.view autoPinToTopLayoutGuideOfViewController:self withInset:0];
    [_tableViewController.view autoPinToBottomLayoutGuideOfViewController:self withInset:0];

    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    NSString *currentCountryCode = OWSSignalService.sharedInstance.manualCensorshipCircumventionCountryCode;

    __weak DomainFrontingCountryViewController *weakSelf = self;

    OWSTableSection *section = [OWSTableSection new];
    section.headerTitle = NSLocalizedString(
        @"XXGJUSTHHANQD33", @"Section title for the 'domain fronting country' view.");
    for (OWSCountryMetadata *countryMetadata in [OWSCountryMetadata allCountryMetadatas]) {
        [section addItem:[OWSTableItem
                             itemWithCustomCellBlock:^{
                                 UITableViewCell *cell = [OWSTableItem newCell];
                                 [OWSTableItem configureCell:cell];
                                 cell.textLabel.text = countryMetadata.localizedCountryName;

                                 if ([countryMetadata.countryCode isEqualToString:currentCountryCode]) {
                                     cell.accessoryType = UITableViewCellAccessoryCheckmark;
                                 }

                                 return cell;
                             }
                             actionBlock:^{
                                 [weakSelf selectCountry:countryMetadata];
                             }]];
    }
    [contents addSection:section];

    self.tableViewController.contents = contents;
}

- (void)selectCountry:(OWSCountryMetadata *)countryMetadata
{
    OWSAssertDebug(countryMetadata);

    OWSSignalService.sharedInstance.manualCensorshipCircumventionCountryCode = countryMetadata.countryCode;

    [self.navigationController popViewControllerAnimated:YES];
}

@end

NS_ASSUME_NONNULL_END
