
#import "OWSTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SignalServiceAddress;

@interface OWSAddToContactViewController : OWSTableViewController

- (void)configureWithAddress:(SignalServiceAddress *)address;

@end

NS_ASSUME_NONNULL_END
