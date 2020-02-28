
#import "AboutTableViewController.h"
#import "Signal-Swift.h"
#import "UIView+OWS.h"
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSPreferences.h>
#import <SignalMessaging/UIUtil.h>

@import SafariServices;

@implementation AboutTableViewController

#pragma mark - Dependencies

- (SDSDatabaseStorage *)databaseStorage
{
    return SDSDatabaseStorage.shared;
}

#pragma mark -

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"XXGJUSTHHANQS49", @"关于我们");
    
    UIImageView *topImg = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"bgXiao"]];
    topImg.frame = CGRectMake(0, 145, [UIScreen mainScreen].bounds.size.width, 60);
    topImg.contentMode = UIViewContentModeCenter;
    topImg.layer.shadowColor = UIColor.grayColor.CGColor;
    topImg.layer.shadowOffset = CGSizeMake(1, 1);
    topImg.layer.shadowOpacity = 0.5;
    topImg.layer.shadowRadius = 4;
    [self.view addSubview:topImg];
    
    
    NSString * tip = [NSString stringWithFormat:@"%@ 当前版本 %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    UILabel *tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 225, [UIScreen mainScreen].bounds.size.width-30, 30)];
    tipLabel.text = tip;
    tipLabel.font = UIFont.ows_dynamicTypeSubheadlineFont;
    tipLabel.textAlignment = 1;
    tipLabel.textColor = UIColor.blackColor;
    tipLabel.numberOfLines = 1;
    [self.view addSubview:tipLabel];
}
@end
