
#import <UIKit/UIKit.h>

@interface OWSLinkedDevicesTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

/**
 * This is used to show the user there is a device provisioning in-progress.
 */
- (void)expectMoreDevices;

@end
