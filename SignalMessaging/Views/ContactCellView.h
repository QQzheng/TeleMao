
NS_ASSUME_NONNULL_BEGIN

extern const CGFloat kContactCellAvatarTextMargin;

@class SDSAnyReadTransaction;
@class SignalServiceAddress;
@class TSThread;

@interface ContactCellView : UIStackView

@property (nonatomic, nullable) NSString *accessoryMessage;

/**
 lcy 20200229 群组，我点击查看群成员的时候，为什么我自己（13376824220）没有显示 群组里面查看联系人专用
 */
- (void)groupConfigureWithRecipientAddress:(SignalServiceAddress *)address;

- (void)configureWithRecipientAddress:(SignalServiceAddress *)address;

- (void)configureWithThread:(TSThread *)thread transaction:(SDSAnyReadTransaction *)transaction;

- (void)prepareForReuse;

- (NSAttributedString *)verifiedSubtitle;

- (void)setAttributedSubtitle:(nullable NSAttributedString *)attributedSubtitle;

- (BOOL)hasAccessoryText;

- (void)setAccessoryView:(UIView *)accessoryView;

@end

NS_ASSUME_NONNULL_END
