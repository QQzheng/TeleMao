
NS_ASSUME_NONNULL_BEGIN

@class SDSAnyReadTransaction;
@class SignalServiceAddress;
@class TSThread;

@interface ContactTableViewCell : UITableViewCell

+ (NSString *)reuseIdentifier;

// lcy 20200229 群组，我点击查看群成员的时候，为什么我自己（13376824220）没有显示
- (void)groupConfigureWithRecipientAddress:(SignalServiceAddress *)address;

- (void)configureWithRecipientAddress:(SignalServiceAddress *)address;

- (void)configureWithThread:(TSThread *)thread transaction:(SDSAnyReadTransaction *)transaction;

// This method should be called _before_ the configure... methods.
- (void)setAccessoryMessage:(nullable NSString *)accessoryMessage;

// This method should be called _after_ the configure... methods.
- (void)setAttributedSubtitle:(nullable NSAttributedString *)attributedSubtitle;

- (NSAttributedString *)verifiedSubtitle;

- (BOOL)hasAccessoryText;

- (void)ows_setAccessoryView:(UIView *)accessoryView;

@end

NS_ASSUME_NONNULL_END
