
#import "SelectThreadViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SignalAttachment;

@protocol ShareViewDelegate;

@interface SharingThreadPickerViewController : SelectThreadViewController

@property (nonatomic) NSArray<SignalAttachment *> *attachments;

- (instancetype)initWithShareViewDelegate:(id<ShareViewDelegate>)shareViewDelegate;

@end

NS_ASSUME_NONNULL_END
