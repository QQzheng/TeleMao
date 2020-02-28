
#import "OWSTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OWSNavigationController;

@interface AppSettingsViewController : OWSTableViewController

+ (OWSNavigationController *)inModalNavigationController;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
