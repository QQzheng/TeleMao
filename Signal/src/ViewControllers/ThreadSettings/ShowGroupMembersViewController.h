
#import "OWSTableViewController.h"

@class TSGroupThread;

@interface ShowGroupMembersViewController : OWSTableViewController

- (void)configWithThread:(TSGroupThread *)thread;

@end
