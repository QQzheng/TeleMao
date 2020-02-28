
#import "OWSViewController.h"
#import <SignalMessaging/ScreenLockViewController.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ShareViewDelegate;

@interface SAEScreenLockViewController : ScreenLockViewController

- (instancetype)initWithShareViewDelegate:(id<ShareViewDelegate>)shareViewDelegate;

@end

NS_ASSUME_NONNULL_END
